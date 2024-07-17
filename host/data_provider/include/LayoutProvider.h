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

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include <gsl/gsl>

namespace layout_provider {
  struct Parameters {
    HOST_OUTPUT(host_mep_layout_t, unsigned) host_mep_layout;
    DEVICE_OUTPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
  };

  /**
   * @brief Provides layout information as
   *        parameters that can be reused in any algorithm.
   *        Currently available layouts are MEP or Allen layout.
   */
  struct layout_provider_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;
  };
} // namespace layout_provider
