# This Python script calculates the volume of a user defined simulation cell, and the number of whole water molecules that would occupy that volume
# If the number of water molecules is a decimal, the math.floor() function is used to round down to the nearest whole number 

import numpy as np
import math

# Define known variables

density = 997 # kg/m3, density of water
conv1 = 1e-30 # conversion of m3 to Ang3
mweight = 18.01 # g/mol, molecular weight of water molecule
conv2 = 1000 # conversion of kg to g
avagadro = 6.022e23 # molecules/mol, Avagadro's numer
pi = math.pi()

# What is the shape of the space to fill with water?
geometry = str(raw_input("What shape are you filling with water? Box or Cylinder?"))

if geometry == "Box":
  x = float(input("Dimension of box in x (Ang): "))
  y = float(input("Dimension of box in y (Ang): "))
  z = float(input("Dimension of box in z (Ang): "))

  volume = x*y*z # Ang3, volume of the cubic cell
  
  water_molecules = density*conv1*volume*(1/mweight)*conv2*avagadro
  print("Number of whole water molecules in", volume, "Angstrom cubed cubic cell is", math.floor(water_molecules))
else:
  r = float(input("Radius of the cylinder (Ang): "))
  h = float(input("Height of the cylinder (Ang): "))
  
  volume = (r**2)*pi*h # Ang3, volume of the cylindrical cell
  
  water_molecules = density*conv1*volume*(1/mweight)*conv2*avagadro
  print("Number of whole water molecules in", volume, "Angstrom cubed cylindrical cell is", math.floor(water_molecules))
