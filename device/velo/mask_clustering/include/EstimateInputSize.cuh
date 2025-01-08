/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ClusteringDefinitions.cuh"

namespace velo_estimate_input_size {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_cluster_candidates_t, unsigned) host_number_of_cluster_candidates;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_superpixels_t, unsigned) dev_superpixels;
    DEVICE_INPUT(dev_superpixels_offsets_t, unsigned) dev_superpixels_offsets;
    DEVICE_INPUT(dev_candidates_offsets_t, unsigned) dev_candidates_offsets;
    DEVICE_OUTPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    HOST_OUTPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    DEVICE_OUTPUT(dev_module_candidate_num_t, unsigned) dev_module_candidate_num;
    DEVICE_OUTPUT(dev_cluster_candidates_t, unsigned) dev_cluster_candidates;
  };

  struct velo_estimate_input_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 16, 1}, "block dimensions"};
  };
} // namespace velo_estimate_input_size
