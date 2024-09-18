#define HEAP_SIZE 1000000
#define ALIGN 4
#define HEADER_SIZE 8

#define BLOCK_NEXT_IDX 0
#define BLOCK_SIZE_IDX 1

// K&R-inspired basic heap.

// The heap is organized as a free list of blocks. Each block has a header consisting of:
// - A pointer to the next free block (4 bytes)
// - The size of the current block in units (4 bytes)

// The total header size is 8 bytes (HEADER_SIZE).

// The free list is a circular linked list of free blocks.
// 'freep' points to the last block we looked at in the free list.

#define STACK_SIZE 10240

int* heap;
int* freep = 0;
extern int __program_end__;

void init_heap() {
    int memsize = _syscall_getmemsize();
    int heap_size = (memsize - STACK_SIZE) - __program_end__;

    heap_size = heap_size / HEADER_SIZE;
    heap = __program_end__;

    heap[BLOCK_NEXT_IDX] = heap; // Initialize ptr to itself (circular list)
    heap[BLOCK_SIZE_IDX] = heap_size; // Initialize size to full heap

    freep = heap;
}

// Function to allocate memory
void* _malloc(unsigned nbytes) {
    int* p;
    int* prevp;
    unsigned nunits;
    unsigned size;
    int remaining_size;
    int* base;

    // Calculate the number of units needed, including the header
    // A unit is the smallest allocatable block of memory, which is equal to HEADER_SIZE (8 bytes).
    // This ensures that all allocations are aligned to 8-byte boundaries and can fit at least
    // one header (for free list management).
    nunits = ((nbytes + HEADER_SIZE - 1) / HEADER_SIZE) + 1;

    prevp = freep;

    // Search for a free block of sufficient size
    p = *prevp;
    while (1) {
        size = p[BLOCK_SIZE_IDX];
        if (size >= nunits) {  // Found a block big enough
            if (size == nunits) {
                // Exact fit
                prevp[BLOCK_NEXT_IDX] = p[BLOCK_NEXT_IDX];
            } else {
                // Allocate tail end
                remaining_size = size - nunits;
                p[BLOCK_SIZE_IDX] = remaining_size;
                p = p + (nunits * HEADER_SIZE);
                p[BLOCK_SIZE_IDX] = nunits;  // Set size
            }
            freep = prevp;
            return p + HEADER_SIZE;  // Return pointer to usable space
        }
        if (p == freep) {
            // Wrapped around free list
            fatal("Out of memory");
        }
        prevp = p;
        p = *p;
    }
}

// Function to free allocated memory
void free(char* ap) {
    int* bp = ap - HEADER_SIZE;
    int size = bp[BLOCK_SIZE_IDX];
    int* p;
    int* next;
    int a;
    int b;

    // Find the block in the free list where bp should be inserted
    p = freep;
    while (1) {
        next = p[BLOCK_NEXT_IDX];
        if (p >= next) {
            a = bp > p;
            b = bp < next;
            if ((a || b) || !(a && b)) {
                // Join to upper neighbor
                if ((bp + (size * HEADER_SIZE)) == next) {
                    size = size + next[BLOCK_SIZE_IDX];
                    bp[BLOCK_NEXT_IDX] = next[BLOCK_NEXT_IDX];
                } else {
                    bp[BLOCK_NEXT_IDX] = next;
                }

                // Join to lower neighbor
                if (p + (p[BLOCK_SIZE_IDX] * HEADER_SIZE) == bp) {
                    p[BLOCK_SIZE_IDX] = p[BLOCK_SIZE_IDX] + size;
                    p[BLOCK_NEXT_IDX] = bp[BLOCK_NEXT_IDX];
                } else {
                    p[BLOCK_NEXT_IDX] = bp;
                }

                freep = p;  // Reset the free list pointer
                return;
            }
        }
        p = p[BLOCK_NEXT_IDX];
    }
}

// Function to dump the heap state
void dump_heap() {
    int* p = freep;
    int count = 0;

    printf("Heap dump, %d:\n", freep);
    while (1) {
        printf("Block %d: Address: %p, Size: %d, Next: %d\n", count, p, p[BLOCK_SIZE_IDX], p[BLOCK_NEXT_IDX]);
        p = p[BLOCK_NEXT_IDX];
        count = count + 1;
        
        // Safeguard against infinite loops
        if (count > 1000) {
            fatal("Warning: Possible circular list detected.");
        }

        if (p == freep) {
            printf("Total free blocks: %d\n", count);
            return;
        }
    }
}
