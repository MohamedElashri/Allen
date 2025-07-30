###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import json
from AllenCore.algorithms import (velo_lumi_counters_t, pv_lumi_counters_t,
                                  muon_lumi_counters_t, scifi_lumi_counters_t,
                                  calo_lumi_counters_t, plume_lumi_counters_t,
                                  calc_lumi_sum_size_t, make_lumi_summary_t)
from AllenCore.algorithms import muon_calculate_srq_size_t
from AllenCore.configuration_options import allen_register_keys
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events, make_dummy
from AllenCore.generator import make_algorithm

from AllenConf.persistency import line_names

from PyConf.tonic import configurable
from PyConf.filecontent_metadata import register_encoding_dictionary

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.scifi_reconstruction import decode_scifi
from AllenConf.muon_reconstruction import decode_muon, make_muon_stubs
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.lumi_schema_generator import LumiSchemaGenerator, concatinate_lumi_schemata
from AllenConf.plume_reconstruction import decode_plume


def findLine(lines, name):
    for i in range(len(lines)):
        if lines[i].startswith(name):
            return i, True
    return -1, False


def get_lumi_info(lumiInfos, name):
    if name in lumiInfos:
        return lumiInfos[name].dev_lumi_infos_t
    else:
        dummy = make_dummy()
        return dummy.dev_lumi_dummy_t


def lumi_summary_maker(lumiInfos, calc_lumi_sum_size, key, key_full,
                       lumi_sum_length, schema):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        make_lumi_summary_t,
        name="make_lumi_summary",
        encoding_key=key,
        encoding_key_full=key_full,
        lumi_sum_length=lumi_sum_length,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_lumi_summaries_size_t=calc_lumi_sum_size.
        host_lumi_summaries_size_t,
        dev_lumi_summary_offsets_t=calc_lumi_sum_size.
        dev_lumi_summary_offsets_t,
        dev_lumi_event_indices_t=calc_lumi_sum_size.dev_lumi_event_indices_t,
        dev_odin_data_t=odin["dev_odin_data"],
        dev_velo_info_t=get_lumi_info(lumiInfos, "velo"),
        dev_pv_info_t=get_lumi_info(lumiInfos, "pv"),
        dev_scifi_info_t=get_lumi_info(lumiInfos, "scifi"),
        dev_muon_info_t=get_lumi_info(lumiInfos, "muon"),
        dev_calo_info_t=get_lumi_info(lumiInfos, "calo"),
        dev_plume_info_t=get_lumi_info(lumiInfos, "plume"),
        lumi_counter_schema=schema)


