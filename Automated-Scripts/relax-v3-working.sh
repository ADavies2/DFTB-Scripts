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

ncores () {
  if (($1 <= 20)); then
    CORES=2
  elif (($1 >= 20 && $1 <= 50)); then
    CORES=4
  elif (($1 >= 50 && $1 <= 100)); then
    CORES=8
  elif (($1 >= 100)); then
    CORES=16
  fi
}

# Prompt for user input of COF name and initial tolerance
# Ask what the input geometry file is and if this is a restart calculation

echo "What is the COF name?"
read COF
echo "What is your initial tolerance?"
read TOL
echo "What is your input geometry file called?"
read GEO
echo "Is this a restart calculation? yes/no"
read RESTART

JOBNAME=$COF-scc-$TOL

# Read input geometry file to get atom types and number of atoms

if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
  N_ATOMS=${N_ATOMS[0]}
  cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< $GEO
}
!
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${POSCAR_ATOMS[@]}; do
    let N_ATOMS+=$i
  done
  cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< $GEO
}
!
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Calculate the number of required cores based on the total number of atoms in the unit cell
ncores $N_ATOMS

# Write dftb_in.hsd for the first calculation
cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  MaxForceComponent = $TOL
  OutputPrefix = $TOL-Out
  AppendGeometries = No }

Hamiltonian = DFTB {
SCC = Yes
SCCTolerance = $TOL
!
if [[ $RESTART == "yes" ]]; then
  printf "ReadInitialCharges = Yes\n" >> dftb_in.hsd
else
  printf "ReadInitialCharges = No\n" >> dftb_in.hsd
fi
cat >> dftb_in.hsd <<!
MaxSCCIterations = 5000
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
HubbardDerivs {
!
printf "%s\n" "${myHUBBARD[@]} }" >> dftb_in.hsd
cat >> dftb_in.hsd <<!
SlaterKosterFiles = Type2FileNames {
  Prefix = "/project/designlab/Shared/Codes/dftb+sk/3ob-3-1/"
  Separator = "-"
  Suffix = ".skf" }
KPointsAndWeights = SupercellFolding {
  4 0 0
  0 4 0
  0 0 4
  0.5 0.5 0.5 }
MaxAngularMomentum {
!
printf "%s\n" "${myMOMENTUM[@]} }" >> dftb_in.hsd
cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Analysis = {
  MullikenAnalysis = Yes }

Parallel = {
  Groups = 1
  UseOmpThreads = Yes }

ParserOptions {
  ParserVersion = 10 }
!
