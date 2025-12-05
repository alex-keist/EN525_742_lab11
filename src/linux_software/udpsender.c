#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define PACKET_SIZE 1028        // 4-byte counter + 256 * (I,Q) = 4 + 256*4
#define PORTNUM 25344      

int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in dest;
    uint8_t buffer[PACKET_SIZE];
    int count;
	int port = PORTNUM;
    int i;

    if (argc < 3) {
        printf("Usage: %s <destination_ip> <count>\n", argv[0]);
        return 1;
    }
	
    char *dest_ip = argv[1]; //configurable destination ip
    count = atoi(argv[2]); //number of UDP packets to send
    if (count <= 0) count = 1;  


    sockfd = socket(AF_INET, SOCK_DGRAM, 0); //handle for socket using datagram (UDP) and using IPv4
    if (sockfd < 0) {
        perror("socket");
        return 1;
    }

    memset(&dest, 0, sizeof(dest));
    dest.sin_family = AF_INET;
    dest.sin_port = htons((uint16_t)port);
    if (inet_pton(AF_INET, dest_ip, &dest.sin_addr) != 1) {
        perror("inet_pton");
        close(sockfd);
        return 1;
    }

    for (i = 0; i < count; i++) {

        // zero everything first
        memset(buffer, 0, PACKET_SIZE);

        // bytes 0-3: 32-bit unsigned counter
        uint32_t seq = (uint32_t)i;
        memcpy(buffer, &seq, sizeof(uint32_t));

        // bytes 4-1027: 256 complex 16-bit samples: I, Q, I, Q...
        for (int sample = 0; sample < 256; sample++) {
            int16_t I = (int16_t)(sample + seq);      
            int16_t Q = (int16_t)(-(sample + seq));   

            size_t offset = 4 + sample * 4;           // 4 bytes per complex sample
            memcpy(&buffer[offset],     &I, sizeof(int16_t)); // I
            memcpy(&buffer[offset + 2], &Q, sizeof(int16_t)); // Q
        }

        ssize_t sent = sendto(sockfd,
                              buffer,
                              PACKET_SIZE,
                              0,
                              (struct sockaddr *)&dest,
                              sizeof(dest));

        if (sent < 0) {
            perror("sendto");
            close(sockfd);
            return 1;
        }

        printf("sent packet %d (bytes=%zd, seq=%u)\n", i + 1, sent, seq);
    }

    close(sockfd);
    return 0;
}
