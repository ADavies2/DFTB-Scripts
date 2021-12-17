import numpy as np
import csv

def counter(list, x):
    count = 0
    for item in list:
        if (item==x):
            count += 1
    return count

Filename = 'COF-out.gen' # This is the .gen file you want to turn into a POSCAR

GenData = [] # Make an array to store the numbers from the .gen file (coordinates, simulation cell parameters)

with open(Filename) as csvfile:
    csvReader = csv.reader(csvfile, delimiter=' ')
    no_atoms = next(csvReader)
    atom_types = next(csvReader)
    for row in csvReader:
        data = list(filter(None, row))
        #data = np.array(data, dtype = np.float32)
        GenData.append(data)

no_atoms = list(filter(None, no_atoms)) # This is a list with the total number of atoms
print(no_atoms[0])

AtomTypes = [list(filter(None, atom_types))] # This is a list with the different types of atom species
print(AtomTypes)
print(len(AtomTypes[0])) # Total number of atom species

Coords = [] # This is where the x,y,z coordinates for each atom will be stored
SpeciesCount = [] # This is to store an array with the number of atoms per atom type
atom_num = [] # temporary array to story the column with the associated atom type number from the .gen file

for i in range(len(GenData)-4):
    row = [float(j) for j in GenData[i]]
    #print(row[4])
    new_row = np.array([row[2],row[3],row[4]])
    Coords.append(new_row)

    atom_num.append(int(row[1]))  # Number associated with the atomic species in column 2 of .gen file

for i in range(1,len(AtomTypes[0])+1):
    count = counter(atom_num,i)
    SpeciesCount.append(count)
  
print(np.shape(Coords))
print(SpeciesCount)

SimCell = [] # This is to store the simulation cell parameters

for i in range((len(GenData)-3),len(GenData)):
    row = [float(j) for j in GenData[i]]
    SimCell.append([row[0],row[1],row[2]])

print(np.shape(SimCell))
print(SimCell)

POSCAR = open('COF-out-POSCAR', 'w') # Create a file to write to
Header = "POSCAR from DFTB+ out.gen\n" # First line in POSCAR file
Scaling = "1\n" # second line in POSCAR file

POSCAR.write(Header)
POSCAR.write(Scaling)

for row in range(0,3):
    POSCAR.write(str(SimCell[row][0]) + ' ' + str(SimCell[row][1]) + ' ' + str(SimCell[row][2]) + "\n")

for element in range(0,len(AtomTypes[0])):
    POSCAR.write(AtomTypes[0][element] + ' ')
POSCAR.write("\n")
for element in range(0,len(AtomTypes[0])):
    POSCAR.write(str(SpeciesCount[element]) + ' ')
POSCAR.write("\n")

POSCAR.write("Cartesian\n")

for row in range(0,len(Coords)):
    POSCAR.write(str(Coords[row][0]) + ' ' + str(Coords[row][1]) + ' ' + str(Coords[row][2]) + "\n")

POSCAR.close()
