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

waveplot () {
# $1 = $JOBNAME
# $2 = $SUPERCELL
# $3 = $COF
  sed -i '/.*srun dftb+.*/s/^/#/g' ~/bin/submit_dftb_automate
  sed -i '/.*waveplot.*/s/^#//g' ~/bin/submit_dftb_automate
  submit_dftb_automate 16 1 $1
  while :
  do
    stat="$(squeue -n $1)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$1 is pending..."
        sleep 10s
      else
        if grep -q "File 'wp-abs2diff.cube' written" $1.log; then
          supercell=$2[@]
          repeatCELL=("${!supercell}")
          echo "${repeatCELL[@]} $3 Waveplot is complete!"
          sed -i '/.*srun dftb+.*/s/^#//g' ~/bin/submit_dftb_automate
          sed -i '/.*waveplot.*/s/^/#/g' ~/bin/submit_dftb_automate
          cp wp-abs2diff.cube $3-wp-abs2diff.cube
          exit
        else
          echo "$1 is still runing..."
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
JOBNAME="$COF-Waveplot"

if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
else
  ATOM_TYPES=($(sed -n 6p $GEO))
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# After a successful relaxation of the supercell, with the detailed.xml and eigenvec. bin files, run the waveplot calculation
waveplot_in SUPERCELL
waveplot $JOBNAME SUPERCELL $COF
