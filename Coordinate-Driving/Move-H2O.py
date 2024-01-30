#!/usr/bin/env python

import ase.io
import numpy as np

Filename = input('What is the COF filename? ')
COF_Name = input('What is the COF name? ')
MovedAtoms = (85, 86, 87)
OutputGenFile = ase.io.read(Filename, format='gen')

for i in (MovedAtoms):
    OutputGenFile.positions[i-1][2] = OutputGenFile.positions[i-1][2]-0.25

ase.io.write(f'{COF_Name}-CD-Input.gen', images=OutputGenFile, format='gen')