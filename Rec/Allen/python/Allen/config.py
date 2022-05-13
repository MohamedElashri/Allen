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
from Configurables import (ApplicationMgr, DumpUTGeometry, DumpFTGeometry,
                           DumpMuonTable, DumpMuonGeometry, DumpCaloGeometry,
                           DumpVPGeometry, DumpMagneticField, DumpBeamline,
                           DumpUTLookupTables, AllenUpdater)
from PyConf import configurable
from DDDB.CheckDD4Hep import UseDD4Hep

@configurable
def setup_allen_non_event_data_service(dump_geometry=False,
                                       out_dir="geometry"):
    """Setup Allen non-event data

    An ExtSvc is added to the ApplicationMgr to provide the Allen non-event
    data (geometries etc.)
    """
    from functools import partial
    ecal_location = "/dd/Structure/LHCb/DownstreamRegion/Ecal"
    # ecal_geom = partial(
    #     DumpCaloGeometry, name="DumpEcal", Location=ecal_location)
    producers = [
        p(DumpToFile=dump_geometry, OutputDirectory=out_dir)
        for p in (DumpUTGeometry, DumpMuonGeometry, DumpMuonTable,
                  DumpUTLookupTables)
    ]
    

    appMgr = ApplicationMgr()
    if not UseDD4Hep:
        # MagneticFieldSvc is required for non-DD4hep builds
        appMgr.ExtSvc.append("MagneticFieldSvc")
    appMgr.ExtSvc.extend(AllenUpdater())
    appMgr.ExtSvc.extend(producers)

