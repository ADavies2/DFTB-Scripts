import numpy as np
import seaborn as sns

from scipy.ndimage import gaussian_filter

import matplotlib.pylab as plt
from matplotlib import rcParams
import matplotlib.colors as colors
import matplotlib.cbook as cbook

rcParams.update({'figure.autolayout': True})
sns.set_style("whitegrid", rc={"axes.edgecolor": "k"})
sns.set_style("ticks", {"xtick.major.size":8,"ytick.major.size":8})

sns.set_context("notebook",rc={"grid.linewidth": 0, 
                            "font.family":"Helvetica", "axes.labelsize":24.,"xtick.labelsize":24., 
                            "ytick.labelsize":24., "legend.fontsize":20.})


colors = sns.color_palette("colorblind", 12) 

Fermi = -4.6135 #eV
COF = 'ATFG'

C_s = np.array(np.loadtxt('dos_C.s.dat'))
C_p = np.array(np.loadtxt('dos_C.p.dat'))

H_s = np.array(np.loadtxt('dos_H.s.dat'))

N_s = np.array(np.loadtxt('dos_N.s.dat'))
N_p = np.array(np.loadtxt('dos_N.p.dat'))

O_s = np.array(np.loadtxt('dos_O.s.dat'))
O_p = np.array(np.loadtxt('dos_O.p.dat'))

Total = np.array(np.loadtxt('%s_dos_total.dat' % COF))

fig = plt.figure(figsize=(12,8))
plt.plot(Total[:,0]-Fermi, Total[:,1], color='black')
plt.plot(C_s[:,0]-Fermi, C_s[:,1], color=colors[0])
plt.plot(C_p[:,0]-Fermi, C_p[:,1], color=colors[1])
plt.plot(H_s[:,0]-Fermi, H_s[:,1], color=colors[2])
plt.plot(N_s[:,0]-Fermi, N_s[:,1], color=colors[3])
plt.plot(N_p[:,0]-Fermi, N_p[:,1], color=colors[4])
plt.plot(O_s[:,0]-Fermi, O_s[:,1], color=colors[5])
plt.plot(O_p[:,0]-Fermi, O_p[:,1], color=colors[6])
plt.xlabel('Energy (eV)')
plt.ylabel('DOS / Partial DOS')
plt.xlim(-3,3)
#plt.ylim(0,17.5)
#plt.savefig('%s-PDOS.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
#plt.savefig('%s-DOS.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()
