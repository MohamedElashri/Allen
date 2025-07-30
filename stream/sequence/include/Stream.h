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

#include <iostream>
#include <vector>
#include <numeric>
#include <algorithm>
#include <tuple>

#include "Common.h"
#include "BackendCommon.h"
#include "Logger.h"
#include "Timer.h"
#include "Tools.h"
#include "Constants.cuh"
#include "RuntimeOptions.h"
#include "HostBuffersManager.cuh"
#include "CheckerInvoker.h"
#include "Configuration.h"
#include "nlohmann/json.hpp"
#include "Scheduler.cuh"

struct HostBuffersManager;

struct Stream {
private:
  // Stream id ranging from 0 to N_streams
  const unsigned stream_id;

  // Dynamic scheduler
  Scheduler* scheduler;

  // Context
  Allen::Context m_context {};

  // Launch options
  bool do_print_memory_manager;

  // Host buffers
  HostBuffersManager* host_buffers_manager;

  // Number of input events
  unsigned number_of_input_events;

  // Constants
  Constants const& constants;

public:
  Stream(
    const unsigned stream_id,
    const ConfiguredSequence& configuration,
    const Allen::ScheduledSequence& sched_seq,
    const bool param_do_print_memory_manager,
    const size_t reserve_mb,
    const unsigned required_memory_alignment,
    const Constants& param_constants,
    HostBuffersManager* buffers_manager);

  unsigned id() const { return stream_id; }

  Allen::error run(const unsigned buf_idx, RuntimeOptions const& runtime_options);

  void print_configured_sequence();

  std::map<std::string, std::map<std::string, nlohmann::json>> get_algorithm_configuration() const;

  bool contains_validation_algorithms() const;
};
