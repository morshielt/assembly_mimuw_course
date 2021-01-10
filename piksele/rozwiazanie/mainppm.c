#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void ppm(unsigned char* M, int cols, int rows, unsigned char RGB_shift,
         signed char change);

// void generate_pgm(unsigned char* M, int size, int R, int G, int B);

int main(int argc, char* argv[]) {
    // input file handling
    FILE *file, *output;

    if (argc != 4) {
        fprintf(stderr, "Usage: %s <input_file>\n <R/G/B> <[-127;127]>",
                argv[0]);
        exit(EXIT_FAILURE);
    }
    char RGB = argv[2][0];
    unsigned char RGB_shift;
    if (RGB == 'R') {
        RGB_shift = 1;
    } else if (RGB == 'G') {
        RGB_shift = 2;
    } else if (RGB == 'B') {
        RGB_shift = 3;
    } else {
        fprintf(stderr, "Usage: %s <input_file>\n <R/G/B> <[-127;127]>",
                argv[0]);
        exit(EXIT_FAILURE);
    }

    signed char change = strtol(argv[3], NULL, 10);

    file = fopen(argv[1], "r");
    if (file == NULL) {
        printf("Error opening file %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    // reading number of columns, rows and max_
    int cols, rows, max_;

    if (fscanf(file, "P3 %d%d%d", &cols, &rows, &max_) != 3) {
        printf("Error reading number of columns, rows and max");
        exit(EXIT_FAILURE);
    }

    int size = cols * rows * 3;
    unsigned char M[size];

    int i;
    for (i = 0; i < size; i++) {
        M[i] = 0;
    }

    // reading the matrix
    for (i = 0; i < size; i++) {
        unsigned char pixel_third;
        if (fscanf(file, "%hhu", &pixel_third) != 1) {
            printf("Error reading row %d\n", i / 3 / cols);
            exit(EXIT_FAILURE);
        }
        M[i] = pixel_third;
    }
    fclose(file);

    int r_multiplier = 77, g_multiplier = 151, b_multiplier = 28;
    // generate_pgm(M, size, r_multiplier, g_multiplier, b_multiplier);
    ppm(M, cols, rows, RGB_shift, change);

    argv[1][strlen(argv[1]) - 5] = 'X';
    printf("%s]\n", argv[1]);
    if (!(output = fopen(argv[1], "w"))) {
        printf("Error fopen\n");
        exit(EXIT_FAILURE);
    }

    fprintf(output, "P3\n%d %d\n%d\n", cols, rows, max_);
    for (i = 0; i < size; i++) {
        fprintf(output, "%hhu ", M[i]);
        if (i % 3 == 2) fprintf(output, "\n");
    }
    fclose(output);

    exit(EXIT_SUCCESS);
}
