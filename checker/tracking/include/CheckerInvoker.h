#pragma once

#include <string>
#include <vector>
#include "TrackChecker.h"
#include "MCEvent.h"
#include "InputTools.h"

struct CheckerInvoker {
  std::string mc_folder;
  uint start_event_offset = 0;
  uint number_of_requested_events = 0;
  uint number_of_selected_events = 0;
  bool check_events = false;
  bool is_mc_folder_populated = true;
  MCEvents mc_events;
  MCEvents selected_mc_events;
  mutable bool create_file = true;

  CheckerInvoker(
    const std::string& param_mc_folder,
    const uint param_start_event_offset,
    const uint* event_list,
    const uint param_number_of_requested_events,
    const uint param_number_of_selected_events,
    const bool param_check_events = false) :
    mc_folder(param_mc_folder),
    start_event_offset(param_start_event_offset), number_of_requested_events(param_number_of_requested_events),
    number_of_selected_events(param_number_of_selected_events), check_events(param_check_events)
  {
    const auto folder_contents = read_mc_folder();

    is_mc_folder_populated = std::get<0>(folder_contents);
    mc_events = std::get<1>(folder_contents);

    // events selected by global event cuts
    for (int i = 0; i < number_of_selected_events; i++) {
      const uint event = event_list[i];
      MCEvent mc_event = mc_events[event];
      selected_mc_events.push_back(mc_event);
    }
  }

  std::tuple<bool, MCEvents> read_mc_folder() const;

  template<typename T>
  std::vector<std::vector<std::vector<uint32_t>>> check(
    const uint start_event_offset,
    const std::vector<Checker::Tracks>& tracks,
    std::vector<std::vector<float>>& p_events) const
  {
    std::vector<std::vector<std::vector<uint32_t>>> scifi_ids_events;

    if (is_mc_folder_populated) {
      T track_checker {create_file};
      create_file = false;
      for (int evnum = 0; evnum < selected_mc_events.size(); ++evnum) {
        const auto& mc_event = selected_mc_events[evnum];
        const auto& event_tracks = tracks[evnum];

        std::vector<uint32_t> matched_mcp_keys =
          track_checker(event_tracks, mc_event, get_num_hits_subdetector<typename T::subdetector_t>);

        std::vector<std::vector<uint32_t>> scifi_ids_tracks;
        std::vector<float> p_tracks;
        for (const auto key : matched_mcp_keys) {
          std::vector<uint32_t> scifi_ids;
          float p = 1e9;
          if (!(key == 0xFFFFFF)) { // track was matched to an MCP
            // Find this MCP
            for (const auto mcp : mc_event.m_mcps) {
              if (mcp.key == key) {
                // Save momentum and charge of this MCP
                p = mcp.p * mcp.charge;
                // debug_cout << "Adding particle with PID = " << mcp.pid << " and charge " << charge << std::endl;
                // Find SciFi IDs of this MCP
                if (mcp.isLong) { // found matched long MCP
                  for (const auto id : mcp.hits) {
                    const uint32_t detector_id = (id >> 20) & 0xFFF;
                    if (detector_id == 0xa00) { // hit in the SciFi
                      scifi_ids.push_back(id);
                    }
                  }
                }
              }
            }
          }
          scifi_ids_tracks.push_back(scifi_ids);
          p_tracks.push_back(p);
        }

        scifi_ids_events.push_back(scifi_ids_tracks);
        p_events.push_back(p_tracks);

        // TODO: Enable back and understand if any duplicated hits exist
        // Check all tracks for duplicate LHCb IDs
        for (int i_track = 0; i_track < event_tracks.size(); ++i_track) {
          const auto& track = event_tracks[i_track];
          auto ids = track.ids();
          std::sort(std::begin(ids), std::end(ids));
          bool containsDuplicates = (std::unique(std::begin(ids), std::end(ids))) != std::end(ids);
           if (containsDuplicates) { 
            warning_cout << "WARNING: Track #" << i_track << " contains duplicate LHCb IDs" << std::endl << std::hex;
            for (auto id : ids) {
              warning_cout << "0x" << id << ", ";
            }
            warning_cout << std::endl << std::endl << std::dec;
          }
        }
      }
    }
    return scifi_ids_events;
  }
};
