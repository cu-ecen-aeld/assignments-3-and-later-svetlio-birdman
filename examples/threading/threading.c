#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// #define DEBUG_LOG(msg,...)
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;

    // Sleep for wait_to_obtain_ms milliseconds
    usleep(thread_func_args->wait_to_obtain_ms * 1000);

    // Obtain the mutex
    pthread_mutex_lock(thread_func_args->mutex);

    // Sleep for wait_to_release_ms milliseconds
    usleep(thread_func_args->wait_to_release_ms * 1000);

    // Release the mutex
    pthread_mutex_unlock(thread_func_args->mutex);

    // Set thread completion status to true
    thread_func_args->thread_complete_success = true;

    return thread_param;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex, int wait_to_obtain_ms, int wait_to_release_ms)
{
    // Allocate memory for thread_data
    struct thread_data* thread_args = (struct thread_data*)malloc(sizeof(struct thread_data));
    if (thread_args == NULL) {
        ERROR_LOG("Failed to allocate memory for thread_data");
        return false;
    }

    // Set up thread arguments
    thread_args->mutex = mutex;
    thread_args->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_args->wait_to_release_ms = wait_to_release_ms;
    thread_args->thread_complete_success = false;

    // Create the thread
    if (pthread_create(thread, NULL, threadfunc, (void*)thread_args) != 0) {
        ERROR_LOG("Failed to create thread");
        free(thread_args); // Free allocated memory in case of failure
        return false;
    }

    // Thread created successfully
    return true;
}
