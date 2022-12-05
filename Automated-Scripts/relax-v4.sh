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

scc_dftb_in () {
# 1 = $GEO
# 2 = $TOL
# 3 = $RESTART
# 4 = myHUBBARD
# 5 = myMOMENTUM
  if [[ $1 == *"gen"* ]]; then
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< "$1"
}
!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< "$1"
}
!
  fi
  cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
!
  if [ $2 == '1e-5' ]; then
    printf "  MaxForceComponent = 1e-4\n" >> dftb_in.hsd
    printf "  OutputPrefix = 1e-4-Out }\n" >> dftb_in.hsd
  else
    printf "  MaxForceComponent = $2\n" >> dftb_in.hsd
    printf "  OutputPrefix = $2-Out }\n" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!
Hamiltonian = DFTB {
SCC = Yes
SCCTolerance = $2
!
  if [[ $3 == "yes" ]]; then
    printf "ReadInitialCharges = Yes\n" >> dftb_in.hsd
  else
    printf "ReadInitialCharges = No\n" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd <<!
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
  if [ $2 == '1e-5' ]; then
    printf "%s\n" "Analysis = {" >> dftb_in.hsd
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  WriteEigenvectors = Yes" >> dftb_in.hsd
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
  if [ $2 == '1e-5' ]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi 
}

scc1 () {
# $1 = $PARTITION
# $2 = $NO_ATOMS
# $3 = $JOBNAME
# $4 = $STALL
# $5 = $TASK
# $6 = $CPUS
# $7 = $TOL
# $8 = $COF
  if [[ $1 == 'teton' ]]; then
    if (($2 <= 80)); then
      TASK=4
      CPUS=1
      submit_dftb_teton $TASK $CPUS $3
    elif (($2 > 80)); then
      if [[ $4 != 'none' ]]; then
        if (($5 == 16)) && (($6 == 1)); then
          CPUS=2
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 16)) && (($6 == 2)); then
          TASK=8
          submit_dftb_teton $TASK $6 $3
        elif (($5 == 8)) && (($6 == 2)); then
          CPUS=1
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 8)) && (($6 == 1)); then
          CPUS=4
          submit_dftb_teton $5 $CPUS $3
        fi
      else
        TASK=16
        CPUS=1
        submit_dftb_teton $TASK $CPUS $3
      fi
    fi
  elif [[ $1 == 'inv-desousa' ]]; then
    if [[ $4 != 'none' ]]; then
      if (($5 == 16)) && (($6 == 1)); then
        TASK=8
        submit_dftb_desousa $TASK $6 $3
      elif (($5 == 8)) && (($6 == 1)); then
        TASK=4
        submit_dftb_desousa $TASK $6 $3 
      elif (($5 == 4)) && (($6 == 1)); then
        CPU=5
        submit_dftb_desousa $5 $CPUS $3
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_desousa $TASK $CPUS $3
    fi
  fi
  while :
  do
    stat=($(squeue -n $3))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 3s
      else
        log_size=($(ls -l "$3.log"))
        size=(${log_size[4]})
        sleep 30s
        log_size2=($(ls -l "$3.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$3 is running..."
        elif [[ $size2 == $size ]]; then
          sleep 15s
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
            if [[ $7 == '1e-5' ]]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              cp detailed* $3.log '1e-4-Out.gen' '1e-4-Out.xyz' charges.bin eigenvec.bin submit_$3 '1e-4-Outputs/'
              cp charges.dat "1e-4-Outputs/$COF-charges.dat"
              rm *out *log *xyz *gen *bin submit* *dat *xml
              RESULT='success1'
              STALL='none'
              break
            elif [[ $7 == '1e-1' || $7 = '1e-2' || $7 = '1e-3' ]]; then
              if [ ! -d "$7-Outputs" ]; then
                mkdir $7-Outputs
              fi
              cp detailed.out $3.log $7-Out.gen $7-Out.xyz charges.bin submit_$3 $7-Outputs/
              rm *out *xyz submit*
              sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
              sed -i "s/.*<<<.*/  <<< ""$7-Out.gen""/g" dftb_in.hsd
              sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd           
              if [ $7 == '1e-1' ]; then
                TOL='1e-2'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $7 == '1e-2' ]; then
                TOL='1e-3'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $7 == '1e-3' ]; then
                TOL='1e-5'
                sed -i 's/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g' dftb_in.hsd
                sed -i 's/.*OutputPrefix.*/  OutputPrefix = "1e-4-Out" }/g' dftb_in.hsd
                sed -i '/.*Analysis.*/d' dftb_in.hsd
                cat >> dftb_in.hsd <<!
