/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
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
#include "EventLine.cuh"
#include "Plume.cuh"

namespace plume_activity_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_plume_t, Plume_) dev_plume;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct plume_activity_line_t : public SelectionAlgorithm, Parameters, EventLine<plume_activity_line_t, Parameters> {
    struct DeviceProperties {
      float min_plume_adc;
      unsigned min_number_plume_adcs_over_min;
      uint64_t plume_channel_mask;
      DeviceProperties(const plume_activity_line_t& algo, const Allen::Context&) :
        min_plume_adc(algo.m_min_plume_adc), min_number_plume_adcs_over_min(algo.m_min_number_plume_adcs_over_min),
        plume_channel_mask(algo.m_plume_channel_mask)
      {}
    };
    __device__ static std::tuple<const Plume_*>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned);

    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const Plume_*> input);

  private:
    Allen::Property<float> m_min_plume_adc {this, "min_plume_adc", 1.f, "ADC threshold"};
    Allen::Property<unsigned> m_min_number_plume_adcs_over_min {this,
                                                                "min_number_plume_adcs_over_min",
                                                                1,
                                                                "Number of ADCs over configured threshold"};
    Allen::Property<uint64_t> m_plume_channel_mask {this,
                                                    "plume_channel_mask",
                                                    0x003FFFFF003FFFFF,
                                                    "PLUME channel mask as a 64-bit bitset"};
  };
} // namespace plume_activity_line
