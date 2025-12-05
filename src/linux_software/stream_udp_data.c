#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>


#define SIMPLE_FIFO_BASEADDR   0x43C10000 

#define FIFO_DATA_OFFSET   0x00    
#define FIFO_COUNT_OFFSET  0x04   

#define PACKET_SIZE    1028
#define PORTNUM 25344

volatile unsigned int * get_a_pointer(unsigned int phys_addr)
{

	int mem_fd = open("/dev/mem", O_RDWR | O_SYNC); 
	void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, phys_addr); 
	volatile unsigned int *fifo_base = (volatile unsigned int *)map_base; 
	return (fifo_base);
}


int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in dest;
    uint8_t buffer[PACKET_SIZE];
    int count;
	int port = PORTNUM;
    int i;

    if (argc < 2) {
        printf("Usage: %s <destination_ip>\n", argv[0]);
        return 1;
    }
	
    char *dest_ip = argv[1]; //configurable destination ip
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

	volatile unsigned int *fifo = get_a_pointer(SIMPLE_FIFO_BASEADDR);
	
    uint32_t seq = 0;
	printf("Starting streaming loop (Ctrl+C to stop)...\n");

	
	//fifo_count = *(SIMPLE_FIFO_BASEADDR+FIFO_COUNT_OFFSET);
	while (1){
		unsigned int fifo_count = fifo[FIFO_COUNT_OFFSET / 4];
		if (fifo_count >= 256){
			for(int i=0; i<256; i++){
				//read 256 samples into array and send as a packet?
			}
			//256 samples in fifo, send a packet
			// zero everything first
			memset(buffer, 0, PACKET_SIZE);

			// bytes 0-3: 32-bit unsigned counter
			seq = seq++;
			memcpy(buffer, &seq, sizeof(uint32_t));

			// bytes 4-1027: 256 complex 16-bit samples: I, Q, I, Q...
			for (int sample = 0; sample < 256; sample++) {
				uint32_t word = fifo[FIFO_DATA_OFFSET / 4];

				size_t offset = 4 + sample * 4;           // 4 bytes per complex sample
				memcpy(&buffer[offset], &word, sizeof(uint32_t)); // Q
			}

			ssize_t sent = sendto(sockfd,
								  buffer,
								  PACKET_SIZE,
								  0,
								  (struct sockaddr *)&dest,
								  sizeof(dest));
		}
	}

    
    close(sockfd);
    return 0;
}