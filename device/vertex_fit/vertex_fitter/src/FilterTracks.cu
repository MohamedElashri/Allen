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
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_sv_atomics_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk1_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk2_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_sv_poca_t>(arguments, 3 * 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
}

void FilterTracks::filter_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_sv_atomics_t>(arguments, 0, context);

  global_function(filter_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void FilterTracks::filter_tracks(FilterTracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = event_number * 10 * VertexFit::max_svs;
  unsigned* event_sv_number = parameters.dev_sv_atomics + event_number;
  unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  const auto long_track_particles = parameters.dev_long_track_particles[event_number];
  const unsigned n_scifi_tracks = long_track_particles.size();

  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < n_scifi_tracks; i_track += blockDim.x) {

    // Filter first track.
    const auto trackA = long_track_particles.particle(i_track);

    if (
      trackA.pt() < parameters.track_min_pt || (trackA.ip_chi2() < parameters.track_min_ipchi2 && !trackA.is_lepton()) ||
      (trackA.chi2() / trackA.ndof() > parameters.track_max_chi2ndof && !trackA.is_lepton()) ||
      (trackA.chi2() / trackA.ndof() > parameters.track_muon_max_chi2ndof && trackA.is_lepton())) {
      continue;
    }

    for (unsigned j_track = threadIdx.y + i_track + 1; j_track < n_scifi_tracks; j_track += blockDim.y) {

      // Filter second track.
      const auto trackB = long_track_particles.particle(j_track);
      if (
        trackB.pt() < parameters.track_min_pt ||
        (trackB.ip_chi2() < parameters.track_min_ipchi2 && !trackB.is_lepton()) ||
        (trackB.chi2() / trackB.ndof() > parameters.track_max_chi2ndof && !trackB.is_lepton()) ||
        (trackB.chi2() / trackB.ndof() > parameters.track_muon_max_chi2ndof && trackB.is_lepton())) {
        continue;
      }

      // Same PV cut for non-muons.
      if (
        trackA.get_pv() != trackB.get_pv() && trackA.ip_chi2() < parameters.max_assoc_ipchi2 &&
        trackB.ip_chi2() < parameters.max_assoc_ipchi2 && (!trackA.is_lepton() || !trackB.is_lepton())) {
        continue;
      }

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
