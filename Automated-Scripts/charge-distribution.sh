#!/bin/bash

## FUTURE EDITS: AUTOMATICALLY GENERATE THE SUPERCELL RATHER THAN MANUALLY WITH OVITO

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

# Write function to write dftb_in.hsd for the supercell calculation
# Check outputs
# Set-up director for charge difference calculation
# Write waveplot_in.hsd
# Begin charge difference calculation

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

waveplot_in () {
# $1 = $SUPERCELL
  cat > waveplot_in.hsd <<!
Options {
  TotalChargeDensity = Yes
  TotalChargeDifference = Yes
  ChargeDensity = Yes
  RealComponent = Yes
  PlottedKPoints = 1
  PlottedSpins = 1 -1
  PlottedLevels = 1
  PlottedRegion = UnitCell {
    MinEdgeLength [Angstrom] = 23
  }
  
  NrOfPoints = 30 30 30
  NrOfCachedGrids = -1
  Verbose = Yes
  FillBoxWithAtoms = Yes
!
  supercell=$1[@]
  repeatCELL=("${!supercell}")
  printf "%s\n" "  RepeatBox = {${repeatCELL[@]}}" >> waveplot_in.hsd
  cat >> waveplot_in.hsd <<!
}
DetailedXML = './detailed.xml'
EigenvecBin = './eigenvec.bin'

Basis {
  Resolution = 0.01
  <<+ '/project/designlab/Shared/Codes/dftb+sk/3ob-3-1/wfc.3ob-3-1.hsd'
}
!
}

dftb_in () {
# $1 = $GEO
# $2 = $COF
# $3 = myHUBBARD
# $4 = myMOMENTUM
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
  cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  OuptutPrefix = "$2-Charge-Relax"
  AppendGeometries = No }
  
Hamiltonian = Yes {
SCC = Yes
ReadInitialCharges = No
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
HubbardDerivs {
!
  hubbard=$3[@]
  sccHUBBARD=("${!hubbard}")
  printf "%s\n" "${sccHUBBARD[@]} }" >> dftb_in.hsd
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
  momentum=$4[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Options {
  WriteDetailedXML = Yes
}

Analysis = {
  MullikenAnalysis = Yes
  WriteEigenvectors = Yes
}

Parallel {
  Groups = 1
  UseOmpThreads = Yes
}

ParserOptions {
  ParserVersion = 10
}
!
}

scc () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
# $4 = $SUPERCELL
  submit_dftb_automate $1 1 $3
  while :
  do
    stat="$(squeue -n $3)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 10s
      else
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
          echo "$4 $2 is fully relaxed! Beginning Waveplot calculations..."
          JOBNAME="$2-Waveplot2"
          break
        elif grep -q "SCC is NOT converged" $3.log; then
          printf "$4 $2 did NOT converge.\n User trouble-shoot required." 
          exit
        else
          echo "#3 is still runing..."
          sleep 10s
        fi
      fi
  done
}

waveplot () {
# $1 = $JOBNAME
# $2 = $SUPERCELL
# $3 = $COF
  sed -i '/.*srun dftb+.*/s/^/#/g' ~/bin/submit_dftb_automate
  sed -i '/.*waveplot.*/s/^#//g' ~/bin/submit_dftb_automate
  submit_dftb_automate 16 1 $1
  while :
  do 
    stat="$(squeue -n $3)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 10s
      else
        if grep -q "File 'wp-abs2diff.cube' written" $3.log; then
          echo "$2 $COF Waveplot is complete!"
          sed -i '/.*srun dftb+.*/s/^#//g' ~/bin/submit_dftb_automate
          sed -i '/.*waveplot.*/s/^/#/g' ~/bin/submit_dftb_automate
          exit
        else
          echo "#3 is still runing..."
          sleep 10s
        fi
      fi
  done
}

# The user needs to supply the supercell input file, the detailed.xml and the eigenvec.bin files

echo "What is the COF name?" 
read COF
echo "What are your supercell dimensions?" 
read SUPERCELL
echo "What is your input geometry file called?"
read GEO
JOBNAME="$COF-Waveplot1"

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

# Run a dftb_in.hsd calculation of the supercell with tags for detailed.xml and eigenvec.bin
dftb_in $GEO $COF myHUBBARD myMOMENTUM
scc $CORES $COF $JOBNAME $SUPERCELL

# After a successful relaxation of the supercell, with the detailed.xml and eigenvec. bin files, run the waveplot calculation
waveplot_in $SUPERCELL
waveplot $JOBNAME $SUPERCELL $COF
