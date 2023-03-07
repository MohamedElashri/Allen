###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
import json
from AllenCore.algorithms import data_provider_t, host_prefix_sum_t
from AllenCore.algorithms import (velo_lumi_counters_t, pv_lumi_counters_t,
                                  muon_lumi_counters_t, scifi_lumi_counters_t,
                                  calo_lumi_counters_t, plume_lumi_counters_t,
                                  calc_lumi_sum_size_t, make_lumi_summary_t)
from AllenCore.algorithms import muon_calculate_srq_size_t
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events, make_dummy
from AllenCore.generator import make_algorithm

from AllenConf.persistency import make_gather_selections

from PyConf.tonic import configurable
from PyConf.filecontent_metadata import _get_hash_for_text

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.scifi_reconstruction import decode_scifi
from AllenConf.muon_reconstruction import decode_muon
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.plume_reconstruction import decode_plume


def findLine(lines, name):
    for i in range(len(lines)):
        if lines[i].name.startswith(name):
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
        76,
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
            "name": "PlumeLumiOverthrLow",
            "offset": 128,
            "size": 22
        }, {
            "name": "MuonHitsM3R2",
            "offset": 150,
            "size": 10
        }, {
            "name": "PlumeLumiOverthrHigh",
            "offset": 160,
            "size": 22
        }, {
            "name": "MuonHitsM4R1",
            "offset": 182,
            "size": 10
        }, {
            "name": "SciFiClustersS3M45",
            "offset": 192,
            "size": 16
        }, {
            "name": "SciFiClusters",
            "offset": 208,
            "size": 16
        }, {
            "name": "SciFiClustersS2M123",
            "offset": 224,
            "size": 16
        }, {
            "name": "SciFiClustersS3M123",
            "offset": 240,
            "size": 16
        }, {
            "name": "ECalET",
            "offset": 256,
            "size": 16
        }, {
            "name": "ECalEInnerTop",
            "offset": 272,
            "size": 16
        }, {
            "name": "ECalEMiddleTop",
            "offset": 288,
            "size": 16
        }, {
            "name": "ECalEOuterTop",
            "offset": 304,
            "size": 16
        }, {
            "name": "ECalEInnerBottom",
            "offset": 320,
            "size": 16
        }, {
            "name": "ECalEMiddleBottom",
            "offset": 336,
            "size": 16
        }, {
            "name": "ECalEOuterBottom",
            "offset": 352,
            "size": 16
        }, {
            "name": "MuonHitsM2R1",
            "offset": 368,
            "size": 16
        }, {
            "name": "MuonHitsM2R2",
            "offset": 384,
            "size": 16
        }, {
            "name": "MuonHitsM2R3",
            "offset": 400,
            "size": 16
        }, {
            "name": "VeloTracks",
            "offset": 416,
            "size": 15
        }, {
            "name": "BCIDHigh",
            "offset": 431,
            "size": 14
        }, {
            "name": "BXType",
            "offset": 445,
            "size": 2
        }, {
            "name": "GEC",
            "offset": 447,
            "size": 1
        }, {
            "name": "SciFiClustersS1M45",
            "offset": 448,
            "size": 13
        }, {
            "name": "SciFiClustersS2M45",
            "offset": 461,
            "size": 13
        }, {
            "name": "VeloVertices",
            "offset": 474,
            "size": 6
        }, {
            "name": "PlumeAvgLumiADC",
            "offset": 480,
            "size": 12
        }, {
            "name": "MuonHitsM2R4",
            "offset": 492,
            "size": 11
        }, {
            "name": "MuonHitsM3R1",
            "offset": 512,
            "size": 11
        }, {
            "name": "MuonHitsM3R3",
            "offset": 523,
            "size": 11
        }, {
            "name": "MuonHitsM4R4",
            "offset": 534,
            "size": 10
        }, {
            "name": "MuonHitsM3R4",
            "offset": 544,
            "size": 11
        }, {
            "name": "MuonHitsM4R2",
            "offset": 555,
            "size": 11
        }, {
            "name": "MuonHitsM4R3",
            "offset": 576,
            "size": 11
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
        dev_calo_info_t=get_lumi_info(lumiInfos, "calo"),
        dev_plume_info_t=get_lumi_info(lumiInfos, "plume"))


def lumi_reconstruction(gather_selections,
                        lines,
                        lumiline_name,
                        with_muon=True,
                        with_velo=True,
                        with_SciFi=True,
                        with_calo=True,
                        with_plume=False):
    lumiLine_index, found = findLine(lines, lumiline_name)
    if not found:
        raise Exception("Line name starting with", lumiline_name,
                        "not found in", lines)

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_scifi = decode_scifi()
    decoded_calo = decode_calo()
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
                "dev_storage_station_region_quarter_offsets"])

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

    if with_plume:
        decoded_plume = decode_plume()
        lumiInfos["plume"] = make_algorithm(
            plume_lumi_counters_t,
            "plume_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_size_t=prefix_sum_lumi_size.
            host_total_sum_holder_t,
            dev_lumi_summary_offsets_t=prefix_sum_lumi_size.
            dev_output_buffer_t,
            dev_plume_t=decoded_plume["dev_plume"])

    make_lumi_summary = lumi_summary_maker(lumiInfos, prefix_sum_lumi_size)

    return {
        "algorithms":
        [prefix_sum_lumi_size, *lumiInfos.values(), make_lumi_summary],
        "dev_lumi_summary_offsets":
        prefix_sum_lumi_size.dev_output_buffer_t,
        "dev_lumi_summaries":
        make_lumi_summary.dev_lumi_summaries_t
    }