Analysis = {
  MullikenAnalysis = Yes
  AtomResolvedEnergies = Yes
  WriteEigenvectors = Yes
  CalculateForces = Yes }
Options {
  WriteChargesAsText = Yes
  WriteDetailedXML = Yes }
!
              fi
              sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd
              echo "$3 has completed."
              JOBNAME="$8-scc-$TOL"
              RESULT='success2'
              STALL='none'
              break
            fi
          elif grep -q "SCC is NOT converged" $3.log; then
            sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd
            sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$7-Forces-Out"/g" dftb_in.hsd
            echo "$3 did NOT converge. Attempting forces only..."
            JOBNAME="$8-forces-$7"
            RESULT='fail1'
            STALL='none'
            break
          elif grep -q "ERROR!" $3.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$3.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$JOBID has stalled. Restarting..."
              qdel $JOBID
              STALL='scc1'
              RESULT='none'
              if [[ $7 == '1e-5' ]]; then
                sed -i "s/.*<<<.*/   <<< '1e-4-Out.gen'/g" dftb_in.hsd
              else
                sed -i "s/.*<<<.*/   <<< '$7-Out.gen'/g" dftb_in.hsd
              fi
              break
            fi 
          fi
        fi
      fi
  done
}

scc2 () {
# $1 = $PARTITION
# $2 = $NO_ATOMS
# $3 = $JOBNAME
# $4 = $STALL
# $5 = $TASK
# $6 = $CPUS
# $7 = $TOL
# $8 = $COF
# $9 = $RESULT
  if [[ $1 == 'teton' ]]; then
    if (($2 <= 80)); then
      TASK=4
      CPUS=1
      submit_dftb_teton $TASK $CPUS $3
    elif (($2 > 80)); then
      if [[ $4 != 'none' ]]; then
        if (($5 == 16)) && (($6 == 1)); then
          CPUS=2
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 16)) && (($6 == 2)); then
          TASK=8
          submit_dftb_teton $TASK $6 $3
        elif (($5 == 8)) && (($6 == 2)); then
          CPUS=1
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 8)) && (($6 == 1)); then
          CPUS=4
          submit_dftb_teton $5 $CPUS $3
        fi
      else
        TASK=16
        CPUS=1
        submit_dftb_teton $TASK $CPUS $3
      fi
    fi
  elif [[ $1 == 'inv-desousa' ]]; then
    if [[ $4 != 'none' ]]; then
      if (($5 == 16)) && (($6 == 1)); then
        TASK=8
        submit_dftb_desousa $TASK $6 $3
      elif (($5 == 8)) && (($6 == 1)); then
        TASK=4
        submit_dftb_desousa $TASK $6 $3 
      elif (($5 == 4)) && (($6 == 1)); then
        CPU=5
        submit_dftb_desousa $5 $CPUS $3
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_desousa $TASK $CPUS $3
    fi
  fi
  while :
  do 
    stat=($(squeue -n $3))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 3s
      else
        log_size=($(ls -l "$3.log"))
        size=(${log_size[4]})
        sleep 30s
        log_size2=($(ls -l "$3.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$3 is running..."
        elif [[ $size2 == $size ]]; then 
          sleep 15s      
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
            if [[ $7 == '1e-5' ]]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              cp detailed* $3.log '1e-4-Out.gen' '1e-4-Out.xyz' eigenvec.bin charges.bin submit_$3 '1e-4-Outputs/'
              cp charges.dat "1e-4-Outputs/$COF-charges.dat"
              rm *out *log *xyz *gen charges* submit* *bin *xml
              RESULT='success1'
              STALL='none'
              break
            elif [[ $7 = '1e-2' || $7 = '1e-3' ]]; then
              if [ ! -d "$7-Outputs" ]; then
                mkdir $7-Outputs
              fi
              cp detailed.out $3.log $7-Out.gen $7-Out.xyz charges.bin submit_$3 $7-Outputs/
              rm *out *xyz submit*
              sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
              sed -i "s/.*<<<.*/  <<< ""$7-Out.gen""/g" dftb_in.hsd
              sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd
              if [ $7 == '1e-2' ]; then
                TOL='1e-3'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $7 == '1e-3' ]; then
                TOL='1e-5'
                sed -i 's/.*MaxForceComponent.*/  MaxForceComponent = 1e-4/g' dftb_in.hsd
                sed -i 's/.*OutputPrefix.*/  OutputPrefix = 1e-4-Out }/g' dftb_in.hsd
                sed -i '/.*Analysis.*/d' dftb_in.hsd
                cat >> dftb_in.hsd <<!
Analysis = {
  MullikenAnalysis = Yes
  AtomResolvedEnergies = Yes
  WriteEigenvectors = Yes
  CalculateForces = Yes }
Options {
  WriteChargesAsText = Yes
  WriteDetailedXML = Yes }
!
              fi
              sed -i "s/.*SCCTolerance.*/SCCTolerance = $TOL/g" dftb_in.hsd           
              echo "$3 has completed."
              JOBNAME="$8-scc-$TOL"
              RESULT='success2'
              STALL='none'
              break
            fi
          elif grep -q "SCC is NOT converged" $3.log; then
            if [ $9 == 'success2' ]; then
              sed -i 's/.*SCC = Yes.*/SCC = No/g' dftb_in.hsd
              sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$7-Forces-Out"/g" dftb_in.hsd
              echo "$3 did NOT converge. Attempting forces only..."
              JOBNAME="$8-forces-$7"
              RESULT='fail1'
              STALL='none'
              break
            elif [ $9 == 'success3' ]; then
              echo "$8 at $7 Forces did NOT converge..."
              echo "$8 at $7 SCC did NOT converge..."
              RESULT='fail3'
              STALL='none'
              break
            fi
          elif grep -q "ERROR!" $3.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$3.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$JOBID has stalled. Restarting..."
              qdel $JOBID
              STALL='scc2'
              RESULT='none'
              if [[ $7 == '1e-5' ]]; then
                sed -i "s/.*<<<.*/   <<< '1e-4-Out.gen'/g" dftb_in.hsd
              else
                sed -i "s/.*<<<.*/   <<< '$7-Out.gen'/g" dftb_in.hsd
              fi
              break
            fi
          fi
        fi
      fi
  done  
}

