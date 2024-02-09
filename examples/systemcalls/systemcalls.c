#include "systemcalls.h"
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>

bool do_system(const char *cmd)
{
    int ret = system(cmd);
    return ret == 0;
}

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    pid_t pid = fork();

    if (pid == -1)
    {
        perror("Fork failed");
        va_end(args);
        return false;
    }
    else if (pid == 0)
    {
        // Child process
        execv(command[0], command);
        // execv only returns if an error occurs
        perror("Execv failed");
        exit(EXIT_FAILURE);
    }
    else
    {
        // Parent process
        int status;
        waitpid(pid, &status, 0);
        va_end(args);

        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
}

bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    pid_t pid = fork();

    if (pid == -1)
    {
        perror("Fork failed");
        va_end(args);
        return false;
    }
    else if (pid == 0)
    {
        // Child process

        // Open the output file for writing, creating it if it doesn't exist
        int fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0666);

        if (fd == -1)
        {
            perror("Open failed");
            exit(EXIT_FAILURE);
        }

        // Redirect standard output to the file
        dup2(fd, STDOUT_FILENO);

        // Close the file descriptor as it's no longer needed
        close(fd);

        // Execute the command
        execv(command[0], command);

        // execv only returns if an error occurs
        perror("Execv failed");
        exit(EXIT_FAILURE);
    }
    else
    {
        // Parent process
        int status;
        waitpid(pid, &status, 0);
        va_end(args);

        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
}
