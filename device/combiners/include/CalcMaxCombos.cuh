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
    DEVICE_INPUT(dev_input1_t, Allen::IMultiEventContainer*) dev_input1;
    DEVICE_INPUT(dev_input2_t, Allen::IMultiEventContainer*) dev_input2;
    DEVICE_OUTPUT(dev_max_combo_offsets_t, unsigned) dev_max_combo_offsets;
    HOST_OUTPUT(host_max_combos_t, unsigned) host_max_combos;
  };

  __global__ void calc_max_combos(Parameters parameters);

  struct calc_max_combos_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {1, 1, 1}, "Block dimensions"};
  };
} // namespace CalcMaxCombos
