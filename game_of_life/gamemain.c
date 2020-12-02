#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void start(int cols, int rows, char* T);
extern void run(int steps);

void print(char* T, int cols, int rows, int offset) {
    // size_t offset = 0 + shift * size / 2;

    printf(" ");
    for (size_t i = 0; i < rows; i++) {
        for (size_t j = 0; j < cols; j++) {
            if (T[i * cols + j + offset] == '0')
                printf("∙ ");
            else
                printf("\x1B[36m▪ \033[0m");
        }
        printf("\n ");
    }
}

int main(int argc, char* argv[]) {
    // input file handling
    FILE* file;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <board_file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    file = fopen(argv[1], "r");
    if (file == NULL) {
        printf("Error opening file %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    // reading number of columns and rows
    int cols, rows;

    if (fscanf(file, "%d%d", &cols, &rows) != 2) {
        printf("Error reading number of columns and rows");
        exit(EXIT_FAILURE);
    }

    // T contains 2 boards one after another
    // boards are used alternately:
    // if 1st is current, then 2nd is next
    // if 2nd is current, then 1st is next
    int size = cols * rows * 2;
    char T[size];

    // reading the board
    for (int i = 0; i < size / 2; i++) {
        int cell;
        if (fscanf(file, "%d", &cell) != 1) {
            printf("Error reading row %d\n", (i % cols + 1));
            exit(EXIT_FAILURE);
        }
        T[i] = cell + '0';
    }
    fclose(file);

    // cleaning the 2nd board
    for (int i = size / 2; i < size; i++) {
        T[i] = '0';
    }

    int ctr = 0, steps;
    char buffer[16];
    int STOP = -1;

    start(cols, rows, T);
    print(T, cols, rows, ctr * size / 2);

    // reading number of steps from input
    // and priniting according board
    while (1) {
        printf("[quit `%d`] [<n> steps `n`] ", STOP);

        if (fgets(buffer, sizeof(buffer), stdin) == NULL) break;

        steps = strtol(buffer, NULL, 10);
        if (steps == STOP) break;
        if (steps != 0) {
            run(steps);
            ctr = (ctr + steps) % 2;
            print(T, cols, rows, ctr * size / 2);
        }
    }

    exit(EXIT_SUCCESS);
}
