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

#include "SciFiDefinitions.cuh"
#include "SciFiRaw.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "AllenMonitoring.h"

namespace scifi_raw_bank_decoder {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    HOST_INPUT(host_accumulated_number_of_scifi_hits_t, unsigned) host_accumulated_number_of_scifi_hits;
    DEVICE_INPUT(dev_scifi_raw_input_t, char) dev_scifi_raw_input;
    DEVICE_INPUT(dev_scifi_raw_input_offsets_t, unsigned) dev_scifi_raw_input_offsets;
    DEVICE_INPUT(dev_scifi_raw_input_sizes_t, unsigned) dev_scifi_raw_input_sizes;
    DEVICE_INPUT(dev_scifi_raw_input_types_t, unsigned) dev_scifi_raw_input_types;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_INPUT(dev_cluster_references_t, unsigned) dev_cluster_references;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
  };

  struct scifi_raw_bank_decoder_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<bool> m_decode_v8_as_v7 {this,
                                             "decode_v8_as_v7",
                                             {false},
                                             "Decode v8 banks as v7 to reproduce a bug in July 2023 (MC only)"};
    Allen::Monitoring::Counter<> m_invalid_chanid {this, "n_invalid_chanid"};
  };
} // namespace scifi_raw_bank_decoder
