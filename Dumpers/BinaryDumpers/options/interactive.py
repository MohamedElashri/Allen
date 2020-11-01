###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
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
