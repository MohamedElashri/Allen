###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.muon_reconstruction import decode_muon
from AllenCore.generator import generate

generate(decode_muon()["dev_muon_hits"].producer)
