/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "FilterTracks.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"

INSTANTIATE_ALGORITHM(FilterTracks::filter_tracks_t)

void FilterTracks::filter_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_atomics_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk1_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk2_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_sv_poca_t>(arguments, 3 * 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_track_prefilter_result_t>(arguments, first<host_number_of_tracks_t>(arguments));
}

void FilterTracks::filter_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_sv_atomics_t>(arguments, 0, context);

  global_function(prefilter_tracks)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_prefilter_t>(), context)(arguments);

  global_function(filter_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_filter_t>(), context)(
    arguments);
}

__global__ void FilterTracks::prefilter_tracks(FilterTracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  const unsigned n_tracks = long_track_particles.size();
  bool* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();

  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    const auto track = long_track_particles.particle(i_track);
    const auto state = track.state();
    const float pt = state.pt();
    const float ipchi2 = track.ip_chi2();
    const float ip = track.ip();
    const float chi2ndof = track.chi2() / track.ndof();
    bool dec = pt > parameters.track_min_pt_both && ipchi2 > parameters.track_min_ipchi2_both &&
               chi2ndof < parameters.track_max_chi2ndof && ip > parameters.track_min_ip_both;
    if (parameters.require_muon) dec &= track.is_muon();
    if (parameters.require_electron) dec &= track.is_electron();
    if (parameters.require_lepton) dec &= track.is_lepton();
    event_prefilter_result[i_track] = dec;
  }
}

__global__ void FilterTracks::filter_tracks(FilterTracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = event_number * 10 * VertexFit::max_svs;
  unsigned* event_sv_number = parameters.dev_sv_atomics + event_number;
  unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  bool* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();
  const unsigned n_scifi_tracks = long_track_particles.size();

  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < n_scifi_tracks; i_track += blockDim.x) {
    // Filter first track.
    if (!event_prefilter_result[i_track]) continue;
    const auto trackA = long_track_particles.particle(i_track);
    const float ipchi2A = trackA.ip_chi2();
    const float ipA = trackA.ip();
    const float ptA = trackA.state().pt();

    for (unsigned j_track = threadIdx.y + i_track + 1; j_track < n_scifi_tracks; j_track += blockDim.y) {
      // Filter second track.
      if (!event_prefilter_result[j_track]) continue;
      const auto trackB = long_track_particles.particle(j_track);
      const float ipchi2B = trackB.ip_chi2();
      const float ipB = trackB.ip();
      const float ptB = trackB.state().pt();

      // OS pair cut. Tracks must have opposite-sign charge.
      if (parameters.require_os_pair) {
        if (trackA.state().charge() * trackB.state().charge() > 0.f) continue;
      }

      // Same PV cut. If tracks are "prompt", they must be associated to the same PV.
      if (parameters.require_same_pv) {
        if (
          &(trackA.pv()) != &(trackB.pv()) && ipchi2A < parameters.max_assoc_ipchi2 &&
          ipchi2B < parameters.max_assoc_ipchi2) {
          continue;
        }
      }

      // Check cuts on at least one track
      if (ptA < parameters.track_min_pt_either && ptB < parameters.track_min_pt_either) continue;
      if (ipA < parameters.track_min_ip_either && ipB < parameters.track_min_ip_either) continue;
      if (ipchi2A < parameters.track_min_ipchi2_either && ipchi2B < parameters.track_min_ipchi2_either) continue;

      // Check the sum of pt.
      if (ptA + ptB < parameters.sum_pt_min) continue;

      // Check the DOCA.
      const float doca = VertexFit::doca(trackA, trackB);
      if (doca > parameters.doca_max) continue;

      // Check the POCA.
      float x;
      float y;
      float z;
      if (!VertexFit::poca(trackA, trackB, x, y, z)) {
        continue;
      }

      unsigned vertex_idx = atomicAdd(event_sv_number, 1);
      event_poca[3 * vertex_idx] = x;
      event_poca[3 * vertex_idx + 1] = y;
      event_poca[3 * vertex_idx + 2] = z;
      event_svs_trk1_idx[vertex_idx] = i_track;
      event_svs_trk2_idx[vertex_idx] = j_track;
    }
  }
}
