# This bash script will run through a series of user-defined tolerances with DFTB+ to relax framework geometries.
# This version will initialize an SCC calculation at the user-defined tolerance. Then, it will check for the outputs GEOMETRY CONVERGED in detailed.out
# and $JOBNAME.log. If this message is present in both output files, the script will copy all of the generated output data (detailed.out, *.gen, *.xyz, 
# charges.bin, and $JOBNAME.log) into a separate directory under the tolerance value these were generated at. If GEOMETRY CONVERGED is NOT found in these
# output files, then the script will search for "SCC did NOT converge". If this message occurs, the script will then re-write the dftb_in.hsd script 
# to run a forces-only calculation at the same user-defined tolerance. This changes the SCC=Yes to SCC=No, and comments out all commands associated 
# with an SCC calculation so as not to produce errors. Then, it will submit another job called $COF-forces-$TOL. A similar loop as previously described 
# will then occur; the script will check for "Geometry converged" in detailed.out and $COF-forces-$TOL.log. If this message is found, then the script
# copies the generated output files into a directory called $TOL-Forces. After this point, it exits the while loop. If this message is NOT found and 
# rather the script finds "Geometry did NOT converge", then the script will exit the while loop, generating an error message and stopping the entire bash
# job.
# In future versions, additional failsafes/tests to converge SCC and Forces will be implemented after a forces-only job does not converge.

