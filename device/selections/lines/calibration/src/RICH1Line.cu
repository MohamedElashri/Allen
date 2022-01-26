/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "RICH1Line.cuh"
#include <ROOTHeaders.h>
#include <ROOTService.h>
#include <random>

// Explicit instantiation of the line
INSTANTIATE_LINE(rich_1_line::rich_1_line_t, rich_1_line::Parameters)

void rich_1_line::rich_1_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<typename Parameters::dev_decisions_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::dev_decisions_offsets_t>(
    arguments, first<typename Parameters::host_number_of_events_t>(arguments));
  set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
  set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);
  set_size<typename Parameters::host_lhcbid_container_t>(arguments, 1);
  set_size<typename Parameters::dev_selected_events_t>(
    arguments, first<typename Parameters::host_number_of_events_t>(arguments));
  set_size<typename Parameters::dev_selected_events_size_t>(arguments, 1);
  set_size<typename Parameters::host_selected_events_size_t>(arguments, 1);

  set_size<typename Parameters::dev_decision_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_decision_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_pt_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_pt_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_p_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_p_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_track_chi2_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_track_chi2_t>(
    arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_eta_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_eta_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));

  set_size<typename Parameters::dev_phi_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
  set_size<typename Parameters::host_phi_t>(arguments, rich_1_line::rich_1_line_t::get_decisions_size(arguments));
}

#ifdef WITH_ROOT
/*
 * Documented in ExampleOneTrackLine.cuh
 */
void rich_1_line::rich_1_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  initialize<dev_decision_t>(arguments, false, context);
  initialize<dev_pt_t>(arguments, 0, context);
  initialize<dev_p_t>(arguments, 0, context);
  initialize<dev_track_chi2_t>(arguments, 0, context);
  initialize<dev_eta_t>(arguments, 0, context);
  initialize<dev_phi_t>(arguments, 0, context);
}

/*
 * Documented in ExampleOneTrackLine.cuh
 */
__device__ void rich_1_line::rich_1_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input,
  unsigned index,
  bool sel)
{
  const auto& track = std::get<0>(input);

  parameters.dev_pt[index] = track.pt();
  parameters.dev_p[index] = track.p();
  parameters.dev_track_chi2[index] = track.chi2 / track.ndof;
  parameters.dev_eta[index] = track.eta();
  parameters.dev_phi[index] = trackPhi(track);

  parameters.dev_decision[index] = sel;
}

/*
 * Documented in ExampleOneTrackLine.cuh
 */
void rich_1_line::rich_1_line_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  if (!property<make_tuple_t>()) return;

  auto handler = runtime_options.root_service->handle(name());
  auto tree = handler.tree("monitor_tree");
  if (tree == nullptr) return;

  Allen::copy_async<host_decision_t, dev_decision_t>(arguments, context);
  Allen::copy_async<host_pt_t, dev_pt_t>(arguments, context);
  Allen::copy_async<host_p_t, dev_p_t>(arguments, context);
  Allen::copy_async<host_track_chi2_t, dev_track_chi2_t>(arguments, context);
  Allen::copy_async<host_eta_t, dev_eta_t>(arguments, context);
  Allen::copy_async<host_phi_t, dev_phi_t>(arguments, context);

  Allen::synchronize(context);

  bool decision {};
  float pt {};
  float p {};
  float chi2 {};
  float eta {};
  float phi {};
  size_t ev {};

  handler.branch(tree, "decision", decision);
  handler.branch(tree, "pt", pt);
  handler.branch(tree, "p", p);
  handler.branch(tree, "ev", ev);
  handler.branch(tree, "chi2", chi2);
  handler.branch(tree, "eta", eta);
  handler.branch(tree, "phi", phi);

  unsigned n_svs = size<host_pt_t>(arguments);
  bool* sv_decision {nullptr};
  float* sv_pt {nullptr};
  float* sv_p {nullptr};
  float* sv_chi2 {nullptr};
  float* sv_eta {nullptr};
  float* sv_phi {nullptr};
  size_t i0 = tree->GetEntries();
  for (unsigned i = 0; i < n_svs; i++) {
    sv_decision = data<host_decision_t>(arguments) + i;
    sv_pt = data<host_pt_t>(arguments) + i;
    sv_p = data<host_p_t>(arguments) + i;
    sv_chi2 = data<host_track_chi2_t>(arguments) + i;
    sv_eta = data<host_eta_t>(arguments) + i;
    sv_phi = data<host_phi_t>(arguments) + i;

    decision = *sv_decision;
    pt = *sv_pt;
    p = *sv_p;
    chi2 = *sv_chi2;
    eta = *sv_eta;
    phi = *sv_phi;

    ev = i0 + i;
    tree->Fill();
  }
}
#endif

__device__ bool rich_1_line::rich_1_line_t::passes(
  const ParKalmanFilter::FittedTrack& track,
  const Parameters& parameters)
{

  // Cut on momentum
  if (track.p() < parameters.minP) return false;

  // Cut on track Chi2 (fiducial)
  if (track.chi2 / track.ndof > parameters.maxTrChi2) return false;

  // Cut on transverse momentum (fiducial)
  if (track.pt() < parameters.minPt) return false;

  // For each eta/phi bin pair, check if our track falls in it
  // Put this last as we return true if the track falls within our allowed bins; otherwise return false
  for (unsigned j = 0; j < parameters.minPhi.get().size(); ++j) {
    const auto eta {track.eta()};
    const auto phi {trackPhi(track)};

    // For now, eta is a 1-length array
    if (
      parameters.minEta.get()[0] < eta && eta < parameters.maxEta.get()[0] && parameters.minPhi.get()[j] < phi &&
      phi < parameters.maxPhi.get()[j]) {
      return true;
    }
  }
  return false;
}

__device__ bool rich_1_line::rich_1_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input)
{
  const auto& track = std::get<0>(input);

  return passes(track, parameters);
}
