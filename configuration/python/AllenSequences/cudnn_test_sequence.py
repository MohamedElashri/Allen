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

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from AllenCore.algorithms import (
    data_provider_t,
    cudnn_basic_convolution_t,
)
from AllenCore.generator import make_algorithm, generate
from PyConf.control_flow import NodeLogic, CompositeNode

# Initialize number of events
number_of_events = initialize_number_of_events()

# VELO reconstruction pipeline
decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)

# CuDNN integration algorithm
cudnn_basic_convolution = make_algorithm(
    cudnn_basic_convolution_t,
    name="cudnn_basic_convolution",
    host_number_of_events_t=number_of_events["host_number_of_events"],
    dev_number_of_events_t=number_of_events["dev_number_of_events"],
    dev_offsets_all_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
    dev_offsets_velo_track_hit_number_t=velo_tracks["dev_offsets_velo_track_hit_number"],
    input_channels=1,
    output_channels=32,
    kernel_size=3,
    input_width=64,
    input_height=64,
    block_dim=(32, 1, 1)
)

# The algorithms are automatically extracted from the reconstruction functions
# We just need to include the CuDNN algorithm in the sequence
hlt1_node = CompositeNode(
    "CuDNNTestSequence", [cudnn_basic_convolution], NodeLogic.NONLAZY_AND, force_order=True)

# Generate the sequence configuration
generate(hlt1_node)
