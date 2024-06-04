/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
// Gaudi
#include "GaudiAlg/Consumer.h"
#include <Gaudi/Accumulators/Histogram.h>

// LHCb
#include "Event/MCHit.h"
#include "Kernel/LHCbID.h"
#include "Event/PrHits.h"

// Allen
#include "LHCbID.cuh"
#include "UTEventModel.cuh"
#include "Logger.h"

class CompareRecAllenUTHits final
  : public Gaudi::Functional::Consumer<void(const std::vector<UT::Hit>&, const std::vector<UT::Hit>&)> {

public:
  /// Standard constructor
  CompareRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator);

  /// Algorithm execution
  void operator()(const std::vector<UT::Hit>&, const std::vector<UT::Hit>&) const override;

private:
  mutable std::unique_ptr<Gaudi::Accumulators::Counter<>> m_allen_hits;
  mutable std::unique_ptr<Gaudi::Accumulators::Counter<>> m_rec_hits;
  mutable std::unique_ptr<Gaudi::Accumulators::BinomialCounter<>> m_overlap;
  mutable std::unique_ptr<Gaudi::Accumulators::BinomialCounter<>> m_LHCbID_overlap;

  Gaudi::Property<std::string> m_weighting_method {this, "WeightingMethod"};
  Gaudi::Property<unsigned> m_max_cluster_size {this, "MaxClusterSize"};
  Gaudi::Property<float> m_abs_tol {this,
                                    "AbsoluteTolerance",
                                    1e-5,
                                    "Absolute difference tolerance between Allen vs Rec Hits"};
  Gaudi::Property<float> m_rel_tol {this,
                                    "RelativeTolerance",
                                    1e-5,
                                    "Relative difference tolerance between Allen vs Rec Hits"};
};

DECLARE_COMPONENT(CompareRecAllenUTHits)

CompareRecAllenUTHits::CompareRecAllenUTHits(const std::string& name, ISvcLocator* pSvcLocator) :
  Consumer(name, pSvcLocator, {KeyValue {"allen_ut_hits", ""}, KeyValue {"rec_ut_hits", ""}})
{}

