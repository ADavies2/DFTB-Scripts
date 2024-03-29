#!/usr/bin/env python

# This is a Python function that generates the .vasp file for single-point calculation scanning of the X, Y, Z offset and layer stacking in order to generate a potential energy surface and determine a starting configuration with the most favorable potential energy
# NOTE: In order for this script to work correctly with the automated bash scripts, Python version 3 MUST be used for ASE

import ase.io

def Generate_New_VASP(Filename, COF, Axis, Change, Optimized_Z, X_Shift):
# Filename should be either a path to a VASP file or the VASP filename if located in directory
# Axis should be X, Y, or Z, which indicates which cell parameter will be changed
# Change should be either an integer (for Z) or a decimal indicating a percent of the simulation cell (for X and Y)
# If the Z scanning has been done, an optimum Z spacing has been determined. This script will ask for that optimized framework before moving into generating the X and Y scanning geometries.
# Provided with the filename (assuming a VASP file) of a COF monolayer, read the file in as an Atoms object
    import ase.io
    Monolayer = ase.io.read(Filename, format='vasp')
    Cell = Monolayer.get_cell()
    Total_Atoms = len(Monolayer)
    Change = float(Change)
# Change the cell parameter in the decided axis by the given amount
# If changing Z, change the simulation cell parameters
    if Axis == 'Z':
        Positions = Monolayer.get_positions()
        MaxZ = max(Positions[:,2])
        Cell[2,2] = Change+MaxZ
        Monolayer.set_cell(Cell)
        TwoLayer = Monolayer.repeat([1,1,2])
# If changing X or Y, shift the positions of the second layer of atoms
# This is assuming that the Z has already been scanned at AA stacking
    elif Axis == 'XY':
# Set the replicated layer at Z spacing that has been previously optimized
        Optimized_Z = float(Optimized_Z)
        X_Shift = float(X_Shift)
        Positions = Monolayer.get_positions()
        MaxZ = max(Positions[:,2])
        Cell[2,2] = Optimized_Z+MaxZ
        Monolayer.set_cell(Cell)
        TwoLayer = Monolayer.repeat([1,1,2])
# Now set-up X and Y shift
        y_shift = Change*Cell[1,1]
        x_shift = X_Shift*Cell[0,0]
        for i in range(Total_Atoms, len(TwoLayer)):
            TwoLayer[i].position[1] += y_shift
            TwoLayer[i].position[0] += x_shift
# At this point, either the system has been replicated (in the case of Z scanning) or the coordinates of the replicated atoms have been shifted (in the case of X and Y scanning)
    ase.io.write(f'{COF}-{Change}{Axis}-POSCAR', images=TwoLayer, format='vasp')
    print(f'{COF}-{Change}{Axis}-POSCAR')

Filename = input('Filename: ')
COF = input('COF: ')
Axis = input('Axis: ').upper()
Change = input('Integer or Percent Decimal: ')
if Axis == 'XY':
    OptZ = input('Optimized Z: ')
    X_Shift = input('X Shift: ')
else:
    OptZ = 0
    X_Shift = 0

Generate_New_VASP(Filename, COF, Axis, Change, OptZ, X_Shift)