###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from __future__ import print_function
from Gaudi.Configuration import importOptions

importOptions("options.py")
importOptions("upgrade-minbias-magdown.py")

from GaudiPython.Bindings import gbl, AppMgr

gaudi = AppMgr()
gaudi.initialize()

TES = gaudi.evtSvc()

gaudi.run(1)

coords = TES['Raw/Muon/Coords'].containedObjects()
print(coords[0])
