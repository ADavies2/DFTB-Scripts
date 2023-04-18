#!/bin/bash

JOBID=$1
COFNAME=$2
ITERATION=$3

SACCT=($(sacct -j $JOBID --format=jobid,jobname,maxdiskread,maxdiskwrite,maxrss,maxvmsize,totalcpu,ncpus,ntasks,nnodes | grep hydra))
CPUEff=($(seff $JOBID | grep "CPU Efficiency"))

if grep -q "Post-geometry optimisation" $COFNAME-$ITERATION.log; then
  DFTB=($(tail -n 13 $COFNAME-$ITERATION.log))
  cat > $JOBID-stats.dat <<!
JOBID $JOBID
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
  DFTB=($(tail -n 12 $COFNAME-$ITERATION.log))
  cat > $JOBID-stats.dat <<!
JOBID $JOBID
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
