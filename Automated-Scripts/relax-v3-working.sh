#!/bin/bash

# First working update:
# Prompt for user input of COF name and initial tolerance
# Then, run the calculation in the background with nohup 

echo "What is the COF name?" 
read COF 
echo "What is your initial tolerance?" 
read TOL 

# Second working update: 
# Read input geometry file to get atom types and number of atoms
# Read atom types into a function for angular momentum and Hubbard Derivative values
# Read number of atoms into a function for number of cores to use in calculation


