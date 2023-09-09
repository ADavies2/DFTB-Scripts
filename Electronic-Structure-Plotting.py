# This is a general Python script for plotting band structures and density of states from DFTB+ output
# The k-path used in this plot is the typical k-path for COFs. It may be different for your materials.

# Variables to change or update are:
# Fermi level
# BandGap
# COF, or material name
# Bands
# DOS
# plt.xlim and plt.xticks to match your designated k-path

import numpy as np
import seaborn as sns

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

Fermi = -4.6135 # Fermi level, taken from well-converged DOS calculation
BandGap = 0.53 # Band gap, calculated from dos-band.out using sigma = 0.001 for broadening
COF = 'ATFG' # COF, or material, name

Bands = np.array(np.loadtxt('bands_tot.dat'))
DOS = np.array(np.loadtxt('dos_tot.dat'))

fig = plt.figure(figsize=(12,8))
plt.subplot(121)
plt.plot(Bands-Fermi, color = 'black')
plt.ylim(-2,2)
plt.xlabel('K-Point Path', labelpad = 10)
plt.ylabel('Energy (eV)', labelpad = 3)
plt.xlim(0,60)
plt.xticks([0,20,40,60], ['\u0393','K','M', '\u0393'])
plt.vlines(20,-2,2,colors='black',alpha=0.2) # Vertical lines at k-points
plt.vlines(40,-2,2,colors='black',alpha=0.2)
plt.vlines(60,-2,2,colors='black',alpha=0.2)
plt.subplot(122)
plt.plot(DOS[:,1], DOS[:,0]-Fermi, color='black')
plt.text(2, 0, f'Band Gap({COF_AA}) = {BandGap} eV', color='black', fontsize=18)
plt.xlabel('DOS')
plt.ylim(-2,2)
#plt.savefig('%s-Bands.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()