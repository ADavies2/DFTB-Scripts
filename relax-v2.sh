## This bash script will run through a complete relaxation of a COF (or building block) beginning with 1e-1 tolerances down to the DFTB+ default tolerances
## This version includes fail safes for if an SCC does not converge. If an SCC does not converge, the algorithm will submit a forces only calculation at the same tolerance as before. If this too fails, then an error message will be displayed. If this suceeds, then it will resubmit the previous SCC with the new geometry.

#!/bin/bash

## Initialize the name of the COF or building block being relaxed, the initial tolerance, and the first jobname
COF='cof5' # Framework name
TOL='1e-1' # Intial SCC and force tolerance
JOBNAME="$COF-scc-$TOL" # Initialize the jobname used when submitting to SLURM

## A double check to initialize dftb_in.hsd to the first format of the relax for a brand new material
sed -i 's/.*Geometry.*/Geometry = VASPFormat {/g' dftb_in.hsd
sed -i 's/.*<<<.*/  <<< "Input-POSCAR"/g' dftb_in.hsd
sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = No/g' dftb_in.hsd

## Submit the first job
submit_dftb_hybrid 8 1 $JOBNAME # submit the first relaxation job

## LOOP 1 (Light Blue)
## SCC 1e-1. Results are either SCC 1e-2 or Forces 1e-1
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else     
      if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the job has suceeded
        if [ -d "./$TOL-Outputs" ]; then # Check if a directory exists that can hold these output files
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *xyz
          # Rewrite dftb_in.hsd for the next SCC iteration
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
        else # If the directory doesn't exist, make one. This loop will be used in the future for all successful SCC calculations.
          mkdir $TOL-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
          rm *out *xyz
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
        echo "The simulation is running..." # In the event the calculations are still running 
        sleep 5s
      fi
    fi
done
        
## Submit the second job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 2 (Light Green)
## Either running SCC 1e-2 or Forces 1e-1. Results are either SCC 1e-3, Forces 1e-2, a repeat SCC 1e-1, or an error message.
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if [ $JOBNAME == "$COF-scc-1e-2" ]; then # If running next SCC iteration
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
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
            rm *out *xyz
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
      elif [ $JOBNAME == "$COF-forces-1e-1" ]; then # If $JOBNAME has been rewritten for a forces calculation. $TOL has not be rewritten since initialization and is still 1e-1
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## submit the third job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 3 (Light Yellow)
## Either running SCC 1e-3, Forces 1e-2, or SCC2 1e-1. 
## The results will either be SCC 1e-5, Forces 1e-3, SCC2 1e-2, SCC 1e-2, or an error message.
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if [ $JOBNAME == "$COF-scc-1e-3" ]; then # If $JOBNAME has been rewritten to continue a successful SCC iteration
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC continuation is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
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
      elif [ $JOBNAME == "$COF-forces-1e-2" ]; then # If $JOBNAME has be rewritten to run a forces calculation from a previously failed SCC 1e-2
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc2-1e-1" ]; then # If $JOBNAME has been rewritten for an SCC calculation from the previously successful forces
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-2' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            sed -i 's/*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd 
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-2' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            sed -i 's/*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd 
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
            echo "The simulation has completed."
            break
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## Submit the fourth job
submit_dftb_hybrid 8 1 $JOBNAME 

## LOOP 4 (Light Red)
## Either running SCC 1e-5, Forces 1e-3, SCC2 1e-2, or SCC 1e-2
## The results are either Fores 1e-4, SCC2 1e-3, SCC 1e-3, Forces 1e-2, an error message, or complete.
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if [ $JOBNAME == "$COF-forces-1e-3" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC continuation is successful
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-5" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin # delete all duplicate output files
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
          sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Forces-Out"/g" dftb_in.hsd
          JOBNAME="$COF-forces-1e-4" # Change the jobname to reflect a forces only calculation
          echo "SCC did NOT converge. Attempting forces only..."
          break
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc2-1e-2" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
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
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-2" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC continuation is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL"/g" dftb_in.hsd # New output file prefix
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
      fi
    fi
done

## Submit the fifth job
submit_dftb_hybrid 8 1 $JOBNAME 

## LOOP 5 (Light Purple)
## Either running Forces 1e-4, SCC2 1e-3, SCC 1e-3, or Forces 1e-2
## The results are either SCC2 1e-5, SCC 1e-5, Forces 1e-3, SCC2 1e-2, or error message.
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if [ $JOBNAME == "$COF-scc2-1e-3" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
            echo "The simulation has completed."
            break
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-forces-1e-4" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""1e-4-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-3" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
            echo "The simulation has completed."
            break
          else 
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
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
      elif [ $JOBNAME == "$COF-forces-1e-2" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## Submit the sixth job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 6 (Kelly Green)
## Either running SCC2 1e-5, SCC 1e-5, Forces 1e-3, or SCC2 1e-2
## The results are either Forces 1e-4, SCC2 1e-3, SCC 1e-3, complete, or an error message
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else 
      if [ $JOBNAME == "$COF-scc-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
          sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Forces-Out"/g" dftb_in.hsd
          JOBNAME="$COF-forces-1e-4" # Change the jobname to reflect a forces only calculation
          echo "SCC did NOT converge. Attempting forces only..."
          break
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc2-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-forces-1e-3" ]; then 
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""$TOL-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc2-1e-2" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-3' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
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
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## submit the seventh job 
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 7 (Sky Blue)
## Either running Forces 1e-4, SCC2 1e-3, or SCC 1e-3
## The results are either SCC2 1e-5, SCC 1e-5, Forces 1e-3, or an error message
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if [ $JOBNAME == "$COF-forces-1e-4" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""1e-4-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc2-1e-3" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
            echo "The simulation has completed."
            break
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-3" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            # Rewrite the inputs in dftb_in.hsd for the next SCC iteration
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
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
      fi
    fi
done

## submit the eigth job 
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 8 (Purple)
## Either running SCC2 1e-5, SCC 1e-5, or Forces 1e-3
## The results are either Forces 1e-4, SCC2 1e-3, complete, or an error message
## The results are either Forces 1e-4, SCC2 1e-3, complete, or error message
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if [ $JOBNAME == "$COF-scc2-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
          sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Forces-Out"/g" dftb_in.hsd
          JOBNAME="$COF-forces-1e-4" # Change the jobname to reflect a forces only calculation
          echo "SCC did NOT converge. Attempting forces only..."
          break
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-forces-1e-3" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""1e-4-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## submit the ninth job 
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 9 (Magenta)
## Either running Forces 1e-4 or SCC2 1e-3
## The results are either SCC2 1e-5, SCC 1e-5, or an error message
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if [ $JOBNAME == "$COF-scc2-1e-3" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then # If the SCC is successful
          if [ -d "./$TOL-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance continuation
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next SCC iteration. The 'scc2' is to indicate that it is the second SCC iteration at this same tolerance
            echo "The simulation has completed."
            break
          else
            mkdir $TOL-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin $TOL-Outputs/
            rm *out *xyz
            sed -i "s/.*<<<.*/  <<< ""$TOL-Out.gen""/g" dftb_in.hsd # Rewrite the input file name
            TOL='1e-5' # Define the next tolerance
            sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g" dftb_in.hsd # New force tolerance
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd # New output file prefix
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd # New scc tolerance
            JOBNAME="$COF-scc-$TOL" # Change the jobname to reflect the next scc iteration
            echo "The simulation has completed."
            break
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-forces-1e-4" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
          sed -i "s/.*<<<.*/  <<< ""1e-4-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
          sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd
          JOBNAME="$COF-scc2-$TOL"
          echo "Forces converged. Attempting SCC at $TOL..."
          break
        elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
          printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## submit the tenth job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 10 (Orange)
