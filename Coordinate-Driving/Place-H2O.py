#!/usr/bin/env python

# This Python script will place an H2O molecule within the unit cell of a COF
# The inputs are the Filename of the COF and the desired coordinates for the oxygen atom in H2O
# I have been taking these coordinates as half of the x-coordinates within a pore, half of the y-coordinates, and the value of the simulation cell vector in zz
# Give these coordinates as space separated values, not comma separated

import ase.io
import numpy as np

Filename = input('What is the COF filename? ')
COF_Name = input('What is the COF name? ')
Coordinates_Input = input('What are the desired coordinates for H2O? ')

Coordinates_For_H2O = []
for i in range(0,len(Coordinates_Input.split())):
    Coordinates_For_H2O.append(float(Coordinates_Input.split()[i]))

COF = ase.io.read(Filename, format='vasp')
Water = ase.io.read('water.vasp', format='vasp') # Third atom is oxygen
# Move the oxygen atom to be centered on the Coordinates_For_H2O

New_H2O = []
for i in range(0,len(Water.get_positions())): # move through each atom in H2O
    new_coords = []
    for j in range(0,len(Water.get_positions()[i])): # move through x, y, z coordiget_positionsch atom
        shift = abs(Water.get_positions()[2,j]-Coordinates_For_H2O[j]) # Oxygen atom is shifted to user-defined coordinates. All other atoms are shifted by an equal amount
        if Coordinates_For_H2O[j] <= 0:
            new_coords.append(Water.get_positions()[i,j]-shift)
        else:
            new_coords.append(Water.get_positions()[i,j]+shift)
    New_H2O.append(new_coords)
    
New_H2O = np.array(New_H2O)

Water.set_positions(New_H2O) # Move the H2O coordinates to the new position

With_H2O = COF+Water # Add the H2O coordinates to the COF. Keep the original COF unit cell

ase.io.write(f'{COF_Name}-H2O-POSCAR', images=With_H2O, format='vasp')