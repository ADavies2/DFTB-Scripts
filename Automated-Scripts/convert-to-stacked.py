# This Python script is written to be called automatically by the relax-v5.sh script, which runs a monolayer COF calculation, and then converts the output monolayer COF into a stacked COF based on the highest and lowest Z coordinate values.

import numpy as np
import pandas as pd

def convert(list):
    
    return '\t'.join(list)

Coordinates = pd.read_csv('1e-4-Out.gen', header=None, skiprows=[0,1], skipfooter=4, delim_whitespace=True, names=['X','Y','Z'], engine='python')
SimCell = pd.read_csv('1e-4-Out.gen', header=None, skiprows=[0,1], delim_whitespace=True, usecols=[0,1,2])

SimCell = SimCell[-4:]

MaxZ = max(Coordinates['Z'])
MinZ = min(Coordinates['Z'])

LowestZ_Allowed = MaxZ+2
LayerSpacing = LowestZ_Allowed-MinZ

lines = open('1e-4-Out.gen', 'r').readlines()

new_line = [' ', str(SimCell.iloc[3,0]), str(SimCell.iloc[3,1]), str(SimCell.iloc[3,2])]
converted_new_line = convert(new_line)
lines[-1] = str(converted_new_line)

open('Stacked-Input.gen', 'w').writelines(lines)