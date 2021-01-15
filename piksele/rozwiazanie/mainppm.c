#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void ppm(unsigned char* M, int rows, int cols, unsigned char RGB_shift,
         signed char change);

int main(int argc, char* argv[]) {
    // input file handling
    FILE *file, *output;

    if (argc != 4) {
        fprintf(stderr, "Usage: %s <input_file> <R/G/B> <[-127;127]>\n",
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
        unsigned char pixel_component;
        if (fscanf(file, "%hhu", &pixel_component) != 1) {
            printf("Error reading row %d\n", i / 3 / cols);
            exit(EXIT_FAILURE);
        }
        M[i] = pixel_component;
    }
    fclose(file);

    // call our assembly procedure
    ppm(M, rows, cols, RGB_shift, change);

    // create new filename
    char new_filename[strlen(argv[1]) + 1 + 1];

    int fst_slash = 0;
    i = strlen(argv[1]);
    int j = i;
    while (i > 0) {
        if (argv[1][i - 1] == '/' && !fst_slash) {
            fst_slash = 1;
            new_filename[j] = 'Y';
            i++;
        } else {
            new_filename[j] = argv[1][i - 1];
        }
        i--;
        j--;
    }

    if (!fst_slash) {
        new_filename[0] = 'Y';
    }
    new_filename[strlen(argv[1]) + 1] = '\0';

    // open/create output file
    if (!(output = fopen(new_filename, "w"))) {
        printf("Error fopen\n");
        exit(EXIT_FAILURE);
    }

    // write new image to file
    fprintf(output, "P3\n%d %d\n%d\n", cols, rows, max_);
    for (i = 0; i < size; i++) {
        fprintf(output, "%hhu ", M[i]);
        if (i % 3 == 2) fprintf(output, "\n");
    }
    fclose(output);

    exit(EXIT_SUCCESS);
}
