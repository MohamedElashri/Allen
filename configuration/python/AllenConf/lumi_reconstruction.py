###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
import json
from AllenCore.algorithms import data_provider_t, host_prefix_sum_t
from AllenCore.algorithms import (velo_lumi_counters_t, pv_lumi_counters_t,
                                  muon_lumi_counters_t, scifi_lumi_counters_t,
                                  calo_lumi_counters_t, calc_lumi_sum_size_t,
                                  make_lumi_summary_t)
from AllenCore.algorithms import muon_calculate_srq_size_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events, make_dummy
from AllenCore.generator import make_algorithm

from AllenConf.persistency import make_gather_selections

from PyConf.tonic import configurable
from PyConf.filecontent_metadata import _get_hash_for_text

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.scifi_reconstruction import decode_scifi
from AllenConf.muon_reconstruction import decode_muon, make_muon_stubs
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.calo_reconstruction import decode_calo


def findLine(lines, name):
    for i in range(len(lines)):
        if lines[i].name == name:
            return i, True
    return -1, False


def get_lumi_info(lumiInfos, name):
    if name in lumiInfos:
        return lumiInfos[name].dev_lumi_infos_t
    else:
        dummy = make_dummy()
        return dummy.dev_lumi_dummy_t


def lumi_summary_maker(lumiInfos, prefix_sum_lumi_size):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    # TODO generate key here, but it does not save the table anywhere
    # so it is not actual usable
    table = json.dumps({
        "version":
        0,
        "size":
        64,
        "counters": [{
            "name": "encodingKey",
            "offset": 0,
            "size": 32
        }, {
            "name": "T0Low",
            "offset": 32,
            "size": 32
        }, {
            "name": "T0High",
            "offset": 64,
            "size": 32
        }, {
            "name": "BCIDLow",
            "offset": 96,
            "size": 32
        }, {
            "name": "ECalEInnerTop",
            "offset": 128,
            "size": 22
        }, {
            "name": "SciFiClustersS1M45",
            "offset": 150,
            "size": 10
        }, {
            "name": "ECalEInnerBottom",
            "offset": 160,
            "size": 22
        }, {
            "name": "SciFiClustersS2M45",
            "offset": 182,
            "size": 10
        }, {
            "name": "ECalET",
            "offset": 192,
            "size": 21
        }, {
            "name": "VeloTracks",
            "offset": 213,
            "size": 11
        }, {
            "name": "ECalEMiddleTop",
            "offset": 224,
            "size": 21
        }, {
            "name": "SciFiClustersS3M45",
            "offset": 245,
            "size": 11
        }, {
            "name": "ECalEOuterTop",
            "offset": 256,
            "size": 21
        }, {
            "name": "MuonHitsM2R1",
            "offset": 277,
            "size": 10
        }, {
            "name": "GEC",
            "offset": 287,
            "size": 1
        }, {
            "name": "ECalEMiddleBottom",
            "offset": 288,
            "size": 21
        }, {
            "name": "MuonHitsM2R2",
            "offset": 309,
            "size": 10
        }, {
            "name": "ECalEOuterBottom",
            "offset": 320,
            "size": 21
        }, {
            "name": "MuonHitsM2R3",
            "offset": 341,
            "size": 9
        }, {
            "name": "BXType",
            "offset": 350,
            "size": 2
        }, {
            "name": "BCIDHigh",
            "offset": 352,
            "size": 14
        }, {
            "name": "SciFiClusters",
            "offset": 366,
            "size": 13
        }, {
            "name": "SciFiClustersS2M123",
            "offset": 384,
            "size": 13
        }, {
            "name": "SciFiClustersS3M123",
            "offset": 397,
            "size": 13
        }, {
            "name": "VeloVertices",
            "offset": 410,
            "size": 6
        }, {
            "name": "MuonHitsM3R1",
            "offset": 416,
            "size": 9
        }, {
            "name": "MuonHitsM4R3",
            "offset": 425,
            "size": 9
        }, {
            "name": "MuonHitsM2R4",
            "offset": 434,
            "size": 8
        }, {
            "name": "MuonHitsM3R2",
            "offset": 448,
            "size": 8
        }, {
            "name": "MuonHitsM3R3",
            "offset": 456,
            "size": 8
        }, {
            "name": "MuonHitsM4R1",
            "offset": 464,
            "size": 8
        }, {
            "name": "MuonHitsM4R4",
            "offset": 472,
            "size": 8
        }, {
            "name": "MuonHitsM3R4",
            "offset": 480,
            "size": 7
        }, {
            "name": "MuonHitsM4R2",
            "offset": 487,
            "size": 7
        }, {
            "name": "MuonTracks",
            "offset": 494,
            "size": 7
        }]
    })
    key = int(_get_hash_for_text(table)[:8], 16)

    return make_algorithm(
        make_lumi_summary_t,
        name="make_lumi_summary",
        encoding_key=key,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_lumi_summaries_size_t=prefix_sum_lumi_size.
        host_total_sum_holder_t,
        dev_lumi_summary_offsets_t=prefix_sum_lumi_size.dev_output_buffer_t,
        dev_odin_data_t=odin["dev_odin_data"],
        dev_velo_info_t=get_lumi_info(lumiInfos, "velo"),
        dev_pv_info_t=get_lumi_info(lumiInfos, "pv"),
        dev_scifi_info_t=get_lumi_info(lumiInfos, "scifi"),
        dev_muon_info_t=get_lumi_info(lumiInfos, "muon"),
        dev_calo_info_t=get_lumi_info(lumiInfos, "calo"))


def lumi_reconstruction(gather_selections,
                        lines,
                        lumiline_name,
                        with_muon=True,
                        with_velo=True,
                        with_SciFi=True,
                        with_calo=True):
    lumiLine_index, found = findLine(lines, lumiline_name)
    if not found:
        return []

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_scifi = decode_scifi()
    decoded_calo = decode_calo()
    pvs = make_pvs(velo_tracks)
    decoded_muon = decode_muon(empty_banks=not with_muon)
    if with_muon:
        muon_stubs = make_muon_stubs()

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

    lumiInfos = {}
    if with_velo:
        lumiInfos["velo"] = make_algorithm(
            velo_lumi_counters_t,
            name="velo_total_tracks",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
            dev_offsets_all_velo_tracks_t=velo_tracks[
                "dev_offsets_all_velo_tracks"])

        lumiInfos["pv"] = make_algorithm(
            pv_lumi_counters_t,
            "pv_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
            dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"])

    if with_SciFi:
        lumiInfos["scifi"] = make_algorithm(
            scifi_lumi_counters_t,
            "scifi_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
            dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"])

    if with_muon:
        lumiInfos["muon"] = make_algorithm(
            muon_lumi_counters_t,
            "muon_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_storage_station_region_quarter_offsets_t=decoded_muon[
                "dev_storage_station_region_quarter_offsets"],
            dev_muon_number_of_tracks_t=muon_stubs["dev_muon_number_of_tracks"])

    if with_calo:
        lumiInfos["calo"] = make_algorithm(
            calo_lumi_counters_t,
            "calo_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
            dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"])

    make_lumi_summary = lumi_summary_maker(lumiInfos, prefix_sum_lumi_size)

    return {
        "algorithms":
        [prefix_sum_lumi_size, *lumiInfos.values(), make_lumi_summary],
        "dev_lumi_summary_offsets":
        prefix_sum_lumi_size.dev_output_buffer_t,
        "dev_lumi_summaries":
        make_lumi_summary.dev_lumi_summaries_t
    }
