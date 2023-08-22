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
ReadInitialCharges = No
MaxSCCIterations = 50
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
# 1 = $COF
# 2 = $CHANGE
# 3 = $AXIS
# 4 = $PARTITION
# 5 = $Z
# Submit calculation
  TASK=8
  CPU=1
  JOBNAME="$1-$2$3"
  if [[ $4 == 'teton' ]]; then
    submit_dftb_teton $TASK $CPU $JOBNAME
    sleep 5s
  elif [[ $4 == 'inv-desousa' ]]; then
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
        echo "Job complete."
        DETAILED=($(grep "Total energy" detailed.out))
        TOTAL_ENERGY=${DETAILED[4]}
        if [[ $3 == 'Z' ]]; then
          cat >> $3.dat <<!
$2 $TOTAL_ENERGY
!
        else
          cat >> $3-Z.dat <<!
$2 $5 $TOTAL_ENERGY
!
        fi
        break
      elif grep -q "SCC is NOT converged" $JOBNAME.log; then
        echo "At $3 = $2 SCC did not converge."
        break
      elif grep -q "ERROR!" $JOBNAME.log; then
        echo "DFTB+ Error. User trouble-shoot required."
        exit
      else
        echo "$JOBNAME is running..."
        sleep 10s
      fi
    fi
  done
}

set_up_calculation () {
# 1 = $GEO 
# 2 = $COF
# 3 = $AXIS
# 4 = $CHANGE 
# 5 = $OPTZ
# 6 = $OPTX

# Generate geometry from XYZ-Scanning
  if [[ $3 == 'Z' ]]; then
    OPTZ=0
    OPTX=0
    NewFILE=($(printf "$1\n$2\n$3\n$4\n$OPTZ\n$OPTX\n" | XYZ-Scanning.py))
    NewFILE=(${NewFILE[7]})
  elif [[ $3 == 'X' ]]; then
    OPTX=0
    NewFILE=($(printf "$1\n$2\n$3\n$4\n$5\n$OPTX\n" | XYZ-Scanning.py))
    NewFILE=(${NewFILE[9]})
  elif [[ $3 == 'Y' ]]; then
    NewFILE=($(printf "$1\n$2\n$3\n$4\n$5\n$6\n" | XYZ-Scanning.py))
    NewFILE=(${NewFILE[11]})
  fi
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
}

# Read in starting structure file, which should be an optimized monolayer
# Set-up the dftb_in.hsd file
# Submit the calculation and check for completion
# Grep the total energy value from detailed.out and save to a .dat file

# Repeat this process for varying values of Z, X%, and Y%

module load gcc/11.2.0 python/3.10.8

# Instruction file containing the name of the initial structure file and COF name
INSTRUCT=$1

COF=($(sed -n 1p $INSTRUCT))
GEO=($(sed -n 2p $INSTRUCT))
AXIS=($(sed -n 3p $INSTRUCT))
AXIS=${AXIS^}
PARTITION=($(sed -n 4p $INSTRUCT))

if [[ $AXIS == 'Z' ]]; then
# First, run an optimization for Z height
  for i in 1 2 3 4 5 # Where i = CHANGE
  do
    set_up_calculation $GEO $COF $AXIS $i
    submit_calculation $COF $i $AXIS $PARTITION
  done

  MinReturn=($(printf "$INSTRUCT" | Find-Minimum.py))
  MIN1=(${MinReturn[5]}) # Minimum Z value from tested values
  Z1=(${MinReturn[6]}) # New Z value that is halfway between two lowest values
  set_up_calculation $GEO $COF $AXIS $Z1
  submit_calculation $COF $Z1 $AXIS $PARTITION

  MinReturn=($(printf "$INSTRUCT" | Find-Minimum.py))
  MIN2=(${MinReturn[5]}) # Minimum Z value, including new test
  Z2=(${MinReturn[6]})

  if [[ $MIN2 != $MIN1 ]]; then
    set_up_calculation $GEO $COF $AXIS $Z2
    submit_calculation $COF $Z2 $AXIS $PARTITION

    MinReturn=($(printf "$INSTRUCT" | Find-Minimum.py))
    OPTZ=(${MinReturn[5]}) # Close enough to finding minimum, take this as the final "optimized Z"

  elif [[ $MIN2 == $MIN1 ]]; then
    OPTZ=$MIN2
  fi
