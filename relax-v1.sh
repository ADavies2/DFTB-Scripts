# This bash script will run through a series of user-defined tolerances with DFTB+ to relax framework geometries.
# Note that this version DOES NOT include the portion of the workflow that accounts for "SCC NOT CONVERGED" or "GEOMETRY NOT CONVERGED"

# This script begins with a POSCAR file format and the dftb_in.hsd script. The dftb_in.hsd script should be set for the system, including the proper Slater-Koster files and associated pathways or any other desired calculations.
# The only variables that the user changes in this script are the following: COF and TOL. COF is the name of this COF and will be used in the jobname for the subsmission script. TOL is the SCC and Force tolerance value that the simulation begins at. Set this at a low value if the POSCAR geometry has never been optimized before.

!/bin/bash

COF='cof139' # Framework name
TOL='1e-1' # Intial SCC and force tolerance
JOBNAME="$COF-scc-$TOL" # The name of the job when submitting to SLURM

sed -i 's/.*Geometry.*/Geometry = VASPFormat {/g' dftb_in.hsd
sed -i 's/.*<<<.*/  <<< "Input-POSCAR"/g' dftb_in.hsd
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = No/g' dftb_in.hsd

submit_dftb_hybrid 8 1 $JOBNAME # submit the first relaxation job

while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
        if [ -d "./$TOL-Outputs" ]; then
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        else
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        fi
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done

# Rewrite the inputs in dftb_in.hsd
sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd # Rewrite the geometry input format
sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
TOL='1e-2' # Redefine the new tolerance
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Read in charge files

JOBNAME="$COF-scc-$TOL" # new jobname for the second relaxation

rm detailed.out
submit_dftb_hybrid 8 1 $JOBNAME # Submit the second relaxation and run the same loop

while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
        if [ -d "./$TOL-Outputs" ]; then
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        else
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        fi
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done

# Rewrite the inputs in dftb_in.hsd
sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd # Rewrite the geometry input format
sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
TOL='1e-3' # Redefine the new tolerance
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Read in charge files

JOBNAME="$COF-scc-$TOL" # new jobname for the second relaxation

rm detailed.out
submit_dftb_hybrid 8 1 $JOBNAME # Submit the second relaxation and run the same loop

while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
        if [ -d "./$TOL-Outputs" ]; then
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        else
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        fi
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done

# Rewrite the inputs in dftb_in.hsd
sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd # Rewrite the geometry input format
sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
TOL='1e-4' # Redefine the new tolerance
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
sed -i "s/.*SCCTolerance.*/SCCTolerance = 1e-5/g" dftb_in.hsd # New scc tolerance
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Read in charge files

JOBNAME="$COF-scc-$TOL" # new jobname for the second relaxation

rm detailed.out
submit_dftb_hybrid 8 1 $JOBNAME # Submit the second relaxation and run the same loop

while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
        if [ -d "./$TOL-Outputs" ]; then
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        else
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          echo "The simulation has completed."
          break
        fi
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done

rm *out *log *xyz *gen *bin # delete all duplicate data files, which have been copied to their respective directories

echo "Relaxation and optimization of $COF has completed."
