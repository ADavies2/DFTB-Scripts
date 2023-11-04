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

dftb_in () {
# $1 = $GEO
# $2 = myHUBBARD
# $3 = myMOMENTUM
# $4 = ATOM TYPES
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
Driver = { }

Hamiltonian = DFTB {
SCC = Yes
MaxSCCIterations = 2000
ReadInitialCharges = Yes
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
  0.5 0.5 0.5
}
MaxAngularMomentum {
!
  momentum=$3[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Analysis {
  MullikenAnalysis = Yes
  ProjectStates {
!
  atoms=$4[@]
  TYPES=("${!atoms}")
  for element in ${TYPES[@]}; do
    printf "%s\n" "    Region {" >> dftb_in.hsd
    printf "%s\n" "      Atoms = $element" >> dftb_in.hsd
    printf "%s\n" "      ShellResolved = Yes" >> dftb_in.hsd
    printf "%s\n" "      Label = "dos_$element"" >> dftb_in.hsd
    printf "%s\n" "    }" >> dftb_in.hsd
  done
  cat >> dftb_in.hsd <<!
  }
}

Parallel {
  Groups = 1
  UseOmpThreads = Yes }
  
ParserOptions {
  ParserVersion = 10 }
!
}

scc () {
# $1 = $CORES
# $2 = $JOBNAME
# $3 = $COF
  submit_dftb_automate $1 1 $2
  while :
  do
    stat="$(squeue -n $2)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$2 is pending..."
        sleep 10s
      else
        if grep -q "SCC converged" detailed.out; then
          echo "DOS files have been generated for $3. Converting to data files..."
          break
        else
          echo "$2 is till running..."
          sleep 10s
        fi
      fi
  done
}

echo "What is the COF name?" 
read COF
echo "What is your input geometry file called?"
read GEO
JOBNAME="$COF-DOS"

# Read input geometry file to get atom types and number of atoms

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
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Calculate the number of required cores based on the total number of atoms in the unit cell
ncores $N_ATOMS

# Write the dftb_in.hsd to calculate the PDOS/DOS
dftb_in $GEO myHUBBARD myMOMENTUM ATOM_TYPES

# Run the SCC calculation to produce the dos.out files
scc $CORES $JOBNAME $COF

# Convert the .out files to .dat files for data analysis
module load dftb/21.2
dp_dos band.out dos_total.dat
for element in ${ATOM_TYPES[@]}; do
  dp_dos -w "dos_${element}.1.out" "dos_${element}.s.dat"
  if [[ ${MOMENTUM[$element]} == "p" ]]; then
    dp_dos -w "dos_${element}.2.out" "dos_${element}.p.dat"
  elif [[ ${MOMENTUM[$element]} == "d" ]]; then
    dp_dos -w "dos_${element}.3.out" "dos_${element}.d.dat"
  fi
done

rm dos*out
