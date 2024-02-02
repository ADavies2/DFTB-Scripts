#!/usr/bin/env python

import numpy as np
import ase.io

COFName = input('What is the COF name? ')
Filetype = input('What is the file type? ')
Filename = input('What is the filename? ')

if Filetype == 'vasp' or 'POSCAR':
    COF = ase.io.read(Filename, format='vasp')
elif Filetype == 'gen':
    COF = ase.io.read(Filename, format='gen')

c_counter = 0; o_counter = 0; h_counter = 0; n_counter = 0; f_counter = 0; s_counter = 0
for i in COF.get_chemical_symbols():
    if i == 'C':
        c_counter += 1
    if i == 'O':
        o_counter += 1
    if i == 'H':
        h_counter += 1
    if i == 'N':
        n_counter += 1
    if i == 'F':
        f_counter += 1
    if i == 'S':
        s_counter += 1

with open(f'{COFName}.densities', 'w') as file:
    file.write(f'O {o_counter} {o_counter/len(COF)}\n')
    file.write(f'C {c_counter} {c_counter/len(COF)}\n')
    file.write(f'H {h_counter} {h_counter/len(COF)}\n')
    file.write(f'N {n_counter} {n_counter/len(COF)}\n')
    file.write(f'F {f_counter} {f_counter/len(COF)}\n')
    file.write(f'S {s_counter} {s_counter/len(COF)}')