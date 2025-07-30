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

#include "Algorithm.cuh"
#include "Property.cuh"
#include "Logger.h"
#include "BackendCommon.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "Datatype.cuh"
#include "InputAggregate.cuh"

struct DeviceAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "DeviceAlgorithm";
};

struct HostAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "HostAlgorithm";
};

struct SelectionAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "SelectionAlgorithm";

protected:
  Allen::Property<float> m_pre_scaler {this, "pre_scaler", 1.f, "Pre-scaling factor"};
  Allen::Property<float> m_post_scaler {this, "post_scaler", 1.f, "Post-scaling factor"};
  Allen::Property<std::string> m_pre_scaler_hash_string {this, "pre_scaler_hash_string", "", "Pre-scaling hash string"};
  Allen::Property<std::string> m_post_scaler_hash_string {this,
                                                          "post_scaler_hash_string",
                                                          "",
                                                          "Post-scaling hash string"};
  Allen::Property<bool> m_enable_monitoring {this, "enable_monitoring", false, "Enable line monitoring"};
  Allen::Property<bool> m_enable_tupling {this, "enable_tupling", false, "Enable line tupling"};
};

struct ValidationAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "ValidationAlgorithm";
};

struct ProviderAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "ProviderAlgorithm";
};

struct BarrierAlgorithm : public Allen::Algorithm {
  constexpr static auto algorithm_scope = "BarrierAlgorithm";
};
