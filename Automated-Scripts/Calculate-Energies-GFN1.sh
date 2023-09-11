#!/bin/bash

# Declare an associative array for the atomic/gaseous phase energy for each element (calculated so far)
declare -A ATOMIC_ENERGY
ATOMIC_ENERGY[C]=-47.28
ATOMIC_ENERGY[H]=-10.9235
ATOMIC_ENERGY[N]=-78.784
ATOMIC_ENERGY[O]=-118.343
ATOMIC_ENERGY[S]=-96.1186
ATOMIC_ENERGY[K]=-5.8157

# Declare an associative array for the reference state energy for each element (calculated so far)
declare -A REFERENCE_ENERGY
REFERENCE_ENERGY[C]=-57.88005
REFERENCE_ENERGY[H]=-14.10515
REFERENCE_ENERGY[N]=-86.1717
REFERENCE_ENERGY[O]=-124.05285
REFERENCE_ENERGY[S]=-100.8698641
REFERENCE_ENERGY[K]=-11.33145

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