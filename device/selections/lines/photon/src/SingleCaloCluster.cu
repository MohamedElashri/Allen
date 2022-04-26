/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SingleCaloCluster.cuh"
#include <ROOTHeaders.h>
#include "CaloConstants.cuh"

#define POW(x) (x * x)

// Explicit instantiation
INSTANTIATE_LINE(single_calo_cluster_line::single_calo_cluster_line_t, single_calo_cluster_line::Parameters)

void single_calo_cluster_line::single_calo_cluster_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, runtime_options, constants, host_buffers);

  // must set_size of all output variables

  set_size<typename Parameters::dev_decisions_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_decisions_offsets_t>(
    arguments, first<typename Parameters::host_number_of_events_t>(arguments));

  set_size<typename Parameters::host_post_scaler_t>(arguments, 1);

  set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);

  set_size<typename Parameters::dev_clusters_x_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::host_clusters_x_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_clusters_y_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::host_clusters_y_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_clusters_Et_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::host_clusters_Et_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_clusters_Eta_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::host_clusters_Eta_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_clusters_Phi_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::host_clusters_Phi_t>(
    arguments, single_calo_cluster_line::single_calo_cluster_line_t::get_decisions_size(arguments));
}

__device__ bool single_calo_cluster_line::single_calo_cluster_line_t::select(
  const Parameters& parameters,
  std::tuple<const CaloCluster> input)
{
  const auto& ecal_cluster = std::get<0>(input);
  const float z = Calo::Constants::z; // mm

  const float sintheta =
    sqrtf((POW(ecal_cluster.x) + POW(ecal_cluster.y)) / (POW(ecal_cluster.x) + POW(ecal_cluster.y) + POW(z)));
  const float E_T = ecal_cluster.e * sintheta;
  const float decision = (E_T > parameters.minEt && E_T < parameters.maxEt);

  return decision;
}

void single_calo_cluster_line::single_calo_cluster_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context) const
{

  initialize<dev_clusters_x_t>(arguments, -1, context);
  initialize<dev_clusters_y_t>(arguments, -1, context);
  initialize<dev_clusters_Et_t>(arguments, -1, context);
  initialize<dev_clusters_Eta_t>(arguments, -1, context);
  initialize<dev_clusters_Phi_t>(arguments, -1, context);
}

__device__ void single_calo_cluster_line::single_calo_cluster_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const CaloCluster> input,
  unsigned index,
  bool sel)
{
  const auto& ecal_cluster = std::get<0>(input);
  const float& z = Calo::Constants::z; // mm
  const float& sintheta =
    sqrtf((POW(ecal_cluster.x) + POW(ecal_cluster.y)) / (POW(ecal_cluster.x) + POW(ecal_cluster.y) + POW(z)));
  const float& cosphi = ecal_cluster.x / sqrtf(POW(ecal_cluster.x) + POW(ecal_cluster.y));
  const float& E_T = ecal_cluster.e * sintheta;

  if (sel) {
    parameters.dev_clusters_x[index] = ecal_cluster.x;
    parameters.dev_clusters_y[index] = ecal_cluster.y;
    parameters.dev_clusters_Et[index] = E_T;
    parameters.dev_clusters_Eta[index] = asinf(sintheta);
    parameters.dev_clusters_Phi[index] = acosf(cosphi);
  }
}

void single_calo_cluster_line::single_calo_cluster_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  [[maybe_unused]] const RuntimeOptions& runtime_options,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifdef WITH_ROOT
  auto handler = runtime_options.root_service->handle(name());
  auto tree = handler.tree("monitor_tree");
  if (tree == nullptr) return;

  Allen::copy<host_clusters_x_t, dev_clusters_x_t>(arguments, context);
  Allen::copy<host_clusters_y_t, dev_clusters_y_t>(arguments, context);
  Allen::copy<host_clusters_Et_t, dev_clusters_Et_t>(arguments, context);
  Allen::copy<host_clusters_Eta_t, dev_clusters_Eta_t>(arguments, context);
  Allen::copy<host_clusters_Phi_t, dev_clusters_Phi_t>(arguments, context);
  Allen::synchronize(context);

  float Et = 0.f;
  float Eta = 0.f;
  float Phi = 0.f;
  float x = 0.f;
  float y = 0.f;
  size_t ev = 0;

  handler.branch(tree, "x", x);
  handler.branch(tree, "y", y);
  handler.branch(tree, "Et", Et);
  handler.branch(tree, "Eta", Eta);
  handler.branch(tree, "Phi", Phi);
  handler.branch(tree, "ev", ev);

  unsigned n_clusters = size<host_clusters_Et_t>(arguments);

  size_t i0 = tree->GetEntries();

  for (unsigned i = 0; i < n_clusters; i++) {

    auto clusters_x = data<host_clusters_x_t>(arguments) + i;
    auto clusters_y = data<host_clusters_y_t>(arguments) + i;
    auto clusters_Et = data<host_clusters_Et_t>(arguments) + i;
    auto clusters_Eta = data<host_clusters_Eta_t>(arguments) + i;
    auto clusters_Phi = data<host_clusters_Phi_t>(arguments) + i;

    if (clusters_Et[0] > 0) {

      x = clusters_x[0];
      y = clusters_y[0];
      Et = clusters_Et[0];
      Eta = clusters_Eta[0];
      Phi = clusters_Phi[0];
      ev = i0 + i;

      tree->Fill();
    }
  }
#endif
}
