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

fig = plt.figure(figsize=(12,8))
plt.plot(Bands-Fermi, color = 'black')
plt.ylim(-2,2) # (-5.5, 2.5), (-8,-3), (-5,-3)
plt.xlabel('K-Point Path', labelpad = 10)
plt.ylabel('Energy (eV)', labelpad = 3)
plt.xlim(0,30)
plt.text(1, 0, f'Band Gap({COF}) = {BandGap} eV', color='black', fontsize=18)
plt.xticks([0,20,40,60], ['\u0393','K','M', '\u0393'])
#plt.savefig(f'{COF}-Bands.jpeg',  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()
