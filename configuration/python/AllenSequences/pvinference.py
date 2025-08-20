###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import PVinference_t
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from PyConf.control_flow import CompositeNode
from AllenCore.generator import generate, make_algorithm
import numpy as np

# Initialize number of events
number_of_events = initialize_number_of_events()

# Decode VELO
decoded_velo = decode_velo()

# Make VELO tracks
velo_tracks = make_velo_tracks(decoded_velo)

# Run VELO Kalman filter
velo_kalman_filter = run_velo_kalman_filter(velo_tracks)

# Create PVinference algorithm
pvinference = make_algorithm(
    PVinference_t,
    name="pvinference",
    host_number_of_events_t=number_of_events["host_number_of_events"],
    dev_number_of_events_t=number_of_events["dev_number_of_events"],
    dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
    dev_velo_kalman_beamline_states_t=velo_kalman_filter["dev_velo_kalman_beamline_states_view"],
    verbosity=3  # Enable verbose output for validation
)

# Create sequence
pvinference_sequence = CompositeNode("PVinference", [pvinference])

# Generate
generate(pvinference_sequence)
