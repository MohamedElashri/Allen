###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from MuonSequence import is_muon

is_muon_result = is_muon()
is_muon_result["dev_is_muon"].producer.configuration().apply()
