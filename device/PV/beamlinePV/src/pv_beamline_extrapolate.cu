/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "pv_beamline_extrapolate.cuh"

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_pvtracks_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_pvtrack_z_t>(arguments, 2 * first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void pv_beamline_extrapolate::pv_beamline_extrapolate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  global_function(pv_beamline_extrapolate)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), stream)(
    arguments);
}

__global__ void pv_beamline_extrapolate::pv_beamline_extrapolate(pv_beamline_extrapolate::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstKalmanStates velo_states {parameters.dev_velo_kalman_beamline_states,
                                                     velo_tracks.total_number_of_tracks()};

  const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = velo_tracks.tracks_offset(event_number);
  const unsigned total_number_of_tracks = velo_tracks.total_number_of_tracks();

  for (unsigned index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const KalmanVeloState s {velo_states.get(event_tracks_offset + index)};

    PatPV::XYZPoint beamline {0.f, 0.f, 0.f};
    const float dz = (s.tx * (beamline.x - s.x) + s.ty * (beamline.y - s.y)) / (s.tx * s.tx + s.ty * s.ty);

    float z = -9999.f;
    if (dz * s.c20 >= 0.f && dz * s.c31 >= 0.f) {
      z = s.z + dz;
    }

    parameters.dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + index] = z;
  }

  __syncthreads();

  // Insert in order
  for (unsigned index = threadIdx.x; index < number_of_tracks_event; index += blockDim.x) {
    const auto z = parameters.dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + index];
    unsigned insert_position = 0;

    for (unsigned other = 0; other < number_of_tracks_event; ++other) {
      const auto other_z = parameters.dev_pvtrack_z[total_number_of_tracks + event_tracks_offset + other];
      insert_position += z > other_z || (z == other_z && index > other);
    }

    const KalmanVeloState s {velo_states.get(event_tracks_offset + index)};
    PVTrack pvtrack = PVTrack {s, z - s.z};
    parameters.dev_pvtracks[event_tracks_offset + insert_position] = pvtrack;
    parameters.dev_pvtrack_z[event_tracks_offset + index] = z;
  }
}
