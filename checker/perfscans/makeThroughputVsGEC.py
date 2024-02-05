###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import os, sys, fnmatch
import ROOT
from ROOT import *
import re

bins = [0, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 25000]
tpts = [
    247678, 229501, 204182, 182705, 169174, 156493, 157174, 166272, 191051,
    145908
]
geceffs = [
    0.049, 0.110, 0.136, 0.148, 0.142, 0.136, 0.107, 0.056, 0.047, 0.067
]

for i, j in enumerate(tpts):
    print tpts[i] * geceffs[i]
