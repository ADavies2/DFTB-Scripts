# This bash script will run through a series of user-defined tolerances with DFTB+ to relax framework geometries.
# This version 

#!/bin/bash

COF='cof5' # Framework name
TOL='1e-1' # Intial SCC and force tolerance
JOBNAME="$COF-scc-$TOL" # The name of the job when submitting to SLURM

sed -i 's/.*Geometry.*/Geometry = VASPFormat {/g' dftb_in.hsd
sed -i 's/.*<<<.*/  <<< "Input-POSCAR"/g' dftb_in.hsd
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = No/g' dftb_in.hsd

submit_dftb_hybrid 8 1 $JOBNAME # submit the first relaxation job

# LOOP 1
# This first loop will be calculating the first SCC at 1e-1 tolerance. If the SCC succeeds, it will set-up the next calculation to be an SCC 1e-2. If the SCC fails, then the next calculation will be set-up to be forces 1e-1 only.
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
          # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
          sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd # Rewrite the geometry input format
          sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
          TOL='1e-2' # Define the next tolerance
          sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
          sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
          sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Read in charge files
          JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
          echo "The simulation has completed."
          break
        else
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *log *xyz
          # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
          sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd # Rewrite the geometry input format
          sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
          TOL='1e-2' # Define the next tolerance
          sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
          sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
          sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Read in charge files
          JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
          echo "The simulation has completed."
          break
        fi
      elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
        sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC calculation as converging forces only
        sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Forces-Out"/g" dftb_in.hsd
        sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
        JOBNAME="$COF-forces-$TOL" # Change the jobname to reflect a forces only calculation
        echo "SCC did NOT converge. Attempting forces only..."
        break
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done
        
submit_dftb_hybrid 8 1 $JOBNAME # This will either submit an SCC calculation or a forces only calculation

# LOOP 2
# This next loop will either be running an SCC or a forces only. In the previous loop, if the SCC was successful, it set-up the next calculation to be an SCC at 1e-2. If this 1e-2 iteration succeeds, it will set-up a 1e-3 SCC calculation for the next loop. If it fails, then it will set-up a forces only calculation at 1e-2. 
# If the previous SCC calculation failed, then this loop will be running a forces only at 1e-1. If that forces only calculation here is successful, it will set the next calculation up to be an SCC only at 1e-1. If the forces only here fails, then an error message will be displayed indicating that both an SCC and forces only calculation at this tolerance failed. 
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if grep -q "SCC = Yes" dftb_in.hsd; then # If SCC = Yes in dftb_in.hsd, this is an SCC calculation
        TOL='1e-2' # New tolerance defined in the previous loop
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *log *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *log *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
            echo "The simulation has completed."
            break
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
          sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Forces-Out"/g" dftb_in.hsd
          JOBNAME="$COF-forces-$TOL" # Change the jobname to reflect a forces only calculation
          echo "SCC did NOT converge. Attempting forces only..."
          break
        else 
          echo "The simulation is running..."
          sleep 5s
        fi
      elif grep -q "SCC = No" dftb_in.hsd; then # If SCC = No, this is a forces-only calculation
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot. 
          printf "SCC did NOT converge at 1e-1\nForces did NOT converge at 1e-1\nUser trouble-shoot required\n"
          exit
        fi
      fi
    fi
done

submit_dftb_hybrid 8 1 $JOBNAME # This is either submitting an SCC continuation, a forces only from the previous SCC, or an SCC from the forces only.

# LOOP 3
# From the previous loop, loop 3 will either be running an SCC from a previously successful SCC, and SCC from a previously successful forces only, or a forces only from a previously failed SCC.
# If the last SCC at 1e-2 was successful, this loop will be running an SCC calculation at 1e-3 tolerance. If this is successful, it will set-up the final SCC calculation with forces at 1e-4 and SCC at 1e-5. If this fails, it will set-up a forces only at 1e-3.
# If the las SCC failed and a forces only calculation was set-up here, that would be a forces only at 1e-2 tolerance. If this forces only succeeds, it will set-up an SCC at 1e-2. If the forces only fails, it will display an error message that SCC 1e-2 failed and forces only at 1e-2 failed.
# Finally, if the previous calculation was a forces only and was successful, this calculation would be an SCC at the same tolerance (1e-1). 
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if grep -q "SCC = Yes" dftb_in.hsd; then # If SCC = Yes, this is either an SCC continuation or an SCC from the previous forces only
        if grep -q "ReadInitialCharges = Yes" dftb_in.hsd; then # If initial charges are read, this is a continuation of the SCC 
          TOL='1e-3' # SCC continuation tolerance
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log: then # If the SCC continuation is successful
            if [ -d "./$TOL-Outputs" ]; then
              cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
              rm *out *log *xyz
              sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
              TOL='1e-4' # Define the next tolerance continuation
              sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
              sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
              sed -i "s/.*SCCTolerance.*/SCCTolerance = 1e-5/g" dftb_in.hsd # New scc tolerance
              JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
              echo "The simulation has completed."
              break
            else
              mkdir $TOL-Outputs
              cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
              rm *out *log *xyz
              sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
              TOL='1e-4' # Define the next tolerance
              sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
              sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
              sed -i "s/.*SCCTolerance.*/SCCTolerance = 1e-5/g" dftb_in.hsd # New scc tolerance
              JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
              echo "The simulation has completed."
              break
            fi
          elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
            sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
            sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Forces-Out"/g" dftb_in.hsd
            JOBNAME="$COF-forces-$TOL" # Change the jobname to reflect a forces only calculation
            echo "SCC did NOT converge. Attempting forces only..."
            break
          else
            echo "The simulation is running..."
            sleep 5s
          fi
        elif grep -q "ReadInitialCharges = No" dftb_in.hsd # This is the first SCC of a prevoiusly successful forces only calculation
          TOL='1e-1'
            if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log: then # If the SCC is successful
              if [ -d "./$TOL-Outputs" ]; then
                cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
                rm *out *log *xyz
                sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
                TOL='1e-2' # Define the next tolerance continuation
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
                sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
                sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd # Since this was the first SCC of a forces calculation, the next iteration will have charges to read
                JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
                echo "The simulation has completed."
                break
              else
                mkdir $TOL-Outputs
                cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
                rm *out *log *xyz
                sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
                TOL='1e-2' # Define the next tolerance
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
                sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
                sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd
                JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
                echo "The simulation has completed."
                break
              fi
            elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
              printf "SCC did NOT converge after forces\nUser trouble-shoot required\n"
            fi
        fi
      elif grep -q "SCC = No" dftb_in.hsd; then # This is a forces only calculation from the previous SCC 1e-2
        TOL='1e-2'
        # If suceeds, start scc 1e-2 calculation
        # If fails, error message
