// counter_rate.c
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>
#include <errno.h>
#include <string.h>

// ====== CHANGE THESE TWO TO MATCH YOUR DESIGN ======
#define PERIPH_BASEADDR     0x43C00000   // base of your simple_fifo / radio block
#define COUNTER_OFFSET      0x0c         // offset of the counter register
// ===================================================

#define MAP_SIZE   0x1000UL
#define MAP_MASK   (MAP_SIZE - 1)

static double timespec_diff_sec(struct timespec a, struct timespec b)
{
    // returns (b - a) in seconds
    double sec  = (double)(b.tv_sec - a.tv_sec);
    double nsec = (double)(b.tv_nsec - a.tv_nsec) / 1e9;
    return sec + nsec;
}

int main(void)
{
    int fd;
    void *map_base;
    volatile uint32_t *regs;
    struct timespec t0, t1;
    uint32_t c0, c1;
    double dt, rate;
    const uint64_t MOD32 = (uint64_t)1 << 32;

    // open /dev/mem
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "open(/dev/mem) failed: %s\n", strerror(errno));
        return 1;
    }

    off_t phys_base  = PERIPH_BASEADDR & ~MAP_MASK;
    off_t page_off   = PERIPH_BASEADDR &  MAP_MASK;

    map_base = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE,
                    MAP_SHARED, fd, phys_base);
    if (map_base == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        close(fd);
        return 1;
    }

    regs = (volatile uint32_t *)((uint8_t *)map_base + page_off);

    // first read
    clock_gettime(CLOCK_MONOTONIC, &t0);
    c0 = regs[COUNTER_OFFSET / 4];

    // wait ~1 second
    sleep(1);

    // second read
    clock_gettime(CLOCK_MONOTONIC, &t1);
    c1 = regs[COUNTER_OFFSET / 4];

    dt = timespec_diff_sec(t0, t1);

    // handle 32-bit wraparound
    uint64_t delta;
    if (c1 >= c0) {
        delta = (uint64_t)(c1 - c0);
    } else {
        delta = (uint64_t)c1 + (MOD32 - (uint64_t)c0);
    }

    rate = (double)delta / dt;

    printf("c0 = %u, c1 = %u, delta = %llu counts\n",
           c0, c1, (unsigned long long)delta);
    printf("elapsed time = %.6f s\n", dt);
    printf("increment rate ≈ %.3f Hz\n", rate);

    munmap(map_base, MAP_SIZE);
    close(fd);
    return 0;
}
