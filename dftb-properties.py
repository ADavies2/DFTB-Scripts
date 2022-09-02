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

def extract_DOS(Filepath):
    DOS = np.array(np.loadtxt(Filepath))
    return DOS 
  
def extract_bands(Filepath):
    Bands = np.array(np.loadtxt(Filepath))
    return Bands
  
COF = 'ACOF1'
Fermi = -4.1738 # eV
Atom_Types = np.array(['N', 'C', 'H'])

Total = extract_DOS('./DOS/%s_dos_total.dat' % COF)
print(np.shape(Total))

GapLower = -5.22
GapHigher = -3.13
Gap = GapLower-GapHigher
print(Gap)

PDOS = []
for i in range(0,len(Atom_Types[:])):
    if 'C' == Atom_Types[i]:
        PDOS.append(extract_DOS('./DOS/dos_%s.s.dat' % Atom_Types[i]))
        PDOS.append(extract_DOS('./DOS/dos_%s.p.dat' % Atom_Types[i]))
    if 'H' == Atom_Types[i]:
        PDOS.append(extract_DOS('./DOS/dos_%s.s.dat' % Atom_Types[i]))
    if 'N' == Atom_Types[i]:
        PDOS.append(extract_DOS('./DOS/dos_%s.s.dat' % Atom_Types[i]))
        PDOS.append(extract_DOS('./DOS/dos_%s.p.dat' % Atom_Types[i]))
PDOS = np.array(PDOS)
print(np.shape(PDOS))

# Smooth DOS
Smooth_Total = gaussian_filter((Total[:,1]), sigma=13)
Smooth_Cs = gaussian_filter((PDOS[0,:,1]), sigma=13)
Smooth_Cp = gaussian_filter((PDOS[1,:,1]), sigma=13)
Smooth_Hs = gaussian_filter((PDOS[2,:,1]), sigma=13)
Smooth_Np = gaussian_filter((PDOS[3,:,1]), sigma=13)
Smooth_Ns = gaussian_filter((PDOS[4,:,1]), sigma=13)

Bands = extract_bands('./Bands/%s_bands_tot.dat' % COF)
print(np.shape(Bands))

# Plot regular DOS
fig = plt.figure(figsize=(12,8))
plt.plot(Total[:,0]-Fermi, Total[:,1], color='black', linewidth=3, label='Total')
plt.plot(PDOS[0,:,0]-Fermi, PDOS[0,:,1], color=colors[0], label='N_s')
plt.plot(PDOS[1,:,0]-Fermi, PDOS[1,:,1], color=colors[1], label='N_p')
plt.plot(PDOS[2,:,0]-Fermi, PDOS[2,:,1], color=colors[2], label='C_s')
plt.plot(PDOS[3,:,0]-Fermi, PDOS[3,:,1], color=colors[3], label='C_p')
plt.plot(PDOS[4,:,0]-Fermi, PDOS[4,:,1], color=colors[4], label='H_s')
plt.xlabel('Energy (eV)')
plt.ylabel('DOS / Partial DOS')
plt.legend()
plt.xlim(-3,3)
#plt.savefig('%s-DOS.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()

# Plot smooth DOS
fig = plt.figure(figsize=(12,8))
plt.plot(Total[:,0]-Fermi, Smooth_Total, color='black', linewidth=3, label='Total')
plt.plot(PDOS[0,:,0]-Fermi, Smooth_Ns, color=colors[0], label='N_s')
plt.plot(PDOS[1,:,0]-Fermi, Smooth_Np, color=colors[1], label='N_p')
plt.plot(PDOS[2,:,0]-Fermi, Smooth_Cs, color=colors[2], label='C_s')
plt.plot(PDOS[3,:,0]-Fermi, Smooth_Cp, color=colors[3], label='C_p')
plt.plot(PDOS[4,:,0]-Fermi, Smooth_Hs, color=colors[4], label='H_s')
plt.xlabel('Energy (eV)')
plt.ylabel('DOS / Partial DOS')
plt.legend()
plt.xlim(-4,4)
#plt.savefig('%s-Smooth-DOS.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()

# Plot band structure
fig = plt.figure(figsize=(12,8))
plt.plot(Bands-Fermi, color='black')
plt.xlabel('K-Point Path', labelpad = 10)
plt.ylabel('Energy (eV)', labelpad = 3)
plt.ylim(-3,3)
plt.xlim(0,30)
plt.xticks([0,10,20,30], ['\u0393','K','M', '\u0393'])
plt.text(2, 0, 'Band Gap(%s) = %s eV' % (COF,Gap), color='black', fontsize=18)
#plt.savefig('%s-Band-Structure.jpeg' % COF,  bbox_inches='tight', pad_inches = 0.5, dpi=400)
plt.show()
