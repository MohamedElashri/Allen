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

#pragma once

#include "BackendCommon.h"
#include "InputReader.h"

namespace Allen::MVAModels {

  struct MVAModelBase;

  struct MVAModelsManager {
    static MVAModelsManager* get()
    {
      static MVAModelsManager instance;
      return &instance;
    }

    void registerNN(MVAModelBase* nn) { m_neural_networks.push_back(nn); }

    void loadData(std::string parameters_path);

    std::vector<MVAModelBase*> m_neural_networks;
  };

  struct MVAModelBase {
    MVAModelBase(std::string name, std::string path) : m_name(name), m_path(path)
    {
      MVAModelsManager::get()->registerNN(this);
    }

    virtual void readData(std::string) {}

    virtual ~MVAModelBase() = default;

    bool data_was_read_before = false;
    std::string m_name;
    std::string m_path;
  };

} // namespace Allen::MVAModels