/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "FilterTwoSvs.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(FilterTwoSvs::filter_two_svs_t)

void FilterTwoSvs::filter_two_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_1_filter_decision_t>(arguments, first<host_number_of_svs_1_t>(arguments));
  set_size<dev_sv_2_filter_decision_t>(arguments, first<host_number_of_svs_2_t>(arguments));
  set_size<dev_combo_offset_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_total_combo_t>(arguments, 1);
  set_size<dev_child1_idx_t>(arguments, first<host_max_combos_t>(arguments));
  set_size<dev_child2_idx_t>(arguments, first<host_max_combos_t>(arguments));
}

void FilterTwoSvs::filter_two_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_combo_offset_t>(arguments, 0, context);

  global_function(filter_two_svs)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_filter, context)(
    arguments,
    m_maxVertexChi2,
    m_minMassV1,
    m_maxMassV1,
    m_minTrackPV1,
    m_minEtaV1,
    m_maxEtaV1,
    m_minCosDiraV1,
    m_minTrackPtV1,
    m_minPtV1,
    m_minTrackIPChi2V1,
    m_minTrackIPV1,
    m_minMassV2,
    m_maxMassV2,
    m_minTrackPV2,
    m_minEtaV2,
    m_maxEtaV2,
    m_minCosDiraV2,
    m_minTrackPtV2,
    m_minPtV2,
    m_minTrackIPChi2V2,
    m_minTrackIPV2);

  PrefixSum::prefix_sum<dev_combo_offset_t, host_total_combo_t>(*this, arguments, context);
}

__global__ void FilterTwoSvs::filter_two_svs(
  FilterTwoSvs::Parameters parameters,
  const float maxVertexChi2,
  const float minMassV1,
  const float maxMassV1,
  const float minTrackPV1,
  const float minEtaV1,
  const float maxEtaV1,
  const float minCosDiraV1,
  const float minTrackPtV1,
  const float minPtV1,
  const float minTrackIPChi2V1,
  const float minTrackIPV1,
  const float minMassV2,
  const float maxMassV2,
  const float minTrackPV2,
  const float minEtaV2,
  const float maxEtaV2,
  const float minCosDiraV2,
  const float minTrackPtV2,
  const float minPtV2,
  const float minTrackIPChi2V2,
  const float minTrackIPV2)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = parameters.dev_max_combo_offsets[event_number];
  unsigned* event_combo_number = parameters.dev_combo_offset + event_number;
  unsigned* event_child1_idx = parameters.dev_child1_idx + idx_offset;
  unsigned* event_child2_idx = parameters.dev_child2_idx + idx_offset;

  // Get SVs array
  const auto svs_1 = parameters.dev_secondary_vertices_1->container(event_number);
  const unsigned n_svs_1 = svs_1.size();
  bool* event_sv_1_filter_decision = parameters.dev_sv_1_filter_decision + svs_1.offset();
  const auto svs_2 = parameters.dev_secondary_vertices_2->container(event_number);
  const unsigned n_svs_2 = svs_2.size();
  bool* event_sv_2_filter_decision = parameters.dev_sv_2_filter_decision + svs_2.offset();

  // Prefilter all SVs. - 1st SV
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs_1; i_sv += blockDim.x) {
    bool dec = true;

    const auto vertex = svs_1.particle(i_sv);

    // Set decision
    dec = vertex.vertex().chi2() >= 0 && vertex.vertex().chi2() < maxVertexChi2;
    dec &= minMassV1 < vertex.m() && vertex.m() < maxMassV1;
    if (dec) {
      // Kinematic cuts.
      dec &= vertex.minp() > minTrackPV1;
      dec &= vertex.eta() > minEtaV1;
      dec &= vertex.eta() < maxEtaV1;
      dec &= vertex.dira() > minCosDiraV1;
      dec &= vertex.minpt() > minTrackPtV1;
      dec &= vertex.vertex().pt() > minPtV1;
      dec &= vertex.minipchi2() > minTrackIPChi2V1;
      dec &= vertex.minip() > minTrackIPV1;
    }
    event_sv_1_filter_decision[i_sv] = dec;
  }

  // Prefilter all SVs. - 2nd SV
  for (unsigned j_sv = threadIdx.x; j_sv < n_svs_2; j_sv += blockDim.x) {
    bool dec = true;

    const auto vertex = svs_2.particle(j_sv);

    // Set decision
    dec = vertex.vertex().chi2() >= 0 && vertex.vertex().chi2() < maxVertexChi2;
    dec &= minMassV2 < vertex.m() && vertex.m() < maxMassV2;
    if (dec) {
      // Kinematic cuts.
      dec &= vertex.minp() > minTrackPV2;
      dec &= vertex.eta() > minEtaV2;
      dec &= vertex.eta() < maxEtaV2;
      dec &= vertex.dira() > minCosDiraV2;
      dec &= vertex.minpt() > minTrackPtV2;
      dec &= vertex.vertex().pt() > minPtV2;
      dec &= vertex.minipchi2() > minTrackIPChi2V2;
      dec &= vertex.minip() > minTrackIPV2;
    }
    event_sv_2_filter_decision[j_sv] = dec;
  }

  __syncthreads();

  for (unsigned i_sv = threadIdx.x; i_sv < n_svs_1; i_sv += blockDim.x) {
    bool dec1 = event_sv_1_filter_decision[i_sv];
    for (unsigned j_sv = threadIdx.y; j_sv < n_svs_2; j_sv += blockDim.y) {
      bool dec2 = event_sv_2_filter_decision[j_sv];
      if (dec1 && dec2) {
        const auto vertex1 = svs_1.particle(i_sv);
        const auto vertex2 = svs_2.particle(j_sv);

        if (
          vertex1.child(0) == vertex2.child(0) || vertex1.child(1) == vertex2.child(0) ||
          vertex1.child(0) == vertex2.child(1) || vertex1.child(1) == vertex2.child(1))
          continue;

        // Add identified couple of SVs to the array
        unsigned combo_idx = atomicAdd(event_combo_number, 1);
        event_child1_idx[combo_idx] = i_sv;
        event_child2_idx[combo_idx] = j_sv;
      }
    }
  }
}
