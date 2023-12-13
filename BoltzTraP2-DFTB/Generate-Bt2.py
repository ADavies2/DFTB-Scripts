# This Python script was NOT written by me! This was written by a collaborator of Dr. Oliveira and Masoumeh Mahmoudi
# The original script was called mof.py. I have edited their script to run as a command line executable with a more descriptive name.
# The output of this script is the COF_BLTZTRP.bt2 file 

#!/usr/bin/env python

import copy
import os.path

import ase
import ase.io
import matplotlib.pylab as plt
import numpy as np
#from environment import data_dir

import BoltzTraP2.bandlib as BL
import BoltzTraP2.dft as BTP
import BoltzTraP2.io as IO
from BoltzTraP2 import fite, serialization, sphere, units
from BoltzTraP2.misc import ffloat
from BoltzTraP2.units import *

# Directory containing the data
data_dir1 = os.path.join("./")
radix = "COF_BLZTRP"

niter = 10
# If a pregenerated bt2 file with the interpolation exists, read it. Otherwise,
# perform the interpolation and create the file.
bt2filnam = radix + ".bt2"
if os.path.isfile(bt2filnam):
    print("Loading the precalculated results from", bt2filnam)
    data, equivalences, coeffs, metadata = serialization.load_calculation(
        bt2filnam
    )
    print("done")
else:
    print("No pregenerated bt2 file found; performing a new interpolation")
    data = BTP.DFTData(data_dir1)
    equivalences = sphere.get_equivalences(
        data.atoms, data.magmom, niter * len(data.kpoints)
    )
    print(
        "There are",
        len(equivalences),
        "equivalence classes in the output grid",
    )
    coeffs = fite.fitde3D(data, equivalences)
    serialization.save_calculation(
        radix + ".bt2",
        data,
        equivalences,
        coeffs,
        serialization.gen_bt2_metadata(data, data.mommat is not None),
    )

lattvec = data.get_lattvec()
eband, vvband, cband = fite.getBTPbands(
    equivalences, coeffs, lattvec, curvature=False
)

npts = 5000
Cepsilon, Cdos, Cvvdos, cdos = BL.BTPDOS(eband, vvband, npts=npts)

Tr = np.linspace(200.0, 600.0, num=17)
margin = 9.0 * units.BOLTZMANN * Tr.max()
mur_indices = np.logical_and(
    Cepsilon > Cepsilon.min() + margin, Cepsilon < Cepsilon.max() - margin
)
mur = Cepsilon[mur_indices]

N, L0, L1, L2, Lm11 = BL.fermiintegrals(Cepsilon, Cdos, Cvvdos, mur=mur, Tr=Tr)
Csigma, Cseebeck, kappa, Hall = BL.calc_Onsager_coefficients(
    L0, L1, L2, mur, Tr, data.get_volume()
)


# Interpolate the relaxation times to the denser grid using the same procedure
# as for the bands themselves.
def read_tauk(filename):
    """Read in data about electron lifetimes on the sparse grids.

    Args:
        filename: path to the file to be read

    Returns:
        An array of scattering rates.
    """
    lines = open(filename, "r", encoding="ascii").readlines()
    # line 1: title string
    # line 2: nk, nspin, Fermi level(Ry)
    linenumber = 1
    tmp = lines[linenumber].split()
    nk, nspin, efermi = int(tmp[0]), int(tmp[1]), float(tmp[2])
    minband = np.infty
    tau = []
    kpoints = []
    for ik in range(nk):
        # k block: line 1 = kx ky kz nband
        linenumber += 1
        tmp = lines[linenumber].split()
        nband = int(tmp[3])
        if nband < minband:
            minband = nband
        kpoints += [np.array(list(map(float, tmp[0:3])))]
        ttau = []
        for ib in range(nband):
            linenumber += 1
            e = ffloat(lines[linenumber].split()[0])
            ttau.append(e)
        tau.append(ttau)
    taus = np.zeros((len(kpoints), minband))
    for i in range(len(kpoints)):
        taus[i] = tau[i][:minband]
    return taus.T


tauDFT = read_tauk(os.path.join(data_dir1, radix + ".tau_k"))
pseudodata = copy.deepcopy(data)
pip = list(range(1, 10)) + list(range(11, 25))
pseudodata.ebands = tauDFT[:, pip]
pseudodata.kpoints = data.kpoints[pip]
pseudocoeffs = fite.fitde3D(pseudodata, equivalences)
tau = fite.getBTPbands(equivalences, pseudocoeffs, lattvec, curvature=False)[0]

epsilon, dos, vvdos, cdos = BL.BTPDOS(
    eband, vvband, npts=npts, scattering_model=tau
)
N, L0, L1, L2, Lm11 = BL.fermiintegrals(epsilon, dos, vvdos, mur=mur, Tr=Tr)
sigma, seebeck, kappa, Hall = BL.calc_Onsager_coefficients(
    L0, L1, L2, mur, Tr, data.get_volume()
)

ctau = np.mean(tau[0])
ii = np.nonzero(N[4] < -1)[0]  # 4 should be 300K
ifermi = ii[0]
Efermi = mur[ifermi]

#Scaled using the examples files for parabolic case

no_e = 96
print(Meter, units.eV)
for i in range(len(seebeck[4, :, 0, 0 ] )):
	print((mur[i] - Efermi) / units.eV, -N[0, ...][i] / (1.0*96 / (Meter / 100.0) ** 3), seebeck[4, :, 0, 0][i]*1e6/3, sigma[4, :, 0, 0][i]*1e-3/3 )

quit()

print("CRTA", Cseebeck[4, ifermi, 0, 0] * 1e6)
print("el-ph", seebeck[4, ifermi, 0, 0] * 1e6)
#print("Model", Mseebeck[4, ifermi, 0, 0] * 1e6)