/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "UTConsolidated.cuh"

namespace lf_least_mean_square_fit {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_ut_t, unsigned) dev_atomics_ut;
    DEVICE_OUTPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_atomics_scifi_t, unsigned) dev_atomics_scifi;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_x_filter_t, float) dev_scifi_lf_parametrization_x_filter;
  };

  __global__ void lf_least_mean_square_fit(Parameters);

  struct lf_least_mean_square_fit_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace lf_least_mean_square_fit
