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
#include "BuildConeJets.cuh"
#include "Common.h"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(build_cone_jets::build_cone_jets_t)

__host__ __device__ float deltaPhi(const float phi1, const float phi2)
{
  // Normalize to the range [-pi, pi]
  float dphi = phi1 - phi2;
  if (!std::isfinite(dphi)) return std::numeric_limits<float>::quiet_NaN();
  dphi = fmodf(dphi + Allen::constants::pi_f_float, 2 * Allen::constants::pi_f_float);
  if (dphi < 0) dphi += 2 * Allen::constants::pi_f_float;
  return dphi - Allen::constants::pi_f_float;
}

__host__ __device__ float deltaR(const float eta1, const float phi1, const float eta2, const float phi2)
{
  float deta = eta1 - eta2;
  float dphi = deltaPhi(phi1, phi2);
  return sqrtf(dphi * dphi + deta * deta);
}

void build_cone_jets::build_cone_jets_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_jet_data_t>(arguments, m_n_max_jets * first<host_number_of_events_t>(arguments));
  set_size<dev_jet_clusters_t>(arguments, m_n_max_jets * first<host_number_of_events_t>(arguments));
  set_size<dev_track_masks_t>(arguments, first<host_number_of_tracks_t>(arguments));
  set_size<dev_neutral_masks_t>(arguments, first<host_number_of_neutrals_t>(arguments));
  set_size<dev_jet_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_jets_t>(arguments, 1);
}

void build_cone_jets::build_cone_jets_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  Allen::Context const& context) const
{
  Allen::memset_async<dev_track_masks_t>(arguments, -1, context);
  Allen::memset_async<dev_neutral_masks_t>(arguments, -1, context);
  Allen::memset_async<dev_jet_data_t>(arguments, 0, context);
  Allen::memset_async<dev_jet_clusters_t>(arguments, 0, context);
  Allen::memset_async<dev_jet_offsets_t>(arguments, 0, context); // initialize to 0, in case event_list size == 0
  data<host_number_of_jets_t>(arguments)[0] = 0;                 // initialize to 0, in case event_list size == 0
  global_function(build_jets)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments, m_n_max_jets, m_cone_radius, data<host_number_of_jets_t>(arguments));
  Allen::synchronize(context); // sync needed for host_number_of_jets
}

