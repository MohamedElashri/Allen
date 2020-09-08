/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Dumpers/IUpdater.h"
#include "Consumers.h"
#include "Constants.cuh"

void register_consumers(Allen::NonEventData::IUpdater* updater, Constants& constants);
