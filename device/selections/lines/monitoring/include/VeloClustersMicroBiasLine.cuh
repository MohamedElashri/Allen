/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
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
#include "EventLine.cuh"

namespace velo_clusters_micro_bias_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
  };

  struct velo_clusters_micro_bias_line_t : public SelectionAlgorithm,
                                           Parameters,
                                           EventLine<velo_clusters_micro_bias_line_t, Parameters> {
    struct DeviceProperties {
      unsigned min_velo_clusters;
      DeviceProperties(const velo_clusters_micro_bias_line_t& algo, const Allen::Context&) :
        min_velo_clusters(algo.m_min_velo_clusters)
      {}
    };
    __device__ static std::tuple<const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned);

    __device__ static bool select(const Parameters&, const DeviceProperties&, std::tuple<const unsigned> input);

  private:
    Allen::Property<unsigned> m_min_velo_clusters {this, "min_velo_clusters", 1, "Minimum number of VELO clusters"};
  };
} // namespace velo_clusters_micro_bias_line
