#include "kernel/spinlock.h" // Define spinlock functions
#include "kernel/types.h" // Define uint
#include "user/thread.h" // Define struct lock_t* lock
#include "user/user.h" // Define malloc
#define PGSIZE 4096

int thread_create(void *(start_routine)(void*), void *arg) {

  // Give the st_ptr a size of PGSIZE bytes = 4096
  int ptr_size = PGSIZE*sizeof(void);
  void* st_ptr = (void* )malloc(ptr_size);
  int tid = clone(st_ptr);

  // Call the start_routine method for a child process with arg, which is tid = 0.
  if (tid == 0) {
    (*start_routine)(arg);
    exit(0);
  }

  // Parent process: return 0
  return 0;
}

// Lock initialization
void lock_init(struct lock_t* lock) {
  lock->locked = 0;
}

void lock_acquire(struct lock_t* lock) {
    // Inform the processor and the C compiler not to relocate any loads or stores
    // References only occur once the lock is acquired after this point to 
    // guarantee that the memory of the critical portion is protected.
    // This emits a fence instruction on RISC-V.
    while(__sync_lock_test_and_set(&lock->locked, 1) != 0);
    __sync_synchronize();
}

void lock_release(struct lock_t* lock) {
    // In order to make sure that all stores in the critical part are 
    // accessible to other CPUs before the lock is released and that 
    // all loads in the critical region occur strictly before the 
    // lock is released, tell the C compiler and CPU not to move loads 
    // or stores past this point.
    // This emits a fence instruction on RISC-V.
    __sync_synchronize();

    // Release the lock by writing lk->locked = 0. 
    // The C standard suggests that an assignment may be achieved with 
    // multiple store instructions, therefore this code does not employ an assignment.
    __sync_lock_release(&lock->locked, 0);
}

