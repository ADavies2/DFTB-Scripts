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

def extract_DOS(COF, Atom_Types):
  Total = np.array(np.loadtxt('./DOS/%s_dos_total.dat' % COF))
  

COF = 
Fermi = 
Atom_types = 

Total = np.array(np.loadtxt('./dos_total.dat'))
Smooth_Total = gaussian_filter((Total[:,1]), sigma=13)

O_s = np.array(np.loadtxt('./dos_O.s.dat'))
O_p = np.array(np.loadtxt('./dos_O.p.dat'))
Smooth_Os = gaussian_filter((O_s[:,1]), sigma=13)
Smooth_Op = gaussian_filter((O_p[:,1]), sigma=13)

C_s = np.array(np.loadtxt('./dos_C.s.dat'))
C_p = np.array(np.loadtxt('./dos_C.p.dat'))
Smooth_Cs = gaussian_filter((C_s[:,1]), sigma=13)
Smooth_Cp = gaussian_filter((C_p[:,1]), sigma=13)

H_s = np.array(np.loadtxt('./dos_H.s.dat'))
Smooth_Hs = gaussian_filter((H_s[:,1]), sigma=13)

N_s = np.array(np.loadtxt('./dos_N.s.dat'))
N_p = np.array(np.loadtxt('./dos_N.p.dat'))
Smooth_Ns = gaussian_filter((N_s[:,1]), sigma=13)
Smooth_Np = gaussian_filter((N_p[:,1]), sigma=13)
