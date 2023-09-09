def Get_Occupancy(Filename, Iteration, No_Atoms):
# Filename: XYZ file from MD calculations
# Iteration: Which MD iteration to grab water occupancy from
# No_Atoms: How many total atoms are in the system, i.e., number of lines to grab

    skip = Iteration*2+No_Atoms*(Iteration-1)
    XYZ = pd.read_csv('COF139-Proton.xyz', header=None, nrows=No_Atoms, delim_whitespace=True,\
                      names=['Particle Type','X','Y','Z','Charge','Vx','Vy','Vz'], skiprows=skip)
        
    if PH == 'acid':
        C_Index = [46,47,95,96,117,118] # Particle index for terminal carbons in COOH groups, for acidic sim
    else:
        C_Index = [42,43,90,91,114,116] # Particle index for second_terminal in COOH, for basic sim
    O_Index = np.linspace(144,167,num=24) # Particle index for oxygens in COOH groups
    
    # The terminal carbons will be used as criterion for H2O being "in the pore" and we want to be sure not to\
    # count the oxygen atoms in the COOH when checking for H2O (or rather, the oxygen in H2O)
    
    COOH_C = []
    for i in C_Index:
        dict = {}
        dict.update(XYZ.iloc[i])
        COOH_C.append(dict)
    COOH_C = pd.DataFrame(COOH_C) # All data for COOH_C terminal atoms
    
    #Min_X = min(COOH_C['X'])+4
    #Max_X = max(COOH_C['X'])+4

    #Min_Y = min(COOH_C['Y'])+4
    #Max_Y = max(COOH_C['Y'])+4 # The length of the COOH group here is used, since there are "gaps" between\
    # functional groups that H2O could be going through as well, not just between the functional group\
    # terminations

    # If the z-coordinate of a water molecule is within the Z maximum and minimum of the COOH groups, then it is likely within the pore as well
    Min_Z = min(COOH_C['Z'])
    Max_Z = max(COOH_C['Z'])
    
    H2O_O = []
    for i in range(int(max(O_Index)),len(XYZ)):
        if XYZ.iloc[i]['Particle Type'] == 'O':
            H2O_O.append(i) # Grab index for H2O. We know the range of indexes for O in COOH, so begin\
            # grabbing O indexes after that range
            
    Occupancy = 0
    for i in H2O_O:
        if Min_X <= XYZ.iloc[i]['X'] <= Max_X:
            if Min_Y <= XYZ.iloc[i]['Y'] <= Max_Y:
                if Min_Z <= XYZ.iloc[i]['Z'] <= Max_Z:
                    Occupancy += 1
                    
    return Occupancy