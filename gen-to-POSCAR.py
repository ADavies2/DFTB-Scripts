#!/usr/bin/env python3.12
# Author: Alathea Davies

import pandas as pd

GenFile = input('What is the name of your .gen file? ')
PoscarFile = input('What would you like your POSCAR file to be called? ')

GenData = pd.read_csv(GenFile, header=None, skiprows=2, skipfooter=4, sep='\\s+', names=['Index','Type','X','Y','Z'], engine='python')
TotalAtoms = len(GenData)
SkipCellRows = TotalAtoms + 2 + 1
CellData = pd.read_csv(GenFile, header=None, sep='\\s+', skiprows=SkipCellRows)

raw_data = open(GenFile,'r')
Lines = raw_data.readlines()
AtomTypes = Lines[1].split()
del Lines, raw_data

Header = "POSCAR from DFTB+ out.gen\n" # First line in POSCAR file
Scaling = "1\n" # second line in POSCAR file
with open(PoscarFile, 'w') as file: # Create a file to write to
    file.write(Header)
    file.write(Scaling)
    for i in range(0,len(CellData)):
        cell = f"{CellData.iloc[i][0]} {CellData.iloc[i][1]} {CellData.iloc[i][2]}\n"
        file.write(cell)
    for i in range(0,len(AtomTypes)):
        file.write(f'{AtomTypes[i]} ')
    file.write('\n')
    type = 1
    for i in AtomTypes:
        count = 0
        for k in range(0,TotalAtoms):
            if GenData['Type'].iloc[k] == type:
                count += 1
        file.write(f'{count} ')
        type += 1
    file.write('\n')
    file.write('Cartesian\n')
    type = 1
    for i in AtomTypes:
        for k in range(0,TotalAtoms):
            if GenData['Type'].iloc[k] == type:
                if k == len(GenData)-1:
                    file.write(f"{GenData['X'].iloc[k]} {GenData['Y'].iloc[k]} {GenData['Z'].iloc[k]}")
                else:
                    file.write(f"{GenData['X'].iloc[k]} {GenData['Y'].iloc[k]} {GenData['Z'].iloc[k]}\n")
        type += 1