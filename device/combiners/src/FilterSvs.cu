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

INSTANTIATE_ALGORITHM(FilterSvs::filter_svs_t)

void FilterSvs::filter_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_filter_decision_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_combo_number_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_child1_idx_t>(arguments, first<host_max_combos_t>(arguments));
  set_size<dev_child2_idx_t>(arguments, first<host_max_combos_t>(arguments));
}

void FilterSvs::filter_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_combo_number_t>(arguments, 0, context);

  global_function(filter_svs)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_filter_t>(), context)(
    arguments);
}

__global__ void FilterSvs::filter_svs(FilterSvs::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = parameters.dev_max_combo_offsets[event_number];
  unsigned* event_combo_number = parameters.dev_combo_number + event_number;
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
    dec = vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < parameters.maxVertexChi2;
    // Kinematic cuts.
    dec &= vertex.minpt() > parameters.minTrackPt;
    dec &= vertex.minp() > parameters.minTrackP;
    dec &= vertex.vertex().pt() > parameters.minComboPt;
    dec &= vertex.eta() > parameters.minChildEta;
    dec &= vertex.eta() < parameters.maxChildEta;
    dec &= vertex.minipchi2() > parameters.minTrackIPChi2;
    dec &= vertex.dira() > parameters.minCosDira;
    event_sv_filter_decision[i_sv] = dec;
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
