#!/bin/bash

# Run a DetailedXML calculation with the supercell of the stacked geometry
## FUTURE EDITS: AUTOMATICALLY GENERATE THE SUPERCELL RATHER THAN MANUALLY WITH OVITO
# The run a charge distribution with the detailed.xml and eigenvec.bin files from the supercell calculation

# Write function to write dftb_in.hsd for the supercell calculation
# Check outputs
# Set-up director for charge difference calculation
# Write waveplot_in.hsd
# Begin charge difference calculation

ncores () {
  if (($1 <= 20)); then
    CORES=2
  elif (($1 >= 20 && $1 <= 50)); then
    CORES=4
  elif (($1 >= 50 && $1 <= 100)); then
    CORES=8
  elif (($1 >= 100)); then
    CORES=16
  fi
}

waveplot_in () {
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

# The user needs to supply the supercell input file, the detailed.xml and the eigenvec.bin files

echo "What is the COF name?" 
read COF
echo "What are your supercell dimensions?" 
read SUPERCELL
echo "What is your input geometry file called?"
read GEO
JOBNAME="$COF-ChargeDiff"


