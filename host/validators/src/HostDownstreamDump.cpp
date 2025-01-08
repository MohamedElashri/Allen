/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostDownstreamDump.h"
#include "TrackChecker.h"
#include <stdlib.h>

INSTANTIATE_ALGORITHM(host_downstream_dump::host_downstream_dump_t)

namespace {
  const float m_minweight = 0.7f;

  template<typename T>
  std::tuple<bool, MCParticles::const_iterator> match_track_to_MCPs(
    const MCAssociator& mc_assoc,
    const Checker::Tracks& tracks,
    const int i_track,
    std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table)
  {
    const auto& track = tracks[i_track];

    // Note: This code is based heavily on
    //       https://gitlab.cern.ch/lhcb/Rec/blob/master/Pr/PrMCTools/src/PrTrackAssociator.cpp
    //
    // check LHCbIDs for MC association
    Checker::TruthCounter total_counter;
    std::unordered_map<unsigned, Checker::TruthCounter> truth_counters;
    int n_meas = 0;
    for (unsigned i = 0; i < track.total_number_of_hits; i++) {
      const auto id = track.allids[i];
      if (lhcb_id::is_velo(id)) {
        n_meas++;
        total_counter.n_velo++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_velo++;
        }
      }
      else if (lhcb_id::is_ut(id)) {
        n_meas++;
        total_counter.n_ut++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_ut++;
        }
      }
      else if (lhcb_id::is_scifi(id)) {
        n_meas++;
        total_counter.n_scifi++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_scifi++;
        }
      }
      else {
        debug_cout << "ID not matched to any subdetector " << std::hex << id << std::dec << std::endl;
      }
    }

    // If the Track has total # Velo hits > 2 AND total # SciFi hits > 2, combine matching of mother and daughter
    // particles
    if ((total_counter.n_velo > 2) && (total_counter.n_scifi > 2)) {
      for (auto& id_counter_1 : truth_counters) {
        if ((id_counter_1.second).n_scifi == 0) continue;
        const int mother_key = (mc_assoc.m_mcps[id_counter_1.first]).motherKey;
        for (auto& id_counter_2 : truth_counters) {
          if (&id_counter_1 == &id_counter_2) continue;
          const int key = (mc_assoc.m_mcps[id_counter_2.first]).key;
          if (key == mother_key) {
            if ((id_counter_2.second).n_velo == 0) continue;
            // debug_cout << "\t Particle with key " << key << " and PID " << (mc_assoc.m_mcps[id_counter_1.first]).pid
            // << " is daughter of particle with PID " << (mc_assoc.m_mcps[id_counter_2.first]).pid << std::endl;

            //== Daughter hits are added to mother.
            (id_counter_2.second).n_velo += (id_counter_1.second).n_velo;
            (id_counter_2.second).n_ut += (id_counter_1.second).n_ut;
            (id_counter_2.second).n_scifi += (id_counter_1.second).n_scifi;
            if ((id_counter_2.second).n_velo > total_counter.n_velo)
              (id_counter_2.second).n_velo = total_counter.n_velo;
            if ((id_counter_2.second).n_ut > total_counter.n_ut) (id_counter_2.second).n_ut = total_counter.n_ut;
            if ((id_counter_2.second).n_scifi > total_counter.n_scifi)
              (id_counter_2.second).n_scifi = total_counter.n_scifi;

            //== Mother hits overwrite Daughter hits
            (id_counter_1.second).n_velo = (id_counter_2.second).n_velo;
            (id_counter_1.second).n_ut = (id_counter_2.second).n_ut;
            (id_counter_1.second).n_scifi = (id_counter_2.second).n_scifi;
          }
        }
      }
    }

    bool match = false;
    auto track_best_matched_MCP = mc_assoc.m_mcps.cend();

    float max_weight = 1e9f;
    for (const auto& id_counter : truth_counters) {
      bool velo_ok = true;
      bool scifi_ok = true;

      if (total_counter.n_velo > 2) {
        const auto weight = id_counter.second.n_velo / ((float) total_counter.n_velo);
        velo_ok = weight >= m_minweight;
      }
      if (total_counter.n_scifi > 2) {
        const auto weight = id_counter.second.n_scifi / ((float) total_counter.n_scifi);
        scifi_ok = weight >= m_minweight;
      }
      const bool ut_ok =
        (id_counter.second.n_ut + 2 > total_counter.n_ut) || (total_counter.n_velo > 2 && total_counter.n_scifi > 2);
      const auto counter_sum = id_counter.second.n_velo + id_counter.second.n_ut + id_counter.second.n_scifi;
      // Decision
      if (velo_ok && ut_ok && scifi_ok && n_meas > 0) {
        // debug_cout << "\t Matched track " << i_track << " to MCP " << (mc_assoc.m_mcps[id_counter.first]).key <<
        // std::endl;
        // save matched hits per subdetector
        // -> needed for hit efficiency
        int subdetector_counter = 0;
        if constexpr (std::is_same_v<T, Checker::Subdetector::Velo>)
          subdetector_counter = id_counter.second.n_velo;
        else if constexpr (std::is_same_v<T, Checker::Subdetector::UT>)
          subdetector_counter = id_counter.second.n_ut;
        else if constexpr (std::is_same_v<T, Checker::Subdetector::SciFi>)
          subdetector_counter = id_counter.second.n_scifi;
        else if constexpr (std::is_same_v<T, Checker::Subdetector::SciFiSeeding>)
          subdetector_counter = id_counter.second.n_scifi;
        else if constexpr (std::is_same_v<T, Checker::Subdetector::Downstream>)
          subdetector_counter = id_counter.second.n_ut + id_counter.second.n_scifi;
        const float weight = ((float) counter_sum) / ((float) n_meas);
        const MCAssociator::TrackWithWeight track_weight = {i_track, weight, subdetector_counter};
        assoc_table[(mc_assoc.m_mcps[id_counter.first]).key].push_back(track_weight);
        match = true;

        if (weight < max_weight) {
          max_weight = weight;
          track_best_matched_MCP = mc_assoc.m_mcps.begin() + id_counter.first;
        }
      }
    }

    // if (total_counter.n_scifi > 2) {
    //   if (match) {
    //     std::ofstream ofs_xchi2;
    //     ofs_xchi2.open("good_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
    //     ofs_xchi2 << track.qop << ", ";
    //     ofs_xchi2.close();
    //   } else {
    //     std::ofstream ofs_xchi2;
    //     ofs_xchi2.open("bad_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
    //     ofs_xchi2 << track.qop << ", ";
    //     ofs_xchi2.close();
    //   }
    // }

    return {match, track_best_matched_MCP};
  }

  auto mcp_to_json(const MCParticle* mcp, unsigned int event)
  {
    using nlohmann::json;
    return json {{"event", event},
                 {"key", mcp->key},
                 {"pid", mcp->pid},
                 {"charge", mcp->charge},
                 {"p", mcp->p},
                 {"pt", mcp->pt},
                 {"eta", mcp->eta},
                 {"phi", mcp->phi},
                 {"ovtx_x", mcp->ovtx_x},
                 {"ovtx_y", mcp->ovtx_y},
                 {"ovtx_z", mcp->ovtx_z},
                 {"nPV", mcp->nPV},
                 {"fromBeautyDecay", mcp->fromBeautyDecay},
                 {"fromStrangeDecay", mcp->fromStrangeDecay},
                 {"fromCharmDecay", mcp->fromCharmDecay},
                 {"fromSignal", mcp->fromSignal},
                 {"isLong", mcp->isLong},
                 {"isDown", mcp->isDown},
                 {"isMuon", mcp->isMuon()},
                 {"isElectron", mcp->isElectron()},
                 {"inEta2_5", mcp->inEta2_5()},
                 {"hasVelo", mcp->hasVelo},
                 {"hasUT", mcp->hasUT},
                 {"hasSciFi", mcp->hasSciFi},
                 {"mother_pid", mcp->mother_pid},
                 {"mother_key", mcp->motherKey},
                 {"DecayOriginMother_pid", mcp->DecayOriginMother_pid},
                 {"DecayOriginMother_key", mcp->DecayOriginMother_key},
                 {"velo_num_hits", mcp->velo_num_hits},
                 {"ut_num_hits", mcp->ut_num_hits},
                 {"scifi_num_hits", mcp->scifi_num_hits},
                 {"numHits", mcp->numHits},
                 {"hits", mcp->hits}};
  }

  // auto ut_hit_to_json(const )

} // namespace

