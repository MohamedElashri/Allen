/*****************************************************************************\
* (c) Copyright 2023-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DataQualityValidator_longTracks.cuh"
#include "VeloDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "CopyTrackParameters.cuh"
// For the Offline Data Quality Validator, not all information
// needed about long tracks are easily available to the host.
// For this reason the long track module is made as a device
// algorithm instead.

INSTANTIATE_ALGORITHM(data_quality_validator_long::data_quality_validator_long_t)

__global__ void data_quality_validator_long::copyLongTrackIP(data_quality_validator_long::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const auto long_track_particles_view = parameters.dev_particle_container->container(event_number);
  const unsigned offset_long_tracks = long_track_particles_view.offset();

  data_quality_validator_long::long_track_info* infos = parameters.dev_dq_long_track_info + offset_long_tracks;

  const unsigned number_of_tracks = long_track_particles_view.size();

  for (unsigned i_track = threadIdx.x; i_track < number_of_tracks; i_track += blockDim.x) {
    data_quality_validator_long::long_track_info track_infos = infos[i_track];
    const auto track = long_track_particles_view.particle(i_track);

    track_infos.ip_chi2 = track.ip_chi2();
    track_infos.ip_x = track.ip_x();
    track_infos.ip_y = track.ip_y();
    track_infos.chi2 = track.chi2();

    track_infos.is_muon = track.is_muon();
    track_infos.is_electron = track.is_electron();

    const auto state = track.state();
    track_infos.cov[0][0] = state.c00();
    track_infos.cov[1][1] = state.c11();
    track_infos.cov[2][0] = state.c20();
    track_infos.cov[2][2] = state.c22();
    track_infos.cov[3][1] = state.c31();
    track_infos.cov[3][3] = state.c33();
    track_infos.tx = state.tx();
    track_infos.ty = state.ty();
    track_infos.qop = state.qop();
    track_infos.eta = state.eta();
    track_infos.pt = state.pt();

    infos[i_track] = track_infos;
  }
  return;
}

void data_quality_validator_long::data_quality_validator_long_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_dq_long_track_info_t>(arguments, first<host_number_of_reconstructed_long_tracks_t>(arguments));
}

void data_quality_validator_long::data_quality_validator_long_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  // Copy the IP params over
  global_function(copyLongTrackIP)(first<host_number_of_events_t>(arguments), m_block_dim, context)(arguments);

  // Write them out
  if (m_enable_tupling.value()) output_monitor(arguments, runtime_options, context);
}

void data_quality_validator_long::data_quality_validator_long_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());
  // --> Long Track Particles
  auto tree = handler.tree("long_track_particles");
  auto eventTree = handler.tree("long_tracks_event");

  const auto event_long_tracks_offsets = make_host_buffer<dev_offsets_long_tracks_t>(arguments, context);
  const auto event_list = make_host_buffer<dev_event_list_t>(arguments, context);
  const auto long_track_info_buffer = make_host_buffer<dev_dq_long_track_info_t>(arguments, context);

  float ip_chi2, chi2, ip_x, ip_y;
  int is_muon, is_electron;
  handler.branch(tree, "ip_chi2", ip_chi2);
  handler.branch(tree, "chi2", chi2);
  handler.branch(tree, "ip_x", ip_x);
  handler.branch(tree, "ip_y", ip_y);
  handler.branch(tree, "is_muon", is_muon);
  handler.branch(tree, "is_electron", is_electron);

  float kalman_cov[4][4] = {{0}};
  float kalman_tx, kalman_ty, kalman_qop, kalman_eta, kalman_phi, kalman_pt;
  handler.branch(tree, "cov00", kalman_cov[0][0]);
  handler.branch(tree, "cov11", kalman_cov[1][1]);
  handler.branch(tree, "cov20", kalman_cov[2][0]);
  handler.branch(tree, "cov22", kalman_cov[2][2]);
  handler.branch(tree, "cov31", kalman_cov[3][1]);
  handler.branch(tree, "cov33", kalman_cov[3][3]);
  handler.branch(tree, "tx", kalman_tx);
  handler.branch(tree, "ty", kalman_ty);
  handler.branch(tree, "qop", kalman_qop);
  handler.branch(tree, "eta", kalman_eta);
  handler.branch(tree, "phi", kalman_phi);
  handler.branch(tree, "pt", kalman_pt);

  float prop_muon, prop_electron;
  int n_long_tracks;
  handler.branch(eventTree, "prop_muon", prop_muon);
  handler.branch(eventTree, "prop_electron", prop_electron);
  handler.branch(eventTree, "n_long_tracks", n_long_tracks);

  for (size_t i = 0; i < event_list.size(); ++i) {
    prop_muon = prop_electron = 0.f;

    const auto evnum = event_list[i];
    const auto long_tracks_offset = event_long_tracks_offsets[evnum];
    n_long_tracks = event_long_tracks_offsets[evnum + 1] - long_tracks_offset;

    std::vector<data_quality_validator_long::long_track_info> dq_long_infos_event = {
      long_track_info_buffer.begin() + long_tracks_offset,
      long_track_info_buffer.begin() + long_tracks_offset + n_long_tracks};

    for (int i_track = 0; i_track < n_long_tracks; i_track++) {
      const auto info = dq_long_infos_event[i_track];
      ip_chi2 = info.ip_chi2;
      chi2 = info.chi2;
      ip_x = info.ip_x;
      ip_y = info.ip_y;
      is_muon = info.is_muon;
      if (is_muon == 1) {
        prop_muon += 1.0f;
      }
      is_electron = info.is_electron;
      if (is_electron == 1) {
        prop_electron += 1.0f;
      }

      // TODO consider copying the Kalman fit straight to
      // host rather than copying to long_track_info struct
      kalman_cov[0][0] = info.cov[0][0];
      kalman_cov[1][1] = info.cov[1][1];
      kalman_cov[2][0] = info.cov[2][0];
      kalman_cov[2][2] = info.cov[2][2];
      kalman_cov[3][1] = info.cov[3][1];
      kalman_cov[3][3] = info.cov[3][3];
      kalman_tx = info.tx;
      kalman_ty = info.ty;
      kalman_qop = info.qop;
      kalman_eta = info.eta;
      kalman_phi = atan2f(kalman_ty, kalman_tx);
      kalman_pt = info.pt;

      tree->Fill();
    }
    prop_muon /= n_long_tracks;
    prop_electron /= n_long_tracks;

    eventTree->Fill();
  }
}
/*---------------------------------------------------------------------------------------------*/
