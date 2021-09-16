/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <optional>
#include <IStream.h>

namespace {
  using factory_t = std::function<std::unique_ptr<Allen::IStream>(
    const bool param_print_memory_usage,
    const size_t param_reserve_mb,
    const size_t reserve_host_mb,
    const unsigned required_memory_alignment,
    const Constants& param_constants,
    HostBuffersManager* buffers_manager)>;
}
namespace Allen {
  using StreamFactory = std::unique_ptr<factory_t, std::function<void(factory_t*)>>;
  std::tuple<StreamFactory, bool> load_stream(std::string const& sequence);
} // namespace Allen
