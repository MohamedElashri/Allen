/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Common.h>
#include <PV_Definitions.cuh>
#include <VeloConsolidated.cuh>
#include <AssociateConsolidated.cuh>
#include <AssociateConstants.cuh>
#include <VeloPVIP.cuh>

void velo_pv_ip::velo_pv_ip_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  auto n_velo_tracks = first<host_number_of_reconstructed_velo_tracks_t>(arguments);
  set_size<dev_velo_pv_ip_t>(arguments, Associate::Consolidated::table_size(n_velo_tracks));
}

void velo_pv_ip::velo_pv_ip_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(velo_pv_ip)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);
}

namespace Distance {
  __device__ float velo_ip(
    Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
    const unsigned state_index,
    const PV::Vertex& vertex)
  {
    float tx = velo_kalman_states.tx(state_index);
    float ty = velo_kalman_states.ty(state_index);
    float dz = vertex.position.z - velo_kalman_states.z(state_index);
    float dx = velo_kalman_states.x(state_index) + dz * tx - vertex.position.x;
    float dy = velo_kalman_states.y(state_index) + dz * ty - vertex.position.y;
    return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
  }

  __device__ float velo_ip_chi2(
    Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
    const unsigned state_index,
    const PV::Vertex& vertex)
  {
    // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
    float tx = velo_kalman_states.tx(state_index);
    float ty = velo_kalman_states.ty(state_index);
    float dz = vertex.position.z - velo_kalman_states.z(state_index);
    float dx = velo_kalman_states.x(state_index) + dz * tx - vertex.position.x;
    float dy = velo_kalman_states.y(state_index) + dz * ty - vertex.position.y;

    // compute the covariance matrix. first only the trivial parts:
    float cov00 = vertex.cov00 + velo_kalman_states.c00(state_index);
    float cov10 = vertex.cov10; // state c10 is 0.f;
    float cov11 = vertex.cov11 + velo_kalman_states.c11(state_index);

    // add the contribution from the extrapolation
    cov00 += dz * dz * velo_kalman_states.c22(state_index) + 2 * dz * velo_kalman_states.c20(state_index);
    // cov10 is unchanged: state c32, c30 and c21 are  0.f
    cov11 += dz * dz * velo_kalman_states.c33(state_index) + 2 * dz * velo_kalman_states.c31(state_index);

    // add the contribution from pv Z
    cov00 += tx * tx * vertex.cov22 - 2 * tx * vertex.cov20;
    cov10 += tx * ty * vertex.cov22 - ty * vertex.cov20 - tx * vertex.cov21;
    cov11 += ty * ty * vertex.cov22 - 2 * ty * vertex.cov21;

    // invert the covariance matrix
    float D = cov00 * cov11 - cov10 * cov10;
    float invcov00 = cov11 / D;
    float invcov10 = -cov10 / D;
    float invcov11 = cov00 / D;

    return dx * dx * invcov00 + 2 * dx * dy * invcov10 + dy * dy * invcov11;
  }
} // namespace Distance

__device__ void associate(
  Velo::Consolidated::ConstKalmanStates& velo_kalman_states,
  Allen::device::span<const PV::Vertex> const& vertices,
  Associate::Consolidated::EventTable& table)
{
  for (unsigned i = threadIdx.x; i < table.size(); i += blockDim.x) {
    float best_value = 0.f;
    short best_index = 0;
    bool first = true;
    for (unsigned j = 0; j < vertices.size(); ++j) {
      float val = fabsf(Distance::velo_ip(velo_kalman_states, i, *(vertices.data() + j)));
      best_index = (first || val < best_value) ? j : best_index;
      best_value = (first || val < best_value) ? val : best_value;
      first = false;
    }
    table.pv(i) = best_index;
    table.value(i) = best_value;
  }
}

__global__ void velo_pv_ip::velo_pv_ip(velo_pv_ip::Parameters parameters)
{
  unsigned const number_of_events = gridDim.x;
  unsigned const event_number = blockIdx.x;

  // Consolidated Velo tracks for this event
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  unsigned const event_tracks_offset = velo_tracks.tracks_offset(event_number);

  Associate::Consolidated::Table velo_pv_ip {parameters.dev_velo_pv_ip, velo_tracks.total_number_of_tracks()};
  velo_pv_ip.cutoff() = Associate::VeloPVIP::baseline;

  // Consolidated Velo fitted states for this event
  Velo::Consolidated::ConstKalmanStates velo_kalman_states {parameters.dev_velo_kalman_beamline_states +
                                                              sizeof(float) * event_tracks_offset,
                                                            velo_tracks.total_number_of_tracks()};

  Allen::device::span<const PV::Vertex> vertices {parameters.dev_multi_fit_vertices +
                                                    event_number * PV::max_number_vertices,
                                                  *(parameters.dev_number_of_multi_fit_vertices + event_number)};

  // The track <-> PV association table for this event
  auto pv_table = velo_pv_ip.event_table(velo_tracks, event_number);

  // Perform the association for this event
  associate(velo_kalman_states, vertices, pv_table);
}
