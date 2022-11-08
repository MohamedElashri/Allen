###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import heavy_ion_event_line_t
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_heavy_ion_event_line(velo_tracks,
                              pvs,
                              calo_decoding,
                              pre_scaler_hash_string="heavy_ion_pre",
                              post_scaler_hash_string="heavy_ion_post",
                              min_velo_tracks_PbPb=-1,
                              max_velo_tracks_PbPb=-1,
                              min_velo_tracks_SMOG=-1,
                              max_velo_tracks_SMOG=-1,
                              min_pvs_PbPb=-1,
                              max_pvs_PbPb=-1,
                              min_pvs_SMOG=-1,
                              max_pvs_SMOG=-1,
                              min_ecal_e=0.,
                              max_ecal_e=-1.,
                              name="Hlt1HeavyIon",
                              pre_scaler = 1.):

    velo_states = run_velo_kalman_filter(velo_tracks)
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    return make_algorithm(
        heavy_ion_event_line_t,
        name=name,
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        dev_velo_tracks_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_t=velo_states["dev_velo_kalman_beamline_states_view"],
        dev_total_ecal_e_t=calo_decoding["dev_total_ecal_e"],
        dev_pvs_t=pvs["dev_multi_final_vertices"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        min_velo_tracks_PbPb=min_velo_tracks_PbPb,
        max_velo_tracks_PbPb=max_velo_tracks_PbPb,
        min_velo_tracks_SMOG=min_velo_tracks_SMOG,
        max_velo_tracks_SMOG=max_velo_tracks_SMOG,
        min_pvs_PbPb=min_pvs_PbPb,
        max_pvs_PbPb=max_pvs_PbPb,
        min_pvs_SMOG=min_pvs_SMOG,
        max_pvs_SMOG=max_pvs_SMOG,
        min_ecal_e=min_ecal_e,
        max_ecal_e=max_ecal_e,
        pre_scaler = pre_scaler)