def lumi_reconstruction(
        gather_selections,
        lumiline_name,
        lumilinefull_name=None,
        with_muon=True,
        with_velo=True,
        with_SciFi=True,
        with_calo=True,
        with_plume=True,
        velo_open=False,
        counterSpecs=[("T0Low", 0xffffffff), ("T0High", 0xffffffff),
                      ("BCIDLow", 0xffffffff), ("BCIDHigh", 0x3fff),
                      ("BXType", 3), ("GEC", 1), ("VeloTracks", 1913),
                      ("VeloFiducialTracks", 1913), ("VeloTracksEtaBin0", 68),
                      ("VeloTracksEtaBin1", 294), ("VeloTracksEtaBin2", 302),
                      ("VeloTracksEtaBin3", 287), ("VeloTracksEtaBin4", 471),
                      ("VeloTracksEtaBin5", 427), ("VeloTracksEtaBin6", 328),
                      ("VeloTracksEtaBin7", 81), ("VeloVertices", 33),
                      ("FiducialVeloVertices", 33), ("VeloVertexX", 0x3fff),
                      ("VeloVertexY", 0x3fff), ("VeloVertexZ", 0x3fff),
                      ("VeloClustersInnerBin00", 11000),
                      ("VeloClustersOuterBin00", 11000),
                      ("VeloClustersInnerBin01", 20000),
                      ("VeloClustersOuterBin01", 20000),
                      ("VeloClustersInnerBin02", 20000),
                      ("VeloClustersOuterBin02", 11000),
                      ("VeloClustersInnerBin03", 20000),
                      ("VeloClustersOuterBin03", 11000), ("SciFiT1M4", 2100),
                      ("SciFiT2M4", 2350), ("SciFiT3M45", 4100),
                      ("SciFiT1M123", 7650), ("SciFiT2M123", 7590),
                      ("SciFiT3M123", 7890), ("ECalET", 0x1fffff),
                      ("ECalEtot", 0x7fffff), ("ECalETInnerTop", 0x3ffff),
                      ("ECalETMiddleTop", 0x3ffff), ("ECalETOuterTop",
                                                     0x3ffff),
                      ("ECalETInnerBottom", 0x3ffff),
                      ("ECalETMiddleBottom", 0x3ffff),
                      ("ECalETOuterBottom", 0x3ffff), ("MuonHitsM2R1", 696),
                      ("MuonHitsM2R2", 593), ("MuonHitsM2R3", 263),
                      ("MuonHitsM2R4", 200), ("MuonHitsM3R1", 478),
                      ("MuonHitsM3R2", 212), ("MuonHitsM3R3", 161),
                      ("MuonHitsM3R4", 102), ("MuonHitsM4R1", 134),
                      ("MuonHitsM4R2", 108), ("MuonHitsM4R3", 409),
                      ("MuonHitsM4R4", 227), ("MuonTracks", 127),
                      ("PlumeAvgLumiADC", 0x7ffff),
                      ("PlumeLumiOverthrLow", 0x3fffff),
                      ("PlumeLumiOverthrHigh", 0x3fffff)],
        extraCounterSpecs=[
            ("PlumeLumiADC00", 0xfff), ("PlumeLumiADC01", 0xfff),
            ("PlumeLumiADC02", 0xfff), ("PlumeLumiADC03", 0xfff),
            ("PlumeLumiADC04", 0xfff), ("PlumeLumiADC05", 0xfff),
            ("PlumeLumiADC06", 0xfff), ("PlumeLumiADC07", 0xfff),
            ("PlumeLumiADC08", 0xfff), ("PlumeLumiADC09", 0xfff),
            ("PlumeLumiADC10", 0xfff), ("PlumeLumiADC11", 0xfff),
            ("PlumeLumiADC12", 0xfff), ("PlumeLumiADC13", 0xfff),
            ("PlumeLumiADC14", 0xfff), ("PlumeLumiADC15", 0xfff),
            ("PlumeLumiADC16", 0xfff), ("PlumeLumiADC17", 0xfff),
            ("PlumeLumiADC18", 0xfff), ("PlumeLumiADC19", 0xfff),
            ("PlumeLumiADC20", 0xfff), ("PlumeLumiADC21", 0xfff),
            ("PlumeLumiADC22", 0xfff), ("PlumeLumiADC23", 0xfff),
            ("PlumeLumiADC24", 0xfff), ("PlumeLumiADC25", 0xfff),
            ("PlumeLumiADC26", 0xfff), ("PlumeLumiADC27", 0xfff),
            ("PlumeLumiADC28", 0xfff), ("PlumeLumiADC29", 0xfff),
            ("PlumeLumiADC30", 0xfff), ("PlumeLumiADC31", 0xfff),
            ("PlumeLumiADC32", 0xfff), ("PlumeLumiADC33", 0xfff),
            ("PlumeLumiADC34", 0xfff), ("PlumeLumiADC35", 0xfff),
            ("PlumeLumiADC36", 0xfff), ("PlumeLumiADC37", 0xfff),
            ("PlumeLumiADC38", 0xfff), ("PlumeLumiADC39", 0xfff),
            ("PlumeLumiADC40", 0xfff), ("PlumeLumiADC41", 0xfff),
            ("PlumeLumiADC42", 0xfff), ("PlumeLumiADC43", 0xfff),
            ("PlumeTiming00", 0x1ffff), ("PlumeTiming01", 0x1ffff),
            ("PlumeTiming02", 0x1ffff), ("PlumeTiming03", 0x1ffff),
            ("PlumeTiming04", 0x1ffff), ("PlumeTiming05", 0x1ffff),
            ("PlumeTiming06", 0x1ffff), ("PlumeTiming07", 0x1ffff),
            ("PlumeTiming08", 0x1ffff), ("PlumeTiming09", 0x1ffff),
            ("PlumeTiming10", 0x1ffff), ("PlumeTiming11", 0x1ffff),
            ("PlumeTiming12", 0x1ffff), ("PlumeTiming13", 0x1ffff),
            ("PlumeTiming14", 0x1ffff), ("PlumeTiming15", 0x1ffff),
            ("PlumeTiming16", 0x1ffff), ("PlumeTiming17", 0x1ffff),
            ("PlumeTiming18", 0x1ffff), ("PlumeTiming19", 0x1ffff),
            ("PlumeTiming20", 0x1ffff), ("PlumeTiming21", 0x1ffff),
            ("PlumeTiming22", 0x1ffff), ("PlumeTiming23", 0x1ffff),
            ("PlumeTiming24", 0x1ffff), ("PlumeTiming25", 0x1ffff),
            ("PlumeTiming26", 0x1ffff), ("PlumeTiming27", 0x1ffff),
            ("PlumeTiming28", 0x1ffff), ("PlumeTiming29", 0x1ffff),
            ("PlumeTiming30", 0x1ffff), ("PlumeTiming31", 0x1ffff),
            ("SciFiT1Q02M0", 0x1fff), ("SciFiT1Q13M0", 0x1fff),
            ("SciFiT1Q02M1", 0x1fff), ("SciFiT1Q13M1", 0x1fff),
            ("SciFiT1Q02M2", 0x1fff), ("SciFiT1Q13M2", 0x1fff),
            ("SciFiT1Q02M3", 0x1fff), ("SciFiT1Q13M3", 0x1fff),
            ("SciFiT1Q02M4", 0x3ff), ("SciFiT1Q13M4", 0x3ff),
            ("SciFiT2Q02M0", 0x1fff), ("SciFiT2Q13M0", 0x1fff),
            ("SciFiT2Q02M1", 0x1fff), ("SciFiT2Q13M1", 0x1fff),
            ("SciFiT2Q02M2", 0x1fff), ("SciFiT2Q13M2", 0x1fff),
            ("SciFiT2Q02M3", 0x1fff), ("SciFiT2Q13M3", 0x1fff),
            ("SciFiT2Q02M4", 0x3ff), ("SciFiT2Q13M4", 0x3ff),
            ("SciFiT3Q02M0", 0x1fff), ("SciFiT3Q13M0", 0x1fff),
            ("SciFiT3Q02M1", 0x1fff), ("SciFiT3Q13M1", 0x1fff),
            ("SciFiT3Q02M2", 0x1fff), ("SciFiT3Q13M2", 0x1fff),
            ("SciFiT3Q02M3", 0x1fff), ("SciFiT3Q13M3", 0x1fff),
            ("SciFiT3Q02M4", 0x3ff), ("SciFiT3Q13M4", 0x3ff),
            ("SciFiT3Q02M5", 0x3ff), ("SciFiT3Q13M5", 0x3ff),
            ("VeloClustersInnerS00", 3000), ("VeloClustersOuterS00", 3000),
            ("VeloClustersInnerS01", 3000), ("VeloClustersOuterS01", 3000),
            ("VeloClustersInnerS02", 3000), ("VeloClustersOuterS02", 3000),
            ("VeloClustersInnerS03", 3000), ("VeloClustersOuterS03", 3000),
            ("VeloClustersInnerS04", 3000), ("VeloClustersOuterS04", 3000),
            ("VeloClustersInnerS05", 3000), ("VeloClustersOuterS05", 3000),
            ("VeloClustersInnerS06", 3000), ("VeloClustersOuterS06", 3000),
            ("VeloClustersInnerS07", 3000), ("VeloClustersOuterS07", 3000),
            ("VeloClustersInnerS08", 3000), ("VeloClustersOuterS08", 3000),
            ("VeloClustersInnerS09", 3000), ("VeloClustersOuterS09", 3000),
            ("VeloClustersInnerS10", 3000), ("VeloClustersOuterS10", 3000),
            ("VeloClustersInnerS11", 3000), ("VeloClustersOuterS11", 3000),
            ("VeloClustersInnerS12", 3000), ("VeloClustersOuterS12", 3000),
            ("VeloClustersInnerS13", 3000), ("VeloClustersOuterS13", 3000),
            ("VeloClustersInnerS14", 3000), ("VeloClustersOuterS14", 3000),
            ("VeloClustersInnerS15", 3000), ("VeloClustersOuterS15", 3000),
            ("VeloClustersInnerS16", 3000), ("VeloClustersOuterS16", 3000),
            ("VeloClustersInnerS17", 3000), ("VeloClustersOuterS17", 3000),
            ("VeloClustersInnerS18", 3000), ("VeloClustersOuterS18", 3000),
            ("VeloClustersInnerS19", 3000), ("VeloClustersOuterS19", 3000),
            ("VeloClustersInnerS20", 3000), ("VeloClustersOuterS20", 3000),
            ("VeloClustersInnerS21", 3000), ("VeloClustersOuterS21", 3000),
            ("VeloClustersInnerS22", 3000), ("VeloClustersOuterS22", 3000),
            ("VeloClustersInnerS23", 3000), ("VeloClustersOuterS23", 3000),
            ("VeloClustersInnerS24", 3000), ("VeloClustersOuterS24", 3000),
            ("VeloClustersInnerS25", 3000), ("VeloClustersOuterS25", 3000),
            ("VeloVertexZ_00", 0x3fff), ("VeloVertexZ_01", 0x3fff),
            ("VeloVertexZ_02", 0x3fff), ("VeloVertexZ_03", 0x3fff),
            ("VeloVertexZ_04", 0x3fff), ("VeloVertexZ_05", 0x3fff),
            ("VeloVertexZ_06", 0x3fff), ("VeloVertexZ_07", 0x3fff),
            ("VeloVertexZ_08", 0x3fff), ("VeloVertexZ_09", 0x3fff),
            ("MuonHitsTell01", 400), ("MuonHitsTell02", 400),
            ("MuonHitsTell03", 400), ("MuonHitsTell04", 400),
            ("MuonHitsTell05", 400), ("MuonHitsTell06", 400),
            ("MuonHitsTell07", 400), ("MuonHitsTell08", 400),
            ("MuonHitsTell09", 400), ("MuonHitsTell10", 400),
            ("MuonHitsTell11", 400), ("MuonHitsTell12", 400),
            ("MuonHitsTell13", 400), ("MuonHitsTell14", 400),
            ("MuonHitsTell15", 400), ("MuonHitsTell16", 400),
            ("MuonHitsTell17", 400), ("MuonHitsTell18", 400),
            ("MuonHitsTell19", 400), ("MuonHitsTell20", 400),
            ("MuonHitsTell21", 400), ("MuonHitsTell22", 400)
        ],
        counterFactors={
            "ECalET": (0x10000, 0.2),
            "ECalEtot": (0x10000, 0.0667),
            "ECalETInnerTop": (0x4000, 0.2),
            "ECalETMiddleTop": (0x4000, 0.2),
            "ECalETOuterTop": (0x4000, 0.2),
            "ECalETInnerBottom": (0x4000, 0.2),
            "ECalETMiddleBottom": (0x4000, 0.2),
            "ECalETOuterBottom": (0x4000, 0.2),
            "VeloVertexX": (0x2000, 1638.4),
            "VeloVertexY": (0x2000, 1638.4),
            "VeloVertexZ": (0x2000, 16.384),
            "VeloVertexZ_00": (0x2000, 16.384),
            "VeloVertexZ_01": (0x2000, 16.384),
            "VeloVertexZ_02": (0x2000, 16.384),
            "VeloVertexZ_03": (0x2000, 16.384),
            "VeloVertexZ_04": (0x2000, 16.384),
            "VeloVertexZ_05": (0x2000, 16.384),
            "VeloVertexZ_06": (0x2000, 16.384),
            "VeloVertexZ_07": (0x2000, 16.384),
            "VeloVertexZ_08": (0x2000, 16.384),
            "VeloVertexZ_09": (0x2000, 16.384),
            "PlumeAvgLumiADC": (0, 128.),
            "PlumeTiming00": (256, 128.),
            "PlumeTiming01": (256, 128.),
            "PlumeTiming02": (256, 128.),
            "PlumeTiming03": (256, 128.),
            "PlumeTiming04": (256, 128.),
            "PlumeTiming05": (256, 128.),
            "PlumeTiming06": (256, 128.),
            "PlumeTiming07": (256, 128.),
            "PlumeTiming08": (256, 128.),
            "PlumeTiming09": (256, 128.),
            "PlumeTiming10": (256, 128.),
            "PlumeTiming11": (256, 128.),
            "PlumeTiming12": (256, 128.),
            "PlumeTiming13": (256, 128.),
            "PlumeTiming14": (256, 128.),
            "PlumeTiming15": (256, 128.),
            "PlumeTiming16": (256, 128.),
            "PlumeTiming17": (256, 128.),
            "PlumeTiming18": (256, 128.),
            "PlumeTiming19": (256, 128.),
            "PlumeTiming20": (256, 128.),
            "PlumeTiming21": (256, 128.),
            "PlumeTiming22": (256, 128.),
            "PlumeTiming23": (256, 128.),
            "PlumeTiming24": (256, 128.),
            "PlumeTiming25": (256, 128.),
            "PlumeTiming26": (256, 128.),
            "PlumeTiming27": (256, 128.),
            "PlumeTiming28": (256, 128.),
            "PlumeTiming29": (256, 128.),
            "PlumeTiming30": (256, 128.),
            "PlumeTiming31": (256, 128.),
        }):

    lines = line_names(gather_selections)
    lumiLine_index, found = findLine(lines, lumiline_name)
    if not found:
        raise Exception("Line name starting with", lumiline_name,
                        "not found in", lines)
    if not lumilinefull_name:
        lumiLineFull_index = lumiLine_index
    else:
        lumiLineFull_index, found = findLine(lines, lumilinefull_name)
        if not found:
            raise Exception("Line name starting with", lumilinefull_name,
                            "not found in", lines)

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_scifi = decode_scifi()
    decoded_calo = decode_calo()
    pvs = make_pvs(velo_tracks, velo_open)
    decoded_muon = decode_muon(empty_banks=not with_muon)
    if with_muon:
        muon_stubs = make_muon_stubs()

    l = LumiSchemaGenerator(counterSpecs, shiftsAndScales=counterFactors)
    l.process()
    table = l.getJSON()

    l_ext = LumiSchemaGenerator(
        extraCounterSpecs,
        shiftsAndScales=counterFactors,
        addEncodingKey=False)
    l_ext.process()
    table_ext = l_ext.getJSON()

    table_full = concatinate_lumi_schemata([table, table_ext])

    if allen_register_keys():
        key = int(
            register_encoding_dictionary(
                "counters", table, directory="luminosity_counters"), 16)
        key_full = int(
            register_encoding_dictionary(
                "counters", table_full, directory="luminosity_counters"), 16)
    else:
        key = 0
        key_full = 0
    lumi_sum_length = table[
        "size"] / 4  #algorithms expect length in words not bytes
    lumi_sum_length_full = table_full["size"] / 4
    schema_for_algorithms = {
        counter["name"]: (counter["offset"], counter["size"])
        for counter in table_full["counters"]
    }
    shifts_and_scales_for_algorithms = {
        counter["name"]: (counter.get("shift", 0.), counter.get("scale", 1.))
        for counter in table_full["counters"]
        if "shift" in counter or "scale" in counter
    }

    calc_lumi_sum_size = make_algorithm(
        calc_lumi_sum_size_t,
        name="calc_lumi_sum_size",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_selections_t=gather_selections.dev_selections_t,
        dev_selections_offsets_t=gather_selections.dev_selections_offsets_t,
        line_index=lumiLine_index,
        line_index_full=lumiLineFull_index,
        lumi_sum_length=lumi_sum_length,
        lumi_sum_length_full=lumi_sum_length_full)

    lumiInfos = {}
    if with_velo:
        velo_states = run_velo_kalman_filter(velo_tracks)
        lumiInfos["velo"] = make_algorithm(
            velo_lumi_counters_t,
            name="velo_total_tracks",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_velo_tracks_view_t=velo_tracks["dev_velo_tracks_view"],
            dev_is_backward_t=velo_states["dev_is_backward"],
            dev_velo_states_view_t=velo_states[
                "dev_velo_kalman_beamline_states_view"],
            dev_offsets_all_velo_tracks_t=velo_tracks[
                "dev_offsets_all_velo_tracks"],
            dev_offsets_estimated_input_size_t=decoded_velo[
                "dev_offsets_estimated_input_size"],
            dev_module_cluster_num_t=decoded_velo["dev_module_cluster_num"],
            dev_velo_clusters_t=decoded_velo["dev_velo_clusters"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

        lumiInfos["pv"] = make_algorithm(
            pv_lumi_counters_t,
            "pv_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
            dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

    if with_SciFi:
        lumiInfos["scifi"] = make_algorithm(
            scifi_lumi_counters_t,
            "scifi_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_scifi_hit_offsets_t=decoded_scifi["dev_scifi_hit_offsets"],
            dev_scifi_hits_t=decoded_scifi["dev_scifi_hits"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

    if with_muon:
        lumiInfos["muon"] = make_algorithm(
            muon_lumi_counters_t,
            "muon_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            host_raw_bank_version_t=decoded_muon["host_raw_bank_version"],
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_storage_station_region_quarter_offsets_t=decoded_muon[
                "dev_storage_station_region_quarter_offsets"],
            dev_muon_tracks_offsets_t=muon_stubs["dev_muon_tracks_offsets"],
            dev_muon_tell_number_t=decoded_muon["dev_muon_tell_number"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

    if with_calo:
        lumiInfos["calo"] = make_algorithm(
            calo_lumi_counters_t,
            "calo_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_ecal_digits_t=decoded_calo["dev_ecal_digits"],
            dev_ecal_digits_offsets_t=decoded_calo["dev_ecal_digits_offsets"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

    if with_plume:
        decoded_plume = decode_plume()
        lumiInfos["plume"] = make_algorithm(
            plume_lumi_counters_t,
            "plume_lumi_counters",
            host_number_of_events_t=number_of_events["host_number_of_events"],
            host_lumi_summaries_count_t=calc_lumi_sum_size.
            host_lumi_summaries_count_t,
            dev_lumi_event_indices_t=calc_lumi_sum_size.
            dev_lumi_event_indices_t,
            dev_plume_t=decoded_plume["dev_plume"],
            lumi_counter_schema=schema_for_algorithms,
            lumi_counter_shifts_and_scales=shifts_and_scales_for_algorithms)

    make_lumi_summary = lumi_summary_maker(lumiInfos, calc_lumi_sum_size, key,
                                           key_full, lumi_sum_length,
                                           schema_for_algorithms)

    return {
        "algorithms": [*lumiInfos.values(), make_lumi_summary],
        "dev_lumi_summary_offsets":
        calc_lumi_sum_size.dev_lumi_summary_offsets_t,
        "dev_lumi_summaries":
        make_lumi_summary.dev_lumi_summaries_t,
        "host_lumi_summary_offsets":
        make_lumi_summary.host_lumi_summary_offsets_t,
        "host_lumi_summaries":
        make_lumi_summary.host_lumi_summaries_t
    }
