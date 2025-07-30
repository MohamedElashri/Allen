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
from AllenCore.algorithms import (
    data_provider_t, muon_calculate_srq_size_t, muon_populate_tile_and_tdc_t,
    muon_add_coords_crossing_maps_t, muon_populate_hits_t, is_muon_t,
    empty_lepton_id_t, find_muon_hits_t, consolidate_muon_t,
    muon_consolidate_tracks_t, muonid_nn_t, chi2_muon_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def decode_muon(empty_banks=False):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    muon_banks = make_algorithm(
        data_provider_t,
        name="muon_banks_{hash}",
        bank_type="Muon",
        empty=empty_banks)

    muon_calculate_srq_size = make_algorithm(
        muon_calculate_srq_size_t,
        name='muon_calculate_srq_size_{hash}',
        host_number_of_events_t=host_number_of_events,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t,
        dev_muon_raw_sizes_t=muon_banks.dev_raw_sizes_t,
        dev_muon_raw_types_t=muon_banks.dev_raw_types_t,
        host_raw_bank_version_t=muon_banks.host_raw_bank_version_t)

    muon_populate_tile_and_tdc = make_algorithm(
        muon_populate_tile_and_tdc_t,
        name='muon_populate_tile_and_tdc_{hash}',
        host_number_of_events_t=host_number_of_events,
        host_muon_total_number_of_tiles_t=muon_calculate_srq_size.
        host_total_sum_holder_t,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t,
        dev_muon_raw_sizes_t=muon_banks.dev_raw_sizes_t,
        dev_muon_raw_types_t=muon_banks.dev_raw_types_t,
        dev_storage_station_region_quarter_offsets_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_offsets_t,
        host_raw_bank_version_t=muon_banks.host_raw_bank_version_t)

    muon_add_coords_crossing_maps = make_algorithm(
        muon_add_coords_crossing_maps_t,
        name='muon_add_coords_crossing_maps_{hash}',
        host_number_of_events_t=host_number_of_events,
        host_muon_total_number_of_tiles_t=muon_calculate_srq_size.
        host_total_sum_holder_t,
        dev_storage_station_region_quarter_offsets_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_offsets_t,
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.dev_storage_tile_id_t,
        host_raw_bank_version_t=muon_banks.host_raw_bank_version_t,
        dev_muon_tile_used_t=muon_populate_tile_and_tdc.dev_muon_tile_used_t,
        dev_station_ocurrences_offset_t=muon_populate_tile_and_tdc.
        dev_station_ocurrences_offset_t,
        host_muon_total_number_of_hits_t=muon_populate_tile_and_tdc.
        host_total_sum_holder_t)

    muon_populate_hits = make_algorithm(
        muon_populate_hits_t,
        name='muon_populate_hits_{hash}',
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_muon_total_number_of_hits_t=muon_populate_tile_and_tdc.
        host_total_sum_holder_t,
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.dev_storage_tile_id_t,
        dev_storage_tdc_value_t=muon_populate_tile_and_tdc.
        dev_storage_tdc_value_t,
        dev_station_ocurrences_offset_t=muon_populate_tile_and_tdc.
        dev_station_ocurrences_offset_t,
        dev_muon_compact_hit_t=muon_add_coords_crossing_maps.
        dev_muon_compact_hit_t,
        dev_storage_station_region_quarter_offsets_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_offsets_t)

    return {
        "dev_storage_station_region_quarter_offsets":
        muon_calculate_srq_size.dev_storage_station_region_quarter_offsets_t,
        "dev_muon_hits":
        muon_populate_hits.dev_muon_hits_t,
        "dev_station_ocurrences_offset":
        muon_populate_tile_and_tdc.dev_station_ocurrences_offset_t,
        "host_raw_bank_version":
        muon_banks.host_raw_bank_version_t,
        "dev_muon_tell_number":
        muon_populate_tile_and_tdc.dev_muon_tell_number_t
    }


def make_is_muon(decoded_muon,
                 host_number_of_tracks,
                 dev_multi_event_tracks_ptr,
                 dev_velo_states,
                 dev_scifi_states,
                 is_muon_name='is_muon'):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    is_muon = make_algorithm(
        is_muon_t,
        name=str(is_muon_name),
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=host_number_of_tracks,
        dev_scifi_states_t=dev_scifi_states,
        dev_tracks_view_t=dev_multi_event_tracks_ptr,
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_velo_states_view_t=dev_velo_states,
        dev_muon_hits_t=decoded_muon["dev_muon_hits"])

    return {
        "dev_is_muon": is_muon.dev_is_muon_t,
        "dev_lepton_id": is_muon.dev_lepton_id_t
    }


def is_muon(decoded_muon, long_tracks, is_muon_name='is_muon'):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_scifi_tracks = long_tracks[
        "host_number_of_reconstructed_scifi_tracks"]
    dev_scifi_states = long_tracks["dev_scifi_states"]
    velo_kalman_filter = long_tracks["velo_kalman_filter"]

    is_muon = make_algorithm(
        is_muon_t,
        name=str(is_muon_name),
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_scifi_states_t=dev_scifi_states,
        dev_tracks_view_t=long_tracks["dev_multi_event_long_tracks_ptr"],
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_velo_states_view_t=velo_kalman_filter[
            "dev_velo_kalman_endvelo_states_view"],
        dev_muon_hits_t=decoded_muon["dev_muon_hits"])

    muon_consolidate_tracks = make_algorithm(
        muon_consolidate_tracks_t,
        name='consolidate_is_muon_{hash}',
        host_number_of_events_t=host_number_of_events,
        host_number_of_hits_in_muon_tracks_t=is_muon.host_total_sum_holder_t,
        host_number_of_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_number_of_events_t=dev_number_of_events,
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_muon_idxs_t=is_muon.dev_muon_idxs_t,
        dev_muon_hits_data_t=decoded_muon["dev_muon_hits"],
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_muon_hit_offsets_t=is_muon.dev_muon_hit_offsets_t)

    # Update long tracks.
    long_tracks[
        "dev_multi_event_long_tracks_view"] = muon_consolidate_tracks.dev_multi_event_muon_long_tracks_view_t
    long_tracks[
        "dev_multi_event_long_tracks_ptr"] = muon_consolidate_tracks.dev_multi_event_muon_long_tracks_ptr_t
    long_tracks[
        "dev_multi_event_long_track_view"] = muon_consolidate_tracks.dev_muon_long_track_view_t

    return {
        "long_tracks":
        long_tracks,
        "dev_is_muon":
        is_muon.dev_is_muon_t,
        "dev_lepton_id":
        is_muon.dev_lepton_id_t,
        "dev_muon_hits_view":
        muon_consolidate_tracks.dev_muon_hits_view_t,
        "dev_muon_track_view":
        muon_consolidate_tracks.dev_muon_track_view_t,
        "dev_muon_tracks_view":
        muon_consolidate_tracks.dev_muon_tracks_view_t,
        "dev_muon_multi_event_tracks_view":
        muon_consolidate_tracks.dev_muon_multi_event_tracks_view_t,
    }


def chi2muon(long_tracks, is_muon):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_scifi_tracks = long_tracks[
        "host_number_of_reconstructed_scifi_tracks"]
    dev_scifi_states = long_tracks["dev_scifi_states"]
    chi2muon = make_algorithm(
        chi2_muon_t,
        name='chi2_muon_{hash}',
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_scifi_states_t=dev_scifi_states,
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_is_muon_t=is_muon['dev_is_muon'])

    return {"dev_chi2corr": chi2muon.dev_chi2_muon_t}


def fake_muon_id(host_number_of_tracks):
    number_of_events = initialize_number_of_events()
    empty_muon_id = make_algorithm(
        empty_lepton_id_t,
        name='empty_muon_id_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_scifi_tracks_t=host_number_of_tracks)

    return {
        "dev_is_muon": empty_muon_id.dev_is_lepton_t,
        "dev_lepton_id": empty_muon_id.dev_lepton_id_t,
        "dev_chi2corr": empty_muon_id.dev_chi2_muon_t,
    }


def muon_id(algorithm_name=''):
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
    from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
    from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks

    if (algorithm_name != ''): algorithm_name = algorithm_name + '_'
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    long_tracks = make_forward_tracks(
        decoded_scifi,
        ut_tracks,
        decoded_ut,
        velo_tracks["dev_accepted_velo_tracks"],
        scifi_consolidate_tracks_name=algorithm_name +
        'scifi_consolidate_tracks_muon_id')
    decoded_muon = decode_muon()
    muonID = is_muon(
        decoded_muon, long_tracks, is_muon_name=algorithm_name + 'is_muon')
    alg = muonID["dev_is_muon"].producer
    return alg


def make_muon_stubs(monitoring=False):
    number_of_events = initialize_number_of_events()
    decoded_muon = decode_muon()

    find_muon_hits = make_algorithm(
        find_muon_hits_t,
        name='find_muon_hits_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_muon_hits_t=decoded_muon["dev_muon_hits"],
        enable_tupling=monitoring)

    consolidate_muon = make_algorithm(
        consolidate_muon_t,
        name='consolidate_muon_t_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_muon_tracks_input_t=find_muon_hits.dev_muon_tracks_t,
        dev_muon_tracks_offsets_t=find_muon_hits.dev_muon_tracks_offsets_t,
        host_muon_total_number_of_tracks_t=find_muon_hits.
        host_muon_total_number_of_tracks_t,
    )

    return {
        "dev_muon_tracks_output":
        consolidate_muon.dev_muon_tracks_output_t,
        "consolidated_muon_tracks":
        consolidate_muon.dev_muon_tracks_output_t,
        "host_muon_total_number_of_tracks":
        find_muon_hits.host_muon_total_number_of_tracks_t,
        "dev_muon_tracks_offsets":
        find_muon_hits.dev_muon_tracks_offsets_t
    }


def muonid_nn(long_tracks, muon_id, decoded_muon):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_scifi_tracks = long_tracks[
        "host_number_of_reconstructed_scifi_tracks"]
    dev_scifi_states = long_tracks["dev_scifi_states"]
    dev_velo_states = long_tracks["velo_kalman_filter"][
        "dev_velo_kalman_endvelo_states_view"]

    chi2muon = make_algorithm(
        chi2_muon_t,
        name='chi2_muon_{hash}',
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_scifi_states_t=dev_scifi_states,
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        dev_is_muon_t=muon_id['dev_is_muon'])

    muonid_nn = make_algorithm(
        muonid_nn_t,
        name='muonid_nn_{hash}',
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_scifi_states_t=dev_scifi_states,
        dev_velo_states_t=dev_velo_states,
        dev_is_muon_t=muon_id['dev_is_muon'],
        dev_chi2_muon_t=chi2muon.dev_chi2_muon_t,
        dev_chi2uncorr_muon_t=chi2muon.dev_chi2uncorr_muon_t,
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
    )
    return {
        "dev_muonidnn": muonid_nn.dev_muonid_evaluation_t,
        "dev_chi2corr": chi2muon.dev_chi2_muon_t,
        "dev_chi2uncorr_muon": chi2muon.dev_chi2uncorr_muon_t,
    }
