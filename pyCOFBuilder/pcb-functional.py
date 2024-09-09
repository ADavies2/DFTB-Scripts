

import pycofbuilder as pcb
import os
from pycofbuilder.io_tools import convert_gjf_2_xyz
from pycofbuilder.building_block import BuildingBlock
from pycofbuilder.tools import smiles_to_xsmiles
from pycofbuilder.cjson import ChemJSON

#pcb.io_tools.convert_gjf_2_xyz(os.getcwd(), 'Phenyl.gjf')

compound_name = 'cyanide-test'
code = 'CN'

# Define object as a BuildingBlock
newBB = BuildingBlock()

# Read the XYZ file using a BuildingBlock function
newBB.from_file(os.getcwd(), f'{compound_name}.gjf')
#print(newBB.print_structure())

newBB.smiles = 'N#C[R]'
newBB.xsmiles, newBB.xsmiles_label, newBB.composition = smiles_to_xsmiles(newBB.smiles)

R = newBB.get_R_points(newBB.atom_types, newBB.atom_pos)
newBB.shift([-1*R['R'][0][0], -1*R['R'][0][1], -1*R['R'][0][2]])

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
