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
    printf "%s\n" "Driver = { }" >> dftb_in.hsd
  fi
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
  if [[ $2 == "bands" ]] || [[ $3 == *"Stack"* ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes }" >> dftb_in.hsd
  elif [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "  MullikenAnalysis = Yes" >> dftb_in.hsd
    printf "%s\n" "  AtomResolvedEnergies = Yes" >> dftb_in.hsd
    printf "%s\n" "  WriteEigenvectors = Yes" >> dftb_in.hsd
    printf "%s\n" "  CalculateForces = Yes }" >> dftb_in.hsd
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
  if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
    printf "%s\n" "Options {" >> dftb_in.hsd
    printf "%s\n" "WriteDetailedXML = Yes" >> dftb_in.hsd
    printf "%s\n" "WriteChargesAsText = Yes }" >> dftb_in.hsd
  fi
}

scc () {
# $1 = $CORES
# $2 = $COF
# $3 = $JOBNAME
# $4 = $GEO
# $5 = $PROPERTY
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
      if [[ $5 == 'stacking' ]]; then
        if [[ $3 == *"Mono"* ]] || [[ $3 == *"Final"* ]]; then
          if grep -q "Geometry converged" detailed.out && grep -q "Geometry converged" $3.log; then
            echo "$2 Monolayer is fully relaxed!"
            break
          elif grep -q "SCC is NOT converged" $3.log; then
            printf "$2 Monolayer did NOT converge.\n User trouble-shoot required." 
            exit
          else
            echo "$3 is still running..."
            sleep 10s
          fi
        else
          if  grep -q "SCC did NOT converge" detailed.out || grep -q "SCC converged" detailed.out; then
            if grep -q "SCC did NOT converge" detailed.out; then
              echo "$3 SCC did NOT converge." 
            fi
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
          else
            echo "$3 is still running..."
            sleep 10s
          fi
        fi
      elif [[ $5 == "bands" ]]; then
        if grep -q "SCC is NOT converged" $3.log; then
          echo "Band.out has been generated for $2. Converting to data file..."
          break
        else
          echo "$3 is still running..."
          sleep 10s
        fi
      elif [[ $5 == "DOS" ]]; then
        if grep -q "SCC converged" detailed.out; then
          echo "DOS files have been generated for $2. Converting to data files..."
          break
        else
          echo "$3 is till running..."
          sleep 10s
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
# $1 = $JOBNAME
# $2 = $SUPERCELL
# $3 = $COF
  sed -i '/.*srun dftb+.*/s/^/#/g' ~/bin/submit_dftb_automate
  sed -i '/.*waveplot.*/s/^#//g' ~/bin/submit_dftb_automate
  submit_dftb_automate 16 1 $1
  while :
  do
    stat="$(squeue -n $1)"
    string=($stat)
    jobstat=(${string[12]})
      if [ "$jobstat" == "PD" ]; then
        echo "$1 is pending..."
        sleep 10s
      else
        if grep -q "File 'wp-abs2diff.cube' written" $1.log; then
          supercell=$2[@]
          repeatCELL=("${!supercell}")
          echo "${repeatCELL[@]} $3 Waveplot is complete!"
          sed -i '/.*srun dftb+.*/s/^#//g' ~/bin/submit_dftb_automate
          sed -i '/.*waveplot.*/s/^/#/g' ~/bin/submit_dftb_automate
          cp wp-abs2diff.cube $3-wp-abs2diff.cube
          rm wp-abs2diff.cube
          break
        else
          echo "$1 is still runing..."
          sleep 10s
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

(
  trap '' 1
  
# Make a directory for each property calculation
mkdir Properties
mkdir Properties/Layer-Analysis
mkdir Properties/Bands
mkdir Properties/DOS
mkdir Properties/Charge-Diff

#Copy the required input files to the Layer-Analysis (first calculation here)
cp Relax/1e-4-Outputs/1e-4-Out.gen Properties/Layer-Analysis/Input.gen
cp Relax/1e-4-Outputs/charges.bin Properties/Layer-Analysis

# Define the height intervals to test for the stacking analysis
# If the stacked geometry is already optimized, copy the files needed for the waveplot calculations into the appropriate directory
# If the stacked geometry is not yep optimized, these files will be copied later
stackedHEIGHTS=(3.3 3.5 4)
if [ $STARTING == 'stacked' ]; then
  JOBNAME="$COF-Mono"
  cp 'Relax/1e-4-Outputs/detailed.xml' Charge-Diff
  cp 'Relax/1e-4-Outputs/eigenvec.bin' Charge-Diff
else
  JOBNAME="$COF-Stack1"
fi

cd Properties/Layer-Analysis
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

# Read atom types into a function for angular momentum and Hubbard derivative values
declare -A myHUBBARD
declare -A myMOMENTUM
for element in ${ATOM_TYPES[@]}; do
  myHUBBARD[$element]="$element = ${HUBBARD[$element]}"
  myMOMENTUM[$element]="$element = ${MOMENTUM[$element]}"
done

# Calculate the number of required cores based on the total number of atoms in the unit cell
ncores $N_ATOMS

## Stacking calculation first
PROPERTY=stacking

# Generate the dftb_in.hsd for stacking.sh
if [[ $STARTING == "stacked" ]]; then
  dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
else
  if [[ $GEO = *"gen"* ]]; then
    GEO="Input1.gen"
  else
    GEO="Input1-POSCAR"
  fi
  dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
fi

# Run stacking. This is either a single monolayer calculation or the first static stacked calculation
scc $CORES $COF $JOBNAME $GEO $PROPERTY

# Run the second static stacked calculation
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY

# Run the third and final static stacked calculation
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY

# Check the total energies of each system in their separate detailed.out files
# Compare the total energy values, determine the minimum, and store the corresponding geometry name 
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

# Set $GEO to match the lowest-energy static geometry previously determined
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

# Run a dynamic SCC calculation with this stacked geometry
JOBNAME="$COF-Final-Opt"
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY

# Copy the required files for the charge difference calculation into the appropriate directory
cp detailed.xml ../Charge-Diff
cp eigenvec.bin ../Charge-Diff

# Copy the input files for the next calculation
if [[ $STARTING == "mono" ]]; then
  cp "$COF-Final-Opt-Out.gen" ../Bands/Input.gen
  cp "$COF-Final-Opt-Out.gen" ../DOS/Input.gen
else
  cp Input.gen ../Bands
  cp Input.gen ../DOS
fi
GEO="Input.gen"
cp charges.bin ../Bands
cp charges.bin ../DOS

## Bands calculation next
PROPERTY="bands"
JOBNAME="$COF-Bands"

# The correct input geometry (either stacked from relax.sh or stacked from stacking.sh) and most recent charges.bin should be in this directory
cd ../Bands

# Generate the dftb_in file for the band calculation, and run
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY

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
dftb_in $GEO $PROPERTY $JOBNAME myHUBBARD myMOMENTUM ATOM_TYPES
scc $CORES $COF $JOBNAME $GEO $PROPERTY

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
waveplot_in SUPERCELL
waveplot $JOBNAME SUPERCELL $COF

## All calculations have been run now
echo "DFTB+ Property Calculations for $COF are complete!"
) </dev/null >log.$COF-Properties 2>&1 &
