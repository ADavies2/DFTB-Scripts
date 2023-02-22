import numpy as np
import pandas as pd
import random
import math
import os

def Remove_Sulfonate(Iteration):
    
    Original = pd.read_csv('COF141-60S.xyz', header=None, skiprows=[0,1], delimiter=' ', names=['Atom','X','Y','Z'])
    
    Sulfur = Original['Atom'].str.find('S')
    Oxygen = Original['Atom'].str.find('O')
    Hydrogen = Original['Atom'].str.find('H')
    
    Sulfur_Indices = []; Oxygen_Indices = []; Hydrogen_Indices = []
    for i in range(0,len(Original)):
        if Sulfur[i] == 0:
            Sulfur_Indices.append(i)
        if Oxygen[i] == 0:
            Oxygen_Indices.append(i)
        if Hydrogen[i] == 0:
            Hydrogen_Indices.append(i)
        
    
    Sulfur_ToRemove = random.sample(Sulfur_Indices, 10)
    
    Oxygen_ToRemove = [] # The indices of the oxygen atoms to remove 
    Hydrogen_ToRemove = [] # The indices of the hydrogen atoms to remove
    for i in range(0,len(Sulfur_ToRemove)):
        icoord = [Original.iloc[Sulfur_ToRemove[i]]['X'], Original.iloc[Sulfur_ToRemove[i]]['Y'], Original.iloc[Sulfur_ToRemove[i]]['Z']]
        for j in Oxygen_Indices:
            if abs(icoord[0]-Original.iloc[j]['X']) <= 2:
                if abs(icoord[1]-Original.iloc[j]['Y']) <= 2:
                    Oxygen_ToRemove.append(j) # If an oxygen atom is within 2 Å in x and y of the sulfur atom to remove, append
                    for k in Hydrogen_Indices:
                        if (math.sqrt((abs(Original.iloc[j]['X']-Original.iloc[k]['X'])**2)+(abs(Original.iloc[j]['Y']-Original.iloc[k]['Y'])**2)\
                                      +(abs(Original.iloc[j]['Z']-Original.iloc[k]['Z'])**2))) <= 1:
                            Hydrogen_ToRemove.append(k)
                            
    New = []
    # Do multiple loops in order to append all atom types at once
    for i in range(0,len(Original)):
        if i in (Sulfur_ToRemove):
            Original.loc[i,'Atom'] = 'H' # Replace sulfur from Sulfur_ToRemove with Hydrogen
            
    for i in range(0,len(Original)): # Carbon first
        dict = {}
        if Original.iloc[i]['Atom'] == 'C':
            dict.update(Original.iloc[i])
            New.append(dict)
        
    for i in range(0,len(Original)): # Hydrogen
        dict = {}
        if ((Original.iloc[i]['Atom'] == 'H') and (i not in Hydrogen_ToRemove)):
            dict.update(Original.iloc[i])
            New.append(dict)
        
    for i in range(0,len(Original)): # Nitrogen
        dict = {}
        if Original.iloc[i]['Atom'] == 'N':
            dict.update(Original.iloc[i])
            New.append(dict)
        
    for i in range(0,len(Original)): # Oxygen
        dict = {}
        if ((Original.iloc[i]['Atom'] == 'O') and (i not in Oxygen_ToRemove)):
            dict.update(Original.iloc[i])
            New.append(dict)
        
    for i in range(0,len(Original)):
        dict = {}
        if Original.iloc[i]['Atom'] == 'S':
            dict.update(Original.iloc[i])
            New.append(dict)

    New = pd.DataFrame(New)
    
    with open('COF141-60S.xyz') as f:
        no_atoms = f.readline()
        header = f.readline()
    
    with open('COF141-50S.xyz', 'w') as f:
        f.write('500\n')
        f.write(header)
    
    with open('COF141-50S.xyz', 'a') as f:
        NewCoords = New.to_string(header=False, index=False)
        f.write(NewCoords)
    
    from ase.io import read
    convert = read('COF141-50S.xyz').write('Random%s.vasp' % Iteration)
    
    os.remove('COF141-50S.xyz')
    
    for i in range(1,11):
    Remove_Sulfonate(i)
