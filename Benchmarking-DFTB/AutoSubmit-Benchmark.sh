#!/bin/bash

# This scrip automatically runs DFTB+ jobs with a pre-set configuration of nodes/cpus/tasks

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
  ParserVersion = 12 }
Options {
  TimingVerbosity = 2 }
!
}

gen_submit () {
# 1 = TASKS
# 2 = CPUS
# 3 = COF_NAME
# 4 = ITER
  NODE=1
  MEM=10G
  TIME=48:00:00
  SCRIPT_NAME=submit_$3
  PROCS=$(($1 * NODE))
  
  cat > $SCRIPT_NAME<<!
#!/bin/bash
#SBATCH --nodes=$NODE
#SBATCH --ntasks-per-node=$1
#SBATCH --cpus-per-task=$2
#SBATCH --account=designlab
#SBATCH --time=$TIME
#SBATCH --job-name=$3-$4
#SBATCH --output=$3-$4.out
#SBATCH --partition=inv-desousa
#SBATCH --mem=$MEM
cd \$SLURM_SUBMIT_DIR
export OMP_NUM_THREADS=$THREADS
module load arcc/1.0 dftb/22.2
mpirun -n $PROCS dftb+ > $3-$4.log
!
}

submit_dftb () {
# 1 = TASKS
# 2 = CPUS
# 3 = COF_NAME
  cd Test1
  JOBID1=($(sbatch submit_$3))
  JOBID1=${JOBID1[3]}
  cat >> submit_$3<<!
$JOBID1
!
  cd ../Test2
  JOBID2=($(sbatch submit_$3))
  JOBID2=${JOBID2[3]}
  cat >> submit_$3<<!
$JOBID2
!
  cd ../Test3
  JOBID3=($(sbatch submit_$3))
  JOBID3=${JOBID3[3]}
  cat >> submit_$3<<!
$JOBID3
!
  cd ../Test4
  JOBID4=($(sbatch submit_$3))
  JOBID4=${JOBID4[3]}
  cat >> submit_$3<<!
$JOBID4
!
  cd ../Test5
  JOBID5=($(sbatch submit_$3))
  JOBID5=${JOBID5[3]}
  cat >> submit_$3<<!
$JOBID5
!

}

benchmark () {
# 1 = TASKS
# 2 = CPUS
# 3 = COF_NAME
  mkdir Test1 Test2 Test3 Test4 Test5
  cd Test1
  ITER=1
  cp ../Input-POSCAR ../dftb_in.hsd ./
  gen_submit $1 $2 $3 $ITER
  
  cd ../Test2
  ITER=2
  cp ../Input-POSCAR ../dftb_in.hsd ./
  gen_submit $1 $2 $3 $ITER
  
  cd ../Test3
  ITER=3
  cp ../Input-POSCAR ../dftb_in.hsd ./
  gen_submit $1 $2 $3 $ITER
  
  cd ../Test4
  ITER=4
  cp ../Input-POSCAR ../dftb_in.hsd ./
  gen_submit $1 $2 $3 $ITER
  
  cd ../Test5
  ITER=5
  cp ../Input-POSCAR ../dftb_in.hsd ./
  gen_submit $1 $2 $3 $ITER
  
  cd ../
  
  submit_dftb $TASKS $CPUS $COF_NAME
}

INSTRUCT=$1

COF_NAME=($(sed -n 1p $INSTRUCT))
GEO=($(sed -n 2p $INSTRUCT))

# These jobs will be submitted in batches of 5 per combination, and the new batch submission will be contigent on the previous 5 finishing
# So as not to take up too much space on the cluster and inv-desousa partition
# If a combination stalls, this will be noted in the final text file output for the 5 average jobs

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

scc_dftb_in $GEO myHUBBARD myMOMENTUM

TASKS=1
CPUS=1
benchmark $TASKS $CPUS $COF_NAME
