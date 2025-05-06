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
#include "AllenMonitoring.h"

namespace velo_calculate_number_of_candidates {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_raw_input_t, char) dev_velo_raw_input;
    DEVICE_INPUT(dev_velo_raw_input_offsets_t, unsigned) dev_velo_raw_input_offsets;
    DEVICE_INPUT(dev_velo_raw_input_sizes_t, unsigned) dev_velo_raw_input_sizes;
    DEVICE_INPUT(dev_velo_raw_input_types_t, unsigned) dev_velo_raw_input_types;

    DEVICE_OUTPUT(dev_superpixels_offsets_t, unsigned) dev_superpixels_offsets;
    DEVICE_OUTPUT(dev_superpixels_module_pair_offsets_t, unsigned) dev_superpixels_module_pair_offsets;
    DEVICE_OUTPUT(dev_superpixels_t, unsigned) dev_superpixels;
    HOST_OUTPUT(host_total_number_of_superpixels_t, unsigned) host_total_number_of_superpixels;
  };

  // Algorithm
  struct velo_calculate_number_of_candidates_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 256, "block dimension X"};
    Allen::Property<bool> m_check_velo_rawbank {this, "check_velo_rawbank", true, "check velo raw bank"};
    Allen::Monitoring::Counter<> m_n_unexpected_velo_rawbank {this, "n_unexpected_velo_rawbank"};
  };
} // namespace velo_calculate_number_of_candidates
