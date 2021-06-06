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

void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants);

int allen(
  std::map<std::string, std::string> options,
  Allen::NonEventData::IUpdater* updater,
  IInputProvider* input_provider,
  OutputHandler* output_handler,
  IZeroMQSvc* zmqSvc,
  std::string_view control_connection);
