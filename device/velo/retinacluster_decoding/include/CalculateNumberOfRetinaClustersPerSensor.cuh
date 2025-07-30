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

namespace calculate_number_of_retinaclusters_each_sensor_pair {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, uint) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_retina_raw_input_t, char) dev_velo_retina_raw_input;
    DEVICE_INPUT(dev_velo_retina_raw_input_offsets_t, uint) dev_velo_retina_raw_input_offsets;
    DEVICE_INPUT(dev_velo_retina_raw_input_sizes_t, uint) dev_velo_retina_raw_input_sizes;
    DEVICE_INPUT(dev_velo_retina_raw_input_types_t, uint) dev_velo_retina_raw_input_types;
    DEVICE_OUTPUT(dev_retina_bank_index_t, uint) dev_retina_bank_index;
    DEVICE_OUTPUT(dev_offsets_each_sensor_pair_size_t, unsigned) dev_offsets_each_sensor_pair_size;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned) host_total_sum_holder;
  };

  struct calculate_number_of_retinaclusters_each_sensor_pair_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<uint64_t> m_masked_modules {this, "masked_modules", 0, "masked modules bitmask"};
    Allen::Property<bool> m_check_velo_rawbank {this, "check_velo_rawbank", true, "check velo raw bank"};
    Allen::Monitoring::Counter<> m_n_unexpected_velo_rawbank {this, "n_unexpected_velo_rawbank"};
  };
} // namespace calculate_number_of_retinaclusters_each_sensor_pair
