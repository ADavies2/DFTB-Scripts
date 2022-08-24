#!/bin/bash

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

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
for element in ${ATOM_TYPES[@]}
do
  myHUBBARD[$element]=${HUBBARD[$element]}
  myMOMENTUM[$element]=${MOMENTUM[$element]}
done

# Read number of atoms
POSCAR_ATOMS=($(sed -n 7p Input-POSCAR))
N_ATOMS=0
for i in ${POSCAR_ATOMS[@]}
do
  let N_ATOMS+=$i
done
