#!/usr/bin/env python3.12
# Author: Alathea Davies
# This Python script is meant to edit a .gjp file from GaussView to generate a compatible building block file for the package, pyCOFBuilder.
# This script is meant specifically for core (node and linker) building blocks.

import pycofbuilder as pcb
import os
from pycofbuilder.io_tools import convert_gjf_2_xyz
from pycofbuilder.building_block import BuildingBlock
from pycofbuilder.tools import smiles_to_xsmiles
from pycofbuilder.cjson import ChemJSON

compound_name = 'HXTR2' ### CHANGE THIS
code = 'HXTR2' ### CHANGE THIS

# Define object as a BuildingBlock
newBB = BuildingBlock()

# Read the XYZ file using a BuildingBlock function
newBB.from_file(os.getcwd(), f'{compound_name}.gjf')
#print(newBB.print_structure())

# The following link can be used to generate a SMILES string: https://www.cheminfo.org/flavor/malaria/Utilities/SMILES_generator___checker/index.html
newBB.smiles = 'Nc4c([R1])c3c1c([R2])c(N)c(N=[Q])c([R1])c1c2c([R2])c(N=[Q])c(N)c([R1])c2c3c([R2])c4N=[Q]' ### CHANGE THIS
newBB.xsmiles, newBB.xsmiles_label, newBB.composition = smiles_to_xsmiles(newBB.smiles)

#print(newBB.print_structure())

newBB.replace_X('Q')

#print(newBB.print_structure())

# Save as XYZ. This will save to out/buildingblocks
newBB.save()

# Create a ChemJSON object to save the BuildingBlock in
newCJSON = ChemJSON()

# Read the previously saved XYZ file as a CJSON object
newCJSON.from_xyz('out/building_blocks', f'{compound_name}.xyz')

# Define properties
newCJSON.properties = {
        "smiles": newBB.smiles,
        "code": code,
        "xsmiles": newBB.xsmiles,
        "xsmiles_label": newBB.xsmiles_label,
        }

# Save as a .cjson file
newCJSON.write_cjson(os.getcwd(), f'{code}.cjson')
