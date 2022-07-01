import numpy as np
import math

concentration = 0.5 # mol NaCl/L H2O
conv1 = 1e-27 # L to Angstrom(3)
avagadro = 6.022e23 # molecules/mol

calculation = input("Are you calculating number of NaCl molecules in a given volume? Enter y/n")
if calculation == "y":
  x = float(input("Dimension of simulation cell in x (Ang): "))
  y = float(input("Dimension of simulation cell in y (Ang): "))
  z = float(input("Dimension of simulation cell in z (Ang): "))
  volume = x*y*z
  num_nacl = concentration*conv1*volume*avagadro
  print("The number of NaCl molecules in", volume, "Angstrom cubed cell is", math.floor(num_nacl))  
 else:
  num_nacl = input("How many NaCl molecules do you want?")
  volume = num_nacl*(1/avagadro)*(1/concentration)*(1/conv1)
  print("The volume to fit the given number of NaCl molecules at 0.5 M is", volume, "Angstrom cubed.")
  





