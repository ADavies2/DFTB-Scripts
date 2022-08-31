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

ncores () {
  if (($1 <= 40)); then
    CORES=2
  elif (($1 >= 40 && $1 <= 50)); then
    CORES=4
  elif (($1 >= 50 && $1 <= 100)); then
    CORES=8
  elif (($1 >= 100)); then
    CORES=16
  fi
}

scc_dftb_in () {
# $1 = $GEO
# $2 = $COF
# $3 = $JOBNAME
# $4 = myHUBBARD
# $5 = myMOMENTUM
  if [[ $1 == *"gen"* ]]; then 
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< $1
}
!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< $1
}
!
  fi
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    cat >> dftb_in.hsd <<!

Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
  OutputPrefix = "$3-Out" }
!
  else
    cat >> dftb_in.hsd <<!

Driver = { }
!
  fi
  cat >> dftb_in.hsd <<!

Hamiltonian = DFTB {
SCC = Yes
ReadInitialCharges = Yes
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
  
!
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "Analysis = {" >> dftb_in.hsd
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  AtomResolvedEnergies = Yes" >> dftb_in.hsd
    printf "%s\n" "  CalculateForces = Yes }" >> dftb_in.hsd
  else
    printf "%s\n" "Analysis = {" >> dftb_in.hsd
    printf "%s\n" "  MullikenAnalysis = Yes }" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!
  
Parallel = {
  Groups = 1
  UseOmpThreads = Yes }

ParserOptions {
  ParserVersion = 10 }
  
!
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi
}

scc1 () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
# $4 = $GEO
  submit_dftb_automate $1 1 $3
  while :
  do
    stat="$(squeue -n $3)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 10s
      else
        if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
            echo "$2 Monolayer is fully relaxed!"
            exit
          elif grep -q "SCC is NOT converged" $3.log; then
            printf "$2 Monolayer did NOT converge.\n User trouble-shoot required." 
            exit
          else
            echo "$3 is still running..."
            sleep 10s
          fi
        else
          if grep -q "SCC converged" detailed.out; then
            cp detailed.out $3-detailed.out
            if [[ $3 == *"Stack1"* ]]; then
              if [[ $4 == *"gen"* ]]; then
                GEO=Input2.gen
              else
                GEO=Input2-POSCAR
              fi
              JOBNAME="$2-Stack2"
              echo "$3 is complete. Starting $JOBNAME..."
              break
            elif [[ $3 == *"Stack2"* ]]; then
              if [[ $4 == *"gen"* ]]; then
                GEO=Input3.gen
              else
                GEO=Input3-POSCAR
              fi
              JOBNAME="$2-Stack3"
              echo "$3 is complete. Starting $JOBNAME..."
              break
            else 
              echo "Static stacked calculations for $2 are complete! Beginning energy analysis..."
              break
            fi
          elif grep -q "SCC is NOT converged" $3.log; then
            echo "$3 did NOT converge."
            cp detailed.out $3-detailed.out
            if [[ $3 == *"Stack1"* ]]; then
              if [[ $4 == *"gen"* ]]; then
                GEO=Input2.gen
              else
                GEO=Input2-POSCAR
              fi
              JOBNAME="$2-Stack2"
              echo "Starting $JOBNAME..."
              break
            elif [[ $3 == *"Stack2"* ]]; then
              if [[ $4 == *"gen"* ]]; then
                GEO=Input3.gen
              else
                GEO=Input3-POSCAR
              fi
              JOBNAME="$2-Stack3"
              echo "Starting $JOBNAME..."
              break
            else
              echo "Static stacked calculations for $2 are complete! Beginning energy analysis..."
              break
            fi
          else
            echo "$3 is still running..."
            sleep 10s
          fi
        fi
      fi
  done
}

echo "What is the COF name?"
read COF
echo "What is your input geometry file called?"
read GEO
echo "Is your input geometry stacked or a monolayer? Answer stacked/mono"
read STARTING

