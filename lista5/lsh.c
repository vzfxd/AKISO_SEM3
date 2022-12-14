#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>

#define MAX_LINE_LENGTH 256
#define MAX_ARGS 64
#define RED  "\x1B[31m"
#define YELLOW  "\x1B[33m"
#define RESET   "\033[0m"

void execute(int background, char* args[MAX_ARGS]);

int main() {
    char* args[MAX_ARGS];
    char line[MAX_LINE_LENGTH];
    int background;
    char cwd[256];
    getcwd(cwd, sizeof(cwd));
    printf(YELLOW "%s" RESET RED " lsh> " RESET,cwd);
    while (fgets(line, MAX_LINE_LENGTH, stdin)) {
        background = 0;
        char* arg = strtok(line, " \t\n");;
        int argc = 0;
        while (arg != NULL) {
            args[argc++] = arg;
            arg = strtok(NULL, " \t\n");
        }
        if (strcmp(args[argc - 1], "&") == 0) {
                background = 1;
                args[--argc] = NULL;
        }else{
            args[argc] = NULL;
        }
        

        
        if (strcmp(args[0], "exit") == 0) {
            return 0;
        } else if (strcmp(args[0], "cd") == 0) {
            if (args[1] == NULL) {
                fprintf(stderr, "lsh: expected argument to \"cd\"\n");
            } else {
                if (chdir(args[1]) != 0) {
                    perror("lsh");
                }
            }
        } else {
            execute(background, args);
        }
        if (!background) wait(NULL);
        getcwd(cwd, sizeof(cwd));
        printf(YELLOW "%s" RESET RED " lsh> " RESET,cwd);
    }
    return 0;
}

void execute(int background, char *args[MAX_ARGS]) {
    if (fork() == 0) {
        if (execvp(args[0], args) == -1) {
            perror("lsh");
        }
        exit(0);
    }else if (background == 0){
        wait(NULL);
    }else{
        signal(SIGCHLD,SIG_IGN);
        fprintf(stdout, "dziecko uruchomiło się w tle\n");
    }
}
