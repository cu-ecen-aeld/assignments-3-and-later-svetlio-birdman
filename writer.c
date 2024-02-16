#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    // Check if both arguments are provided
    if (argc != 3) {
        fprintf(stderr, "Error: Please provide both writefile and writestr as arguments.\n");
        exit(EXIT_FAILURE);
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    // Write the content to the file
    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        fprintf(stderr, "Error: Could not create the file %s.\n", writefile);
        exit(EXIT_FAILURE);
    }

    fprintf(file, "%s", writestr);
    fclose(file);

    // Log the message to syslog
    openlog("writer_utility", LOG_PID, LOG_USER);
    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);
    closelog();

    printf("File created successfully: %s with content: %s\n", writefile, writestr);

    return 0;
}
