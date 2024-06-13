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
from AllenCore.algorithms import (downstream_lambdatoppi_line_t,
                                  downstream_kstopipi_line_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenCore.configuration_options import is_allen_standalone
from PyConf.tonic import configurable


@configurable
def make_downstream_kshort_line(downstream_tracks,
                                downstream_secondary_vertices,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                post_scaler=1.0,
                                mva_ks_threshold=0.5,
                                mva_detached_ks_threshold=0.5,
                                name='Hlt1DownstreamKsToPiPi',
                                enable_monitoring=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        downstream_kstopipi_line_t,
        name=name,
        minMass=497.6 - 80,
        maxMass=497.6 + 80,
        mva_ks_threshold=mva_ks_threshold,
        mva_detached_ks_threshold=mva_detached_ks_threshold,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        dev_downstream_mva_ks_t=downstream_secondary_vertices[
            'dev_downstream_mva_ks'],
        dev_downstream_mva_detached_ks_t=downstream_secondary_vertices[
            'dev_downstream_mva_detached_ks'],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=downstream_secondary_vertices[
            "host_number_of_svs"],
        dev_particle_container_t=downstream_secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        post_scaler=post_scaler)


@configurable
def make_downstream_lambda_line(downstream_tracks,
                                downstream_secondary_vertices,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                post_scaler=1.0,
                                mva_l0_threshold=0.5,
                                mva_detached_l0_threshold=0.5,
                                name='Hlt1DownstreamLambdaToPPi',
                                enable_monitoring=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        downstream_lambdatoppi_line_t,
        name=name,
        minMass=1115.7 - 25,
        maxMass=1115.7 + 25,
        mva_l0_threshold=mva_l0_threshold,
        mva_detached_l0_threshold=mva_detached_l0_threshold,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        dev_downstream_mva_l0_t=downstream_secondary_vertices[
            'dev_downstream_mva_l0'],
        dev_downstream_mva_detached_l0_t=downstream_secondary_vertices[
            'dev_downstream_mva_detached_l0'],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=downstream_secondary_vertices[
            "host_number_of_svs"],
        dev_particle_container_t=downstream_secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        post_scaler=post_scaler)
