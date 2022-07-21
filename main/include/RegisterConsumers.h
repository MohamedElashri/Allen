/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <unordered_set>
#include "Dumpers/IUpdater.h"
#include "Consumers.h"
#include "Constants.cuh"
#include "BankTypes.h"

void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants, const std::unordered_set<BankTypes> requested_banks);
