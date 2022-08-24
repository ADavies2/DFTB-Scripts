#!/bin/bash

function 3obparams {
# Declare an associative array for the Hubbard derivatives of each element for the 3ob parameters
declare -A HUBBARD
HUBBARD[Br]=-0.0573
HUBBARD[C]=-0.1492
HUBBBARD[Ca]=-0.034
HUBBARD[Cl]=-0.0697
HUBBARD[F]=-0.1623
HUBBARD[H]=-0.1857
HUBBARD[I]=-0.0433
HUBBARD[K]=-0.0339
HUBBARD[Mg]=-0.02
HUBBARD[N]=-0.1535
HUBBARD[Na]=-0.0454
HUBBARD[O]=-0.1575
HUBBARD[P]=-0.14
HUBBARD[S]=-0.11
HUBBARD[Zn]=-0.03

# Declare an associative array for the max angular momentum orbitals for each element for the 3ob parameters
declare -A MOMENTUM
MOMENTUM[Br]=d
MOMENTUM[C]=p
MOMENTUM[Ca]=p
MOMENTUM[Cl]=d
MOMENTUM[F]=p
MOMENTUM[H]=s
MOMENTUM[I]=d
MOMENTUM[K]=p
MOMENTUM[Mg]=p
MOMENTUM[N]=p
MOMENTUM[Na]=p
MOMENTUM[O]=p
MOMENTUM[P]=d
MOMENTUM[S]=d
MOMENTUM[Zn]=d

# Declare an associative array for Hubbard derivatives of atom types in Input-POSCAR only
declare -A myHUBBARD
#myHUBBARD[$1]=${HUBBARD[$1]}

# Write for loop to add associative element to array for every element of $ATOM_TYPES
# Do this for myHUBBARD and myMOMENTUM
}

# First working update:
# Prompt for user input of COF name and initial tolerance
# Then, run the calculation in the background with nohup 

echo "What is the COF name?" 
read COF 
echo "What is your initial tolerance?" 
read TOL 

# Second working update:
# Read input geometry file to get atom types and number of atoms
ATOM_TYPES=($(sed -n 6p Input-POSCAR))

# Read atom types into a function for angular momentum and Hubbard Derivative values
# Read number of atoms into a function for number of cores to use in calculation


