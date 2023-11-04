# Python function for importing XRD data exported from VESTA in a .xy file type
# This imports the data as a Pandas dataframe
# Column 1 is the 2Theta values, Column 2 is intensity, and Column 3 can be marked as N/A

import pandas as pd

def LoadXRD(Filename):
    col_names = ['2 Theta', 'Intensity', 'n/a']
    Data = pd.read_csv(Filename, header=None, delim_whitespace=True, engine='python', names=col_names)
    return Data