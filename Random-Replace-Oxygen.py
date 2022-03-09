# This script is used for OVITO Python to randomly select four atoms of the previously (manually) selected type, and replace them with type Na. 

from ovito.data import *
import numpy as np

def modify(frame: int, data: DataCollection):
    ptypes = data.particles_.particle_types_
    ptypes.types.append(ParticleType( id = 3, name = "Na"))
    
    rng = np.random.default_rng()
    select = np.where(data.particles.selection)[0]
    
    
    ptypes[rng.choice(select, int(4), replace=False)] = 3
