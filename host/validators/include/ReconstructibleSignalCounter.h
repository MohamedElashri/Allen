/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
 \*****************************************************************************/
#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include "BackendCommon.h"
#include <mutex>
#include <ROOTHeaders.h>
#include "ROOTService.h"

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include <ODINBank.cuh>

// trivial algorithm to count the number of reconstructible (under long/downstream) track
// category signal particles in each event. Used to filter the bandwidth tuning
// to events which we could fully reconstruct

namespace reconstructible_signal_counter {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    HOST_INPUT(host_odin_data_t, ODINData) host_odin_data;
  };

  struct reconstructible_signal_counter_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };
} // namespace reconstructible_signal_counter
