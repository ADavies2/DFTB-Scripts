# This Python script is meant to build COF structures using pyCOFBuilder.

import pycofbuilder as pcb
from pycofbuilder.building_block import BuildingBlock

cof = pcb.Framework('T3_PAC_Cl_SO3H-L2_BENZ_Cl_H_O-HCB_A-A')
# BuildingBlock1-BuildingBlock2-Net-Stacking
# BuildingBlock : Symmetry_Core_Connector_FunctionalGroupR1_FunctionalGroupR2...

cof.save(fmt='vasp', supercell=[1,1,1], save_dir='.')
# This format (fmt) can be updated to a different file type. Supercells can also be generated.