## Either running SCC2 1e-5 or SCC 1e-5
## The results are either complete, error message, or Forces 1e-4
while :
do
  stat="$(squeue -n $JOBNAME)"
  string=($stat)
  jobstat=(${string[12]}) # Check the status of the submitted job
    if [ "$jobstat" == "PD" ]; then # If the job is pending
      echo "The simulation is pending..."
      sleep 5s
    else
      if [ $JOBNAME == "$COF-scc2-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          printf "SCC at $TOL did NOT converge after forces\nUser trouble-shoot required\n"
          exit
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      elif [ $JOBNAME == "$COF-scc-1e-5" ]; then
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $JOBNAME.log; then
          if [ -d "./1e-4-Outputs" ]; then
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!" 
            rm *out *log *xyz *gen *bin
            exit
          else
            mkdir 1e-4-Outputs
            cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
            echo "$COF has been fully relaxed!"
            rm *out *log *xyz *gen *bin
            exit
          fi
        elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd # No SCC iterations as converging forces only
          sed -i '/^\s*SCCTolerance.*-0.1623 }$/ s|^|#|; /^\s*SCCTolerance/, /-0.1623 }$/ s|^|#|' dftb_in.hsd # Comment out the range of lines used in an SCC calculation 
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Forces-Out"/g" dftb_in.hsd
          JOBNAME="$COF-forces-1e-4" # Change the jobname to reflect a forces only calculation
          echo "SCC did NOT converge. Attempting forces only..."
          break
        else
          echo "The simulation is running..."
          sleep 5s
        fi
      fi
    fi
done

## submit the eleventh job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 11 (Mustard Yellow)
## Only running forces 1e-4
## The results are either error message or SCC2 1e-5
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
        sed -i 's/.*SCC = No.*/SCC = Yes/g' dftb_in.hsd # Initialize an SCC run next, but this must read-in the newly generated geometry 
        sed -i "s/.*<<<.*/  <<< ""1e-4-Forces-Out.gen""/g" dftb_in.hsd # Use previously generated geometry from forces-only calculation
        sed -i 's/^#//' dftb_in.hsd # Remove all commented lines that are necessary for SCC calculation
        sed -i "s/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out"/g" dftb_in.hsd
        JOBNAME="$COF-scc2-$TOL"
        echo "Forces converged. Attempting SCC at $TOL..."
        break
      elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $JOBNAME.log; then # If the Geometry does not converge with a forces only calculation, then exit and prompt for user troubleshoot.
        printf "SCC did NOT converge at $TOL\nForces did NOT converge at $TOL\nUser trouble-shoot required\n"
        exit
      else
        echo "The simulation is running..."
        sleep 5s
      fi
    fi
done

## submit the twelfth job
submit_dftb_hybrid 8 1 $JOBNAME

## LOOP 12 (Eggplant)
## This loop is only running the outcome of SCC2 1e-5
## The result is either complete or error message
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
        if [ -d "./1e-4-Outputs" ]; then
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
          echo "$COF has been fully relaxed!" 
          rm *out *log *xyz *gen *bin
          exit
        else
          mkdir 1e-4-Outputs
          cp detailed.out $JOBNAME.log $TOL-Out.gen $TOL-Out.xyz charges.bin 1e-4-Outputs/
          echo "$COF has been fully relaxed!"
          rm *out *log *xyz *gen *bin
          exit
        fi
      elif grep -q "SCC is NOT converged" $JOBNAME.log; then # If the SCC does not converge, first run a forces only simulation
        printf "SCC at $TOL did NOT converge after fores\nUser trouble-shoot required\n"
        exit
      fi
    fi
done
