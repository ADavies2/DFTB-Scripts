#!/bin/bash

submit () {
# 1 = COF_NAME
# 2 = ITER
# 3 = PARTITION
  # Number of nodes intended:
  NODE=3
  # memory per core:
  MEM=100GB
  # Time for the job:
  TIME=48:00:00
  # Number of CPUs per task:
  CPUS=1
  # Number of tasks per node:
  TASKS=16
  # Jobname:
  JOBNAME=$1-cd$2

  # Generate particular job submit script
  SCRIPT_NAME=submit_$JOBNAME

cat > $SCRIPT_NAME<<!
#!/bin/bash
#SBATCH --nodes=$NODE
#SBATCH --ntasks-per-node=$TASKS
#SBATCH --cpus-per-task=$CPUS
#SBATCH --account=designlab
#SBATCH --time=$TIME
#SBATCH --job-name=$JOBNAME
#SBATCH --output=$JOBNAME.out
#SBATCH --partition=$3
#SBATCH --mem=$MEM

cd \$SLURM_SUBMIT_DIR

export OMP_NUM_THREADS=$CPUS

module load gcc/12.2.0 openmpi/4.1.4 fftw/3.3.10-ompi openblas/0.3.21 netlib-scalapack/2.2.0-ompi wannier90/3.1.0 hdf5/1.12.2-ompi

/usr/bin/time -o job_statistics.out --verbose srun /project/designlab/vasp/beartooth/vasp.6.3.2/bin/vasp_std
!
  JOBID=($(sbatch $SCRIPT_NAME))
  JOBID=${JOBID[3]}

  cat >> $SCRIPT_NAME<<!
$JOBID
!
echo "$JOBID has been submitted."
  while :
  do
    stat=($(squeue -n $JOBNAME))
    jobstat=(${stat[12]})
    if [ "$jobstat" == "PD" ]; then
      echo "$JOBNAME is pending..."
      sleep 10s
    elif [ "$jobstat" == "R" ]; then
      echo "$JOBNAME is running..."
      sleep 20s
    else
      if grep -q "reached required accuracy - stopping" OUTCAR; then
        rm submit_$JOBNAME $JOBNAME.out CHGCAR WAVECAR 
        mv OUTCAR OUTCAR$2
        mv CONTCAR CONTCAR$2
        echo "$JOBID is complete."
        break
      elif grep -q "I REFUSE TO CONTINUE" $JOBNAME.out; then
          echo "VASP Error. User trouble-shoot required."
          exit
      fi
    fi 
  done
}

module load gcc/11.2.0 python/3.10.8

INSTRUCT=$1

COFNAME=($(sed -n 1p $INSTRUCT))
MOVED_ATOMS=($(sed -n 2p $INSTRUCT))
PARTITION=($(sed -n 3p $INSTRUCT))
DIST=($(sed -n 4p $INSTRUCT)) # distance the molecule of H2O will move. Move through at least 1 layer. 

# Determine the number of steps based on the distance travelled, which is provided as user input
# Distance travelled should be through at least one layer. Take the layer spacing and round up to the nearest integer
STEP=0.25
N_STEPS=$(echo $DIST / $STEP | bc)

echo "$N_STEPS steps of 0.25 Ang each"

for i in $(seq 1 $N_STEPS); do

  # Submit the calculation
  submit $COFNAME $i $PARTITION

  # Generate the next input file based on the positions of the H2O molecule in the output file
  printf "CONTCAR$i\n$COFNAME\n${MOVED_ATOMS[0]} ${MOVED_ATOMS[1]} ${MOVED_ATOMS[2]}" | Move-H2O.py
  echo "\n"
done

for i in $(seq 1 $N_STEPS); do
  OUTCAR=($(grep "TOTEN" OUTCAR$i | tail -n 1))
  TOTAL_ENERGY=${OUTCAR[4]}
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

echo "Coordinate driving for $COFNAME is complete."