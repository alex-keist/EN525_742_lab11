#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>

#define SIMPLE_FIFO_BASEADDR   0x43C10000 

#define FIFO_DATA_OFFSET   0x00    
#define FIFO_COUNT_OFFSET  0x04   

#define TARGET_SAMPLES     480000

// mmap parameters
#define MAP_SIZE   0x1000UL
#define MAP_MASK   (MAP_SIZE - 1)


int main(void)
{
    int fd;
    void *map_base;
    volatile uint32_t *fifo_regs;
    uint32_t total_read = 0;

    printf("hello I am going to read 10 seconds worth of data now...\n");

    fd = open("/dev/mem", O_RDWR | O_SYNC);

    off_t phys_base = SIMPLE_FIFO_BASEADDR & ~MAP_MASK;
    off_t page_offset = SIMPLE_FIFO_BASEADDR & MAP_MASK;

    map_base = mmap(NULL,
                    MAP_SIZE,
                    PROT_READ | PROT_WRITE,
                    MAP_SHARED,
                    fd,
                    phys_base);

    fifo_regs = (volatile uint32_t *)((uint8_t *)map_base + page_offset);

    while (total_read < TARGET_SAMPLES) {
        uint32_t count = fifo_regs[FIFO_COUNT_OFFSET / 4];

        if (count == 0) {
            // nothing in FIFO
            usleep(1000);
            continue;
        }

        for (uint32_t i = 0;
             (i < count) && (total_read < TARGET_SAMPLES);
             i++)
        {
            volatile uint32_t data;

            data = fifo_regs[FIFO_DATA_OFFSET / 4];

            (void)data; 

            total_read++;
        }

		//print progress
        if ((total_read % 1000) == 0) {
            printf("Read %u samples so far...\n", total_read);
            fflush(stdout);
        }
    }

    printf("Finished! Total samples read: %u\n", total_read);


    return 0;
}
