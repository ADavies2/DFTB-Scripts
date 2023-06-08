#!/bin/bash

# This version of automated relax can either run an already stacked calculation, or start a monolayer calculation and edit the output geometry file to be AA and AB stacked.

# Read the instruction file
INSTRUCT=$1
COF=($(sed -n 1p $INSTRUCT)) # Name of the COF
TOL=($(sed -n 2p $INSTRUCT)) # Initial SCC tolerance
GEO=($(sed -n 3p $INSTRUCT)) # Name of structure input file
RESTART=($(sed -n 4p $INSTRUCT)) # Is this calculation a restarted calculation? i.e., is there a DFTB+ charges.bin file?
PARTITION=($(sed -n 5p $INSTRUCT)) # Which partition this calculation will be running on (teton vs. inv-desousa)
SPACING=($(sed -n 6p $INSTRUCT)) # Is this a monolayer calculation or a stacked COF? 
# If the calculation is a monolayer, run the monolayer with relax-v4, then adjust the output geometries to AA and AB stacking and run both with relax-v4
# If the calculation is stacked already, run only relax-v4-with-energies

if [ $SPACING == 'stacked' ]; then
    cat > stacked.in <<!
# COF Name
$COF
# Initial SCC
$TOL
# Geometry input file name
$GEO
# Restart?
$RESTART
# Partition?
$PARTITION
!
    submit_bash stacked.in autorelax-$COF
fi

if [ $SPACING == 'monolayer' ]; then
    mkdir Monolayer
    cd Monolayer
    cat > monolayer.in <<!
# COF Name
$COF
# Initial SCC
$TOL
# Geometry input file name
$GEO
# Restart?
$RESTART
# Partition?
$PARTITION
!
    submit_bash monolayer.in autorelax-$COF-monolayer
fi