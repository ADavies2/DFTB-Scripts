# This script is used for OVITO Python to randomly select four atoms of the previously (manually) selected type, and replace them with type Na, and also delete the bonded hydrogen atoms
from ovito.data import *
from ovito.data import NearestNeighborFinder
import numpy as np

def modify(frame: int, data: DataCollection):
    ptypes = data.particles_.particle_types_
    ptypes.types.append(ParticleType( id = 3, name = "Na"))
    
    rng = np.random.default_rng()
    select = np.where(data.particles.selection)[0]
    ptypes[rng.choice(select, int(4), replace=False)] = 3
    
    finder = NearestNeighborFinder(2, data)
    H_atoms, _ = finder.find_all(indices = np.where(ptypes==3)[0])
    data.particles_.delete_indices(H_atoms.flatten())  
    
    print("There are %i particles with the following properties:" % data.particles.count)
    for type in ptypes.types:
        print(type.id, type.name)
