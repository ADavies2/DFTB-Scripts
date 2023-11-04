#!/bin/bash

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
          exit
        else
          echo "$1 is still runing..."
          sleep 10s
        fi
      fi
  done
}

# The user needs to supply the detailed.xml and the eigenvec.bin files

echo "What is the COF name?"
read COF
echo "What are your supercell dimensions? (i.e. 2 2 1)"
read SUPERCELL
JOBNAME="$COF-Waveplot"

waveplot_in SUPERCELL
waveplot $JOBNAME SUPERCELL $COF
