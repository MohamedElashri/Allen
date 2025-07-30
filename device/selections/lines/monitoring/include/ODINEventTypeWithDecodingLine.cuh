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
#include "ODINLine.cuh"
#include "ODINBank.cuh"

#include "Plume.cuh"

namespace odin_event_type_with_decoding_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    // dummy inputs to establish a dependence on the decoding algorithms
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_total_ecal_e_t, float) dev_total_ecal_energy;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_INPUT(dev_plume_t, Plume_) dev_plume;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct odin_event_type_with_decoding_line_t : public SelectionAlgorithm,
                                                Parameters,
                                                ODINLine<odin_event_type_with_decoding_line_t, Parameters> {
    struct DeviceProperties {
      unsigned odin_event_type;
      DeviceProperties(const odin_event_type_with_decoding_line_t& algo, const Allen::Context&) :
        odin_event_type(algo.m_odin_event_type)
      {}
    };
    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const ODINData> input);

  private:
    Allen::Property<unsigned> m_odin_event_type {this,
                                                 "odin_event_type",
                                                 static_cast<uint16_t>(LHCb::ODIN::EventTypes::Lumi),
                                                 "ODIN event type"};
  };
} // namespace odin_event_type_with_decoding_line
