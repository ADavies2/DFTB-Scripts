# Before running this script, make sure there is a base dftb_in.hsd script in the Properties directory, as well as the final geometry and charges. All calculations should be run with fully optimized geometry.

#!/bin/bash

COF='cof5' # COF name

## Make directories to store the data from each property calculation
mkdir Charges # charge distribution, charges as text from DFTB+
mkdir Band # band structures
mkdir DOS # density of states
mkdir Waveplot # charge density distribution (blue and red isosurface plots)

## Calculate charge distribution from DFTB+ first using the option WriteChargesAsText = Yes

cd Charges
cp ../dftb_in.hsd ./
printf '\nOptions {\n  WriteChargesAsText = Yes }\n' >> dftb_in.hsd
# The above is the only change that needs to be made to the dftb_in.hsd script to generate charge data as a text file.
cp ../Input.gen ./
cp ../charges.bin ./

# submit the calculation to generate the charge data as a text file
submit_dftb_hybrid 8 1 $COF-charges
echo "$COF charges as text has been submitted..."

## Calculate the band structure from DFTB+

cd ../Band
mkdir Relax
cd Relax
# Rerun a relaxation with the final geometry and charges in order to generate the band.out file
cp ../../dftb_in.hsd ../../Input.gen ../../charges.bin ./

submit_dftb_hybrid 8 1 $COF-bands-relax
echo "Relaxation of $COF for bands has been submitted..."

while :
do
  stat="$(squeue -n $COF-bands-relax)"
  string=($stat)
  jobstat=(${string[12]})
    if [ "$jobstat" == "PD" ]; then
      echo "$COF-bands-relax is pending..."
      sleep 5s
    else
      if grep -q "SCC converged" detailed.out; then
        cp dftb_in.hsd Input.gen charges.bin ../
      fi
    fi
done

cd ../
# Now, the dftb_in.hsd script must be edited to generate the band structure of a well converged system upon initial diagonalization of the Hamiltonian
# These edits include a static calculation, max SCC iterations, and the path of high symmetry.
# The path of high symmetry used here is the general path for hexagonal COFs.
# NOTE, that the user may want to change this if they see so fit.

sed -i 's/.*Driver.*/Driver = { }/g' dftb_in.hsd # Rewrite for a static calculation
sed -i '/.*MovedAtoms.*/,/.*LatticeOpt.*/d' dftb_in.hsd # Remove the other driver lines
sed -i 's/.*MaxSCCIterations.*/MaxSCCIterations = 1/g' dftb_in.hsd # Set to one scc iteration
sed -i '/.*4 0 0.*/,/.*0.5 0.5 0.5.*/d' dftb_in.hsd # Remove the previous k-point mesh
sed -i 's/.*KPointsAndWeights.*/KPointsAndWeights [relative] = Klines {\n  1 0.0 0.0 0.0\n  10 0.33 0.33 0.0\n  10 0.5 0.0 0.0\n  10 0.0 0.0 0.0 }/g' dftb_in.hsd # Rewrite the new k-path of high symmetry

submit_dftb_hybrid 8 1 generate-$COF-bands
echo "Generating $COF bands submitted..."

while :
do
  stat="$(squeue -n generate-$COF-bands)"
  string=($stat)
  jobstat=(${string[12]})
    if [ "$jobstat" == "PD" ]; then
      echo "generate-$COF-bands is pending..."
      sleep 5s
    else
      if grep -q "SCC is NOT converged" generate-$COF-bands.log; then
        break
      fi
    fi
done

submit_dftb_bands 4 $COF-band # generate a plottable data file to visualize the band structure
# The data file will be $COF-band_tot.dat
echo "$COF band structure conversion submitted..."

## Calculate the density of states and atom-resolved partial density of states

cd ../DOS
cp ../dftb_in.hsd ../Input.gen ../charges.bin ./

# Edits to the base dftb_in.hsd script include making this a static calculation and including the analysis section that has the atom resolved DOS input.
# NOTE, the user will want to change this depending on the types of atoms in their simulation

sed -i 's/.*Driver.*/Driver = { }/g' dftb_in.hsd # Rewrite for a static calculation
sed -i '/.*MovedAtoms.*/,/.*LatticeOpt.*/d' dftb_in.hsd # Remove the other driver lines
sed -i 's/.*MullikenAnalysis.*/  MullikenAnalysis = Yes\n  ProjectStates {\n    Region {\n      Atoms = C\n      ShellResolved = Yes\n      label = "dos_C" }\n    Region {\n      Atoms = H\n      ShellResolved = Yes\n      label = "dos_H" }\n    Region {\n      Atoms = N\n      ShellResolved = Yes\n      label = "dos_N" }\n    Region {\n      Atoms = O\n      ShellResolved = Yes\n      label = "dos_O" }\n  }\n}/g' dftb_in.hsd # Include the DOS information

submit_dftb_hybrid 8 1 generate-$COF-dos
echo "Generating $COF DOS..."

while :
do
  stat="$(squeue -n generate-$COF-dos)"
  string=($stat)
  jobstat=(${string[12]})
    if [ "$jobstat" == "PD" ]; then
      echo "generate-$COF-dos is pending..."
      sleep 5s
    else
      if grep -q "SCC converged" detailed.out; then
        break
      fi
    fi
done

submit_dftb_dos 4 $COF-dos
echo "$COF DOS conversion submitted..."
