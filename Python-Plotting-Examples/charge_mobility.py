def charge_mobility(trace, POSCAR):
# This function calculates the charge carrier mobility from a BoltzTraP2 .trace file
# The carrier mobility is a function of the electrical conductivity and density of carriers per unit cell, per Ohm's Law
# The volume of the unit cell is calculated using the previously defined function
    import pandas as pd

    Ang2m = 1e-30 # Convert angstrom^3 to m^3
    q = 1.602e-19 # coulombs (A*s)
    simulation_cell = unitcell_volume(POSCAR)
    volume_ang3 = simulation_cell[0]
    volume_m3 = Ang2m*volume_ang3
    
    trace['N[e/m**3]'] = trace['N[e/uc]']/volume_m3
    trace['mu[m**2/V*s]'] = (trace['sigma/tau0[1/(ohm*m*s)]']*1e-14)/(q*trace['N[e/m**3]'])