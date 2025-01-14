/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "MVAModelsManager.h"
#include "BackendCommon.h"

void Allen::MVAModels::MVAModelsManager::loadData(std::string parameters_path)
{
  for (MVAModelBase* nn : m_neural_networks) {
    if (!nn->data_was_read_before) {
      nn->readData(parameters_path);
      nn->data_was_read_before = true;
    }
  }
}