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

COF_Name = 'COF141'

Fermi = -5.7803 # eV
Bands = np.array(np.loadtxt('bands_tot.dat'))

fig = plt.figure(figsize=(12,8))
plt.plot(Bands-Fermi, color='k')
plt.ylim(-1,1)
plt.xlabel('K-Point Path', labelpad=10)
plt.ylabel('Energy (eV)', labelpad=10)
plt.xticks([0,20,40,60], ['\u0393', 'K', 'M', '\u0393'])
plt.savefig('s%-BandStructure.jpeg' % COF_NAME, bbox_inches='tight', pad_inches=0.5, dpi=400)
