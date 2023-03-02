#!/bin/bash

# This scrip automatically runs DFTB+ jobs with a pre-set configuration of nodes/cpus/tasks. 
# The final output includes data from DFTB+ directly and from SLURM. This includes:
# The CPU time for each step of the calculation (from DFTB+)
# The maximum number of bytes read, maximum number of bytes written, maximum resident set size (memory), maximum virtual memory size
# The number of CPUs, Nodes, and Tasks and the total CPU time (from SLURM)

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

scc_dftb_in () {
# 1 = $GEO
# 2 = myHUBBARD
# 3 = myMOMENTUM
  if [[ $1 == *"gen"* ]]; then
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< "$1"
}
!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< "$1"
}
!
  fi
  cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
  MaxForceComponent = 1e-2 }
Hamiltonian = DFTB {
SCC = Yes
SCCTolerance = 1e-2
ReadInitialCharges = No
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
  ParserVersion = 11 }
Options {
  TimingVerbosity = 2 }
!
}

# User fed arguements
COF_NAME=$1
GEO=$2 # Geometry structure input filename

# Core combinations that will run are 56, 48, 42, 34, 28, 20, 14, and 6
# For each core combination, there will be one with all tasks and one with all CPUs
# i.e. 56 tasks-per-node and 1 cpus-per-task, and 1 tasks-per-node and 56 cpus-per-task

# For each of these jobs, there will be 5 repetitions in order to take an average of the following data points:
# DFTB+ SCC clock time
# DFTB+ Post-SCC clock time
# DFTB+ Post-Geom clock time
# sacct MaxDiskRead, MaxDiskWrite, MaxRSS, MaxVMSize, TotalCPU, NCPUS, NTasks, NNodes
# seff CPU efficiency

# These jobs will be submitted in batches of 5 per combination, and the new batch submission will be contigent on the previous 5 finishing
# So as not to take up too much space on the cluster and inv-desousa partition
# If a combination stalls, this will be noted in the final text file output for the 5 average jobs

# This will be tested for three system sizes constituting "small", "medium", and "large" COF unit cells.
# These systems are TpTt (54 atoms), COF-66 (210 atoms), and COF-141 Random1 (500 atoms).
# These will only run for a 1e-2 tolerance to get a long enough job with data points and ideally without taking multiple days to run

# The first job will be 56 tasks-per-node and 1 cpus-per-task
STALL='none'

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

# Write dftb_in.hsd for the first calculation
scc_dftb_in $GEO myHUBBARD myMOMENTUM

#mkdir Test1 Test2 Test3 Test4 Test5 # Make a directory for each average job. These directories will be concatenated upon completion of all 5 jobs

TASKS=56
CPUS=1