void host_downstream_dump::host_downstream_dump_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Basic
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);

  // UT
  const auto ut_hits = make_host_buffer<dev_ut_hits_t>(arguments, context);
  const auto ut_hits_offsets = make_host_buffer<dev_ut_hit_offsets_t>(arguments, context);
  const auto& unique_x_sector_layer_offsets = constants.host_unique_x_sector_layer_offsets;

  // Scifi
  const auto scifi_seed_atomics = make_host_buffer<dev_offsets_scifi_seeds_t>(arguments, context);
  const auto scifi_seed_hit_number = make_host_buffer<dev_offsets_scifi_seed_hit_number_t>(arguments, context);
  const auto scifi_seed_hits = make_host_buffer<dev_scifi_hits_t>(arguments, context);
  const auto scifi_seeds = make_host_buffer<dev_scifi_seeds_t>(arguments, context);
  const auto seeding_states_base = make_host_buffer<dev_seeding_states_t>(arguments, context);
  const auto seeding_qop = make_host_buffer<dev_seeding_qop_t>(arguments, context);
  // const auto seeding_chi2X = make_host_buffer<dev_seeding_chi2X_t>(arguments, context);
  const auto seeding_chi2Y = make_host_buffer<dev_seeding_chi2Y_t>(arguments, context);
  // const auto seeding_nY = make_host_buffer<dev_seeding_nY_t>(arguments, context);

  // VeloSciFi matching
  const auto matched_is_scifi_track_used = make_host_buffer<dev_matched_is_scifi_track_used_t>(arguments, context);

  // Downstream
  const auto downstream_track_offsets = make_host_buffer<dev_offsets_downstream_tracks_t>(arguments, context);
  const auto downstream_hit_offsets = make_host_buffer<dev_offsets_downstream_hit_numbers_t>(arguments, context);
  const auto downstream_track_scifi_idx = make_host_buffer<dev_downstream_track_scifi_idx_t>(arguments, context);
  const auto downstream_track_hits = make_host_buffer<dev_downstream_track_hits_t>(arguments, context);
  const auto downstream_track_states = make_host_buffer<dev_downstream_track_states_t>(arguments, context);

  // MC
  const auto mc_events = *first<host_mc_events_t>(arguments);

  // Define output paths
  auto seconds = time(NULL);
  const std::string output_downstream_tracks =
    std::string(m_output_folder) + std::string("/dump_downstream_tracks_") + std::to_string(seconds) + ".json";
  const std::string output_scifi_tracks =
    std::string(m_output_folder) + std::string("/dump_scifi_tracks_") + std::to_string(seconds) + ".json";
  const std::string output_ut_hits =
    std::string(m_output_folder) + std::string("/dump_ut_hits_") + std::to_string(seconds) + ".json";
  const std::string output_mcps =
    std::string(m_output_folder) + std::string("/dump_mcps_") + std::to_string(seconds) + ".json";

  // Define output container
  using nlohmann::json;
  json output_downstream_tracks_data = json::array();
  json output_scifi_tracks_data = json::array();
  json output_ut_hits_data = json::array();
  json output_mcps_data = json::array();

  //
  // Loop all events
  //
  const auto n_eventlist = event_list.size();
  for (unsigned int i_eventlist = 0; i_eventlist < n_eventlist; i_eventlist++) {

    const auto i_event = event_list[i_eventlist];

    // Scifi tracks
    SciFi::Consolidated::ConstSeeds scifi_tracks_consolidated {
      scifi_seed_atomics.data(), scifi_seed_hit_number.data(), seeding_states_base.data(), i_event, number_of_events};
    const auto number_of_scifi_tracks = scifi_tracks_consolidated.number_of_tracks(i_event);
    const auto scifi_tracks_event_offset = scifi_tracks_consolidated.tracks_offset(i_event);

    // Downstream tracks
    UT::Consolidated::ConstTracks downstream_tracks_consolidated {
      downstream_track_offsets.data(), downstream_hit_offsets.data(), i_event, number_of_events};
    const auto total_number_of_downstream_tracks = downstream_tracks_consolidated.total_number_of_tracks();
    const auto number_of_downstream_tracks = downstream_tracks_consolidated.number_of_tracks(i_event);
    const auto downstream_tracks_offset = downstream_tracks_consolidated.tracks_offset(i_event);
    const auto downstream_track_scifi_indices = downstream_track_scifi_idx.data() + downstream_tracks_offset;
    Velo::Consolidated::ConstStates downstream_states {
      downstream_track_states.data(), total_number_of_downstream_tracks, downstream_tracks_offset};

    // Store all ut hits in this event
    // And dumpt it
    std::map<unsigned int, json> all_ut_hits_in_this_event;
    {
      // Create event object
      using UT::Constants::n_layers;
      const auto number_of_unique_x_sectors = unique_x_sector_layer_offsets[n_layers];
      const auto total_number_of_hits = ut_hits_offsets[number_of_events * number_of_unique_x_sectors];
      const UT::HitOffsets offsets {
        &ut_hits_offsets[0], i_event, number_of_unique_x_sectors, &unique_x_sector_layer_offsets[0]};
      const auto event_offset = offsets.event_offset();
      UT::ConstHits hits {&ut_hits[0], total_number_of_hits, event_offset};

      for (unsigned int i_layer = 0; i_layer < n_layers; i_layer++) {
        const auto& sector_begin = unique_x_sector_layer_offsets[i_layer];
        const auto& sector_end = unique_x_sector_layer_offsets[i_layer + 1];

        const auto dxDy = constants.host_ut_dxDy[i_layer];

        for (auto i_sector = sector_begin; i_sector < sector_end; i_sector++) {
          const auto hit_begin = offsets.sector_group_offset(i_sector) - event_offset;
          const auto hit_end = offsets.sector_group_offset(i_sector + 1) - event_offset;

          for (auto i_hit = hit_begin; i_hit < hit_end; i_hit++) {
            const auto event = static_cast<unsigned int>(i_event);
            const auto id = hits.id(i_hit);
            json ut_hit {{"event", event},
                         {"layer", i_layer},
                         {"sector", i_sector},
                         {"id", id},
                         {"xAtYEq0", hits.xAtYEq0(i_hit)},
                         {"zAtYEq0", hits.zAtYEq0(i_hit)},
                         {"yMin", hits.yMin(i_hit)},
                         {"yMax", hits.yMax(i_hit)},
                         {"yMid", hits.yMid(i_hit)},
                         {"weight", hits.weight(i_hit)},
                         {"dxDy", dxDy}};
            all_ut_hits_in_this_event[id] = ut_hit;
          }
        }
      }

      if (m_dump_ut_hits.value()) {
        std::vector<json> all_ut_hits_in_this_event_array;
        all_ut_hits_in_this_event_array.reserve(all_ut_hits_in_this_event.size());
        for (const auto& hit : all_ut_hits_in_this_event)
          all_ut_hits_in_this_event_array.push_back(hit.second);
        output_ut_hits_data.push_back(all_ut_hits_in_this_event_array);
      }
    }

    // Dump SciFi seeds information
    if (m_dump_scifi.value()) {

      // Load velo-scifi matching information
      auto is_veloscifi_matcheds = matched_is_scifi_track_used.data() + scifi_tracks_event_offset;

      // Run truth matching
      Checker::Tracks chcker_tracks_scifi;
      chcker_tracks_scifi.reserve(number_of_scifi_tracks);

      // Fill checker tracks for scifi tracks
      for (unsigned i_track = 0; i_track < number_of_scifi_tracks; i_track++) {
        auto& checker_track = chcker_tracks_scifi.emplace_back();
        const auto lhcb_ids = scifi_tracks_consolidated.get_lhcbids_for_track(scifi_seed_hits.data(), i_track);
        for (const auto& id : lhcb_ids) {
          checker_track.addId(id);
        };
      }

      // Create association table for truth matching
      const auto& mc_event = mc_events[i_event];
      MCAssociator mc_assoc_scifi {mc_event.m_mcps};
      std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table_scifi;

      for (unsigned int i_track = 0; i_track < number_of_scifi_tracks; i_track++) {

        // Run truth matching
        auto [is_matched, matched_mcp] = match_track_to_MCPs<Checker::Subdetector::SciFiSeeding>(
          mc_assoc_scifi, chcker_tracks_scifi, i_track, assoc_table_scifi);

        // Get matched data
        auto matched_mcp_data = json {};
        if (is_matched) {
          const auto& mcp = *matched_mcp;
          matched_mcp_data = mcp_to_json(&mcp, static_cast<unsigned int>(i_event));

          json true_ut_hits_info = json::array();
          for (const auto& hit_id : mcp.hits) {
            if (lhcb_id::is_ut(hit_id) && all_ut_hits_in_this_event.count(hit_id)) {
              true_ut_hits_info.push_back(all_ut_hits_in_this_event[hit_id]);
            }
          }
          matched_mcp_data["UTHits"] = true_ut_hits_info;
        }
        else {
          matched_mcp_data["UTHits"] = json::array();
        }

        // Get Scifi info
        const auto lhcb_ids = scifi_tracks_consolidated.get_lhcbids_for_track(scifi_seed_hits.data(), i_track);
        const auto state = scifi_tracks_consolidated.states(i_track);
        const auto event_offset = scifi_tracks_consolidated.tracks_offset(i_event);
        const auto qop = seeding_qop[event_offset + i_track];
        const auto chi2Y = seeding_chi2Y[event_offset + i_track];
        // const auto chi2X = seeding_chi2X[event_offset + i_track];
        // const auto nY = seeding_nY[event_offset + i_track];
        const auto is_veloscifi_matched = is_veloscifi_matcheds[i_track];

        output_scifi_tracks_data.push_back(json {{"event", static_cast<unsigned int>(i_event)},
                                                 {"track_idx", i_track},
                                                 {"x", state.x()},
                                                 {"y", state.y()},
                                                 {"z", state.z()},
                                                 {"tx", state.tx()},
                                                 {"ty", state.ty()},
                                                 {"qop", qop},
                                                 //  {"chi2X", chi2X},
                                                 {"chi2Y", chi2Y},
                                                 //  {"nY", nY},
                                                 {"numHits", lhcb_ids.size()},
                                                 {"ids", lhcb_ids},
                                                 {"is_matched", is_matched},
                                                 {"matched_mcp", matched_mcp_data},
                                                 {"veloscifi_matched", is_veloscifi_matched}});
      }
    }

    if (m_dump_downstream.value()) {
      // Create checker tracks containers
      Checker::Tracks checker_tracks_ut, checker_tracks_all;
      checker_tracks_ut.reserve(number_of_downstream_tracks);
      checker_tracks_all.reserve(number_of_downstream_tracks);

      for (unsigned i_track = 0; i_track < number_of_downstream_tracks; i_track++) {
        auto& checker_track_ut = checker_tracks_ut.emplace_back();
        auto& checker_track_all = checker_tracks_all.emplace_back();
        const auto lhcb_ids =
          downstream_tracks_consolidated.get_lhcbids_for_track(downstream_track_hits.data(), i_track);
        for (const auto& id : lhcb_ids) {
          checker_track_ut.addId(id);
          checker_track_all.addId(id);
        };
        const auto correspond_scifi_track_idx = downstream_track_scifi_indices[i_track];
        const auto scifi_lhcb_ids =
          scifi_tracks_consolidated.get_lhcbids_for_track(scifi_seed_hits.data(), correspond_scifi_track_idx);
        for (const auto& id : scifi_lhcb_ids) {
          checker_track_all.addId(id);
        };
      }

      const auto& mc_event = mc_events[i_event];
      MCAssociator mc_assoc_ut {mc_event.m_mcps}, mc_assoc_all {mc_event.m_mcps};
      std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table_ut, assoc_table_all;

      for (unsigned int i_track = 0; i_track < number_of_downstream_tracks; i_track++) {

        // Run truth matching
        auto [is_matched_ut, matched_mcp_ut] = match_track_to_MCPs<Checker::Subdetector::Downstream>(
          mc_assoc_ut, checker_tracks_ut, i_track, assoc_table_ut);
        auto [is_matched_all, matched_mcp_all] = match_track_to_MCPs<Checker::Subdetector::Downstream>(
          mc_assoc_all, checker_tracks_all, i_track, assoc_table_all);

        // Get matched data
        auto matched_mcp_ut_data =
          is_matched_ut ? mcp_to_json(&matched_mcp_ut[0], static_cast<unsigned int>(i_event)) : json {};
        auto matched_mcp_all_data =
          is_matched_all ? mcp_to_json(&matched_mcp_all[0], static_cast<unsigned int>(i_event)) : json {};

        // Store the track result with truth matching
        auto scifi_idx = downstream_track_scifi_indices[i_track];

        // Get Scifi info
        const auto scifi_lhcb_ids = scifi_tracks_consolidated.get_lhcbids_for_track(scifi_seed_hits.data(), scifi_idx);
        const auto scifi_state = scifi_tracks_consolidated.states(scifi_idx);
        const auto scifi_event_offset = scifi_tracks_consolidated.tracks_offset(i_event);
        const auto scifi_qop = seeding_qop[scifi_event_offset + scifi_idx];
        const auto scifi_chi2Y = seeding_chi2Y[scifi_event_offset + scifi_idx];
        // const auto scifi_chi2X = seeding_chi2X[scifi_event_offset + scifi_idx];
        // const auto scifi_nY = seeding_nY[scifi_event_offset + scifi_idx];

        // Get UT Hits info
        const auto ut_hits_ids =
          downstream_tracks_consolidated.get_lhcbids_for_track(downstream_track_hits.data(), i_track);
        json track_ut_hits_data = json::array();
        for (const auto& ut_hit_id : ut_hits_ids) {
          track_ut_hits_data.push_back(all_ut_hits_in_this_event[ut_hit_id]);
        }

        output_downstream_tracks_data.emplace_back(json {{"event", static_cast<unsigned int>(i_event)},
                                                         {"track_idx", i_track},
                                                         {"x", downstream_states.x(i_track)},
                                                         {"y", downstream_states.y(i_track)},
                                                         {"z", downstream_states.z(i_track)},
                                                         {"tx", downstream_states.tx(i_track)},
                                                         {"ty", downstream_states.ty(i_track)},
                                                         {"chi2", downstream_states.chi2(i_track)},
                                                         {"qop", downstream_states.qop(i_track)},
                                                         {"ids", ut_hits_ids},
                                                         {"hits", track_ut_hits_data},
                                                         {"scifi",
                                                          {
                                                            {"scifi_idx", scifi_idx},
                                                            {"hits", scifi_lhcb_ids},
                                                            {"qop", scifi_qop},
                                                            {"x", scifi_state.x()},
                                                            {"y", scifi_state.y()},
                                                            {"z", scifi_state.z()},
                                                            {"tx", scifi_state.tx()},
                                                            {"ty", scifi_state.ty()},
                                                            {"chi2Y", scifi_chi2Y},
                                                            // {"chi2X", scifi_chi2X},
                                                            // {"nY", scifi_nY},
                                                          }},
                                                         {"is_matched_ut", is_matched_ut},
                                                         {"matched_ut_mcp", matched_mcp_ut_data},
                                                         {"is_matched_all", is_matched_all},
                                                         {"matched_all_mcp", matched_mcp_all_data}});
      }
    }

    if (m_dump_mcps.value()) {
      auto mcps_per_event = json::array();
      const auto& mc_event = mc_events[i_event];
      const auto& mc_particles = mc_event.m_mcps;
      for (const auto& mcp : mc_particles) {
        mcps_per_event.push_back(mcp_to_json(&mcp, i_event));
      }
      output_mcps_data.push_back(mcps_per_event);
    }
  }

  auto write_output = [](std::string output_path, json output_data) {
    const auto last_slash = output_path.find_last_of("//");
    if (last_slash != std::string::npos) {
      const auto dir_path = output_path.substr(0, last_slash);
      std::string cmd = std::string("mkdir -p ") + dir_path;
      system(cmd.c_str());
    }

    printf("Writting to file %s\n", output_path.c_str());
    std::ofstream out_ut(output_path);
    out_ut << output_data << std::endl;
  };

  if (m_dump_downstream.value()) {
    write_output(output_downstream_tracks, output_downstream_tracks_data);
  }
  if (m_dump_scifi.value()) {
    write_output(output_scifi_tracks, output_scifi_tracks_data);
  }
  if (m_dump_ut_hits.value()) {
    write_output(output_ut_hits, output_ut_hits_data);
  }
  if (m_dump_mcps.value()) {
    write_output(output_mcps, output_mcps_data);
  }

  printf("END\n");
}
