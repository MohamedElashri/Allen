/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#include "FilterVELOTracks.cuh"

INSTANTIATE_ALGORITHM(FilterVELOTracks::filter_velo_tracks_t)

// TODO: can be merged with VertexFitDefinitions once #402 is fixed
template<typename part>
__device__ float velo_doca(const part& stateA, const part& stateB)
{
  const float xA = stateA.x;
  const float yA = stateA.y;
  const float zA = stateA.z;
  const float txA = stateA.tx;
  const float tyA = stateA.ty;
  const float xB = stateB.x;
  const float yB = stateB.y;
  const float zB = stateB.z;
  const float txB = stateB.tx;
  const float tyB = stateB.ty;
  const float secondAA = txA * txA + tyA * tyA + 1.f;
  const float secondBB = txB * txB + tyB * tyB + 1.f;
  const float secondAB = -txA * txB - tyA * tyB - 1.f;
  const float det = secondAA * secondBB - secondAB * secondAB;
  float ret = -1.f;
  if (fabsf(det) > 0) {
    const float secondinvAA = secondBB / det;
    const float secondinvBB = secondAA / det;
    const float secondinvAB = -secondAB / det;
    const float firstA = txA * (xA - xB) + tyA * (yA - yB) + (zA - zB);
    const float firstB = -txB * (xA - xB) - tyB * (yA - yB) - (zA - zB);
    const float muA = -(secondinvAA * firstA + secondinvAB * firstB);
    const float muB = -(secondinvBB * firstB + secondinvAB * firstA);
    const float dx = (xA + muA * txA) - (xB + muB * txB);
    const float dy = (yA + muA * tyA) - (yB + muB * tyB);
    const float dz = (zA + muA) - (zB + muB);
    ret = sqrtf(dx * dx + dy * dy + dz * dz);
  }
  return ret;
}

void FilterVELOTracks::filter_velo_tracks_t::set_arguments_size(
  ArgumentReferences<FilterVELOTracks::Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_filtered_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_number_of_close_track_pairs_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_filtered_velo_track_idx_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void FilterVELOTracks::filter_velo_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto dev_beamline = constants.dev_beamline.data();
  global_function(filter_velo_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, dev_beamline);
}

__global__ void FilterVELOTracks::filter_velo_tracks(FilterVELOTracks::Parameters parameters, float* dev_beamline)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_tracks = parameters.dev_velo_track_view[event_number];
  const auto velo_states = parameters.dev_velo_states_view[event_number];
  unsigned* event_velo_filtered_idx = parameters.dev_filtered_velo_track_idx + velo_tracks.offset();

  __shared__ unsigned shared_number_of_filtered_tracks;
  __shared__ unsigned shared_number_of_close_track_pairs;

  if (threadIdx.x == 0) {
    shared_number_of_filtered_tracks = 0;
    shared_number_of_close_track_pairs = 0;
  }
  __syncthreads();

  for (unsigned i_track = threadIdx.x; i_track < velo_tracks.size(); i_track += blockDim.x) {
    const auto track = velo_tracks.track(i_track);
    const auto state = track.state(velo_states);

    const float beamspot_doca_r = std::sqrt(
      (state.x - dev_beamline[0]) * (state.x - dev_beamline[0]) +
      (state.y - dev_beamline[1]) * (state.y - dev_beamline[1]));

    if (beamspot_doca_r > parameters.beamdoca_r) {
      auto insert_index = atomicAdd(&shared_number_of_filtered_tracks, 1);
      event_velo_filtered_idx[insert_index] = i_track;
    }
  }

  __syncthreads();
  parameters.dev_number_of_filtered_tracks[event_number] = shared_number_of_filtered_tracks;

  for (unsigned idx = threadIdx.x; idx < shared_number_of_filtered_tracks; idx += blockDim.x) {
    auto trackA = velo_tracks.track(event_velo_filtered_idx[idx]);
    for (unsigned jdx = threadIdx.y + idx + 1; jdx < shared_number_of_filtered_tracks; jdx += blockDim.y) {
      auto trackB = velo_tracks.track(event_velo_filtered_idx[jdx]);

      auto tracks_doca = velo_doca(trackA.state(velo_states), trackB.state(velo_states));
      if (tracks_doca < parameters.max_doca_for_close_track_pairs) atomicAdd(&shared_number_of_close_track_pairs, 1);
    }
  }

  __syncthreads();
  parameters.dev_number_of_close_track_pairs[event_number] = shared_number_of_close_track_pairs;
}
