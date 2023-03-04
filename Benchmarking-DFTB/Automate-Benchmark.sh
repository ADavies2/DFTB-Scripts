#!/bin/bash

# This scrip automatically runs DFTB+ jobs with a pre-set configuration of nodes/cpus/tasks
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

gen_submit () {
# 1 = TASKS
# 2 = CPUS
# 3 = COF_NAME
# 4 = ITER
  THREADS=$(($1 * $2))
  NODE=1
  MEM=20G
  TIME=72:00:00
  SCRIPT_NAME=submit_$3
  
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
module load arcc/1.0 gcc/12.2.0 dftb/22.1-ompi
srun dftb+ > $3-$4.log
!
}

check_status () {
# 1 = JOBID
# 2 = COF_NAME
# 3 = ITER

#SCCClock(s) ${DFTB[2]}
#Diagonalisation(s) ${DFTB[9]}
#DensityMatrix(s) ${DFTB[18]}
#PostSCCClock(s) ${DFTB[27]}
#EnergyDensity(s) ${DFTB[36]}
#Force(s) ${DFTB[44]}
#Stress(s) ${DFTB[52]}
#TotalClockTime(s) ${DFTB[69]}

  while :
  do
    qstat=($(qstat $1))
    jobstat=(${qstat[18]})
    if [ "$jobstat" == "Q" ]; then
      echo "$1 is pending..."
      sleep 20s
    elif [ "$jobstat" == "C" ]; then
      echo "$1 has completed."
      SACCT=($(sacct -j $1 --format=jobid,jobname,maxdiskread,maxdiskwrite,maxrss,maxvmsize,totalcpu,ncpus,ntasks,nnodes | grep dftb+))
      CPUEff=($(seff $1 | grep "CPU Efficiency"))
      if grep -q "Post-geometry optimisation" $2-$3.log; then
        DFTB=($(tail -n 13 $2-$3.log))
        cat > $1-stats.dat <<!
JOBID $1
PreSCC(s) ${DFTB[3]}
SCC(s) ${DFTB[11]}
Diagonalisation(s) ${DFTB[18]}
DensityMatrix(s) ${DFTB[27]}
PostSCC(s) ${DFTB[36]}
Force(s) ${DFTB[53]}
Stress(s) ${DFTB[61]}
PostGeom(s) ${DFTB[70]}
TotalClock(s) ${DFTB[87]}
DiskRead(bytes) ${SACCT[2]}
DiskWrite(bytes) ${SACCT[3]}
RSS(bytes) ${SACCT[4]}
VMS(bytes) ${SACCT[5]}
NCPUS ${SACCT[7]}
NTasks ${SACCT[8]}
NNodes ${SACCT[9]}
CPUEfficiency ${CPUEff[2]}
!
      else
        DFTB=($(tail -n 12 $2-$3.log))
        cat > $1-stats.dat <<!
JOBID $1
PreSCC(s) ${DFTB[3]}
SCC(s) ${DFTB[11]}
Diagonalisation(s) ${DFTB[18]}
DensityMatrix(s) ${DFTB[27]}
PostSCC(s) ${DFTB[36]}
Force(s) ${DFTB[53]}
Stress(s) ${DFTB[61]}
TotalClock(s) ${DFTB[78]}
DiskRead(bytes) ${SACCT[2]}
DiskWrite(bytes) ${SACCT[3]}
RSS(bytes) ${SACCT[4]}
VMS(bytes) ${SACCT[5]}
NCPUS ${SACCT[7]}
NTasks ${SACCT[8]}
NNodes ${SACCT[9]}
CPUEfficiency ${CPUEff[2]}
!
      fi
    break
    elif [ "$jobstat" == "R" ]; then
      echo "$1 is running..."
      log_size=($(ls -l "$2-$3.log"))
      size=(${log_size[4]})
      sleep 60s
      log_size2=($(ls -l "$2-$3.log"))
      size2=(${log_size2[4]})
      if [[ $size == $size2 ]]; then
        echo "$1 has stalled and is being cancelled."
        qdel $1
        SACCT=($(sacct -j $1 --format=jobid,jobname,maxdiskread,maxdiskwrite,maxrss,maxvmsize,totalcpu,ncpus,ntasks,nnodes | grep dftb+))
        CPUEff=($(seff $1 | grep "CPU Efficiency"))
        if grep -q "Post-geometry optimisation" $2-$3.log; then
          DFTB=($(tail -n 13 $2-$3.log))
          cat > $1-stats.dat <<!
JOBID $1
STALL YES
PreSCC(s) ${DFTB[3]}
SCC(s) ${DFTB[11]}
Diagonalisation(s) ${DFTB[18]}
DensityMatrix(s) ${DFTB[27]}
PostSCC(s) ${DFTB[36]}
Force(s) ${DFTB[53]}
Stress(s) ${DFTB[61]}
PostGeom(s) ${DFTB[70]}
TotalClock(s) ${DFTB[87]}
DiskRead(bytes) ${SACCT[2]}
DiskWrite(bytes) ${SACCT[3]}
RSS(bytes) ${SACCT[4]}
VMS(bytes) ${SACCT[5]}
NCPUS ${SACCT[7]}
NTasks ${SACCT[8]}
NNodes ${SACCT[9]}
CPUEfficiency ${CPUEff[2]}
!
        else
          DFTB=($(tail -n 12 $2-$3.log))
          cat > $1-stats.dat <<!
JOBID $1
STALL YES
PreSCC(s) ${DFTB[3]}
SCC(s) ${DFTB[11]}
Diagonalisation(s) ${DFTB[18]}
DensityMatrix(s) ${DFTB[27]}
PostSCC(s) ${DFTB[36]}
Force(s) ${DFTB[53]}
Stress(s) ${DFTB[61]}
TotalClock(s) ${DFTB[78]}
DiskRead(bytes) ${SACCT[2]}
DiskWrite(bytes) ${SACCT[3]}
RSS(bytes) ${SACCT[4]}
VMS(bytes) ${SACCT[5]}
NCPUS ${SACCT[7]}
NTasks ${SACCT[8]}
NNodes ${SACCT[9]}
CPUEfficiency ${CPUEff[2]}
!
        fi
      break
      else
        echo "$1 is running..."
      fi
    fi
  done
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
  cd ../Test1
  check_status $JOBID1 $3 1
  cd ../Test2
  check_status $JOBID2 $3 2
  cd ../Test3
  check_status $JOBID3 $3 3
  cd ../Test4
  check_status $JOBID4 $3 4
  cd ../Test5
  check_status $JOBID5 $3 5
  cd ../
  
  mkdir "$1"t-"$2"cpus
  
  cp Test1/"$3"-1.log Test1/"$JOBID1"-stats.dat "$1"t-"$2"cpus
  cp Test2/"$3"-2.log Test2/"$JOBID2"-stats.dat "$1"t-"$2"cpus
  cp Test3/"$3"-3.log Test3/"$JOBID3"-stats.dat "$1"t-"$2"cpus
  cp Test4/"$3"-4.log Test4/"$JOBID4"-stats.dat "$1"t-"$2"cpus
  cp Test5/"$3"-5.log Test5/"$JOBID5"-stats.dat "$1"t-"$2"cpus
  
  rm -r Test1 Test2 Test3 Test4 Test5

  echo "$1 tasks and $2 CPUs complete for $3"
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

# This will be tested for three system sizes constituting "small", "medium", and "large" COF unit cells
# These systems are TpTt (54 atoms), COF-66 (210 atoms), and COF-141 Random1 (500 atoms)
# These will only run for a 1e-2 tolerance to get a long enough job with data points and ideally without taking multiple days to run

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

TASKS=28
CPUS=1
benchmark $TASKS $CPUS $COF_NAME

TASKS=1
CPUS=28
benchmark $TASKS $CPUS $COF_NAME

TASKS=20
CPUS=1
benchmark $TASKS $CPUS $COF_NAME

TASKS=1
CPUS=20
benchmark $TASKS $CPUS $COF_NAME

TASKS=14
CPUS=1
benchmark $TASKS $CPUS $COF_NAME

TASKS=1
CPUS=14
benchmark $TASKS $CPUS $COF_NAME

TASKS=6
CPUS=1
benchmark $TASKS $CPUS $COF_NAME

TASKS=1
CPUS=6
benchmark $TASKS $CPUS $COF_NAME
