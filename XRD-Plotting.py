# Math/data analysis packages
import numpy as np
import pandas as pd

# Plotting pacakges
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from matplotlib import rcParams
import seaborn as sns

# Set plot formatting
rcParams.update({'figure.autolayout': True})
sns.set_style("whitegrid", rc={"axes.edgecolor": "k"})
sns.set_context("notebook", rc={"grid.linewidth":0, "font.family":"Helvetica", "axes.labelsize":22, "xtick.labelsize":22,\
                               "ytick.labelsize":20, "legend.fontsize":20, "axes.titlesize":22})

def LoadXRD(Filename):
    col_names = ['2 Theta', 'Intensity', 'n/a']
    Data = pd.read_csv(Filename, header=None, delim_whitespace=True, names=col_names)
    return Data

Hydrox_AA_Stag = LoadXRD('Hydroxy/Hydroxy-AA-Stag-v1.xy')
Hydrox_AB_Inclined = LoadXRD('Hydroxy/Hydroxy-AB-Inclined.xy')

fig = plt.figure(figsize=(12,8))

plt.plot(Hydrox_AB_Inclined['2 Theta'], Hydrox_AB_Inclined['Intensity']/max(Hydrox_AB_Inclined['Intensity']), linewidth=2, label='AB Inclined')
plt.plot(Hydrox_AA_Stag['2 Theta'], Hydrox_AA_Stag['Intensity']/max(Hydrox_AA_Stag['Intensity']), linewidth=2, label='AA Stag')

plt.ylabel('Intensity', labelpad=10)
plt.ylabel('Relative Intensity', labelpad=10)

plt.legend()
plt.xlim(3,30)
plt.show()