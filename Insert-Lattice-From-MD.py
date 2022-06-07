import numpy as np
import csv

filename = 'md.out'
xyz_filename = 'test.xyz'

md_length = 5000 # total MD steps
restart = 20 # restart interval
data_points = md_length//restart # number of MD data points
no_rows = 479 # Number of atoms plus 2 to account for other labels

x = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 9, None, 20):
        x.append([line[10], line[19], line[28]])      
x = np.array(x) # extract and append the lattice vectors in x

y = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 10, None, 20):
        y.append([line[10], line[20], line[30]])
y = np.array(y) # extract and append the lattice vectors in y

z = []
with open(filename, 'r') as file:
    reader = csv.reader(file, delimiter=' ')
    for line in islice(reader, 11, None, 20):
        z.append([line[10], line[20], line[30]])
z = np.array(z) # extract and append the lattice vectors in z

file = open(xyz_filename, 'r') # open the xyz-file
lines = file.readlines()

for i in range(0,data_points):
    replace = 'Lattice=' + x[i,0] + ' ' + x[i,1] + ' ' + x[i,2] + ' ' + y[i,0] + ' ' + y[i,1] + ' ' + y[i,2] + ' ' + z[i,0] + ' ' + z[i,1] + ' ' + z[i,2] + '" Origin="0.0 0.0 0.0" Properties=species:S:1:pos:R:3\n'
    
    for j in range(1, len(lines), no_rows):
        lines[j] = replace
        
file = open(xyz_filename, 'w')
file.writelines(lines) # rewrite the original xyz-file with the new lattice parameters
file.close()
