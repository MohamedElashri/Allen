/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Common.h>
#include <PV_Definitions.cuh>
#include <VeloConsolidated.cuh>
#include <AssociateConsolidated.cuh>
#include <AssociateConstants.cuh>
#include <VeloPVIP.cuh>

INSTANTIATE_ALGORITHM(velo_pv_ip::velo_pv_ip_t)

void velo_pv_ip::velo_pv_ip_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_velo_tracks = first<host_number_of_reconstructed_velo_tracks_t>(arguments);
  set_size<dev_velo_pv_ip_t>(arguments, Associate::Consolidated::table_size(n_velo_tracks));
}

void velo_pv_ip::velo_pv_ip_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(velo_pv_ip)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

namespace Distance {
  __device__ float velo_ip(const KalmanVeloState& state, const PV::Vertex& vertex, const float denom)
  {
    float tx = state.tx;
    float ty = state.ty;
    float dz = vertex.position.z - state.z;
    float dx = state.x + dz * tx - vertex.position.x;
    float dy = state.y + dz * ty - vertex.position.y;
    return sqrtf((dx * dx + dy * dy) * denom);
  }

  __device__ float velo_ip_chi2(const KalmanVeloState& velo_kalman_state, const PV::Vertex& vertex)
  {
    // ORIGIN: Rec/Tr/TrackKernel/src/TrackVertexUtils.cpp
    float tx = velo_kalman_state.tx;
    float ty = velo_kalman_state.ty;
    float dz = vertex.position.z - velo_kalman_state.z;
    float dx = velo_kalman_state.x + dz * tx - vertex.position.x;
    float dy = velo_kalman_state.y + dz * ty - vertex.position.y;

    // compute the covariance matrix. first only the trivial parts:
    float cov00 = vertex.cov00 + velo_kalman_state.c00;
    float cov10 = vertex.cov10; // state c10 is 0.f;
    float cov11 = vertex.cov11 + velo_kalman_state.c11;

    // add the contribution from the extrapolation
    cov00 += dz * dz * velo_kalman_state.c22 + 2 * dz * velo_kalman_state.c20;
    // cov10 is unchanged: state c32, c30 and c21 are  0.f
    cov11 += dz * dz * velo_kalman_state.c33 + 2 * dz * velo_kalman_state.c31;

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
  const Allen::Views::Physics::KalmanStates& velo_kalman_states,
  Allen::device::span<const PV::Vertex> const& vertices,
  Associate::Consolidated::EventTable& table)
{
  for (unsigned i = threadIdx.x; i < table.size(); i += blockDim.x) {
    const KalmanVeloState state = velo_kalman_states.state(i);
    const float denom = 1.f / (1.0f + state.tx * state.tx + state.ty * state.ty);
    float best_value = 0.f;
    short best_index = 0;
    bool first = true;
    for (unsigned j = 0; j < vertices.size(); ++j) {
      float val = fabsf(Distance::velo_ip(state, *(vertices.data() + j), denom));
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
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];
  const auto velo_kalman_states = parameters.dev_velo_kalman_beamline_states_view[event_number];

  Associate::Consolidated::Table velo_pv_ip {parameters.dev_velo_pv_ip,
                                             parameters.dev_offsets_all_velo_tracks[number_of_events]};
  velo_pv_ip.cutoff() = Associate::VeloPVIP::baseline;

  Allen::device::span<const PV::Vertex> vertices {parameters.dev_multi_final_vertices +
                                                    event_number * PV::max_number_vertices,
                                                  *(parameters.dev_number_of_multi_final_vertices + event_number)};

  // The track <-> PV association table for this event
  auto pv_table = velo_pv_ip.event_table(velo_tracks.offset(), velo_tracks.size());

  // Perform the association for this event
  associate(velo_kalman_states, vertices, pv_table);
}
