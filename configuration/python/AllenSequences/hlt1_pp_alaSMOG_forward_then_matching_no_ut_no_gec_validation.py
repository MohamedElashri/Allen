###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node, default_SMOG2_lines
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line, make_SMOG2_dimuon_highmass_line
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.utils import make_checkPV
from AllenConf.primary_vertex_reconstruction import make_pvs

with make_pvs.bind(zmin=-845., SMOG2_pp_separation=-300., Nbins=4608):
    with make_checkPV.bind(min_z=-717., max_z=-300.):
        with default_SMOG2_lines.bind(min_z=-717., max_z=-300.):
            with make_SMOG2_minimum_bias_line.bind(min_z=-717., max_z=-300.):
                with make_SMOG2_dimuon_highmass_line.bind(
                        enable_monitoring=True,
                        histogram_smogdimuon_svz_min=-717.,
                        histogram_smogdimuon_svz_max=-300.,
                        histogram_smogdimuon_svz_nbins=200):
                    hlt1_node = setup_hlt1_node(
                        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
                        with_ut=False,
                        withSMOG2=True,
                        EnableGEC=False,
                        withMCChecking=True)

                    generate(hlt1_node)
