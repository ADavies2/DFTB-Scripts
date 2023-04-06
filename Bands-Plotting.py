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

Fermi = -4.6135 # eV
COF = 'ATFG'

Bands = np.array(np.loadtxt("%s_bands_tot.dat" % COF))
print(np.shape(Bands))

fig = plt.figure(figsize=(12,8))
plt.plot(Bands-Fermi, color = 'black')
plt.ylim(-2,2) # (-5.5, 2.5), (-8,-3), (-5,-3)
plt.xlabel('K-Point Path', labelpad = 10)
plt.ylabel('Energy (eV)', labelpad = 3)
plt.xlim(0,30)
plt.text(1, 0, 'Band Gap(%s) = 0.53 eV' % COF, color='black', fontsize=18)
plt.xticks([0,10,20,30], ['\u0393','K','M', '\u0393'])
#plt.savefig('%s-Bands.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()