__global__ void build_cone_jets::build_jets(
  build_cone_jets::Parameters parameters,
  const unsigned n_max_jets,
  const float cone_radius,
  unsigned* host_number_of_jets)
{
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i <= parameters.dev_number_of_events[0];
       i += blockDim.x * gridDim.x) {
    parameters.dev_jet_offsets[i] = i * n_max_jets;
  }
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    *host_number_of_jets = parameters.dev_number_of_events[0] * n_max_jets;
  }

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto tracks = static_cast<const Allen::Views::Physics::BasicParticles>(
    parameters.dev_long_track_particle_container[0].container(event_number));
  const auto calos = static_cast<const Allen::Views::Physics::NeutralBasicParticles>(
    parameters.dev_neutral_particle_container[0].container(event_number));
  const int n_tracks = tracks.size();
  const int n_calos = calos.size();

  int* event_track_masks = parameters.dev_track_masks + tracks.offset();
  int* event_neutral_masks = parameters.dev_neutral_masks + calos.offset();
  Jets::Jet* event_jets = parameters.dev_jet_data + n_max_jets * event_number;
  CaloCluster* event_jet_clusters = parameters.dev_jet_clusters + n_max_jets * event_number;

  // Create jets until no seed tracks are available or the maximum number of
  // jets is reached.
  unsigned i_jet = 0;
  while (i_jet < n_max_jets) {

    __shared__ int max_pt_idx;
    __shared__ unsigned fixed_pt_sum;
    __shared__ unsigned fixed_eta_sum;
    __shared__ int fixed_phi_sum;

    // Find the seed track for this iteration.
    if (threadIdx.x == 0) {

      float max_pt = 0.f;
      max_pt_idx = -1;
      for (int i_track = 0; i_track < n_tracks; i_track++) {

        // Skip used tracks.
        if (event_track_masks[i_track] >= 0) continue;

        const auto track = tracks.particle(i_track);
        if (track.state().pt() > max_pt) {
          max_pt = track.state().pt();
          max_pt_idx = i_track;
        }
      }

      // Mask the seed track.
      if (max_pt_idx != -1) {
        event_track_masks[max_pt_idx] = i_jet;
      }

      fixed_pt_sum = 0;
      fixed_eta_sum = 0;
      fixed_phi_sum = 0;
    }

    __syncthreads();
    // If no seed track was found, then we're out of tracks, so we can
    // exit the loop.
    if (max_pt_idx == -1) break;

    __shared__ Jets::Jet jet;

    // Find the tracks that will go in the jet.
    const auto seed_track = tracks.particle(max_pt_idx);
    for (int i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {

      // Skip used tracks, including the seed.
      if (event_track_masks[i_track] >= 0) continue;
      const auto test_track = tracks.particle(i_track);

      // Check if the tracks are associated to the same PV. If both tracks have
      // a PV, check if it's the same. If only one track has an associated PV
      // (this should be impossible), skip the pair. If the event has no PVs,
      // make no requirement.
      const int found_pvs = test_track.has_pv() + seed_track.has_pv();
      switch (found_pvs) {
      case 1: continue;
      case 2:
        if (&(seed_track.pv()) != &(test_track.pv())) continue;
      }

      // Check if the track is in the cone and assign it.
      float dr =
        deltaR(seed_track.state().eta(), seed_track.state().phi(), test_track.state().eta(), test_track.state().phi());

      // Mask the track if it's in the cone.
      if (dr < cone_radius) {
        event_track_masks[i_track] = i_jet;

        // Use fixed-precision addition so these sums will be deterministic.
        atomicAdd(&(jet.n_tracks), 1);
        atomicAdd(&fixed_pt_sum, (unsigned) (test_track.state().pt() / Jets::pt_sum_precision));
        atomicAdd(
          &fixed_eta_sum,
          (unsigned) (test_track.state().pt() * test_track.state().eta() / Jets::eta_weighted_sum_precision));
        float dphi = deltaPhi(seed_track.state().phi(), test_track.state().phi());
        atomicAdd(&fixed_phi_sum, (int) (dphi * test_track.state().pt() / Jets::phi_weighted_sum_precision));
      }
    }

    // Find the neutrals that will go in the cone.
    for (int i_calo = threadIdx.x; i_calo < n_calos; i_calo += blockDim.x) {

      // Check if the calo cluster is masked.
      if (event_neutral_masks[i_calo] >= 0) continue;
      const auto test_calo = calos.particle(i_calo);

      // Check if the calo cluster is in the cone.
      float dr = deltaR(seed_track.state().eta(), seed_track.state().phi(), test_calo.eta(), test_calo.phi());

      // Mask the photon if it's in the cone.
      if (dr < cone_radius) {
        event_neutral_masks[i_calo] = i_jet;

        atomicAdd(&(jet.n_calos), 1);
        atomicAdd(&fixed_pt_sum, (unsigned) (test_calo.et() / Jets::pt_sum_precision));
        atomicAdd(&fixed_eta_sum, (unsigned) (test_calo.et() * test_calo.eta() / Jets::eta_weighted_sum_precision));
        float dphi = deltaPhi(seed_track.state().phi(), test_calo.phi());
        atomicAdd(&fixed_phi_sum, (int) (test_calo.et() * dphi / Jets::phi_weighted_sum_precision));
      }
    }

    __syncthreads();

    if (threadIdx.x == 0) {
      jet.pt = fixed_pt_sum * Jets::pt_sum_precision;
      jet.eta = fixed_eta_sum * Jets::eta_weighted_sum_precision / jet.pt;
      jet.phi = deltaPhi(seed_track.state().phi(), fixed_phi_sum / jet.pt);
      event_jets[i_jet] = jet;
      event_jet_clusters[i_jet] = CaloCluster(jet);
    }

    i_jet++;
    __syncthreads();
  }
}
