#!/usr/bin/env python

import pandas as pd

InstructFilename = input('What is the instruction file? ')

f = open(InstructFilename, 'r')
l = f.readlines()
# COF name, structure filename, axis, partition

Instructions = []
for i in l:
    Instructions.append(i.replace('\n',''))

Axis = Instructions[2].upper()

if Axis == 'Z':
    Data = pd.read_csv(f'{Axis}.dat', header=None, delim_whitespace=True, names=['Z','Energy'])
    Sorted = Data.sort_values(by=['Energy'])
    print(Sorted.iloc[0]['Z'])

    NewZ = Sorted.iloc[0]['Z']-abs((Sorted.iloc[0]['Z']-Sorted.iloc[1]['Z'])/2)
    print(NewZ)
elif Axis == 'XY':
    Data = pd.read_csv(f'{Axis}.dat', header=None, delim_whitespace=True, names=['X','Y','Z','Energy'])
    Sorted = Data.sort_values(by=['Energy'])
    print(Sorted.iloc[0]['X'], Sorted.iloc[0]['Y'], Sorted.iloc[0]['Z'])
    OptAB = Sorted[(Sorted.X == 0.5) & (Sorted.Y == 0.5)].iloc[0]
    print(OptAB['Z'])