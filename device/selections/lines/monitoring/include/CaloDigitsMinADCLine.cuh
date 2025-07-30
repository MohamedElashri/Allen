/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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
#include "ParticleTypes.cuh"
#include "Line.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "ODINBank.cuh"

namespace calo_digits_minADC {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_of_digits;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct calo_digits_minADC_t : public SelectionAlgorithm, Parameters, Line<calo_digits_minADC_t, Parameters> {
    struct DeviceProperties {
      int16_t minADC;
      DeviceProperties(const calo_digits_minADC_t& algo, const Allen::Context&) : minADC(algo.m_minADC) {}
    };
    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const CaloDigit> input);

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_digits_offsets[event_number];
    }

    __device__ static std::tuple<const CaloDigit>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const CaloDigit event_ecal_digits =
        parameters.dev_ecal_digits[parameters.dev_ecal_digits_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_digits);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<host_ecal_number_of_digits_t>(arguments);
    }

  private:
    Allen::Property<int16_t> m_minADC {this, "minADC", 500, "minADC description"}; // MeV
  };
} // namespace calo_digits_minADC
