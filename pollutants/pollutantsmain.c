#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void start(int cols, int rows, float* M, float weight);
void step(float P[]);

void print(float* M, int colsM, int rowsM) {
    for (int i = 1; i < colsM - 1; i++) {
        // TODO: ensure that number below is correct
        for (int j = 1; j < rowsM / 2 + 1; j++) {
            // printf("[%2d] ", (i + j * colsM));
            printf("%f ", M[i + j * colsM]);
        }
        printf("\n");
    }
    printf("\n");
}

void big_print(float* M, int colsM, int rowsM) {
    printf(" ");
    for (int j = 0; j < rowsM; j++) {
        for (int i = 0; i < colsM; i++) {
            printf("[%3d] ", (i + j * colsM));
            printf("%f ", M[i + j * colsM]);
        }
        printf("\n ");
    }
    printf("\n");
}

int main(int argc, char* argv[]) {
    // input file handling
    FILE* file;

    // if (argc != 2) {
    //     fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
    //     exit(EXIT_FAILURE);
    // }

    // file = fopen(argv[1], "r");
    file = fopen("example.txt", "r");
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
    // TODO: accept size at least 3x3 (wywalą się obliczenia przy mniejszych!)

    printf("weight = %f\n", weight);

    // M symbolic structure (width = 1+rows+1, length = 1 + 2*cols):
    // (columns are in fact rows - we keep the input matrix transposed
    // to enable convenient SSE operations)
    // [0][current input  ][0]
    // [0][column 1       ][0]
    // [0][column 2       ][0]
    // [        ...          ]
    // [0][last column    ][0]
    // [0][tmp column 1   ][0]
    // [0][tmp column 2   ][0]
    // [        ...          ]
    // [0][tmp last column][0]
    // TODO: 1st row/col contains new data from input (we rewrite it in asm)
    // left and right border are padded by 0s for convenience
    // in tmp matrix we'll keep sums of the neighbours

    int colsM = (1 + rows + 1);
    int rowsM = 1 + 2 * cols;
    int sizeM = colsM * rowsM;
    float M[sizeM];

    for (int i = 0; i < sizeM; i++) {
        M[i] = 0;
    }

    printf("rowsM = %d\n", rowsM);
    printf("colsM = %d\n", colsM);
    // reading the matrix
    for (int i = 1; i < colsM - 1; i++) {
        for (int j = 1; j < rowsM / 2 + 1; j++) {
            // TODO: ensure that number below is correct
            float cell;
            if (fscanf(file, "%f", &cell) != 1) {
                printf("Error reading row %d\n", j);
                exit(EXIT_FAILURE);
            }
            M[i + j * colsM] = cell;
        }
    }

    big_print(M, colsM, rowsM);

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

    for (int s = 0; s < steps; s++) {
        printf("step vector: [0 ");
        for (int i = 1; i < colsM - 1; i++) {
            // TODO: ensure that number below is correct
            float cell;
            if (fscanf(file, "%f", &cell) != 1) {
                printf("Error reading step vector");
                exit(EXIT_FAILURE);
            }
            step_vector[i] = cell;
            printf("%f ", cell);
        }
        printf("0]\n");
        step(step_vector);
        big_print(M, colsM, rowsM);
        print(M, colsM, rowsM);
    }
    fclose(file);

    exit(EXIT_SUCCESS);
}
