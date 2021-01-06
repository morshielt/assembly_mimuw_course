#!/usr/bin/python

import sys
import argparse
from collections import defaultdict
import numpy as np

# get command line args
parser = argparse.ArgumentParser("interpreter")
parser.add_argument("path_to_turing_machine",
                    help="Path to turing machine description \
                    .tm file to be interpreted.")
args = parser.parse_args()

# parse transitions to turing machine map:
# (state_from, letter) -> [(state_to, letter_out, direction)]
tm = defaultdict(list)
alphabet = set()

# szerokość wysokość waga
# pierwszy wiersz M
# ....
# ostatni wiersz M
# liczba-kroków
# pierwsze dane wejściowe
# ...
# ostatnie dane wejściowe

M = []
step = []

with open(args.path_to_turing_machine, "r") as f:

    ctr = 0
    for line in f:
        if ctr == 0:
            (szer, wys, waga) = line.split()
            szer = int(szer)
            wys = int(wys)
            waga = float(waga)
            a = [[0] * (szer+1) for i in range(wys)]
            tmp = [[0] * (szer+1) for i in range(wys)]
            # print(szer, wys, waga)
        elif ctr >= 1 and ctr <= wys:
            a[ctr-wys-1] = [0] + line.split()
            # M.append(line.split())
        elif ctr == wys + 1:
            # print(a)
            (steps) = line.split()
            for wiersz in range(wys):
                for kol in range(szer+1):
                    a[wiersz][kol] = float(a[wiersz][kol])
            for wiersz in range(wys):
                for kol in range(1, szer+1):
                    a[wiersz][kol] = a[wiersz][kol] - tmp[wiersz][kol]
                    # print(a[wiersz][kol])
                    print("%12.4f " % a[wiersz][kol], end='')
                print("")
            print("")
        else:
            step = line.split()
            for i in range(wys):
                a[i][0] = float(step[i])
            for wiersz in range(wys):
                for kol in range(1, szer+1):
                    if wiersz == 0:
                        tmp[wiersz][kol] = 3*a[wiersz][kol] - \
                            a[wiersz][kol-1] - \
                            a[wiersz+1][kol-1] - a[wiersz+1][kol]
                    elif wiersz == wys-1:
                        tmp[wiersz][kol] = 3*a[wiersz][kol] - \
                            a[wiersz][kol-1] - \
                            a[wiersz-1][kol-1] - a[wiersz-1][kol]
                    else:
                        tmp[wiersz][kol] = 5*a[wiersz][kol] - \
                            a[wiersz][kol-1] - \
                            a[wiersz+1][kol-1] - a[wiersz+1][kol] - \
                            a[wiersz-1][kol-1] - a[wiersz-1][kol]

                    tmp[wiersz][kol] = tmp[wiersz][kol] * waga
            for wiersz in range(wys):
                for kol in range(1, szer+1):
                    a[wiersz][kol] = a[wiersz][kol] - tmp[wiersz][kol]
                    # print(a[wiersz][kol])
                    print("%12.4f " % a[wiersz][kol], end='')
                print("")
            print("")

        ctr = ctr+1
