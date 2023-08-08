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

# Write a dftb_in.hsd file for a single-point calculation
dftb_in () {
# 1 = $GEO
# 2 = myHUBBARD
# 3 = myMOMENTUM
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< "$1"
}

Driver = { }

Hamiltonian = DFTB {
SCC = Yes
MaxSCCIterations = 5000
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
HubbardDerivs {
!
  hubbard=$2[@]
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
  momentum=$3[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Analysis = {
    MullikenAnalysis = Yes }

Parallel = {
  Groups = 1
  UseOmpThreads = Yes }

ParserOptions {
  ParserVersion = 12 }
!
}

submit_calculation () {
# 1 = $GEO
# 2 = $COF
# 3 = $AXIS
# 4 = $CHANGE
# 5 = $PARTITION

# Generate geometry file for testing from monolayer
  NewFILE=($(printf "$1\n$2\n$3\n$4\n" | XYZ-Scanning.py))
  NewFILE=(${NewFILE[7]})
  ATOM_TYPES=($(sed -n 6p $NewFILE))

# Read atom types into a function for angular momentum and Hubbard derivative values
  declare -A myHUBBARD
  declare -A myMOMENTUM
  nl=$'\n'
  for element in ${ATOM_TYPES[@]}; do
    myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
    myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
  done

# Write dftb_in.hsd reading in NewFILE
  dftb_in $NewFILE myHUBBARD myMOMENTUM

# Submit calculation
  TASK=8
  CPU=1
  JOBNAME="$2-$4$3"
  if [[ $5 == 'teton' ]]; then
    submit_dftb_teton $TASK $CPU $JOBNAME
    sleep 5s
  elif [[ $5 == 'inv-desousa' ]]; then
    submit_dftb_desousa $TASK $CPU $JOBNAME
    sleep 5s
  fi
  while :
  do
    stat=($(squeue -n $JOBNAME))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
    if [ "$jobstat" == "PD" ]; then
      echo "$JOBNAME is pending..."
      sleep 5s
    else
      if grep -q "SCC converged" detailed.out; then
        DETAILED=($(grep "Total energy" detailed.out))
        TOTAL_ENERGY=${DETAILED[4]}
        cat >> Z.dat <<!
$4 $TOTAL_ENERGY
!
        break
      elif grep -q "SCC is NOT converged" $JOBNAME.log; then
        echo "SCC did not converge. User-trouble shoot required."
        exit
      else
        echo "$JOBNAME is running..."
        sleep 10s
      fi
    fi
  done
}

# Read in starting structure file, which should be an optimized monolayer
# Set-up the dftb_in.hsd file
# Submit the calculation and check for completion
# Grep the total energy value from detailed.out and save to a .dat file

# Repeat this process for varying values of Z, X%, and Y%

# Instruction file containing the name of the initial structure file and COF name
INSTRUCT=$1

GEO=($(sed -n 1p $INSTRUCT))
COF=($(sed -n 2p $INSTRUCT))
PARTITION=($(sed -n 3p $INSTRUCT))

# Conduct Z scanning first
AXIS='Z'
CHANGE=0
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION

CHANGE=1
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION

CHANGE=2
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION

CHANGE=4
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION

CHANGE=6
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION

CHANGE=8
submit_calculation $GEO $COF $AXIS $CHANGE $PARTITION