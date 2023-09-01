#!/usr/bin/env python

import ase.io

def Generate_Inclined(Filename, COF, Offset, OptZ):
    Monolayer = ase.io.read(Filename, format='vasp')
    Cell = Monolayer.get_cell()
    Positions = Monolayer.get_positions()
    MaxZ = max(Positions[:,2])
    OptZ = float(OptZ)
    Cell[2,2] = OptZ+MaxZ
    
    if Offset == 'AA':
        Monolayer.set_cell(Cell)
        ase.io.write(f'{COF}-{Offset}-Incl-POSCAR', images=Monolayer, format='vasp')
    if Offset == 'AB':
        Cell[2,0] = 0.5*Cell[0,0]
        Cell[2,1] = 0.5*Cell[1,1]
        Monolayer.set_cell(Cell)
        ase.io.write(f'{COF}-{Offset}-Incl-POSCAR', images=Monolayer, format='vasp')
    print(f'{COF}-{Offset}-Incl-POSCAR')

Filename = inputt('Filename: ')
COF = input('COF: ')
Offset = input('Offset: ')
OptZ = input('OptZ: ')

Generate_Inclined(Filename, COF, Offset, OptZ)