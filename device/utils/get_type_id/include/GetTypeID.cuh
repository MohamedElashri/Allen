/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TypeID.h"
#include "MultiEventContainer.cuh"

namespace get_type_id {
  struct Parameters {
    DEVICE_OUTPUT(dev_type_id_t, Allen::TypeIDs) dev_type_id;
    HOST_OUTPUT(host_type_id_t, Allen::TypeIDs) host_type_id;
    DEVICE_INPUT(dev_imec_t, Allen::IMultiEventContainer*) dev_imec;
  };

  struct get_type_id_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;
  };
} // namespace get_type_id
