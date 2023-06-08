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
    cp ../$GEO ./
    if [ $RESTART == 'yes' ]; then
        cp ../charges.bin ./
    fi
    submit_bash monolayer.in autorelax-$COF-monolayer
    while :
    do
        squeue=($(squeue -n autorelax-$COF-monolayer))
        jobstat=(${stat[12]})
        if [ "$jobstat" == "R" ]; then
            echo "autorelax-$COF-monolayer is running..."
            sleep 90s
        elif [ "$jobstat" == "PD" ]; then
            echo "autorelax-$COF-monolayer is pending..."
            sleep 90s
        else
            echo "autorelax-$COF-monolayer is complete."
        fi
    done

    cd 1e-4-Outputs
    module load arcc/1.0 gcc/12.2.0 python/3.10.6

    cd ../
    mkdir Stacked
    cd Stacked
    mkdir AA
    mkdir AB

    cp ../Monolayer/1e-4-Outputs/AB-Input.gen AB/
    cp ../Monolayer/1e-4-Outputs/charges.bin AB/
    cp ../Monolayer/1e-4-Outputs/AA-Input.gen AA/
    cp ../Monolayer/1e-4-Outputs/charges.bin AA/

    cd AA
    cat >> aa.in <<!
# COF Name
$COF-AA
# Initial SCC
1e-1
# Geometry input file name
AA-Input.gen
# Restart?
yes
# Partition?
$PARTITION
!
    submit_bash aa.in autorelax-$COF-AA

    cd ../AB
    cat >> ab.in <<!
# COF Name
$COF-AB
# Initial SCC
1e-1
# Geometry input file name
AB-Input.gen
# Restart?
yes
# Partition?
$PARTITION
!
fi