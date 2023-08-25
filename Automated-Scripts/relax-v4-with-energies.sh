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

# Declare an associative array for the atomic/gaseous phase energy for each element (calculated so far)
declare -A ATOMIC_ENERGY
ATOMIC_ENERGY[C]=-38.055
ATOMIC_ENERGY[H]=-6.4926
ATOMIC_ENERGY[N]=-57.2033
ATOMIC_ENERGY[O]=-83.9795
ATOMIC_ENERGY[S]=-62.3719
ATOMIC_ENERGY[Br]=-79.5349
ATOMIC_ENERGY[F]=-115.2462
ATOMIC_ENERGY[Cl]=-84.1056
ATOMIC_ENERGY[K]=-2.3186

# Declare an associative array for the reference state energy for each element (calculated so far)
declare -A REFERENCE_ENERGY
REFERENCE_ENERGY[C]=-44.1197
REFERENCE_ENERGY[H]=-9.1083
REFERENCE_ENERGY[N]=-65.4249
REFERENCE_ENERGY[O]=-87.7172
REFERENCE_ENERGY[S]=-65.7086
REFERENCE_ENERGY[Br]=-81.167
REFERENCE_ENERGY[F]=-117.3936
REFERENCE_ENERGY[Cl]=-86.2041
REFERENCE_ENERGY[K]=-3.4933

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
  ParserVersion = 12 }
!
  if [ $2 == '1e-5' ]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi 
}

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

