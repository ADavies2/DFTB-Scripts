def sigma(conduction_band, valence_band, fermi, trace):
# This function finds the maximum electrical conductivity value from a BoltzTrapp trace file, given the maximum conduction band and the minimum valence band values
    Ry2eV = 13.6057039763
    converted_Ef = []
    for i in range(0,len(trace)):
        ef_ev = trace.iloc[i][0]*Ry2eV
        converted_Ef.append(ef_ev)
    trace['Ef[eV]'] = converted_Ef
    
    Ef_Conduct = next(c for c in range(0,len(trace)) if round(conduction_band-fermi,3)-0.01 <= \
                      round(trace.iloc[c]['Ef[eV]'],3) <= round(conduction_band-fermi,3)+0.01)

    Ef_Valence = next(c for c in range(0,len(trace)) if round(valence_band-fermi,3)-0.01 <= \
                      round(trace.iloc[c]['Ef[eV]'],3) <= round(valence_band-fermi,3)+0.01)
    
    Sigma = max(trace[Ef_Conduct:Ef_Valence]['sigma/tau0[1/(ohm*m*s)]'])
    for i in range(Ef_Conduct, Ef_Valence):
        if trace.iloc[i]['sigma/tau0[1/(ohm*m*s)]'] == Sigma:
            Ef = trace.iloc[i]['Ef[eV]']
    return Sigma, Ef