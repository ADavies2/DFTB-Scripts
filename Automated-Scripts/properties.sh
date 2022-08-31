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
  if (($1 <= 40)); then
    CORES=2
  elif (($1 >= 40 && $1 <= 50)); then
    CORES=4
  elif (($1 >= 50 && $1 <= 100)); then
    CORES=8
  elif (($1 >= 100)); then
    CORES=16
  fi
}

dftb_in () {
# $1 = $GEO
# $2 = $PROPERTY
# $3 = $JOBNAME
# $4 = myHUBBARD
# $5 = myMOMENTUM
# $6 = ATOM_TYPES
  if [[ $1 == *"gen"* ]]; then 
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< $1
}

!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< $1
}

!
  fi
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
  OutputPrefix = "$3-Out" }
!
  else
    printf "%s\n" "Driver = { }" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!

Hamiltonian = DFTB {
SCC = Yes
ReadInitialCharges = Yes
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
!
  if [[ $2 == "bands" ]]; then
    printf "%s\n" "MaxSCCIterations = 1" >> dftb_in.hsd
  else
    printf "%s\n" "MaxSCCIterations = 2000" >> dftb_in.hsd
  fi
  printf "%s\n" "HubbardDerivs {" >> dftb_in.hsd
  hubbard=$4[@]
  sccHUBBARD=("${!hubbard}")
  printf "%s\n" "${sccHUBBARD[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
SlaterKosterFiles = Type2FileNames {
  Prefix = "/project/designlab/Shared/Codes/dftb+sk/3ob-3-1/"
  Separator = "-"
  Suffix = ".skf" }
!
  if [[ $2 == "bands" ]]; then
    cat >> dftb_in.hsd <<!
KPointsAndWeights [relative] = Klines { # Path for hexagonal COFs
  1   0.0   0.0   0.0 # Gamma
  20  0.33  0.33  0.0 # K
  20  0.5   0.5   0.0 # M
  20  0.0   0.0   0.0 # Gamma
}
MaxAngularMomentum {
!
  else
    cat >> dftb_in.hsd <<!
KPointsAndWeights = SupercellFolding {
  4 0 0
  0 4 0
  0 0 4
  0.5 0.5 0.5 }
MaxAngularMomentum {
!
  fi
  momentum=$5[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Analysis = {
!
  if [[ $2 == "bands" ]] || [[ $3 == *"Stack"* ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes }" >> dftb_in.hsd
  elif [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  AtomResolvedEnergies = Yes" >> dftb_in.hsd
    printf "%s\n" "  WriteEigenvectors = Yes" >> dftb_in.hsd
    printf "%s\n" "  CalculateForces = Yes }" >> dftb_in.hsd
  elif [[ $2 == "DOS" ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  ProjectStates {" >> dftb_in.hsd
    atoms=$6[@]
    TYPES=("${!atoms}")
    for element in ${TYPES[@]}; do
      printf "%s\n" "    Region {" >> dftb_in.hsd
      printf "%s\n" "      Atoms = $element" >> dftb_in.hsd
      printf "%s\n" "      ShellResolved = Yes" >> dftb_in.hsd
      printf "%s\n" "      Label = "dos_$element"" >> dftb_in.hsd
      printf "%s\n" "    }" >> dftb_in.hsd
    done
    printf "%s\n" "  }" >> dftb_in.hsd
    printf "%s\n" "}" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd<<!
  
Parallel {
  Groups = 1
  UseOmpThreads = Yes }
  
ParserOptions {
  ParserVersion = 10 } 
  
!
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi
}

echo "What is the COF name?"
read COF
echo "What is your input geometry file called?"
read GEO
echo "Is your input geometry stacked or a monolayer? Answer stacked/mono"
read STARTING

if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
  N_ATOMS=${N_ATOMS[0]}
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${POSCAR_ATOMS[@]}; do
    let N_ATOMS+=$i
  done
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# First, make a directory for each property calculation
#mkdir Layer-Analysis
#mkdir Bands
#mkidr DOS
#mkdir Charge-Diff

# Run the stacking calculation first
#PROPERTY=stacking
# Generate the dftb_in.hsd for stacking.sh
