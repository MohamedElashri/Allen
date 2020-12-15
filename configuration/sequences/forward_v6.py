###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import VeloSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.algorithms import compose_sequences

velo_sequence = VeloSequence()

ut_sequence = UTSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
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
    velo_kalman_filter=velo_sequence["velo_kalman_filter"],
    forward_decoding="v6")

compose_sequences(velo_sequence, ut_sequence, forward_sequence).generate()