void CompareRecAllenUTHits::operator()(const std::vector<UT::Hit>& allen_hits, const std::vector<UT::Hit>& rec_hits)
  const
{
  // Different counter names for different UT decoding settings
  // Need to do it this way because m_max_cluster_size and m_weighting_method will only be known
  //   during first invocation of operator()
  if (!m_allen_hits) {
    const std::string label =
      "UT " + m_weighting_method + " clusters max " + std::to_string(static_cast<unsigned>(m_max_cluster_size)) + ": ";
    m_allen_hits = std::make_unique<Gaudi::Accumulators::Counter<>>(this, label + "Number of Allen Hit");
    m_rec_hits = std::make_unique<Gaudi::Accumulators::Counter<>>(this, label + "Number of Rec Hit");
    m_overlap = std::make_unique<Gaudi::Accumulators::BinomialCounter<>>(this, label + "Rec vs Allen overlap");
    m_LHCbID_overlap = std::make_unique<Gaudi::Accumulators::BinomialCounter<>>(this, label + "LHCbID overlap");
  }

  const auto n_hits_total_allen = allen_hits.size();
  const auto n_hits_total_rec = rec_hits.size();

  debug() << "Number of UT hits (Allen) in this event " << n_hits_total_allen << endmsg;
  debug() << "Number of UT hits (Rec) in this event   " << n_hits_total_rec << endmsg;

  std::vector<UT::Hit> sorted_allen_hits, sorted_rec_hits;
  std::copy(allen_hits.begin(), allen_hits.end(), std::back_inserter(sorted_allen_hits));
  std::copy(rec_hits.begin(), rec_hits.end(), std::back_inserter(sorted_rec_hits));

  // sort Rec and Allen by LHCbID
  auto sort_by_lhcb_id = [](const auto& hit_a, const auto& hit_b) -> bool { return hit_a.LHCbID < hit_b.LHCbID; };
  auto value_compatible = [&](const float a, const float b) {
    const bool small_value = std::abs(a - b) < m_abs_tol;
    const bool small_diff = std::abs((a - b) / (0.5 * (a + b))) < m_rel_tol;
    return small_diff || small_value;
  };
  std::sort(sorted_allen_hits.begin(), sorted_allen_hits.end(), sort_by_lhcb_id);
  std::sort(sorted_rec_hits.begin(), sorted_rec_hits.end(), sort_by_lhcb_id);

  std::vector<bool> allen_hits_matched(n_hits_total_allen, false);
  std::vector<bool> rec_hits_matched(n_hits_total_rec, false);

  for (unsigned i = 0; i < n_hits_total_allen; i++) {
    const auto iterator = std::lower_bound(
      sorted_rec_hits.begin(), sorted_rec_hits.end(), sorted_allen_hits[i], [](const auto& hit_a, const auto& hit_b) {
        return hit_a.LHCbID < hit_b.LHCbID;
      });

    const bool LHCbID_matched = iterator->LHCbID == sorted_allen_hits[i].LHCbID;
    const bool matched =
      (LHCbID_matched && value_compatible(iterator->xAtYEq0, sorted_allen_hits[i].xAtYEq0) &&
       value_compatible(iterator->yBegin, sorted_allen_hits[i].yBegin) &&
       value_compatible(iterator->yEnd, sorted_allen_hits[i].yEnd) &&
       value_compatible(iterator->zAtYEq0, sorted_allen_hits[i].zAtYEq0) &&
       value_compatible(iterator->weight, sorted_allen_hits[i].weight));

    (*m_overlap) += matched;
    (*m_LHCbID_overlap) += LHCbID_matched;

    if (matched) {
      const auto rec_index = iterator - sorted_rec_hits.begin();
      rec_hits_matched[rec_index] = true;
      allen_hits_matched[i] = true;
    }
  }

  const auto read_lambda = [](const bool matched) { return matched; };
  const bool all_allen_matched = std::all_of(allen_hits_matched.begin(), allen_hits_matched.end(), read_lambda);
  const bool all_rec_matched = std::all_of(rec_hits_matched.begin(), rec_hits_matched.end(), read_lambda);

  if (!all_allen_matched || !all_rec_matched) {
    constexpr unsigned width = 12;
    info() << std::string(8 * width, '-') << endmsg;
    info() << "Printing Allen and Rec hits that are not matched" << endmsg;
    info() << std::setw(width) << "Type" << std::setw(width) << "LHCbID" << std::setw(width) << "xAtYEq0"
           << std::setw(width) << "yBegin" << std::setw(width) << "yEnd" << std::setw(width) << "zAtYEq0"
           << std::setw(width) << "weight" << endmsg;
    for (unsigned i = 0; i < n_hits_total_allen; i++) {
      if (!allen_hits_matched[i]) {
        const auto& hit = sorted_allen_hits[i];
        info() << std::setw(width) << "Allen" << std::setw(width) << hit.LHCbID << std::setw(width) << hit.xAtYEq0
               << std::setw(width) << hit.yBegin << std::setw(width) << hit.yEnd << std::setw(width) << hit.zAtYEq0
               << std::setw(width) << hit.weight << endmsg;
      }
    }
    for (unsigned i = 0; i < n_hits_total_rec; i++) {
      if (!rec_hits_matched[i]) {
        const auto& hit = sorted_rec_hits[i];
        info() << std::setw(width) << "Rec" << std::setw(width) << hit.LHCbID << std::setw(width) << hit.xAtYEq0
               << std::setw(width) << hit.yBegin << std::setw(width) << hit.yEnd << std::setw(width) << hit.zAtYEq0
               << std::setw(width) << hit.weight << endmsg;
      }
    }
    info() << std::string(8 * width, '-') << endmsg;
  }

  (*m_rec_hits) += n_hits_total_rec;
  (*m_allen_hits) += n_hits_total_allen;
}
