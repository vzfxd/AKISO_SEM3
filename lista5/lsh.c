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

void execute(char* args[MAX_ARGS][MAX_ARGS]);
void handler(int sig_int);
int background;
int pid=0;

int main() {
    char line[MAX_LINE_LENGTH];
    char cwd[256];
    int argc;
    getcwd(cwd, sizeof(cwd));
    printf(YELLOW "%s" RESET RED " lsh> " RESET,cwd);
    signal(SIGINT, handler);
    while (fgets(line, MAX_LINE_LENGTH, stdin)) {
        char* args[MAX_ARGS][MAX_ARGS] = {};
        int pipes = 0;
        background = 0;

        char *pipe, *cmd;
        char *token = strtok_r(line,"|",&pipe);
        
        while(token!=NULL){
            char *token2 = strtok_r(token," \n",&cmd);
            argc = 0;
            while(token2 != NULL){
                args[pipes][argc++] = token2;
                token2 = strtok_r(NULL," \n",&cmd);
            }
            args[pipes][argc] = NULL;
            token = strtok_r(NULL, "|", &pipe);
            pipes++;
        }
        pipes--;
        if (pipes==0 && strcmp(args[0][argc-1], "&") == 0) {
            background = 1;
            args[0][--argc] = NULL;
        }
        
        if (strcmp(args[0][0], "exit") == 0) {
            return 0;
        } else if (strcmp(args[0][0], "cd") == 0) {
            if (args[0][1] == NULL) {
                fprintf(stderr, "lsh: expected argument to \"cd\"\n");
            } else {
                if (chdir(args[0][1]) != 0) {
                   perror("directory does not exists");
                }
            }
        } else execute(args);
        getcwd(cwd, sizeof(cwd));
        printf(YELLOW "%s" RESET RED " lsh> " RESET,cwd);
    }
    return 0;
}
    

void handler(int sig_num){
    if(pid!=0) kill(pid,SIGKILL);
}

void execute(char *args[MAX_ARGS][MAX_ARGS]) { 
    int fd[2];
    int i = 0;
    int fd_in = 0;
    while(args[i][0] != NULL){
        pipe(fd);
        pid = fork();
        if(pid==0){
            dup2(fd_in,0);
            if(args[i+1][0] != NULL) dup2(fd[1],1);
            close(fd[0]);
            execvp(args[i][0],args[i]);
            exit(0);
        }else{
            if(background==0){
                wait(NULL);
                close(fd[1]);
                fd_in = fd[0];
                i++;
            }else{
                signal(SIGCHLD,SIG_IGN);
                i++;
            }
            
        }
    }
}