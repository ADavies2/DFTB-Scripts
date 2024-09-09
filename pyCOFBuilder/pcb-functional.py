# This Python script is meant to edit a .gjp file from GaussView to generate a compatible building block file for the package, pyCOFBuilder.
# This script is specifically for functional group building blocks.

import pycofbuilder as pcb
import os
from pycofbuilder.io_tools import convert_gjf_2_xyz
from pycofbuilder.building_block import BuildingBlock
from pycofbuilder.tools import smiles_to_xsmiles
from pycofbuilder.cjson import ChemJSON

compound_name = 'cyanide-test' ### CHANGE THIS
code = 'CN' ### CHANGE THIS

# Define object as a BuildingBlock
newBB = BuildingBlock()

# Read the XYZ file using a BuildingBlock function
newBB.from_file(os.getcwd(), f'{compound_name}.gjf')
#print(newBB.print_structure())

newBB.smiles = 'N#C[R]' ### CHANGE THIS
newBB.xsmiles, newBB.xsmiles_label, newBB.composition = smiles_to_xsmiles(newBB.smiles)

R = newBB.get_R_points(newBB.atom_types, newBB.atom_pos)
newBB.shift([-1*R['R'][0][0], -1*R['R'][0][1], -1*R['R'][0][2]]) # Shifts the R atom to coordinates 0,0,0
# Shifts the rest of the atoms respectively

### If you know that your functional group will be rotated 90 degrees relative the COF plane, uncomment these lines
#print(newBB.print_structure())
#newBB.rotate_around([1,0,0], 90)

newBB.remove_X()

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
