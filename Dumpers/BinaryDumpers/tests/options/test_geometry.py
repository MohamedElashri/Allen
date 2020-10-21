###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from Configurables import LHCbApp, TestMuonTable

app = LHCbApp()
tmt = TestMuonTable()
tmt.MuonTable = "geometry/muon_table_%s_%s.bin" % (app.DDDBtag, app.CondDBtag)
