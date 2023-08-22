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

Data = pd.read_csv(f'{Axis}.dat', header=None, delim_whitespace=True, names=['Value','Energy'])
Sorted = Data.sort_values(by=['Energy'])

print(Sorted.iloc[0]['Value'])

NewZ = Sorted.iloc[0]['Value']-abs((Sorted.iloc[0]['Value']-Sorted.iloc[1]['Value'])/2)
print(NewZ)