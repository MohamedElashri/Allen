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
#include "PromptVertexEvaluator.cuh"
#include <cmath>

INSTANTIATE_ALGORITHM(prompt_vertex_evaluator::prompt_vertex_evaluator_t)

void prompt_vertex_evaluator::prompt_vertex_evaluator_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_vertex_passes_prompt_selection_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_vertex_passes_displaced_selection_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void prompt_vertex_evaluator::prompt_vertex_evaluator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(prompt_vertex_evaluator)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void prompt_vertex_evaluator::prompt_vertex_evaluator(prompt_vertex_evaluator::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs_in_evt = parameters.dev_sv_offsets[event_number + 1] - sv_offset;

  for (unsigned sv_in_evt_idx = threadIdx.x; sv_in_evt_idx < n_svs_in_evt; sv_in_evt_idx += blockDim.x) {
    VertexFit::TrackMVAVertex vertex = parameters.dev_svs[sv_offset + sv_in_evt_idx];

    const float brem_corrected_dielectron_pt =
      parameters.dev_brem_corrected_pt[vertex.trk1 + parameters.dev_track_offsets[event_number]] +
      parameters.dev_brem_corrected_pt[vertex.trk2 + parameters.dev_track_offsets[event_number]];

    const float brem_corrected_pt1 =
      parameters.dev_brem_corrected_pt[vertex.trk1 + parameters.dev_track_offsets[event_number]];
    const float brem_corrected_pt2 =
      parameters.dev_brem_corrected_pt[vertex.trk2 + parameters.dev_track_offsets[event_number]];
    const float brem_corrected_minpt = min(brem_corrected_pt1, brem_corrected_pt2);

    bool passes_common_selection = vertex.doca < parameters.maxDOCA && vertex.chi2 < parameters.maxVtxChi2 &&
                                   brem_corrected_dielectron_pt > parameters.minDielectronPT;

    bool passes_prompt_selection = passes_common_selection && brem_corrected_minpt > parameters.minPTprompt &&
                                   vertex.minipchi2 < parameters.minIPChi2Threshold;

    bool passes_displaced_selection = passes_common_selection && brem_corrected_minpt > parameters.minPTdisplaced &&
                                      vertex.minipchi2 > parameters.minIPChi2Threshold;

    auto sv_idx = sv_in_evt_idx + sv_offset;
    parameters.dev_vertex_passes_prompt_selection[sv_idx] = passes_prompt_selection;
    parameters.dev_vertex_passes_displaced_selection[sv_idx] = passes_displaced_selection;
  }
}
