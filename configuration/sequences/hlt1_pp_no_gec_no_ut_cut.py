###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.MuonSequence import MuonSequence
from definitions.HLT1Sequence import HLT1Sequence
from definitions.algorithms import compose_sequences

velo_sequence = VeloSequence(doGEC=False)

pv_sequence = PVSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

ut_sequence = UTSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    restricted=False,
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

forward_sequence = ForwardSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

muon_sequence = MuonSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks_t=forward_sequence["scifi_consolidate_tracks_t"])

hlt1_sequence = HLT1Sequence(
    layout_provider=velo_sequence["mep_layout"],
    initialize_lists=velo_sequence["initialize_lists"],
    full_event_list=velo_sequence["full_event_list"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_kalman_filter=pv_sequence["velo_kalman_filter"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    pv_beamline_multi_fitter=pv_sequence["pv_beamline_cleanup"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks=forward_sequence["scifi_consolidate_tracks_t"],
    is_muon=muon_sequence["is_muon_t"])

compose_sequences(velo_sequence, pv_sequence, ut_sequence, forward_sequence,
                  muon_sequence, hlt1_sequence).generate()
