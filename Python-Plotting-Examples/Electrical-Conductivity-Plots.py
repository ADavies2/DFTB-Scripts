# This is an example Python script for plotting DFTB+ density of states and band structures, as well as plotting BoltzTrapp generated electrical conductivity

import numpy as np
import seaborn as sns
import pandas as pd

import matplotlib.pylab as plt
from matplotlib import rcParams
import matplotlib.colors as colors
import matplotlib.cbook as cbook
from matplotlib.lines import Line2D

rcParams.update({'figure.autolayout': True})
sns.set_style("whitegrid", rc={"axes.edgecolor": "k"})
sns.set_style("ticks", {"xtick.major.size":8,"ytick.major.size":8})

sns.set_context("notebook",rc={"grid.linewidth": 0, 
                            "font.family":"Helvetica", "axes.labelsize":24.,"xtick.labelsize":24., 
                            "ytick.labelsize":24., "legend.fontsize":20.})

colors = sns.color_palette("colorblind", 12)

Ry2eV = 13.6057039763

# GAMMA -> K -> M -> GAMMA -> A
KPOINTS = [[0,0,0],[0.33,0.33,0],[0.5,0,0],[0,0,0],[0,0,0.5]]
# Be sure to update this to reflect your own k-path

def k_path(kpoints, POSCAR):
# This function determines the k-path length for band structures
# kpoints : a list of the k-points sampled on the k-path. The k-vectors will be determined from this
# POSCAR : the path to the POSCAR file type for this band structure. The simulation cell is taken from this file.
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

# DFTB+ AA
DOSFermi_AA = -3.9513 # Determined from detailed.out
ValenceBand_AA = -3.37 # Maximum valence band value from converted dos_tot.dat
ConductionBand_AA = -4.54 # Minimum conduction band value from converted dos_tot.dat
COF_AA = 'KCK-COF1-AA' # Name of COF (or material in question)
BandGap_AA = 1.15 # Calculated band gap from converted dos_tot.dat

# Be sure to update the paths and file names in the following lines
Bands_AA = np.array(np.loadtxt('./KCK-COF1/AA-Inclined/Band-Structure/p6-bands_tot.dat'))
DOS_AA = np.array(np.loadtxt('./KCK-COF1/AA-Inclined/DOS/band-sigma02.dat'))
KPATH_AA = k_path(KPOINTS, './KCK-COF1/AA-Inclined/1e-4-Outputs/COF-K1-Methoxy-Stacked-Out-POSCAR')
TraceAA = pd.read_csv('./KCK-COF1/AA-Inclined/BoltzTrapp/COF_BLZTRP.trace', header=None, skiprows=1,\
                      delim_whitespace=True, names=['Ef[Ry]','T[K]','N[e/uc]','DOS(ef)[1/(Ha*uc)]',\
                                                   'S[V/K]','sigma/tau0[1/(ohm*m*s)]','RH[m**3/C]',\
                                                   'kappae/tau0[W/(m*K*s)]','cv[J/(mol*K)]','chi[m**3/mol]'])
Sigma_AA = sigma(ConductionBand_AA, ValenceBand_AA, DOSFermi_AA, TraceAA)

fig = plt.figure(figsize=(16,6))
plt.subplot(131)
plt.plot(KPATH_AA, Bands_AA-DOSFermi_AA, color='black')
plt.ylim(-1,1)
plt.ylabel('Energy (eV)', labelpad=10)
plt.xticks([0,KPATH_AA[20],KPATH_AA[40],KPATH_AA[60],KPATH_AA[80]], ['\u0393', 'K', 'M', '\u0393', 'A'])
plt.vlines(KPATH_AA[20],-4,4,color='black',linestyle='dashed')
plt.vlines(KPATH_AA[40],-4,4,color='black',linestyle='dashed')
plt.vlines(KPATH_AA[60],-4,4,color='black',linestyle='dashed')
plt.vlines(KPATH_AA[80],-4,4,color='black',linestyle='dashed')
plt.xlim(0,KPATH_AA[80])
plt.subplot(132)
plt.plot(DOS_AA[:,1], DOS_AA[:,0]-DOSFermi_AA, color='black')
plt.text(2, 0.15, f'{COF_AA} = {BandGap_AA} eV', color='black', fontsize=16)
plt.xlabel('DOS', labelpad=10)
plt.ylim(-1,1)
plt.xlim(0,60)
plt.hlines(ConductionBand_AA-DOSFermi_AA,0,80,colors='black',linestyle='dashed')
plt.hlines(ValenceBand_AA-DOSFermi_AA,0,80,colors='black',linestyle='dashed')
plt.subplot(133)
plt.plot((1e-14*TraceAA['sigma/tau0[1/(ohm*m*s)]'])/1e5, TraceAA['Ef[eV]'], color='black')
plt.text(0.1, 0.15, f'$\sigma$(AA) = {round((1e-14*Sigma_AA[0])/1e5,2)} 10$^{5}$ $\Omega^{-1}$ m$^{-1}$', color='black', fontsize=15)
plt.xlabel('$\sigma$ (10$^{5}$ $\Omega^{-1}$ m$^{-1}$)', labelpad=10)
plt.ylim(-1,1)
plt.xlim(0,3)
plt.hlines(ConductionBand_AA-DOSFermi_AA,0,80,colors='black',linestyle='dashed')
plt.hlines(ValenceBand_AA-DOSFermi_AA,0,80,colors='black',linestyle='dashed')
plt.show()