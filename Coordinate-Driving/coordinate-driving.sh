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

scc_dftb_in () {
# 1 = $GEO
# 2 = $MOVED_ATOMS
# 3 = $ITER
# 4 = myHUBBARD
# 5 = myMOMENTUM
  movedatoms=$2[@]
  ATOMIDS=("${!movedatoms}")
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
  MaxSteps = 100000
  LatticeOpt = No
  AppendGeometries = No
  OutputPrefix = CD-Out$3
  MovedAtoms = ${ATOMIDS[@]}
  Constraints = {
    ${ATOMIDS[0]} 0.0 0.0 1.0
    ${ATOMIDS[1]} 0.0 0.0 1.0
    ${ATOMIDS[2]} 0.0 0.0 1.0 } } 

Hamiltonian = DFTB {
SCC = Yes
ReadInitialCharges = No
MaxSCCIterations = 5000
ThirdOrderFull = Yes
Dispersion = LennardJones {
Parameters = UFFParameters{} }
HCorrection = Damping {
Exponent = 4.05 }
HubbardDerivs {
!
  hubbard=$4[@]
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
  momentum=$5[@]
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

submit () {
# 1 = COF_NAME
# 2 = ITER
# 3 = PARTITION
  # Number of nodes intended:
  NODE=1
  # memory per core:
  MEM=20GB
  # Time for the job:
  TIME=48:00:00
  # Number of tasks per node:
  TASK=8
  # Number of CPUs per task:
  CPUS=1
  # Jobname:
  JOBNAME=$1-cd$2

  # Generate particular job submit script
  SCRIPT_NAME=submit_$JOBNAME

  PROC=$((NODE * TASK))

cat > $SCRIPT_NAME<<!
#!/bin/bash
#SBATCH --nodes=$NODE
#SBATCH --ntasks-per-node=$TASK
#SBATCH --cpus-per-task=$CPUS
#SBATCH --account=designlab
#SBATCH --time=$TIME
#SBATCH --job-name=$JOBNAME
#SBATCH --output=$JOBNAME.out
#SBATCH --partition=$3
#SBATCH --mem=$MEM

cd \$SLURM_SUBMIT_DIR

export OMP_NUM_THREADS=$CPUS

module load arcc/1.0 dftb/22.2

mpirun -n $PROC dftb+ > $JOBNAME.log
!
  JOBID=($(sbatch $SCRIPT_NAME))
  JOBID=${JOBID[3]}

  cat >> $SCRIPT_NAME<<!
$JOBID
!
  while :
  do
    stat=($(squeue -n $JOBNAME))
    jobstat=(${stat[12]})
    if [ "$jobstat" == "PD" ]; then
      echo "$JOBNAME is pending..."
      sleep 10s
    else
      sleep 10s
      if grep -q "Geometry converged" detailed.out; then
  	    echo "Job complete."
        rm submit_$JOBNAME $JOBNAME.log $JOBNAME.out *bin dftb* band.out *xyz
        mv detailed.out detailed$2.out
        break
      elif grep -q "SCC is NOT converged" $JOBNAME.log; then
        echo "SCC did not converge.\nDouble-check structure."
        exit
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

module load gcc/11.2.0 python/3.10.8

INSTRUCT=$1

COFNAME=($(sed -n 1p $INSTRUCT))
GEO=($(sed -n 2p $INSTRUCT))
MOVED_ATOMS=($(sed -n 3p $INSTRUCT))
PARTITION=($(sed -n 4p $INSTRUCT))
DIST=($(sed -n 5p $INSTRUCT)) # distance the molecule of H2O will move. Move through at least 1 layer. 

# Read input geometry file to get atom types and number of atoms  
if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
else
  ATOM_TYPES=($(sed -n 1p $GEO))
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Determine the number of steps based on the distance travelled, which is provided as user input
# Distance travelled should be through at least one layer. Take the layer spacing and round up to the nearest integer
STEP=0.25
N_STEPS=$(echo $DIST / $STEP | bc)

echo "$N_STEPS steps of 0.25 Ang each"

for i in $(seq 1 $N_STEPS); do
  if [[ $i == 1 ]]; then # If this is the first iteration, use the geo provided by the instruction file
    GEO=($(sed -n 2p $INSTRUCT))
  else # Otherwise, use the modified geo file made with Move-H2O.py
    GEO="$COFNAME-CD-Input.gen"
  fi

  # Write the dftb_in file
  scc_dftb_in $GEO MOVED_ATOMS $i myHUBBARD myMOMENTUM

  # Submit the calculation
  submit $COFNAME $i $PARTITION

  # Generate the next input file based on the positions of the H2O molecule in the output file
  printf "CD-Out$i.gen\n$COFNAME\n${MOVED_ATOMS[0]} ${MOVED_ATOMS[1]} ${MOVED_ATOMS[2]}" | Move-H2O.py
  echo "\n"
done

for i in $(seq 1 $N_STEPS); do
  DETAILED=($(grep "Total energy" detailed$i.out))
  TOTAL_ENERGY=${DETAILED[4]}
  cat >> $COFNAME-CD.dat <<!
$TOTAL_ENERGY
!
done

MIN=$(sort -n "$COFNAME-CD.dat" | head -1)
MAX=$(sort -n "$COFNAME-CD.dat" | tail -1)

EBARRIER=$(echo $MAX - $MIN | bc)

cat >> $COFNAME-CD.dat <<!
Maximum = $MAX eV
Minimum = $MIN eV
Barrier energy = $EBARRIER eV
!