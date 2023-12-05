import numpy as np
import sys
import os

filename=sys.argv[1]
outfile=sys.argv[2]

a = np.loadtxt(filename, delimiter=',')
np.save(outfile,a)
