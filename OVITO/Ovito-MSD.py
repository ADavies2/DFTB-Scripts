# This Python script interfaces with OVITO to calculate the mean squared displacement (MSD). In this particular example, it is of the type = 2 atom, which is oxygen. Prior to running this script, the oxygen atoms within the framework were deleted, in order to only calculate the mean squared displacement of the oxygen-water atoms. 
# The user will first need to calculate the displacement vectors using the built-in OVITO function. Then, run this Python script. 
# The self-diffusion coefficient can be calculated from the slope of the MSD against the time. This data can be quickly obtained from OVITO using the built-in function "Time Series". This will generate a text file or data plot of the MSD over the animation length. This animation length will need to be converted to time units based on the length of time of your simulation. 

from ovito.data import *
import numpy

def modify(frame, data):
    # Access the per-particle displacement magnitudes computed by the 
    # 'Displacement Vectors' modifier preceding this user-defined modifier in the 
    # data pipeline:
    ptypes = data.particles_.particle_types_
    
    displacement_magnitudes = data.particles['Displacement Magnitude']

    # Compute MSD:
    msd = numpy.sum(displacement_magnitudes[ptypes == 2] ** 2) / len(displacement_magnitudes[ptypes == 2])

    # Output value as a global attribute to make it available within OVITO:
    data.attributes["Oxygen MSD"] = msd
