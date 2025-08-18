###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
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
from AllenCore.algorithms import PVInference_t
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

def make_pv_inference(velo_tracks, velo_states):
    """Create PVInference algorithm instance"""
    number_of_events = initialize_number_of_events()
    return make_algorithm(
        PVInference_t,
        name="pv_inference",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states["dev_velo_kalman_beamline_states_view"],
        # Algorithm properties
        max_tracks_per_event=2048,
        enable_debug=False,
        z_min=-100.0,
        z_max=300.0
    )

def pv_inference_reconstruction():
    """Complete PVInference reconstruction sequence"""
    # Step 1: Decode Velo hits
    decoded_velo = decode_velo()
    
    # Step 2: Reconstruct Velo tracks  
    velo_tracks = make_velo_tracks(decoded_velo)
    
    # Step 3: Run Kalman filter to get track states
    velo_states = run_velo_kalman_filter(velo_tracks)
    
    # Step 4: Run PVInference algorithm
    pv_inference = make_pv_inference(velo_tracks, velo_states)
    
    return pv_inference

# Create the main sequence
pv_inference_algorithm = pv_inference_reconstruction()

pv_inference_sequence = CompositeNode(
    "PVInferenceTest", 
    [pv_inference_algorithm],
    NodeLogic.LAZY_AND,
    force_order=True
)

generate(pv_inference_sequence)
