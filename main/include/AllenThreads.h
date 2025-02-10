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

#include <string>

class IZeroMQSvc;
class OutputHandler;
struct StreamWrapper;
struct CheckerInvoker;
struct HostBuffersManager;
struct ROOTService;
struct Stream;
class IInputProvider;

std::string connection(const size_t id, std::string suffix = "");

void run_output(
  const size_t thread_id,
  const size_t output_id,
  IZeroMQSvc* zmqSvc,
  OutputHandler* output_handler,
  HostBuffersManager* buffer_manager);

void run_slices(const size_t thread_id, IZeroMQSvc* zmqSvc, IInputProvider* input_provider);

void run_stream(
  size_t const thread_id,
  size_t const stream_id,
  int device_id,
  Stream* stream,
  std::shared_ptr<IInputProvider> input_provider,
  IZeroMQSvc* zmqSvc,
  CheckerInvoker* checker_invoker,
  ROOTService* root_service,
  unsigned n_reps,
  bool mep_layout,
  uint inject_mem_fail,
  bool prefer_shared);

struct MonitoringPrinter;

void run_aggregation(const size_t thread_id, const int device_id, IZeroMQSvc* zmqSvc, MonitoringPrinter* printer);
