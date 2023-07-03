/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <map>
#include <string>

#include <ZeroMQ/IZeroMQSvc.h>
#include <Dumpers/IUpdater.h>
#include "InputProvider.h"
#include "OutputHandler.h"

struct Constants;

int allen(
  std::map<std::string, std::string> options,
  std::string_view configuration,
  Allen::NonEventData::IUpdater* updater,
  std::shared_ptr<IInputProvider> input_provider,
  OutputHandler* output_handler,
  IZeroMQSvc* zmqSvc,
  std::string_view control_connection);

void register_consumers(
  Allen::NonEventData::IUpdater* updater,
  Constants& constants,
  const std::unordered_set<BankTypes> requested_banks);
