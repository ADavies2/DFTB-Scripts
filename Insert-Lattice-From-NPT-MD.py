# This Python script extracts simulation cell data from the md.out files and inputs it into the .xyz files
# .xyz files generated with DFBT+ do not contain any simulation cell data
# This script will input that data from each MD timestep from an NPT simulation 

import numpy as np
import csv
from itertools import islice

filename = 'md.out' # The md.out file to collect data from
xyz_filename = 'Water-NaCl-NPT.xyz' # The XYZ file to convert

md_length = 3000 # steps
restart = 20 # restart interval
data_points = md_length//restart # number of MD data points
no_atoms = 1214 # number of atoms

x = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 9, None, 20):
        x.append(list(filter(None, line)))
x = np.array(x)

y = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 10, None, 20):
        y.append(list(filter(None, line)))
y = np.array(y)

z = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 11, None, 20):
        z.append(list(filter(None, line)))
z = np.array(z)

file = open(xyz_filename, 'r')
replace = []
lines = file.readlines()

for i in range(0,len(x)):
    replace.append('Lattice="' + x[i,0] + ' ' + x[i,1] + ' ' + x[i,2] + ' ' + y[i,0] + ' ' + y[i,1] + ' ' + y[i,2] + ' ' + z[i,0] + ' ' + z[i,1] + ' ' + z[i,2] + '" Origin="0.0 0.0 0.0" Properties=species:S:1:pos:R:3:charge:R:1:velocity:R:3\n')

i = 0
for j in range(1, len(lines), no_atoms+2):
    lines[j] = replace[i]
    i += 1
    if i >= len(replace):
        break
        
file = open(xyz_filename, 'w')
file.writelines(lines)
file.close()
