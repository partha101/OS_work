#include "kernel/spinlock.h" // Define spinlock functions
#include "kernel/types.h" // Define uint
#include "user/thread.h" // Define struct lock_t* lock
#include "user/user.h" // Define malloc
#define PGSIZE 4096

// This function creates a new thread which shares the parent's memory space
int thread_create(void *(start_routine)(void*), void *arg) {
  // Allocate memory of PGSIZE bytes for the new thread's stack
  void* st_ptr = (void* )malloc(PGSIZE * sizeof(void));

  // Create a new thread, passing the stack pointer to the clone system call
  int tid = clone(st_ptr);

  // If clone() returned 0, we're in the child thread
  if (tid == 0) {
    // Call the specified function with the given argument
    (*start_routine)(arg);

    // Once the function returns, terminate the thread with exit()
    exit(0);
  }

  // If clone() returned non-zero, we're in the parent thread. The return value of 
  // thread_create() should be 0 in this case.
  return 0;
}


// Function to initialize the lock
void lock_init(struct lock_t* lock) {
  lock->locked = 0;
}

void lock_acquire(struct lock_t* lock) {
    // This loop will keep trying to acquire the lock. 
    // The __sync_lock_test_and_set atomic builtin function sets the lock to 1 (locked state),
    // and if it was previously 0 (unlocked state), it breaks the loop, thus acquiring the lock.
    while(__sync_lock_test_and_set(&lock->locked, 1) != 0);

    // The __sync_synchronize function is a builtin function that emits a memory barrier, or a fence instruction on RISC-V.
    // It ensures that all explicit memory accesses that precede this call in the instruction stream are 
    // globally visible before any that follow it. This provides the guarantee of memory protection 
    // for the critical section following the lock acquisition.
    __sync_synchronize();
}


void lock_release(struct lock_t* lock) {
    // The __sync_synchronize function is a builtin function that emits a memory barrier, or a fence instruction on RISC-V.
    // It ensures that all explicit memory accesses (both loads and stores) within the critical section that 
    // precede this call in the instruction stream are globally visible before any that follow it. 
    // This guarantees memory consistency before the lock is released.
    __sync_synchronize();

    // The __sync_lock_release function is an atomic builtin that releases the lock.
    // It atomically sets the lock's state to 0 (unlocked). Using this function instead of a regular assignment ensures 
    // that the operation is completed in a single instruction, thus preventing potential race conditions.
    __sync_lock_release(&lock->locked);
}


