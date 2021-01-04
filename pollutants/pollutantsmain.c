#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void start(int cols, int rows, float* M, float weight);
void step(float P[]);

void print(float* M, int colsM, int rowsM) {
    for (int i = 1; i < colsM - 1; i++) {
        for (int j = 1; j < rowsM / 2 + 1; j++) {
            printf("%12.6f ", M[i + j * colsM]);
        }
        printf("\n");
    }
    printf("\n");
}

// void big_print(float* M, int colsM, int rowsM) {
//     printf(" ");
//     for (int j = 0; j < rowsM; j++) {
//         for (int i = 0; i < colsM; i++) {
//             printf("[%3d] ", (i + j * colsM));
//             printf("%f ", M[i + j * colsM]);
//         }
//         printf("\n ");
//     }
//     printf("\n");
// }

int main(int argc, char* argv[]) {
    // input file handling
    FILE* file;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    file = fopen(argv[1], "r");
    // file = fopen("example2.txt", "r");
    if (file == NULL) {
        printf("Error opening file %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    // reading number of columns, rows and weight
    int cols, rows;
    float weight;

    if (fscanf(file, "%d%d%f", &cols, &rows, &weight) != 3) {
        printf("Error reading number of columns, rows and weight");
        exit(EXIT_FAILURE);
    }

    if (cols < 3 || rows < 3) {
        printf("Program works on matrices of size at least 3x3.");
        exit(EXIT_FAILURE);
    }

    // M symbolic structure (width = 1+rows+1, length = 1 + 2*cols):
    // (columns are in fact rows - we keep the input matrix transposed
    // to enable convenient SSE operations)
    // [0][current input  ][0] // 1st row/col contains new data from input (we
    // rewrite it in asm) [0][column 1       ][0] [0][column 2       ][0] [ ...
    // ] [0][last column    ][0] [0][tmp column 1   ][0] [0][tmp column 2   ][0]
    // [        ...          ]
    // [0][tmp last column][0]
    // left and right border are padded by 0s for convenience
    // in tmp matrix (bottom half of the matrix) we'll keep sums of the
    // neighbours

    int colsM = (1 + rows + 1);
    int rowsM = 1 + 2 * cols;
    int sizeM = colsM * rowsM;
    float M[sizeM];

    for (int i = 0; i < sizeM; i++) {
        M[i] = 0;
    }

    // reading the matrix
    for (int i = 1; i < colsM - 1; i++) {
        for (int j = 1; j < rowsM / 2 + 1; j++) {
            float cell;
            if (fscanf(file, "%f", &cell) != 1) {
                printf("Error reading row %d\n", j);
                exit(EXIT_FAILURE);
            }
            M[i + j * colsM] = cell;
        }
    }

    // reading number of steps from input
    // and priniting according board
    int steps;
    if (fscanf(file, "%d", &steps) != 1) {
        printf("Error reading number of steps");
        exit(EXIT_FAILURE);
    }

    float step_vector[rowsM];
    for (int i = 0; i < colsM; i++) {
        step_vector[i] = 0;
    }

    start(colsM, rowsM, M, weight);
    print(M, colsM, rowsM);

    // reading step vectors, performing step calculations and printing result
    for (int s = 0; s < steps; s++) {
        for (int i = 1; i < colsM - 1; i++) {
            float cell;
            if (fscanf(file, "%f", &cell) != 1) {
                printf("Error reading step vector");
                exit(EXIT_FAILURE);
            }
            step_vector[i] = cell;
        }
        step(step_vector);
        print(M, colsM, rowsM);
    }

    fclose(file);

    exit(EXIT_SUCCESS);
}
