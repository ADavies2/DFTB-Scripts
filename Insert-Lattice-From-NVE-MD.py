import numpy as np
import csv
from itertools import islice

filename = 'md.out'
xyz_filename = 'Water-NaCl-NVE.xyz'

md_length = 3000 # steps
restart = 20 # restart interval
data_points = md_length//restart # number of MD data points
no_rows = 1214 # rows in the XYZ file, number of atoms+2

x = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 2, None, 20):
        print(len(line))
        x.append(list(filter(None, line)))
x = np.array(x)

y = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 3, None, 20):
        print(len(line))
        y.append(list(filter(None, line)))
y = np.array(y)

z = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 4, None, 20):
        print(len(line))
        z.append(list(filter(None, line)))
z = np.array(z)

print(len(x))
print(len(y))
print(len(z))

file = open(xyz_filename, 'r')
replace = []
lines = file.readlines()

for i in range(0,len(x)):
    replace.append('Lattice="' + x[i,0] + ' ' + x[i,1] + ' ' + x[i,2] + ' ' + y[i,0] + ' ' + y[i,1] + ' ' + y[i,2] + ' ' + z[i,0] + ' ' + z[i,1] + ' ' + z[i,2] + '" Origin="0.0 0.0 0.0" Properties=species:S:1:pos:R:3\n')

i = 0
for j in range(1, len(lines), no_rows):
    lines[j] = replace[i]
    i += 1
    if i >= len(replace):
        break

file = open(xyz_filename, 'w')
file.writelines(lines)
file.close()
