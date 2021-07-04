/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>

class IZeroMQSvc;
class OutputHandler;
struct StreamWrapper;
struct CheckerInvoker;
struct HostBuffersManager;
struct MonitorManager;
struct IInputProvider;
struct ROOTService;
namespace Allen {
  struct IStream;
}

std::string connection(const size_t id, std::string suffix = "");

void run_output(
  const size_t thread_id,
  IZeroMQSvc* zmqSvc,
  OutputHandler* output_handler,
  HostBuffersManager* buffer_manager);

void run_slices(const size_t thread_id, IZeroMQSvc* zmqSvc, IInputProvider* input_provider);

void run_stream(
  size_t const thread_id,
  size_t const stream_id,
  int device_id,
  Allen::IStream* stream,
  std::shared_ptr<IInputProvider> input_provider,
  IZeroMQSvc* zmqSvc,
  CheckerInvoker* checker_invoker,
  ROOTService* root_service,
  unsigned n_reps,
  bool cpu_offload,
  bool mep_layout,
  uint inject_mem_fail);

void run_monitoring(const size_t mon_id, IZeroMQSvc* zmqSvc, MonitorManager* monitor_manager, unsigned i_monitor);
