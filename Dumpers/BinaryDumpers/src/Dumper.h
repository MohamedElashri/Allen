/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <set>
#include <string>
#include <filesystem>

#include <Gaudi/Accumulators.h>
#include "LHCbAlgs/Consumer.h"
#include "LHCbAlgs/Traits.h"
#include <Dumpers/Utils.h>

#include "AllenUpdater.h"

namespace {
  using namespace std::string_literals;
}

namespace Allen::Dumpers {

  template<typename Signature, typename Traits_ = LHCb::Algorithm::Traits::useDefaults>
  class Dumper : public LHCb::Algorithm::Consumer<Signature, Traits_> {
  public:
    using LHCb::Algorithm::Consumer<Signature, Traits_>::Consumer;

    StatusCode initialize() override
    {
      auto sc = LHCb::Algorithm::Consumer<Signature, Traits_>::initialize();
      if (!sc.isSuccess()) {
        return sc;
      }

      if (m_dumpToFile.value() && !DumpUtils::createDirectory(m_outputDirectory.value())) {
        this->error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
        return StatusCode::FAILURE;
      }

      m_updater = this->template service<AllenUpdater>("AllenUpdater", true);
      if (!m_updater) {
        this->error() << "Failed to retrieve AllenUpdater" << endmsg;
        return StatusCode::FAILURE;
      }
      return sc;
    }

  protected:
    static std::string location(std::string name, std::string loc)
    {
      std::string prefix;
#ifdef USE_DD4HEP
      prefix = "/world:";
#endif
      return prefix + "AlgorithmSpecific-" + name + "-" + loc;
    }

    void register_producer(std::string id, std::string fn, std::vector<char> const& data)
    {

      m_updater->registerProducer(id, [&data]() -> std::optional<std::vector<char>> { return {data}; });

      if (!m_dumpToFile) return;

      auto counter = m_bytesWritten.find(id);
      if (counter == m_bytesWritten.end()) {
        bool success = false;
        std::tie(counter, success) = m_bytesWritten.try_emplace(id, this, "BytesWritten_"s + id);
        assert(success);
      }
      m_ids.try_emplace(id, fn, data);
    }

    void dump()
    {

      if (!m_dumpToFile) return;

      for (auto const& [id, entry] : m_ids) {
        auto const& [fn, data] = entry;
        auto filename = m_outputDirectory.value() + "/" + fn + ".bin";
        std::ofstream output {filename, std::ios::out | std::ios::binary};
        output.write(data.data(), data.size());

        auto counter = m_bytesWritten.find(id);
        assert(counter != m_bytesWritten.end());
        counter->second += data.size();
      }
    }

  private:
    SmartIF<AllenUpdater> m_updater;

    Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "geometry"};
    Gaudi::Property<bool> m_dumpToFile {this, "DumpToFile", false};

    mutable std::map<std::string, Gaudi::Accumulators::Counter<>> m_bytesWritten;

    std::map<std::string, std::tuple<std::string, std::vector<char> const&>> m_ids;
  };

} // namespace Allen::Dumpers
