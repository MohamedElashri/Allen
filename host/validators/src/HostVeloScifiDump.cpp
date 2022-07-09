/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostVeloScifiDump.h"
#include "KalmanChecker.h"

INSTANTIATE_ALGORITHM(host_veloscifi_dump::host_veloscifi_dump_t)

namespace {
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
    int n_hits_missing = 0; // FIXME
    const auto nhits = track.total_number_of_hits;
    for (unsigned ihit=0; ihit<nhits; ihit++) {
      const auto id = track.allids[ihit];
      if (id == 0) {
        // std::cout << "check SciFi: " << lhcb_id::is_scifi(id) << std::endl;
        n_hits_missing += 1;
      }
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
    // if (n_hits_missing != 0){std::cout << "This track has missing hits: " << n_hits_missing << std::endl;}

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
        velo_ok = weight >= 0.7f;
      }
      if (total_counter.n_scifi > 2) {
        const auto weight = id_counter.second.n_scifi / ((float) total_counter.n_scifi);
        scifi_ok = weight >= 0.7f;
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

    return {match, track_best_matched_MCP};
  }
} // namespace

void host_veloscifi_dump::host_veloscifi_dump_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto number_of_events = first<host_number_of_events_t>(arguments);
  const auto event_list = make_vector<dev_event_list_t>(arguments);

  const auto offsets_all_velo_tracks = make_vector<dev_offsets_all_velo_tracks_t>(arguments);
  const auto offsets_velo_track_hit_number = make_vector<dev_offsets_velo_track_hit_number_t>(arguments);
  const auto velo_track_hits = make_vector<dev_velo_track_hits_t>(arguments);
  const auto velo_states_base = make_vector<dev_velo_kalman_states_t>(arguments);
  const auto number_of_selected_velo = make_vector<dev_ut_number_of_selected_velo_tracks_t>(arguments);
  const auto selected_velo_tracks = make_vector<dev_ut_selected_velo_tracks_t>(arguments);

  const auto scifi_seed_atomics = make_vector<dev_offsets_scifi_seeds_t>(arguments);
  const auto scifi_seed_hit_number = make_vector<dev_offsets_scifi_seed_hit_number_t>(arguments);
  const auto scifi_seed_hits = make_vector<dev_scifi_hits_t>(arguments);
  const auto scifi_seeds = make_vector<dev_scifi_seeds_t>(arguments);
  const auto seeding_states_base = make_vector<dev_seeding_states_t>(arguments);

  const auto mc_events = *first<host_mc_events_t>(arguments);

  std::ofstream jsonfile;
  jsonfile.open(property<dump_output_filename_t>());

  // Loop over events.
  jsonfile << "[" << std::endl;
  for (unsigned i_evlist = 0; i_evlist < event_list.size(); i_evlist++) {
    jsonfile << "{" << std::endl;
    const auto i_event = event_list[i_evlist];

    // Velo tracks
    Velo::Consolidated::ConstTracks velo_tracks {
      offsets_all_velo_tracks.data(), offsets_velo_track_hit_number.data(), i_event, number_of_events};
    const unsigned event_velo_tracks_offset = velo_tracks.tracks_offset(i_event);
    Velo::Consolidated::ConstStates velo_states {velo_states_base.data(), velo_tracks.total_number_of_tracks()};

    // Scifi tracks
    SciFi::Consolidated::ConstSeeds scifi_tracks_consolidated {
      scifi_seed_atomics.data(), scifi_seed_hit_number.data(), seeding_states_base.data(), i_event, number_of_events};
    const SciFi::Seeding::Track* event_scifi_seeds = scifi_seeds.data() + i_event * SciFi::Constants::Nmax_seeds;
    const unsigned number_of_tracks_scifi = scifi_tracks_consolidated.number_of_tracks(i_event);

    // Checker tracks
    Checker::Tracks velo_checker;
    velo_checker.reserve(number_of_selected_velo[i_event]);
    Checker::Tracks scifi_checker;
    scifi_checker.reserve(number_of_tracks_scifi);

    // Loop over velo tracks
    jsonfile << "  \"velo\":[\n";
    for (unsigned i_selected = 0; i_selected < number_of_selected_velo[i_event]; i_selected++) {
      unsigned i_track = selected_velo_tracks[event_velo_tracks_offset + i_selected];

      Checker::Track& t = velo_checker.emplace_back();
      const unsigned velo_track_number_of_hits = velo_tracks.number_of_hits(i_track);
      Velo::Consolidated::ConstHits track_hits_velo = velo_tracks.get_hits(velo_track_hits.data(), i_track);
      for (unsigned i_hit = 0; i_hit < velo_track_number_of_hits; ++i_hit) {
        t.addId(track_hits_velo.id(i_hit));
      }

      const auto endvelo_state = velo_states.get(event_velo_tracks_offset + i_track);
      auto tx = endvelo_state.tx;
      auto ty = endvelo_state.ty;
      auto x = endvelo_state.x;
      auto y = endvelo_state.y;
      auto z = endvelo_state.z;

      jsonfile << "    {\"tx\":" << tx << ", \"ty\":" << ty << ", \"x\":" << x << ", \"y\":" << y << ", \"z\":" << z
               << "},\n";
    } // velo tracks
    if (number_of_selected_velo[i_event] > 0) jsonfile.seekp(-2, jsonfile.cur);
    jsonfile << "\n  ],\n";

    // Loop over seeding tracks
    jsonfile << "  \"scifi\":[\n";
    for (unsigned i_track = 0; i_track < number_of_tracks_scifi; i_track++) {
      const SciFi::Seeding::Track& track = event_scifi_seeds[i_track];
      Checker::Track& t = scifi_checker.emplace_back();
      const auto scifi_lhcb_ids = scifi_tracks_consolidated.get_lhcbids_for_track(scifi_seed_hits.data(), i_track);
      for (const auto id : scifi_lhcb_ids) {
        t.addId(id);
      }

      jsonfile << "    {\"ax\":" << track.ax << ", \"bx\":" << track.bx << ", \"cx\":" << track.cx
               << ", \"ay\":" << track.ay << ", \"by\":" << track.by << "},\n";
    } // scifi tracks
    if (number_of_tracks_scifi > 0) jsonfile.seekp(-2, jsonfile.cur);
    jsonfile << "\n  ],\n";

    // Matchs
    const auto& mc_event = mc_events[i_event];
    MCAssociator mc_assoc {mc_event.m_mcps};
    std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table;

    jsonfile << "  \"matches\":[\n";
    int num_matches = 0;
    for (unsigned i_velo = 0; i_velo < number_of_selected_velo[i_event]; i_velo++) {
      auto [match, velo_MCP] =
        match_track_to_MCPs<Checker::Subdetector::Velo>(mc_assoc, velo_checker, i_velo, assoc_table);
      if (!match) continue;

      for (unsigned i_scifi = 0; i_scifi < number_of_tracks_scifi; i_scifi++) {
        auto [match, scifi_MCP] =
          match_track_to_MCPs<Checker::Subdetector::SciFiSeeding>(mc_assoc, scifi_checker, i_scifi, assoc_table);
        if (!match) continue;

        if (velo_MCP == scifi_MCP) {
          jsonfile << "    {\"velo\":" << i_velo << ", \"seed\":" << i_scifi
                   << ", \"qop\": " << (scifi_MCP->charge / scifi_MCP->p) << "},\n";
          num_matches++;
        }
      }
    } // matches
    if (num_matches > 0) jsonfile.seekp(-2, jsonfile.cur);
    jsonfile << "\n  ]\n";
    jsonfile << "},\n";
  } // events
  jsonfile.seekp(-2, jsonfile.cur);
  jsonfile << "\n]" << std::endl;

  jsonfile.close();
}
