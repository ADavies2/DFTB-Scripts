# This Python script is an example of plotting XRD data
# It plots .xy files from VESTA and Excel spreadsheets
# Be sure to read through this script carefully before use in order to change variables where appropriate for your own data

import pandas as pd

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

def LoadXRD(Filename):
    col_names = ['2 Theta', 'Intensity', 'n/a']
    Data = pd.read_csv(Filename, header=None, delim_whitespace=True, engine='python', names=col_names)
    return Data

cof1_aa = LoadXRD('KCK-COF1/AA-Inclined/COF1-AA.xy') # Use the LoadXRD function to read .xy files generated from VESTA
cof1_exp = pd.read_excel('KCK-COF1/Experimental-XRD.xlsx', header=None, skiprows=1, usecols='A,B', names=['2 Theta', 'Intensity']) # This line uses the pandas function read_excel to read an Excel spreadsheet with XRD data
# Be sure to update the usecols to reflect which columns contain the XRD data (2Theta and Intensity, respectively)
# This line also assumes that the first row in both columns is the label and not numerical data, so it is skipped

fig = plt.figure(figsize=(12,8))
plt.plot(cof1_ab['2 Theta'], cof1_ab['Intensity']/max(cof1_ab['Intensity']), label='Sim.', linewidth=3)
plt.plot(cof1_exp['2 Theta'], cof1_exp['Intensity']/max(cof1_exp['Intensity']), label='Exp.', linewidth=3)
plt.legend()
plt.xlim(3,40)
plt.yticks([])
plt.ylabel('Relative Intensity', labelpad=10)
plt.xlabel('2\u03B8 (degrees)', labelpad=10)
#plt.savefig('./KCK-COF1/XRD-Comparison.png', dpi=400)
plt.show()