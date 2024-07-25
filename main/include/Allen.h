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
  std::string_view configuration_source,
  Allen::NonEventData::IUpdater* updater,
  IInputProvider* input_provider,
  OutputHandler* output_handler,
  IZeroMQSvc* zmqSvc,
  std::string_view control_connection);

void register_consumers(
  Allen::NonEventData::IUpdater* updater,
  Constants& constants,
  const std::unordered_set<BankTypes> requested_banks);
