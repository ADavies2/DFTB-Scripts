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
# $1 = $NO_ATOMS
# $2 = $STALL
# $3 = $CORES
  if [[ $2 != 'none' ]]; then
    if (($3 == 16)); then
      CORES=8
      CORE_TYPE='TASKS'
    elif (($3 == 8)); then
      if (($1 < 80)); then
        CORES=4
      elif (($1 >= 80)); then
        CORES=8
      fi
      CORE_TYPE='CPUS'
    fi
  else
    CORES=16
    CORE_TYPE='TASKS'
  fi
}

dftb_in () {
# $1 = $GEO
# $2 = $PROPERTY
# $3 = $JOBNAME
# $4 = myHUBBARD
# $5 = myMOMENTUM
# $6 = ATOM_TYPES
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
  printf "%s\n" "Driver = { }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!

Hamiltonian = DFTB {
SCC = Yes
ReadInitialCharges = Yes
ThirdOrderFull = Yes
Dispersion = LennardJones {
  Parameters = UFFParameters{} }
HCorrection = Damping {
  Exponent = 4.05 }
!
  if [[ $2 == "bands" ]]; then
    printf "%s\n" "MaxSCCIterations = 1" >> dftb_in.hsd
  else
    printf "%s\n" "MaxSCCIterations = 2000" >> dftb_in.hsd
  fi
  printf "%s\n" "HubbardDerivs {" >> dftb_in.hsd
  hubbard=$4[@]
  sccHUBBARD=("${!hubbard}")
  printf "%s\n" "${sccHUBBARD[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
SlaterKosterFiles = Type2FileNames {
  Prefix = "/project/designlab/Shared/Codes/dftb+sk/3ob-3-1/"
  Separator = "-"
  Suffix = ".skf" }
!
  if [[ $2 == "bands" ]]; then
    cat >> dftb_in.hsd <<!
KPointsAndWeights [relative] = Klines { # Path for hexagonal COFs
  1   0.0   0.0   0.0 # Gamma
  20  0.33  0.33  0.0 # K
  20  0.5   0.5   0.0 # M
  20  0.0   0.0   0.0 # Gamma
}
MaxAngularMomentum {
!
  else
    cat >> dftb_in.hsd <<!
KPointsAndWeights = SupercellFolding {
  4 0 0
  0 4 0
  0 0 4
  0.5 0.5 0.5 }
MaxAngularMomentum {
!
  fi
  momentum=$5[@]
  sccMOMENTUM=("${!momentum}")
  printf "%s\n" "${sccMOMENTUM[@]} }" >> dftb_in.hsd
  cat >> dftb_in.hsd <<!
Filling = Fermi {
  Temperature [Kelvin] = 0 } }

Analysis = {
!
  if [[ $2 == "bands" ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes }" >> dftb_in.hsd
  elif [[ $2 == "DOS" ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  ProjectStates {" >> dftb_in.hsd
    atoms=$6[@]
    TYPES=("${!atoms}")
    for element in ${TYPES[@]}; do
      printf "%s\n" "    Region {" >> dftb_in.hsd
      printf "%s\n" "      Atoms = $element" >> dftb_in.hsd
      printf "%s\n" "      ShellResolved = Yes" >> dftb_in.hsd
      printf "%s\n" "      Label = "dos_$element"" >> dftb_in.hsd
      printf "%s\n" "    }" >> dftb_in.hsd
    done
    printf "%s\n" "  }" >> dftb_in.hsd
    printf "%s\n" "}" >> dftb_in.hsd
  fi
  cat >> dftb_in.hsd<<!
  
Parallel {
  Groups = 1
  UseOmpThreads = Yes }
  
ParserOptions {
  ParserVersion = 10 } 
  
!
}

scc () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
# $4 = $TOL
# $5 = $PROPERTY
# $6 = $CORE_TYPE
  if [[ $6 == 'CPUS' ]]; then
    submit_dftb_cpus 1 $1 $3
  else
    submit_dftb_tasks $1 1 $3
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
        if [[ $5 == "bands" ]]; then
          if grep -q "SCC is NOT converged" $3.log; then
            echo "Band.out has been generated for $2. Converting to data file..."
            STALL='none'
            break
          elif 
            grep -q "ERROR!" $3.log; then
            echo "DFTB+ Error. User trouble-shoot required."
            exit
          else
            log_size3=($(ls -l "$3.log"))
            size3=(${log_size3[4]})
            if [[ $size3 == $size2 ]]; then
              echo "$3 has stalled. Restarting..."
              qdel $JOBID
              STALL='bands'
              break
            fi
          fi
        elif [[ $5 == "DOS" ]]; then
          if grep -q "SCC converged" detailed.out; then
            echo "DOS files have been generated for $2. Converting to data files..."
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
              STALL='dos'
              break
            fi
          fi
        fi
      fi
    fi
  done       
}

waveplot_in () {
# $1 = $SUPERCELL
  cat > waveplot_in.hsd <<!
Options {
  TotalChargeDensity = Yes
  TotalChargeDifference = Yes
  ChargeDensity = Yes
  RealComponent = Yes
  PlottedKPoints = 1
  PlottedSpins = 1 -1
  PlottedLevels = 1
  PlottedRegion = UnitCell {
    MinEdgeLength [Angstrom] = 23
  }
  NrOfPoints = 30 30 30
  NrOfCachedGrids = -1
  Verbose = Yes
  FillBoxWithAtoms = Yes
!
  supercell=$1[@]
  repeatCELL=("${!supercell}")
  printf "%s\n" "  RepeatBox = {${repeatCELL[@]}}" >> waveplot_in.hsd
  cat >> waveplot_in.hsd <<!
}
DetailedXML = './detailed.xml'
EigenvecBin = './eigenvec.bin'
Basis {
  Resolution = 0.01
  <<+ '/project/designlab/Shared/Codes/dftb+sk/3ob-3-1/wfc.3ob-3-1.hsd'
}
!
}

waveplot () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
# $4 = $CORE_TYPE
  if [[ $4 == 'CPUS' ]]; then
    sed -i '/.*srun dftb+.*/s/^/#/g' ~/bin/submit_dftb_cpus
    sed -i '/.*waveplot.*/s/^#//g' ~/bin/submit_dftb_cpus
    submit_dftb_cpus 1 $1 $3
  else
    sed -i '/.*srun dftb+.*/s/^/#/g' ~/bin/submit_dftb_tasks
    sed -i '/.*waveplot.*/s/^#//g' ~/bin/submit_dftb_tasks
    submit_dftb_tasks $1 1 $3
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
        if grep -q "File 'wp-abs2diff.cube' written" $1.log; then
          supercell=$2[@]
          repeatCELL=("${!supercell}")
          echo "${repeatCELL[@]} $3 Waveplot is complete!"
          sed -i '/.*srun dftb+.*/s/^#//g' ~/bin/submit_dftb_automate
          sed -i '/.*waveplot.*/s/^/#/g' ~/bin/submit_dftb_automate
          cp wp-abs2diff.cube $3-wp-abs2diff.cube
          rm wp-abs2diff.cube
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
            STALL='waveplot'
            break
          fi
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
echo "What supercell will you use for the charge distribution? (i.e. 2 2 1)"
read SUPERCELL
STALL='none'
CORES=16
id=$$

(
  trap '' 1

echo $id
# Make a directory for each property calculation

if [ ! -d "Properties" ]; then
  mkdir Properties
  mkdir Properties/Bands
  mkdir Properties/DOS
  mkdir Properties/Charge-Diff
fi

cp 'Relax/1e-4-Outputs/detailed.xml' Properties/Charge-Diff/
cp 'Relax/1e-4-Outputs/eigenvec.bin' Properties/Charge-Diff/

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
fi

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

## Bands calculation next
PROPERTY="bands"
JOBNAME="$COF-Bands"

# The correct input geometry (either stacked from relax.sh or stacked from stacking.sh) and most recent charges.bin should be in this directory
cd Properties/Bands

# Generate the dftb_in file for the band calculation, and run
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
CORES=16
CPU_TYPE='TASKS'
scc $CORES $COF $JOBNAME $GEO $PROPERTY
if [[ $STALL != 'none' ]]; then
  ncores $N_ATOMS $STALL $CORES
  scc $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  if [[ $STALL != 'none' ]]; then
    ncores $N_ATOMS $STALL $CORES
    scc $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  fi
fi

# Convert the .out file into the .dat file
module load dftb/21.2
dp_bands -N band.out "${COF}_bands"
echo "$COF bands converted!"

## DOS calculation next
PROPERTY="DOS"
JOBNAME="$COF-DOS"

# The correct input geometry (either stacked from relax.sh or stacked from stacking.sh) and most recent charges.bin should be in this directory
cd ../DOS

# Generate the dftb_in.hsd file for the DOS calculation, and run
CORES=16
CPU_TYPE='TASKS'
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY
if [[ $STALL != 'none' ]]; then
  ncores $N_ATOMS $STALL $CORES
  scc $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  if [[ $STALL != 'none' ]]; then
    ncores $N_ATOMS $STALL $CORES
    scc $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  fi
fi

# Convert the .out files into .dat files
dp_dos band.out "${COF}_dos_total.dat"
for element in ${ATOM_TYPES[@]}; do
  dp_dos -w "dos_${element}.1.out" "dos_${element}.s.dat"
  if [[ ${MOMENTUM[$element]} == "p" ]]; then
    dp_dos -w "dos_${element}.2.out" "dos_${element}.p.dat"
  elif [[ ${MOMENTUM[$element]} == "d" ]]; then
    dp_dos -w "dos_${element}.3.out" "dos_${element}.d.dat"
  fi
done
rm dos*out

## Waveplot calculation is final
PROPERTY="waveplot"
JOBNAME="$COF-Waveplot"

# The detailed.xml and eigenvec.bin from the stacked calculation should be in this folder
cd ../Charge-Diff

# Generate waveplot_in.hsd and run
CORES=16
CORE_TYPE='TASKS'
waveplot_in SUPERCELL
waveplot $JOBNAME SUPERCELL $COF
if [[ $STALL != 'none' ]]; then
  ncores $N_ATOMS $STALL $CORES
  waveplot $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  if [[ $STALL != 'none' ]]; then
    ncores $N_ATOMS $STALL $CORES
    waveplot $CORES $COF $JOBNAME $GEO $PROPERTY $CORE_TYPE
  fi
fi

## All calculations have been run now
echo "DFTB+ Property Calculations for $COF are complete!"
exit
) </dev/null >log.$COF-Properties 2>&1 &
