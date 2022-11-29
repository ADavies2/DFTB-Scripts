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
      if [[ $4 != 'none' ]]: then
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
        echo "$3 is running..."
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
            if [ $4 == '1e-5' ]; then
              if [ ! -d "1e-4-Outputs" ]; then
                mkdir '1e-4-Outputs'
              fi
              cp detailed* $3.log '1e-4-Out.gen' '1e-4-Out.xyz' charges.bin eigenvec.bin submit_$3 '1e-4-Outputs/'
              cp charges.dat "1e-4-Outputs/$COF-charges.dat"
              rm *out *log *xyz *gen *bin submit* *dat *xml
              RESULT='success1'
              STALL='none'
              break
            elif [[ $7 == '1e-1' || $4 = '1e-2' || $4 = '1e-3' ]]; then
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
      if [[ $4 != 'none' ]]: then
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
        echo "$3 is running..."
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
            if [ $7 == '1e-5' ]; then
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
              if [ ! -d "$4-Outputs" ]; then
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
              break
            fi
          fi
        fi
      fi
  done  
}

