def k_path(kpoints, POSCAR):
# This function determines the k-path length for band structures
# kpoints : a list of the k-points sampled on the k-path. The k-vectors will be determined from this
# POSCAR : the path to the POSCAR file type for this band structure. The simulation cell is taken from this file.
    import pandas as pd
    import numpy as np

    kvectors = []
    for i in range(0,len(kpoints)-1):
        vector = [kpoints[i+1][0]-kpoints[i][0], kpoints[i+1][1]-kpoints[i][1], kpoints[i+1][2]-kpoints[i][2]]
        kvectors.append(vector)
    
    simulation_cell = pd.read_csv(POSCAR, header=None, delim_whitespace=True, skiprows=[0,1], nrows=3)
    
    klength = []
    for i in range(0,len(kvectors)):
        distance = np.linalg.norm(np.dot(kvectors[i], simulation_cell))
        klength.append(np.pi/distance)
        
    kpath = np.linspace(0, np.sum(klength), 81)
    return kpath