import numpy as np
import os
import csv

XYZ_Filename = 'COF-out.xyz'
Gen_Filename = 'COF-out.gen'

GenData = [] # Make an array with the data from the .gen file, which has the cell parameters

with open(Gen_Filename) as csvfile:
    csvReader = csv.reader(csvfile, delimiter=' ')
    for row in csvReader:
        data = list(filter(None, row))
        GenData.append(data)

SimCell = [] # This is to store the simulation cell parameters

for i in range((len(GenData)-4),len(GenData)):
    row = [float(j) for j in GenData[i]]
    SimCell.append([row[0],row[1],row[2]])

print(np.shape(SimCell), type(SimCell))
print(SimCell)

del(GenData) # The rest of the .gen data is no longer needed, so delete it to save space

File = open(XYZ_Filename, 'r') # Open and read the original .xyz file
lines = File.readlines()

replacement = 'Lattice="' + str(SimCell[1][0]) + ' ' + str(SimCell[1][1]) + ' ' + str(SimCell[1][2]) + ' ' + str(SimCell[2][0]) + ' ' + str(SimCell[2][1]) + ' ' + str(SimCell[2][2]) + ' ' + str(SimCell[3][0]) + ' ' + str(SimCell[3][1]) + ' ' + str(SimCell[3][2]) + '" Origin="' + str(SimCell[0][0]) + ' ' + str(SimCell[0][1]) + ' ' + str(SimCell[0][2]) + '" Properties=species:S:1:pos:R:3\n'

for i in range(1,len(lines),170):
    lines[i] = replacement

File = open(XYZ_Filename, 'w')
File.writelines(lines) # Rewrite the original .xyz file with the lattice parameters
File.close()
