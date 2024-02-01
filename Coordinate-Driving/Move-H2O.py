#!/usr/bin/env python

import ase.io
import numpy as np

Filename = input('What is the COF filename? ')
COF_Name = input('What is the COF name? ')
Input_IDs = input('What are the IDs of the H2O atoms? ')

OutputGenFile = ase.io.read(Filename, format='gen')

MovedAtoms = []
for i in range(0,len(Input_IDs.split())):
    MovedAtoms.append(int(Input_IDs.split()[i]))

for i in (MovedAtoms):
    #print(OutputGenFile.positions[i-1][2])
    OutputGenFile.positions[i-1][2] = OutputGenFile.positions[i-1][2]-0.25
    #print(OutputGenFile.positions[i-1][2])

ase.io.write(f'{COF_Name}-CD-Input.gen', images=OutputGenFile, format='gen')