(
  trap '' 1
stackedHEIGHTS=(3.3 3.5 4)

if [ $STARTING == 'stacked' ]; then
  JOBNAME="$COF-Mono"
else
  JOBNAME="$COF-Stack1"
fi

if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
  N_ATOMS=${N_ATOMS[0]}
  if [ $STARTING == 'stacked' ]; then
    zorigin=($(sed -n '$p' $GEO))
    declare -a znew
    znew=("${zorigin[0]}" "${zorigin[1]}" "30")
    oldZ="    ${zorigin[0]}    ${zorigin[1]}    ${zorigin[2]}"
    newZ="    ${znew[0]}   ${znew[1]}    ${znew[2]}"
    sed -i '$ d' $GEO
    cat >> $GEO <<!
$newZ
!
  else
    cp $GEO Input1.gen
    cp $GEO Input2.gen
    cp $GEO Input3.gen
    zorigin=($(sed -n '$p' $GEO))
    znew1=("${zorigin[0]}" "${zorigin[1]}" "3.3")
    znew2=("${zorigin[0]}" "${zorigin[1]}" "3.5")
    znew3=("${zorigin[0]}" "${zorigin[1]}" "4")
    oldZ="    ${zorigin[0]}    ${zorigin[1]}    ${zorigin[2]}"
    newZ1="    ${znew1[0]}   ${znew1[1]}    ${znew1[2]}"
    newZ2="    ${znew2[0]}   ${znew2[1]}    ${znew2[2]}"
    newZ3="    ${znew3[0]}   ${znew3[1]}    ${znew3[2]}"
    sed -i '$ d' Input1.gen
    sed -i '$ d' Input2.gen
    sed -i '$ d' Input3.gen
    cat >> Input1.gen <<!
$newZ1
!
    cat >> Input2.gen <<!
$newZ2
!
    cat >> Input3.gen <<!
$newZ3
!
  fi
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${POSCAR_ATOMS[@]}; do
    let N_ATOMS+=$i
  done
  if [ $STARTING == 'stacked' ]; then
    zorigin=($(sed -n 5p $GEO))
    declare -a znew
    znew=("${zorigin[0]}" "${zorigin[1]}" "30")
    oldZ="${zorigin[0]} ${zorigin[1]} ${zorigin[2]}"
    newZ="${znew[0]} ${znew[1]} ${znew[2]}"
    sed -i "s/$oldZ/$newZ/g" $GEO
  else
    cp $GEO Input1-POSCAR
    cp $GEO Input2-POSCAR
    cp $GEO Input3-POSCAR
    zorigin=($(sed -n 5p $GEO))
    znew1=("${zorigin[0]}" "${zorigin[1]}" "3.3")
    znew2=("${zorigin[0]}" "${zorigin[1]}" "3.5")
    znew3=("${zorigin[0]}" "${zorigin[1]}" "4")
    oldZ="${zorigin[0]} ${zorigin[1]} ${zorigin[2]}"
    newZ1="${znew1[0]} ${znew1[1]} ${znew1[2]}"
    newZ2="${znew2[0]} ${znew2[1]} ${znew2[2]}"
    newZ3="${znew3[0]} ${znew3[1]} ${znew3[2]}"
    sed -i "s/$oldZ/$newZ1/g" Input1-POSCAR
    sed -i "s/$oldZ/$newZ2/g" Input2-POSCAR
    sed -i "s/$oldZ/$newZ3/g" Input3-POSCAR
  fi
fi

declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

ncores $N_ATOMS

# Write dftb_in.hsd for monolayer calculation or for the first stacked static calculation
if [ $STARTING == 'stacked' ]; then
  scc_dftb_in $GEO $COF $JOBNAME myHUBBARD myMOMENTUM
else
  GEO="Input1.gen"
  scc_dftb_in $GEO $COF $JOBNAME myHUBBARD myMOMENTUM
fi

# Run either an SCC of a monolayer, or a static SCC of the first stacked geometry
scc1 $CORES $COF $JOBNAME $GEO

# Run the next static SCC of the stacked geometries
scc_dftb_in $GEO $COF $JOBNAME myHUBBARD myMOMENTUM
scc1 $CORES $COF $JOBNAME $GEO

# Run the last static SCC of the stacked geometries
scc_dftb_in $GEO $COF $JOBNAME myHUBBARD myMOMENTUM
scc1 $CORES $COF $JOBNAME $GEO

# Check the total energies of each system, compare to find the minimum, and store that value along with the geometry that produced it
stackedGEOS=("$COF-Stack1" "$COF-Stack2" "$COF-Stack3")
min=0
declare -A ENERGY
for geo in "${stackedGEOS[@]}"; do
  energy=($(grep "Total energy" $geo-detailed.out))
  ENERGY[$geo]="${energy[4]}"
  lessthan=($(echo "${ENERGY[$geo]}<$min" | bc))
  if (( $lessthan == 1 )); then
    min=${ENERGY[$geo]}
    geoOPT=$geo
  fi
done

# Set $GEO to match the lowest-energy static geometry
if [[ $GEO == *"gen"* ]]; then
  if [[ $geoOPT == *"1"* ]]; then
    GEO="Input1.gen"
  elif [[ $geoOPT == *"2"* ]]; then
    GEO="Input2.gen"
  else
    GEO="Input3.gen"
  fi
else
  if [[ $geoOPT == *"1"* ]]; then
    GEO="Input1-POSCAR"
  elif [[ $geoOPT == *"2"* ]]; then
    GEO="Input2-POSCAR"
  else
    GEO="Input3-POSCAR"
  fi
fi

# Run a dynamic SCC calculation with new $GEO
JOBNAME="$COF-Final-Opt"
scc_dftb_in $GEO $COF $JOBNAME myHUBBARD myMOMENTUM
scc1 $CORES $COF $JOBNAME $GEO
) </dev/null >log.$COF-Stacking 2>&1 &
