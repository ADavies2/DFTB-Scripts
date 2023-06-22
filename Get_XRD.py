import pandas as pd

def LoadXRD(Filename):
    col_names = ['2 Theta', 'Intensity', 'n/a']
    Data = pd.read_csv(Filename, header=None, delim_whitespace=True, engine='python', names=col_names)
    return Data
