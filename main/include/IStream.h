/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <map>
#include <string>
#include <functional>

#include <RuntimeOptions.h>
#include <Constants.cuh>
#include <HostBuffersManager.cuh>
#include <BackendCommon.h>

namespace Allen {
  struct IStream {

    virtual Allen::error run(const unsigned buf_idx, RuntimeOptions const& runtime_options) = 0;

    virtual void configure_algorithms(const std::map<std::string, std::map<std::string, std::string>>& config) = 0;

    virtual std::map<std::string, std::map<std::string, std::string>> get_algorithm_configuration() const = 0;

    /**
     * @brief Prints the configured sequence.
     */
    virtual void print_configured_sequence() = 0;

    virtual ~IStream() = default;
  };
} // namespace Allen
