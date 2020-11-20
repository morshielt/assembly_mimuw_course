#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void start(int cols, int rows, char* T);
extern void run(int steps);

int ctr = 0;

void start2222222(int cols, int rows, char* T) {}
void run22222222(int steps, int cols, int rows, char* T, int size) {
    for (size_t step = 0; step < steps; step++) {
        int from = (ctr % 2) * cols * rows;
        // printf("from: %d\n", from);
        int to = ((from + 1) % 2) * cols * rows;
        // printf("to: %d\n", to);

        for (size_t r = 0; r < rows; r++) {
            for (size_t c = 0; c < cols; c++) {
                int neighbours = 0;

                for (int j = -1; j <= 1; j++) {
                    for (int i = -1; i <= 1; i++) {
                        if (c + i >= 0 && c + i < cols && r + j >= 0 &&
                            r + j < rows) {
                            if (T[(r + j) * cols + (c + i) + from] == '1')
                                neighbours++;
                        }
                    }
                }

                if (T[r * cols + c + from] == '1') neighbours--;
                // printf("%d\n", neighbours);
                if (neighbours == 3 ||
                    (neighbours == 2 && T[r * cols + c + from] == '1')) {
                    T[r * cols + c + to] = '1';
                } else {
                    T[r * cols + c + to] = '0';
                }
            }
        }

        ctr++;
    }
}

void print(char* T, int size, int cols) {
    printf("\n ");
    for (size_t i = 0; i < size; i++) {
        if (i % cols == 0 && i != 0) {
            printf("\n ");
        }
        if (i == (size / 2)) {
            printf("\n ");
        }
        if (T[i] == '0')
            printf("\x1B[0m∙ \033[0m");
        else
            printf("\x1B[36m▪ \033[0m");
        // printf("%c ", T[i]);
    }
    printf("\n-----------------------------------\n");
}

int main(int argc, char* argv[]) {
    int cols = 9, rows = 9;
    // int cols = 3, rows = 3;
    int size = cols * rows * 2;
    char T[size];
    // = {'0'};

    for (size_t i = 0; i < size; i++) {
        T[i] = '0';
    }

    T[3 * rows + 3] = '1';
    T[3 * rows + 5] = '1';
    T[4 * rows + 3] = '1';
    T[4 * rows + 4] = '1';
    T[4 * rows + 5] = '1';
    T[5 * rows + 4] = '1';
    // T[3] = '1';
    // T[4] = '1';
    // T[5] = '1';

    print(T, size, cols);
    start(cols, rows, T);
    for (size_t i = 0; i < 5; i++) {
        run(2);  // TODO: check run(0);
        print(T, size, cols);
    }

    //     FILE *stream;
    //     char *line = NULL;
    //     size_t len = 0;
    //     ssize_t nread;

    //     if (argc != 2) {
    //         fprintf(stderr, "Usage: %s <file>\n", argv[0]);
    //         exit(EXIT_FAILURE);
    //     }

    //     stream = fopen(argv[1], "r");
    //     if (stream == NULL) {
    //         perror("fopen");
    //         exit(EXIT_FAILURE);
    //     }

    //     const int MAX_NUM_LEN = 128;
    //     char cols[MAX_NUM_LEN], rows[MAX_NUM_LEN];
    //     int cols, rows;
    //     if ((nread = getline(&line, &len, stream)) != -1) {
    //     }

    //     while ((nread = getline(&line, &len, stream)) != -1) {
    //         printf("Retrieved line of length %zd:\n", nread);
    //         fwrite(line, nread, 1, stdout);
    //     }

    //     free(line);
    //     fclose(stream);
    //     exit(EXIT_SUCCESS);
    // }
}
