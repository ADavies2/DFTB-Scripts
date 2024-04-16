#!/usr/bin/env python

import ase.io
import numpy as np

Filename = input('What is the COF filename? ')
COF_Name = input('What is the COF name? ')
Input_IDs = input('What are the IDs of the H2O atoms? ')

if '.gen' in Filename:
    OutputFile = ase.io.read(Filename, format='gen')
elif 'POSCAR' in Filename:
    OutputFile = ase.io.read(Filename, format='vasp')

MovedAtoms = []
for i in range(0,len(Input_IDs.split())):
    MovedAtoms.append(int(Input_IDs.split()[i]))

for i in (MovedAtoms):
    OutputFile.positions[i-1][2] = OutputFile.positions[i-1][2]-0.25

if '.gen' in Filename:
    ase.io.write(f'{COF_Name}-CD-Input.gen', images=OutputFile, format='gen')
elif 'POSCAR' in Filename:
    ase.io.write(f'POSCAR', images=OutputFile, format='vasp')