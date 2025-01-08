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
#include "FilterSvs.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(FilterSvs::filter_svs_t)

void FilterSvs::filter_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_filter_decision_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_combo_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_combos_t>(arguments, 1);
  set_size<dev_child1_idx_t>(arguments, first<host_max_combos_t>(arguments));
  set_size<dev_child2_idx_t>(arguments, first<host_max_combos_t>(arguments));
}

void FilterSvs::filter_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_combo_offsets_t>(arguments, 0, context);

  global_function(filter_svs)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_filter, context)(
    arguments,
    m_maxVertexChi2,
    m_minTrackP,
    m_minChildEta,
    m_maxChildEta,
    m_minCosDira,
    m_minTrackPt,
    m_minComboPt,
    m_minTrackIPChi2,
    m_minTrackPtLowIP,
    m_minTrackLowIP,
    m_minComboPtHighIP,
    m_minTrackHighIP);

  PrefixSum::prefix_sum<dev_combo_offsets_t, host_number_of_combos_t>(*this, arguments, context);
}

__global__ void FilterSvs::filter_svs(
  FilterSvs::Parameters parameters,
  const float maxVertexChi2,
  const float minTrackP,
  const float minChildEta,
  const float maxChildEta,
  const float minCosDira,
  const float minTrackPt,
  const float minComboPt,
  const float minTrackIPChi2,
  const float minTrackPtLowIP,
  const float minTrackLowIP,
  const float minComboPtHighIP,
  const float minTrackHighIP)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = parameters.dev_max_combo_offsets[event_number];
  unsigned* event_combo_number = parameters.dev_combo_offsets + event_number;
  unsigned* event_child1_idx = parameters.dev_child1_idx + idx_offset;
  unsigned* event_child2_idx = parameters.dev_child2_idx + idx_offset;

  // Get SVs array
  const auto svs = parameters.dev_secondary_vertices->container(event_number);
  const unsigned n_svs = svs.size();
  bool* event_sv_filter_decision = parameters.dev_sv_filter_decision + svs.offset();

  // Prefilter all SVs.
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    bool dec = true;

    const auto vertex = svs.particle(i_sv);

    // Set decision
    dec = vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < maxVertexChi2;
    // Kinematic cuts.
    dec &= vertex.minp() > minTrackP;
    dec &= vertex.eta() > minChildEta;
    dec &= vertex.eta() < maxChildEta;
    dec &= vertex.dira() > minCosDira;
    // Kinematic cuts - IPchi2(dec2), IPlow(dec3) and IPhigh(dec4)
    bool dec2 = true;
    dec2 &= vertex.minpt() > minTrackPt;
    dec2 &= vertex.vertex().pt() > minComboPt;
    dec2 &= vertex.minipchi2() > minTrackIPChi2;
    bool dec3 = true;
    dec3 &= vertex.minpt() > minTrackPtLowIP;
    dec3 &= vertex.vertex().pt() > minComboPt;
    dec3 &= vertex.minip() > minTrackLowIP;
    bool dec4 = true;
    dec4 &= vertex.minpt() > minTrackPt;
    dec4 &= vertex.vertex().pt() > minComboPtHighIP;
    dec4 &= vertex.minip() > minTrackHighIP;
    event_sv_filter_decision[i_sv] = dec & (dec2 | dec3 | dec4);
  }

  __syncthreads();

  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    // TODO: Don't worry about 2D blocks for now.
    bool dec1 = event_sv_filter_decision[i_sv];
    for (unsigned j_sv = i_sv + 1; j_sv < n_svs; j_sv += 1) {
      bool dec2 = event_sv_filter_decision[j_sv];
      if (dec1 && dec2) {
        const auto vertex1 = svs.particle(i_sv);
        const auto vertex2 = svs.particle(j_sv);

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