# After Z height has been optimized, begin testing X offset
# At each X offset, test the previously optimized Z height, +0.25, and +0.5
# Each of these are appended to an XY.dat file, to find if there are Z heights that result in lower energie X offsets
  AXIS='X'
  sed -i "3s/.*/$AXIS/" $INSTRUCT # Change the testing axis in the instruction file to X
  cat >> $INSTRUCT <<! # Write the optimum Z to the instruction file
$OPTZ
!
  ZReturn=($(printf "$OPTZ" | Return-NewZ.py))
  Z1=(${ZReturn[5]}) # OPTZ - 0.25
  Z2=(${ZReturn[6]}) # OPTZ + 0.25
  # Now, using these three heights, test a different X offset
  for i in '0.1' '0.2' '0.3' '0.4' '0.5'
  do
    set_up_calculation $GEO $COF $AXIS $i $Z1
    submit_calculation $COF $i $AXIS $PARTITION $Z1
    # Now run OPTZ from the instruction file
    set_up_calculation $GEO $COF $AXIS $i $OPTZ
    submit_calculation $COF $i $AXIS $PARTITION $OPTZ
    # Finally, run Z1 and Z2 which are added values 
    set_up_calculation $GEO $COF $AXIS $i $Z2
    submit_calculation $COF $i $AXIS $PARTITION $Z2
  done

  # Now, find the minimum X and minimum Z from this test
  MinReturn=($(printf "$INSTRUCT" | Find-Minimum.py))
  OPTX=(${MinReturn[5]}) # Optimum X from test
  OPTZ=(${MinReturn[6]}) # Corresponding optimum Z from test
  # Write these to the $INSTRUCT file for the Y testing
  AXIS='Y'
  sed -i "3s/.*/$AXIS/" $INSTRUCT
  sed -i "5s/.*/$OPTZ/" $INSTRUCT
  cat >> $INSTRUCT <<!
$OPTX
!
elif [[ $AXIS == 'X' ]]; then
# If beginning with X offset, it is assumed an optimum Z has been determined
  OPTZ=($(sed -n 5p $INSTRUCT))
  # Using the optimum Z, get the Z height for +/- 0.25
  ZReturn=($(printf "$OPTZ" | Return-NewZ.py))
  Z1=(${ZReturn[5]}) # OPTZ - 0.25
  Z2=(${ZReturn[6]}) # OPTZ + 0.25
  # Now, using these three heights, test a different X offset
  for i in '0.1' '0.2' '0.3' '0.4' '0.5'
  do
    set_up_calculation $GEO $COF $AXIS $i $Z1
    submit_calculation $COF $i $AXIS $PARTITION $Z1
    # Now run OPTZ from the instruction file
    set_up_calculation $GEO $COF $AXIS $i $OPTZ
    submit_calculation $COF $i $AXIS $PARTITION $OPTZ
    # Finally, run Z1 and Z2 which are added values 
    set_up_calculation $GEO $COF $AXIS $i $Z2
    submit_calculation $COF $i $AXIS $PARTITION $Z2
  done

  # Now, find the minimum X and minimum Z from this test
  MinReturn=($(printf "$INSTRUCT" | Find-Minimum.py))
  OPTX=(${MinReturn[5]}) # Optimum X from test
  OPTZ=(${MinReturn[6]}) # Corresponding optimum Z from test
  # Write these to the $INSTRUCT file for the Y testing
  AXIS='Y'
  sed -i "3s/.*/$AXIS/" $INSTRUCT
  sed -i "5s/.*/$OPTZ/" $INSTRUCT
  cat >> $INSTRUCT <<!
$OPTX
!
fi