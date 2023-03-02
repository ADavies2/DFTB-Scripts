# This scrip automatically runs DFTB+ jobs with a pre-set configuration of nodes/cpus/tasks. 
# The final output includes data from DFTB+ directly and from SLURM. This includes:
# The CPU time for each step of the calculation (from DFTB+)
# The maximum number of bytes read, maximum number of bytes written, maximum resident set size (memory), maximum virtual memory size
# The number of CPUs, Nodes, and Tasks and the total CPU time (from SLURM)

