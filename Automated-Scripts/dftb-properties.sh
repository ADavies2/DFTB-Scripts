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
  cat >> dftb_in.hsd <<!

Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
  OutputPrefix = "$2-Out-$3" }
  
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
  if [ $2 == 'yes' ]; then
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
  if [ $2 == 'yes' ]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi
}

scc_mono () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
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
        if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
          
          if [ $4 == '1e-5' ]; then
            if [ ! -d "1e-4-Outputs" ]; then
              mkdir '1e-4-Outputs'
            fi
            cp detailed.out $3.log '1e-4-Out.gen' '1e-4-Out.xyz' charges* submit_$3 '1e-4-Outputs/'
            rm *out *log *xyz *gen *bin submit* *dat
            RESULT='success1'
            break
          elif [[ $4 == '1e-1' || $4 = '1e-2' || $4 = '1e-3' ]]; then
            if [ ! -d "$4-Outputs" ]; then
              mkdir $4-Outputs
            fi
            cp detailed.out $3.log $4-Out.gen $4-Out.xyz charges.bin submit_$3 $4-Outputs/
            rm *out *xyz submit*
            sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
            sed -i "s/.*<<<.*/  <<< ""$4-Out.gen""/g" dftb_in.hsd
            sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd
            if [ $4 == '1e-1' ]; then
              TOL='1e-2'
              sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
              sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
            elif [ $4 == '1e-2' ]; then
              TOL='1e-3'
              sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
              sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
            elif [ $4 == '1e-3' ]; then
              TOL='1e-5'
              sed -i 's/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g' dftb_in.hsd
              sed -i 's/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out" }/g' dftb_in.hsd
              sed -i '/.*Analysis.*/d' dftb_in.hsd
              printf "%s\n" "Analysis = {" >> dftb_in.hsd
              printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
              printf "%s\n" "  AtomResolvedEnergies = Yes" >> dftb_in.hsd
              printf "%s\n" "  CalculateForces = Yes }" >> dftb_in.hsd
              printf "%s\n" "Options {" >> dftb_in.hsd
              printf "%s\n" "  WriteChargesAsText = Yes }" >> dftb_in.hsd
            fi
            sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
            echo "$3 has completed."
            JOBNAME="$2-scc-$TOL"
            RESULT='success2'
            break
          fi
        elif grep -q "SCC is NOT converged" $3.log; then
          sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd
          sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$4-Forces-Out"/g" dftb_in.hsd
          echo "$3 did NOT converge. Attempting forces only..."
          JOBNAME="$2-forces-$4"
          RESULT='fail1'
          break
        else
          echo "$3 is still running..."
          sleep 10s
        fi
      fi
  done
}

echo "What is the COF name?"
read COF
echo "What is your input geometry file called?"
read GEO
echo "Is your input geometry stacked or a monolayer? Answer stack/mono"
read CALC

if [ $CALC == 'stacked' ]; then
  JOBNAME="$COF-$CALC"
fi

if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
  N_ATOMS=${N_ATOMS[0]}
  if [ $CALC == 'stacked' ]; then
  zorigin=($(sed -n '$p' $GEO))
    declare -a znew
    znew[0]="${zorigin[0]}"
    znew[1]="${zorigin[1]}"
    znew[2]=30
    oldZ="    ${zorigin[0]}    ${zorigin[1]}    ${zorigin[2]}"
    newZ="    ${znew[0]}   ${znew[1]}    ${znew[2]}"
    sed -i '$ d' $GEO
    cat >> $GEO <<!
$newZ
!
  fi
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${POSCAR_ATOMS[@]}; do
    let N_ATOMS+=$i
  done
  if [ $CALC == 'stacked' ]; then
    zorigin=($(sed -n 5p $GEO))
    declare -a znew
    znew[0]="${zorigin[0]}"
    znew[1]="${zorigin[1]}"
    znew[2]=30
    oldZ="${zorigin[0]} ${zorigin[1]} ${zorigin[2]}"
    newZ="${znew[0]} ${znew[1]} ${znew[2]}"
    sed -i "s/$oldZ/$newZ/g" $GEO
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

scc_dftb_in $GEO $COF $CALC myHUBBARD myMOMENTUM

# Run an SCC calculation of the monolayer, 1e-5 with ReadInitialCharges

# For $CALC = stacked, create three geometry files (4, 3.5, 3.3)
# Run a static SCC calculation
# Check detailed.out TotalEnergy and take the geometry with the lowest energy
# Run an SCC calculation of this stacked geometry, 1e-5 with ReadInitialCharges