forces_dftb_in () {
# $1 = $GEO
# $2 = $TOL
# $3 = myMOMENTUM
  if [ $1 == *"gen"* ]; then
    cat > dftb_in.hsd <<!
Geometry = GenFormat {
  <<< "$1"
}
!
  else
    cat > dftb_in.hsd <<!
Geometry = VASPFormat {
  <<< "$1"
}
!
  fi
  cat >> dftb_in.hsd <<!
Driver = ConjugateGradient {
  MovedAtoms = 1:-1
  MaxSteps = 100000
  LatticeOpt = Yes
  AppendGeometries = No
!
  if [ $2 == '1e-5' ]; then
    printf "  MaxForceComponent = 1e-4\n" >> dftb_in.hsd
    printf "  OutputPrefix = 1e-4-Forces-Out }\n" >> dftb_in.hsd
  else
    printf  "  MaxForceComponent = $2\n" >> dftb_in.hsd
    printf " OutputPrefix = $2-Forces-Out }\n" >> dftb_in.hsd
  fi
  momentum=$3[@]
  forcesMOMENTUM=("${!momentum}")
  cat >> dftb_in.hsd <<!
Hamiltonian = DFTB {
SCC = No
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
  printf "%s\n" "${forcesMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }
Analysis = {
  MullikenAnalysis = Yes }
Parallel = {
  Groups = 1
  UseOmpThreads = Yes }
ParserOptions {
  ParserVersion = 10 }
!
}

forces () {
# $1 = $PARTITION
# $2 = $NO_ATOMS
# $3 = $JOBNAME
# $4 = $STALL
# $5 = $TASK
# $6 = $CPUS
# $7 = $TOL
# $8 = $COF
# $9 = $RESULT
  if [[ $1 == 'teton' ]]; then
    if (($2 <= 80)); then
      TASK=4
      CPUS=1
      submit_dftb_teton $TASK $CPUS $3
    elif (($2 > 80)); then
      if [[ $4 != 'none' ]]; then
        if (($5 == 16)) && (($6 == 1)); then
          CPUS=2
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 16)) && (($6 == 2)); then
          TASK=8
          submit_dftb_teton $TASK $6 $3
        elif (($5 == 8)) && (($6 == 2)); then
          CPUS=1
          submit_dftb_teton $5 $CPUS $3
        elif (($5 == 8)) && (($6 == 1)); then
          CPUS=4
          submit_dftb_teton $5 $CPUS $3
        fi
      else
        TASK=16
        CPUS=1
        submit_dftb_teton $TASK $CPUS $3
      fi
    fi
  elif [[ $1 == 'inv-desousa' ]]; then
    if [[ $4 != 'none' ]]; then
      if (($5 == 16)) && (($6 == 1)); then
        TASK=8
        submit_dftb_desousa $TASK $6 $3
      elif (($5 == 8)) && (($6 == 1)); then
        TASK=4
        submit_dftb_desousa $TASK $6 $3 
      elif (($5 == 4)) && (($6 == 1)); then
        CPU=5
        submit_dftb_desousa $5 $CPUS $3
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_desousa $TASK $CPUS $3
    fi
  fi
  while :
  do
    stat=($(squeue -n $3))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
      if [ "$jobstat" == "PD" ]; then
        echo "$3 is pending..."
        sleep 3s 
      else
        log_size=($(ls -l "$3.log"))
        size=(${log_size[4]})
        sleep 30s
        log_size2=($(ls -l "$3.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$3 is running..."
        elif [[ $size2 == $size ]]; then
          sleep 30s
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
            echo "$3 converged. Attemping SCC again at $7..."
            JOBNAME="$8-scc-$7"
            RESTART='no'
            RESULT='success3'
            STALL='none'
            break
          elif grep -q "Geometry did NOT converge" detailed.out && grep -q "Geometry did NOT converge" $3.log; then
            echo "$8 at $7 SCC did NOT converge..."
            echo "$8 at $7 Forces did NOT converge..."
            RESULT='fail2'
            STALL='none'
            break
          elif grep -q "ERROR!" $3.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$3.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$3 has stalled. Restarting..."
              qdel $JOBID 
              STALL='forces'
              RESULT='none'
              if [[ $7 == '1e-5' ]]; then
                sed -i "s/.*<<<.*/   <<< '1e-4-Out.gen'/g" dftb_in.hsd
              else
                sed -i "s/.*<<<.*/   <<< '$7-Out.gen'/g" dftb_in.hsd
              fi
              break
            fi
          fi
        fi
      fi
  done      
}

# The instruction file is passed as an arguement when the job is submitted
INSTRUCT=$1

# Read the input file for the COF name, starting tolerance, restart calculation, input structure file, and partition
COF=($(sed -n 2p $INSTRUCT))
TOL=($(sed -n 4p $INSTRUCT))
GEO=($(sed -n 6p $INSTRUCT))
RESTART=($(sed -n 8p $INSTRUCT))
PARTITION=($(sed -n 10p $INSTRUCT))

STALL='none'
TASK=16
CPUS=1
JOBNAME="$COF-scc-$TOL"

if [ ! -d "Relax" ]; then
  mkdir Relax
  cp $GEO Relax
  rm $GEO
  if [[ $RESTART == 'yes' ]]; then
    cp charges.bin Relax
    rm charges.bin 
  fi
fi

cd Relax # Change to the working directory for the following calculations

# Read input geometry file to get atom types and number of atoms  
if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
  N_ATOMS=${N_ATOMS[0]}
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
  N_ATOMS=0
  for i in ${POSCAR_ATOMS[@]}; do
    let N_ATOMS+=$i
  done
!
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
nl=$'\n'
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Write dftb_in.hsd for the first calculation
scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM

# LOOP 1 (LIGHTBLUE) RESULTS, SUBMITTING LOOP 2 (LIGHTGREEN) CALCULATIONS
# submit the first calculation
scc1 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF
if [[ $STALL == 'scc1' ]]; then
  scc1 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

#LOOP 2 (LIGHTGREEN) RESULTS, SUBMITTING LOOP 3 (LIGHTYELLOW) CALCULATIONS 
if [ $STALL == 'scc1' ]; then
  scc1 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF
elif [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# Repeat these if statements until all loops on the flowchart are accounted for

# LOOP 3 (LIGHTYELLOW) RESULTS, SUBMITTING LOOP 4 (LIGHTRED)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 4 (LIGHTRED) RESULTS, SUBMITTING LOOP 5 (LIGHTPURPLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 5 (LIGHTPURPLE) RESULTS, SUBMITTING LOOP 6 (KELLYGREEN)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 6 (KELLYGREEN) RESULTS, SUBMITTING LOOP 7 (SKYBLUE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 7 (SKYBLUE) RESULTS, SUBMITTING LOOP 8 (BRIGHTPURPLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 8 (BRIGHTPURPLE) RESULTS, SUBMITTING LOOP 9 (FUSCHIA)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 9 (FUSCHIA) RESULTS, SUBMITTING LOOP 10 (ORANGE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 10 (ORANGE) RESULTS, SUBMITTING LOOP 11 (MUSTARD YELLOW)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 11 (MUSTARD YELLOW) RESULTS, SUBMITTING LOOP 12 (EGGPLANT)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 12 (EGGPLANT) RESULTS, SUBMITTING LOOP 13 (PERIWINKLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

# LOOP 13 (PERIWINKLE) RESULTS
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
elif [ $STALL == 'forces' ]; then
  forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail1' ]; then
    forces_dftb_in $GEO $TOL myMOMENTUM
    forces $PARTITION $N_ATOMS $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi
