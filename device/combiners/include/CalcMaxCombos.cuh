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
#include "ParticleTypes.cuh"

namespace CalcMaxCombos {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT_AGGREGATE(dev_input_agg_t, Allen::IMultiEventContainer*) dev_input_agg;
    DEVICE_OUTPUT(dev_input_containers_t, Allen::IMultiEventContainer*) dev_input_containers;
    DEVICE_OUTPUT(dev_max_combos_t, unsigned) dev_max_combos;
    PROPERTY(block_dim_t, "block_dim", "Block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void calc_max_combos(Parameters parameters, const unsigned number_of_input_containers);

  struct calc_max_combos_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{1, 1, 1}}};
  };
} // namespace CalcMaxCombos
