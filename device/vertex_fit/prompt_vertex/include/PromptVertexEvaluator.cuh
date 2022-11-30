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
#pragma once

#include "AlgorithmTypes.cuh"
#include "VertexDefinitions.cuh"
#include <cmath>

namespace prompt_vertex_evaluator {

  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_svs;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    DEVICE_OUTPUT(dev_vertex_passes_prompt_selection_t, float) dev_vertex_passes_prompt_selection;
    DEVICE_OUTPUT(dev_vertex_passes_displaced_selection_t, float) dev_vertex_passes_displaced_selection;
    PROPERTY(block_dim_t, "block_dim", "block dimension", DeviceDimensions) block_dim;
    PROPERTY(MinIPChi2Threshold_t, "MinIPChi2Threshold", "Min IP Chi2 threshold", float) minIPChi2Threshold;
    PROPERTY(MaxDOCA_t, "MaxDOCA", "Max DOCA", float) maxDOCA;
    PROPERTY(MaxVtxChi2_t, "MaxVtxChi2", "Max vertex chi2", float) maxVtxChi2;
    PROPERTY(MinPTprompt_t, "MinPTprompt", "Min PTprompt", float) minPTprompt;
    PROPERTY(MinPTdisplaced_t, "MinPTdisplaced", "Min PTdisplaced", float) minPTdisplaced;
    PROPERTY(MinDielectronPT_t, "MinDielectronPT", "Min dielectron PT", float) minDielectronPT;
  };

  __global__ void prompt_vertex_evaluator(Parameters);

  struct prompt_vertex_evaluator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
    Property<MinIPChi2Threshold_t> m_MinIPChi2Threshold {
      this,
      2.0f}; // threshold to split 'prompt' and 'displaced' candidates
    Property<MaxDOCA_t> m_MaxDOCA {this, 0.082f};
    Property<MinPTprompt_t> m_MinPTprompt {this, 0.f};
    Property<MinPTdisplaced_t> m_MinPTdisplaced {this, 0.f};
    Property<MaxVtxChi2_t> m_MaxVtxChi2 {this, 7.4f};
    Property<MinDielectronPT_t> m_MinDielectronPT {this, 1000.f};
  };

} // namespace prompt_vertex_evaluator
