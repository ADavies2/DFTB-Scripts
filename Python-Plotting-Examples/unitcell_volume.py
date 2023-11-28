def unitcell_volume(POSCAR):
# This function calculates the lattice parameters a, b, and c, as well as the angles between parameters, from the unit cell vectors given by a POSCAR file
# It returns in the form volume, a, b, c, alpha, beta, gamma
# POSCAR is the path to the POSCAR file
    import pandas as pd
    import numpy as np
    
    simulation_cell = pd.read_csv(POSCAR, header=None, delim_whitespace=True, skiprows=[0,1], nrows=3)
    
    a = np.sqrt(simulation_cell.loc[0][0]**2+simulation_cell.loc[0][1]**2+simulation_cell.loc[0][2]**2)
    b = np.sqrt(simulation_cell.loc[1][0]**2+simulation_cell.loc[1][1]**2+simulation_cell.loc[1][2]**2)
    c = np.sqrt(simulation_cell.loc[2][0]**2+simulation_cell.loc[2][1]**2+simulation_cell.loc[2][2]**2)
    
    a_b = (simulation_cell.loc[0][0]*simulation_cell.loc[1][0])+(simulation_cell.loc[0][1]*simulation_cell.loc[1][1])+(simulation_cell.loc[0][2]*simulation_cell.loc[1][2])
    a_c = (simulation_cell.loc[0][0]*simulation_cell.loc[2][0])+(simulation_cell.loc[0][1]*simulation_cell.loc[2][1])+(simulation_cell.loc[0][2]*simulation_cell.loc[2][2])
    b_c = (simulation_cell.loc[1][0]*simulation_cell.loc[2][0])+(simulation_cell.loc[1][1]*simulation_cell.loc[2][1])+(simulation_cell.loc[1][2]*simulation_cell.loc[2][2])
    
    alpha = np.degrees(np.arccos(b_c/(c*b)))
    beta = np.degrees(np.arccos(a_c/(a*c)))
    gamma = np.degrees(np.arccos(a_b/(a*b)))
    
    volume = (a*b*c)*np.sqrt(1-np.cos(np.radians(alpha))**2-np.cos(np.radians(beta))**2-np.cos(np.radians(gamma))**2+2*np.cos(np.radians(alpha))*np.cos(np.radians(beta))*np.cos(np.radians(gamma)))
    
    return volume, a, b, c, alpha, beta, gamma