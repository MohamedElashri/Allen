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

#include <memory>
#include <map>
#include <string>

#include "BankTypes.h"
#include "InputProvider.h"
#include "OutputHandler.h"

class IZeroMQSvc;
struct ConfigurationReader;

namespace {
  constexpr size_t n_input = 1;
#ifdef ALLEN_STANDALONE
  // Stand-alone build does not run an aggregation thread
  constexpr size_t n_agg = 0;
#else
  constexpr size_t n_agg = 1;
#endif
  constexpr size_t max_stream_threads = 1024;
} // namespace

namespace Allen {
  struct IOConf {
    bool async_io = false;
    unsigned number_of_slices = 0;
    unsigned number_of_repetitions = 0;
    unsigned n_io_reps = 0;
  };

  void set_environment(unsigned number_of_threads);

  std::tuple<bool, bool> velo_decoding_type(const ConfigurationReader& configuration_reader);

  std::tuple<std::string, std::string> sequence_conf(std::map<std::string, std::string> const& options);

  std::tuple<bool, std::string, std::string> config_from_tck(std::string_view source);

  std::unique_ptr<IInputProvider> make_provider(
    std::map<std::string, std::string> const& options,
    std::string_view configuration);

  std::unique_ptr<OutputHandler> output_handler(
    IInputProvider* input_provider,
    IZeroMQSvc* zmq_svc,
    std::map<std::string, std::string> const& options);

  Allen::IOConf io_configuration(
    unsigned number_of_slices,
    unsigned number_of_repetitions,
    unsigned number_of_threads,
    bool quiet = false);
} // namespace Allen
