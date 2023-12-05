import numpy as np
import math
import sys
import os

filename=sys.argv[1]
outfile=sys.argv[2]
numstreams=int(sys.argv[3])

a = np.loadtxt(filename, delimiter=',')
b=a

b[a<numstreams*math.pow(10,(-7))]=0

np.save(outfile,b)
