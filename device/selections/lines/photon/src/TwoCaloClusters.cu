/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include <math.h>
#include "TwoCaloClusters.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

// Explicit instantiation
INSTANTIATE_LINE(two_calo_clusters_line::two_calo_clusters_line_t, two_calo_clusters_line::Parameters)

void two_calo_clusters_line::two_calo_clusters_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants);
  set_size<dev_local_decisions_t>(arguments, get_decisions_size(arguments));
}

__device__ bool two_calo_clusters_line::two_calo_clusters_line_t::select(
  const Parameters& parameters,
  std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned> input)
{
  const auto number_of_velo_tracks = std::get<1>(input);
  const auto ecal_number_of_clusters = std::get<2>(input);
  const auto n_pvs = std::get<3>(input);
  const auto dicluster = std::get<0>(input);

  bool decision = (dicluster.Mass > parameters.minMass) && (dicluster.Mass < parameters.maxMass) &&
                  (dicluster.Pt > parameters.minPt) && (dicluster.Pt > parameters.minPtEta * (10 - dicluster.Eta)) &&
                  (dicluster.et1 > parameters.minEt_clusters && dicluster.et2 > parameters.minEt_clusters) &&
                  (dicluster.et1 + dicluster.et2 > parameters.minSumEt_clusters) &&
                  (dicluster.CaloNeutralE19_1 > parameters.minE19_clusters &&
                   dicluster.CaloNeutralE19_2 > parameters.minE19_clusters) &&
                  (number_of_velo_tracks <= parameters.max_velo_tracks) &&
                  (ecal_number_of_clusters <= parameters.max_ecal_clusters) && (n_pvs <= parameters.max_n_pvs) &&
                  (dicluster.Eta < parameters.eta_max);

  return decision;
}

void two_calo_clusters_line::two_calo_clusters_line_t::init_tuples(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_local_decisions_t>(arguments, false, context);
}

__device__ void two_calo_clusters_line::two_calo_clusters_line_t::fill_tuples(
  const Parameters& parameters,
  std::tuple<const TwoCaloCluster, const unsigned, const unsigned, const unsigned>,
  unsigned index,
  bool sel)
{
  parameters.dev_local_decisions[index] = sel;
}

void two_calo_clusters_line::two_calo_clusters_line_t::output_tuples(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  [[maybe_unused]] const RuntimeOptions& runtime_options,
  [[maybe_unused]] const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());

  // Distributions per dicluster
  auto tree_twoclusters = handler.tree("monitor_tree_twoclusters");
  if (tree_twoclusters == nullptr) return;

  // Distributions per event
  auto tree_evts = handler.tree("monitor_tree_evts");
  if (tree_evts == nullptr) return;

  const auto host_ecal_twocluster_offsets = make_host_buffer<dev_ecal_twocluster_offsets_t>(arguments, context);
  const auto host_ecal_twoclusters = make_host_buffer<dev_ecal_twoclusters_t>(arguments, context);
  const auto host_local_decisions = make_host_buffer<dev_local_decisions_t>(arguments, context);

  float Mass = 0.f;
  float Pt = 0.f;
  float Distance = 0.f;
  float x1 = 0.f;
  float x2 = 0.f;
  float y1 = 0.f;
  float y2 = 0.f;
  float et1 = 0.f;
  float et2 = 0.f;
  float e19_1 = 0.f;
  float e19_2 = 0.f;
  unsigned num_twoclusters = 0u;
  unsigned event_number = 0u;

  handler.branch(tree_twoclusters, "Mass", Mass);
  handler.branch(tree_twoclusters, "Pt", Pt);
  handler.branch(tree_twoclusters, "Distance", Distance);
  handler.branch(tree_twoclusters, "x1", x1);
  handler.branch(tree_twoclusters, "x2", x2);
  handler.branch(tree_twoclusters, "y1", y1);
  handler.branch(tree_twoclusters, "y2", y2);
  handler.branch(tree_twoclusters, "et1", et1);
  handler.branch(tree_twoclusters, "et2", et2);
  handler.branch(tree_twoclusters, "e19_1", e19_1);
  handler.branch(tree_twoclusters, "e19_2", e19_2);
  handler.branch(tree_twoclusters, "num_twoclusters", num_twoclusters);
  handler.branch(tree_twoclusters, "event_number", event_number);

  handler.branch(tree_evts, "num_twoclusters", num_twoclusters);

  auto const n_events = first<host_number_of_events_t>(arguments);

  for (unsigned event_index = 0; event_index < n_events; event_index++) {
    const unsigned& twoclusters_offset = host_ecal_twocluster_offsets[event_index];
    num_twoclusters = host_ecal_twocluster_offsets[event_index + 1] - twoclusters_offset;
    event_number = event_index;
    tree_evts->Fill();

    for (unsigned twocluster_index = 0; twocluster_index < num_twoclusters; twocluster_index++) {
      const bool& decision = host_local_decisions[twoclusters_offset + twocluster_index];
      if (decision) {
        const auto& dicluster = host_ecal_twoclusters[twoclusters_offset + twocluster_index];

        Mass = dicluster.Mass;
        Distance = dicluster.Distance;
        Pt = dicluster.Pt;
        x1 = dicluster.x1;
        x2 = dicluster.x2;
        y1 = dicluster.y1;
        y2 = dicluster.y2;
        et1 = dicluster.et1;
        et2 = dicluster.et2;
        e19_1 = dicluster.CaloNeutralE19_1;
        e19_2 = dicluster.CaloNeutralE19_2;

        tree_twoclusters->Fill();
      }
    }
  }
}
