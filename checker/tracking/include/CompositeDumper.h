/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include <functional>
#include <memory>
#include <set>
#include <string>
#include <vector>
#include <variant>
#include <Common.h>
#include <InputTools.h>
#include <CheckerTypes.h>
#include <TrackChecker.h>
#include <CheckerInvoker.h>
#include <MCAssociator.h>
#include <MCEvent.h>
#include <algorithm>
#include <mutex>
#include <Datatype.cuh>

#include <ROOTHeaders.h>
#include <functional>

class CompositeDumper : public Checker::BaseChecker {
public:
  // Define supported column
  using Column_t = std::variant<float, unsigned, int, bool>;

  // Define truth matching result
  struct MatchedComposite_t {
    // Truth matching category:
    //  -1 = Undefined
    //   0 = Correct matched
    //   1 = Tracks from same origin but not same mother
    //   2 = Combinatorial backgrounds (tracks are real but not from same composite)
    //   3 = Partial: one of the track is ghost
    //   4 = Ghost: both are ghsots
    int category = -1;
    const MCParticle* trackA = nullptr;
    const MCParticle* trackB = nullptr;
  };

  // Define tupling data handle
  using Columns_t = std::map<std::string, Column_t>;

  //
  // Functions
  //
  //                                           event           composite                  truth matching tupling
  using FillComposite_t =
    std::function<void(const unsigned, const Checker::Composite&, const MatchedComposite_t&, Columns_t&)>;
  using FilterComposite_t = std::function<bool(const unsigned, const Checker::Composite&, const MatchedComposite_t&)>;
  //                                           event           mc event
  using FilterEvent_t = std::function<bool(const unsigned, const MCEvent&)>;

  CompositeDumper(CheckerInvoker const* invoker, std::string const& root_file, std::string const& name);

  virtual ~CompositeDumper() = default;

  template<typename T>
  void accumulate(
    MCEvents const& mc_events,
    gsl::span<const Checker::Composites> tracks,
    gsl::span<const mask_t> event_list,
    FillComposite_t const& fill_composite,
    FilterComposite_t const& filter_composite =
      [](const unsigned, const Checker::Composite&, const MatchedComposite_t&) -> bool { return true; },
    FilterEvent_t const& filter_event = [](const unsigned, const MCEvent&) -> bool { return true; });

  void report(size_t n_events) const override;

protected:
  // Custom columns
  bool m_prepared = false;
  Columns_t m_columns;

  TFile* m_file = nullptr;
  TTree* m_tree = nullptr;

  std::string m_directory;
  std::mutex m_mutex;
};

namespace {
  inline int compute_truth_matching_category(const MCParticle* mcpA, const MCParticle* mcpB)
  {
    if (mcpA && mcpB) {
      if (mcpA->motherKey == mcpB->motherKey) {
        return 0;
      }
      else if (mcpA->DecayOriginMother_key == mcpB->DecayOriginMother_key) {
        return 1;
      }
      else {
        return 2;
      }
    }
    else {
      if (mcpA || mcpB) {
        return 3;
      }
      else {
        return 4;
      }
    }
    return -1;
  }

  using truth_matching_result_t = std::map<const Checker::Track*, const MCParticle*>;

  template<typename CheckerType>
  truth_matching_result_t truth_matching(
    const MCAssociator& mc_assoc,
    const std::vector<const Checker::Track*>& tracks,
    const MCParticles& mcps,
    float threshold = 0.7f)
  {
    // Output
    truth_matching_result_t result;

    // Create the association table
    // std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table;
    std::unordered_map<int, std::pair<uint32_t, float>> assoc_table;

    // Fill the association table
    for (unsigned i = 0; i < tracks.size(); i++) {
      TrackChecker<CheckerType>::template match_track_to_MCPs_impl<const Checker::Track*>(
        mc_assoc, tracks, i, assoc_table, threshold);
    }

    // Find the best matched track
    for (const auto& [track_idx, matched_results] : assoc_table) {
      // Find the mcp
      const unsigned int key = matched_results.first;
      MCParticles::const_iterator matched_mcp =
        std::find_if(mcps.cbegin(), mcps.cend(), [&key](const auto& mcp) { return key == mcp.key; });
      assert(matched_mcp != mcps.cend());

      // Add it to the result
      result[tracks[track_idx]] = matched_mcp.base();
    }

    return result;
  }
} // namespace

template<typename CheckerType>
void CompositeDumper::accumulate(
  MCEvents const& mc_events,
  gsl::span<const Checker::Composites> all_composites,
  gsl::span<const mask_t> event_list,
  FillComposite_t const& fill_composite,
  FilterComposite_t const& filter_composite,
  FilterEvent_t const& filter_event)
{
  // Multithread guard
  std::scoped_lock guard(m_mutex);

  // Initialization
  if (!m_prepared) {
    fill_composite(0u, Checker::Composite {}, MatchedComposite_t {}, m_columns);
    // Link branches
    for (auto& [var_name, var_value] : m_columns) {
      const auto tree = m_tree;
      const auto name = var_name;
      std::visit([&tree, &name](auto&& value) { tree->Branch(name.c_str(), &value); }, var_value);
    }
    m_prepared = true;
  }

  // Run all events
  const auto number_events = event_list.size();

  printf("[%s] Dumpping start, processing %u events\n", m_directory.c_str(), static_cast<unsigned>(number_events));

  for (unsigned event_idx = 0; event_idx < number_events; event_idx++) {
    const auto event_number = event_list[event_idx];
    const auto& composites = all_composites[event_idx];
    const auto& mc_event = mc_events[event_number];
    const auto& mcps = mc_event.m_mcps;

    if (!filter_event(event_idx, mc_event)) continue;

    // Get Tracks
    std::vector<const Checker::Track*> tracks;
    tracks.reserve(composites.size() * 2);
    for (const auto& composite : composites) {
      tracks.push_back(&(composite.TrackA));
      tracks.push_back(&(composite.TrackB));
    }

    // Run truth matching over tracks
    MCAssociator mc_associator(mcps);
    auto truth_matching_result = truth_matching<CheckerType>(mc_associator, tracks, mcps);

    // Run over all composites
    for (const auto& composite : composites) {

      // Truth matching result
      MatchedComposite_t matched_composite;
      bool matched_A = truth_matching_result.count(&(composite.TrackA));
      bool matched_B = truth_matching_result.count(&(composite.TrackB));
      matched_composite.trackA = matched_A ? truth_matching_result.at(&(composite.TrackA)) : nullptr;
      matched_composite.trackB = matched_B ? truth_matching_result.at(&(composite.TrackB)) : nullptr;

      // Compute category
      matched_composite.category = compute_truth_matching_category(matched_composite.trackA, matched_composite.trackB);

      // Filter
      if (!filter_composite(event_number, composite, matched_composite)) continue;

      // Fill
      fill_composite(event_number, composite, matched_composite, m_columns);

      // Store to TTree
      m_tree->Fill();
    }
  }
}
