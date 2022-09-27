###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import data_provider_t, host_prefix_sum_t
from AllenAlgorithms.algorithms import calc_lumi_sum_size_t, make_lumi_summary_t
from AllenAlgorithms.algorithms import muon_calculate_srq_size_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.scifi_reconstruction import decode_scifi
from AllenConf.muon_reconstruction import decode_muon
from AllenConf.primary_vertex_reconstruction import make_pvs

from AllenConf.persistency import make_gather_selections


def findLine(lines, name):
    for i in range(len(lines)):
        if lines[i].name == name:
            return i, True
    return -1, False


def lumi_reconstruction(gather_selections,
                        lines,
                        lumiline_name,
                        with_muon=True):
    lumiLine_index, found = findLine(lines, lumiline_name)
    if not found:
        return []

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_scifi = decode_scifi()
    pvs = make_pvs(velo_tracks)
    decoded_muon = decode_muon(empty_banks=not with_muon)

    calc_lumi_sum_size = make_algorithm(
        calc_lumi_sum_size_t,
        name="calc_lumi_sum_size",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        line_index=lumiLine_index)

    prefix_sum_lumi_size = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_lumi_size",
        dev_input_buffer_t=calc_lumi_sum_size.dev_lumi_sum_sizes_t)

    make_lumi_summary = make_algorithm(
        make_lumi_summary_t,
        name="make_lumi_summary",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_lumi_summaries_size_t=prefix_sum_lumi_size.
        host_total_sum_holder_t,
        dev_lumi_summary_offsets_t=prefix_sum_lumi_size.dev_output_buffer_t,
        dev_odin_data_t=odin["dev_odin_data"],
        dev_offsets_all_velo_tracks_t=velo_tracks[
            "dev_offsets_all_velo_tracks"],
        dev_number_of_pvs_t=pvs["dev_number_of_zpeaks"],
        dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
        dev_storage_station_region_quarter_offsets_t=decoded_muon[
            "dev_storage_station_region_quarter_offsets"])

    return make_lumi_summary
