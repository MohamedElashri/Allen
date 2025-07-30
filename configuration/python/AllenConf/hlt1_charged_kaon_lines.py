###############################################################################
# (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import kplus_to_three_tracks_line_t
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenCore.configuration_options import is_allen_standalone
from PyConf.tonic import configurable

#Cuts for k2pimumu
minIP_k2pimumu = 0.5
minFD_k2pimumu = 0.0
minP_k2pimumu = 3000
massWindow_k2pimumu_min = 30
massWindow_k2pimumu_max = 30

#Cuts for k2pipipi
minPt = 80.0
mincomPt = 100.0
minIP = 0.5
minFD = 0.0
minP = 3000
massWindow_min = 60
massWindow_max = 130

#Cuts for k2piee
minPt_k2piee = 80.0
mincomPt_k2piee = 100.0
minIP_k2piee = 0.5
minFD_k2piee = 0.0
minP_k2piee = 3000
massWindow_min_k2piee = 100
massWindow_max_k2piee = 50


def make_kplus_to_piee_line(kplus_to_three_tracks,
                            name="Hlt1Kplus2PiEE",
                            enable_monitoring=True,
                            enable_tupling=False,
                            pre_scaler_hash_string=None,
                            post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        kplus_to_three_tracks_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        is_dielectron=True,
        mass_seed_track_one=0.51099891,
        mass_seed_track_two=0.51099891,
        massWindow_min=massWindow_min_k2piee,
        massWindow_max=massWindow_max_k2piee,
        minTrackIP=minIP_k2piee,
        minTrackPt=minPt,
        minTrackP=minP_k2piee,
        minComboPt=mincomPt_k2piee,
        minFlightDistance=minFD_k2piee,
        minPairMass=50.,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=kplus_to_three_tracks[
            "host_number_of_three_body_svs"],
        dev_particle_container_t=kplus_to_three_tracks["dev_three_body_svs"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_kplus_to_pimumu_line(kplus_to_three_tracks,
                              name="Hlt1Kplus2PiMuMu",
                              enable_monitoring=True,
                              enable_tupling=False,
                              pre_scaler_hash_string=None,
                              post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        kplus_to_three_tracks_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        is_dimuon=True,
        mass_seed_track_one=105.65837,
        mass_seed_track_two=105.65837,
        massWindow_min=massWindow_k2pimumu_min,
        massWindow_max=massWindow_k2pimumu_max,
        minTrackIP=minIP_k2pimumu,
        minTrackPt=minPt,
        minTrackP=minP_k2pimumu,
        minComboPt=mincomPt,
        minFlightDistance=minFD_k2pimumu,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=kplus_to_three_tracks[
            "host_number_of_three_body_svs"],
        dev_particle_container_t=kplus_to_three_tracks["dev_three_body_svs"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_kplus_to_3pi_line(kplus_to_three_tracks,
                           name="Hlt1Kplus2PiPiPi",
                           enable_monitoring=True,
                           enable_tupling=False,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           pre_scaler=0.01):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        kplus_to_three_tracks_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        massWindow_min=massWindow_min,
        massWindow_max=massWindow_max,
        minTrackIP=minIP,
        minTrackPt=minPt,
        minTrackP=minP,
        minComboPt=mincomPt,
        minFlightDistance=minFD,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=kplus_to_three_tracks[
            "host_number_of_three_body_svs"],
        dev_particle_container_t=kplus_to_three_tracks["dev_three_body_svs"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        pre_scaler=pre_scaler)
