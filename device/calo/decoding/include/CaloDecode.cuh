/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "AlgorithmTypes.cuh"
#include "CaloConstants.cuh"

namespace calo_decode {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_digits;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_raw_input_t, char) dev_ecal_raw_input;
    DEVICE_INPUT(dev_ecal_raw_input_offsets_t, unsigned) dev_ecal_raw_input_offsets;
    DEVICE_INPUT(dev_ecal_raw_input_sizes_t, unsigned) dev_ecal_raw_input_sizes;
    DEVICE_INPUT(dev_ecal_raw_input_types_t, unsigned) dev_ecal_raw_input_types;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
  };

  struct check_digits : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  // Algorithm
  struct calo_decode_t : public DeviceAlgorithm, Parameters {

    using contracts = std::tuple<check_digits>;

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension X"};
    Allen::Property<int16_t> m_ecal_min_seed_adc {this, "ecal_min_seed_adc", 10, "Seed minimum ADC"};
    Allen::Property<int16_t> m_ecal_min_neighbor_adc {this, "ecal_min_neighbor_adc", -5, "Neighbor minimum ADC"};
  };
} // namespace calo_decode