scc1 () {
# $1 = $PARTITION
# $2 = $JOBNAME
# $3 = $STALL
# $4 = $TASK
# $5 = $CPUS
# $6 = $TOL
# $7 = $COF
  if [[ $1 == 'teton' ]]; then
    if [[ $3 != 'none' ]]; then
      if (($4 == 16)) && (($5 == 1)); then
        TASK=8
        submit_dftb_teton $TASK $5 $2
      elif (($4 == 8)) && (($5 == 1)); then
        TASK=4
        submit_dftb_teton $TASK $5 $2
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_teton $TASK $CPUS $2
    fi
  elif [[ $1 == 'inv-desousa' ]]; then
    if [[ $3 != 'none' ]]; then
      if (($4 == 16)) && (($5 == 1)); then
        TASK=8
        submit_dftb_desousa $TASK $5 $2
      elif (($4 == 8)) && (($5 == 1)); then
        TASK=4
        submit_dftb_desousa $TASK $5 $2 
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_desousa $TASK $CPUS $2
    fi
  fi
  while :
  do
    stat=($(squeue -n $2))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
      if [ "$jobstat" == "PD" ]; then
        echo "$2 is pending..."
        sleep 5s
      else
        log_size=($(ls -l "$2.log"))
        size=(${log_size[4]})
        sleep 60s
        log_size2=($(ls -l "$2.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$2 is running..."
        elif [[ $size2 == $size ]]; then
          sleep 15s
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $2.log; then
            if [[ $6 == '1e-5' ]]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              cp detailed* $2.log '1e-4-Out.gen' '1e-4-Out.xyz' charges.bin eigenvec.bin submit_$2 '1e-4-Outputs/'
              cp charges.dat "1e-4-Outputs/$7-charges.dat"
              rm $2.out *log *xyz *gen *bin submit_$2 *dat *xml detailed.out band.out
              RESULT='success1'
              STALL='none'
              break
            elif [[ $6 == '1e-1' || $6 = '1e-2' || $6 = '1e-3' ]]; then
              if [ ! -d "$6-Outputs" ]; then
                mkdir $6-Outputs
              fi
              cp detailed.out $2.log $6-Out.gen $6-Out.xyz charges.bin submit_$2 $6-Outputs/
              rm $2.out *xyz submit_$2
              sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
              sed -i "s/.*<<<.*/  <<< ""$6-Out.gen""/g" dftb_in.hsd
              sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd           
              if [ $6 == '1e-1' ]; then
                TOL='1e-2'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $6 == '1e-2' ]; then
                TOL='1e-3'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $6 == '1e-3' ]; then
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
              echo "$2 has completed."
              JOBNAME="$7-scc-$TOL"
              RESULT='success2'
              STALL='none'
              break
            fi
          elif grep -q "SCC is NOT converged" $2.log; then
            echo "$2 did NOT converge. User trouble-shoot required to check atoms."
            exit
          elif grep -q "ERROR!" $2.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$2.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$JOBID has stalled. Restarting..."
              qdel $JOBID
              STALL='scc1'
              RESULT='none'
              if [[ $6 == '1e-5' ]]; then
                sed -i "s/.*<<<.*/   <<< '1e-4-Out.gen'/g" dftb_in.hsd
              else
                sed -i "s/.*<<<.*/   <<< '$6-Out.gen'/g" dftb_in.hsd
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
# $2 = $JOBNAME
# $3 = $STALL
# $4 = $TASK
# $5 = $CPUS
# $6 = $TOL
# $7 = $COF
# $8 = $RESULT
  if [[ $1 == 'teton' ]]; then
    if [[ $3 != 'none' ]]; then
      if (($4 == 16)) && (($5 == 1)); then
        TASK=8
        submit_dftb_teton $TASK $5 $2
      elif (($4 == 8)) && (($5 == 1)); then
        TASK=4
        submit_dftb_teton $TASK $5 $2 
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_teton $TASK $CPUS $2
    fi
  elif [[ $1 == 'inv-desousa' ]]; then
    if [[ $3 != 'none' ]]; then
      if (($4 == 16)) && (($5 == 1)); then
        TASK=8
        submit_dftb_desousa $TASK $5 $2
      elif (($4 == 8)) && (($5 == 1)); then
        TASK=4
        submit_dftb_desousa $TASK $5 $2 
      fi
    else
      TASK=16
      CPUS=1
      submit_dftb_desousa $TASK $CPUS $2
    fi
  fi
  while :
  do 
    stat=($(squeue -n $2))
    jobstat=(${stat[12]})
    JOBID=(${stat[8]})
      if [ "$jobstat" == "PD" ]; then
        echo "$2 is pending..."
        sleep 3s
      else
        log_size=($(ls -l "$2.log"))
        size=(${log_size[4]})
        sleep 30s
        log_size2=($(ls -l "$2.log"))
        size2=(${log_size2[4]})
        if [[ $size2 > $size ]]; then
          echo "$2 is running..."
        elif [[ $size2 == $size ]]; then 
          sleep 15s      
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $2.log; then
            if [[ $6 == '1e-5' ]]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              cp detailed* $2.log '1e-4-Out.gen' '1e-4-Out.xyz' eigenvec.bin charges.bin submit_$2 '1e-4-Outputs/'
              cp charges.dat "1e-4-Outputs/$COF-charges.dat"
              rm $2.out *log *xyz *gen *bin submit_$2 *dat *xml detailed.out band.out
              RESULT='success1'
              STALL='none'
              break
            elif [[ $6 = '1e-2' || $6 = '1e-3' ]]; then
              if [ ! -d "$6-Outputs" ]; then
                mkdir $6-Outputs
              fi
              cp detailed.out $2.log $6-Out.gen $6-Out.xyz charges.bin submit_$2 $6-Outputs/
              rm $2.out *xyz submit_$2
              sed -i 's/.*Geometry.*/Geometry = GenFormat {/g' dftb_in.hsd
              sed -i "s/.*<<<.*/  <<< ""$6-Out.gen""/g" dftb_in.hsd
              sed -i 's/.*ReadInitialCharges.*/ReadInitialCharges = Yes/g' dftb_in.hsd
              if [ $6 == '1e-2' ]; then
                TOL='1e-3'
                sed -i "s/.*MaxForceComponent.*/  MaxForceComponent = $TOL/g" dftb_in.hsd
                sed -i "s/.*OutputPrefix.*/  OutputPrefix = "$TOL-Out" }/g" dftb_in.hsd
              elif [ $6 == '1e-3' ]; then
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
              echo "$2 has completed."
              JOBNAME="$7-scc-$TOL"
              RESULT='success2'
              STALL='none'
              break
            fi
          elif grep -q "SCC is NOT converged" $2.log; then
            echo "$2 did NOT converge. User trouble-shoot required to check atoms."
            exit
          elif grep -q "ERROR!" $2.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$2.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$JOBID has stalled. Restarting..."
              qdel $JOBID
              STALL='scc2'
              RESULT='none'
              if [[ $6 == '1e-5' ]]; then
                sed -i "s/.*<<<.*/   <<< '1e-4-Out.gen'/g" dftb_in.hsd
              else
                sed -i "s/.*<<<.*/   <<< '$6-Out.gen'/g" dftb_in.hsd
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

# Read input geometry file to get atom types and number of atoms  
if [[ $GEO == *"gen"* ]]; then
  ATOM_TYPES=($(sed -n 2p $GEO))
  N_ATOMS=($(sed -n 1p $GEO))
else
  ATOM_TYPES=($(sed -n 6p $GEO))
  POSCAR_ATOMS=($(sed -n 7p $GEO))
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
scc1 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF
if [[ $STALL == 'scc1' ]]; then
  scc1 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  fi
fi

#LOOP 2 (LIGHTGREEN) RESULTS, SUBMITTING LOOP 3 (LIGHTYELLOW) CALCULATIONS 
if [ $STALL == 'scc1' ]; then
  scc1 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF
elif [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# Repeat these if statements until all loops on the flowchart are accounted for

# LOOP 3 (LIGHTYELLOW) RESULTS, SUBMITTING LOOP 4 (LIGHTRED)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 4 (LIGHTRED) RESULTS, SUBMITTING LOOP 5 (LIGHTPURPLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 5 (LIGHTPURPLE) RESULTS, SUBMITTING LOOP 6 (KELLYGREEN)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 6 (KELLYGREEN) RESULTS, SUBMITTING LOOP 7 (SKYBLUE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 7 (SKYBLUE) RESULTS, SUBMITTING LOOP 8 (BRIGHTPURPLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 8 (BRIGHTPURPLE) RESULTS, SUBMITTING LOOP 9 (FUSCHIA)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 9 (FUSCHIA) RESULTS, SUBMITTING LOOP 10 (ORANGE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 10 (ORANGE) RESULTS, SUBMITTING LOOP 11 (MUSTARD YELLOW)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 11 (MUSTARD YELLOW) RESULTS, SUBMITTING LOOP 12 (EGGPLANT)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 12 (EGGPLANT) RESULTS, SUBMITTING LOOP 13 (PERIWINKLE)
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi

# LOOP 13 (PERIWINKLE) RESULTS
if [ $STALL == 'scc2' ]; then
  scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
else
  if [ $RESULT == 'success1' ]; then
    cd 1e-4-Outputs
    calculate_energies '1e-4-Out.gen'
    cd ..
    echo "$COF is fully relaxed!"
    exit
  elif [ $RESULT == 'success2' ]; then
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'success3' ]; then
    scc_dftb_in $GEO $TOL $RESTART myHUBBARD myMOMENTUM
    scc2 $PARTITION $JOBNAME $STALL $TASK $CPUS $TOL $COF $RESULT
  elif [ $RESULT == 'fail2' ]; then
    echo "User trouble-shoot required."
    exit
  elif [ $RESULT == 'fail3' ]; then
    echo "User trouble-shoot required."
    exit
  fi
fi
