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
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"

namespace total_ecal_energy {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_of_digits;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_OUTPUT(dev_ecal_digits_e_t, float) dev_ecal_digits_e;
    DEVICE_OUTPUT(dev_total_ecal_e_t, float) dev_total_ecal_e;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  __global__ void sum_ecal_energy(Parameters parameters, const char* raw_ecal_geometry);

  struct total_ecal_energy_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      Allen::Context const&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
  };
} // namespace total_ecal_energy