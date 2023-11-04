#!/bin/bash
# # This bash script calculated enthalpy of formation and cohesive energy from a DFTB+ simulation 
# Specifically, the simulation must have used the GFN2-xTB Hamiltonian rather than the base DFTB

# To run this script, give the name of the .gen file as input on the same line. For example...
# Calculate-Energies-GFN2.sh 1e-4-Out.gen

# Declare an associative array for the atomic/gaseous phase energy for each element (calculated so far)
declare -A ATOMIC_ENERGY
ATOMIC_ENERGY[C]=-48.7487
ATOMIC_ENERGY[H]=-10.7072
ATOMIC_ENERGY[N]=-70.9081
ATOMIC_ENERGY[O]=-102.4724
ATOMIC_ENERGY[S]=-85.5701
ATOMIC_ENERGY[K]=-4.5106

# Declare an associative array for the reference state energy for each element (calculated so far)
declare -A REFERENCE_ENERGY
REFERENCE_ENERGY[C]=-58.670025
REFERENCE_ENERGY[H]=-13.3701
REFERENCE_ENERGY[N]=-78.42235
REFERENCE_ENERGY[O]=-107.5753
REFERENCE_ENERGY[S]=-88.98266641
REFERENCE_ENERGY[K]=-5.24555

calculate_energies () {
# $1 = $GEO
  printf "$1\ntmp-POSCAR" | gen-to-POSCAR.py
  GEO='tmp-POSCAR'
  ATOM_TYPES=($(sed -n 6p $GEO))
  N_TYPES=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${N_TYPES[@]}; do
    let N_ATOMS+=$i
    done

  E_atom=0
  E_ref=0
  count=0
  for element in ${ATOM_TYPES[@]}; do
    E_atom=$(echo $E_atom+${ATOMIC_ENERGY[$element]}*${N_TYPES[$count]} | bc)
    E_ref=$(echo $E_ref+${REFERENCE_ENERGY[$element]}*${N_TYPES[$count]} | bc)
    ((count++))
  done

  DETAILED=($(grep "Total energy" detailed.out))
  TOTAL_ENERGY=${DETAILED[4]}

  COHESIVE=$(echo "scale=3; ($E_atom - $TOTAL_ENERGY) / $N_ATOMS" | bc)
  ENTHALPY=$(echo "scale=3; ($TOTAL_ENERGY - $E_ref) / $N_ATOMS" | bc)

  cat > Energies.dat <<!
E(COH) $COHESIVE eV
H(f) $ENTHALPY eV
!

  rm tmp-POSCAR
}

GEN=$1

calculate_energies $GEN