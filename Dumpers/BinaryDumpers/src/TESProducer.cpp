/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>
#include <string>
#include <mutex>
#include <filesystem>

#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include <GaudiAlg/Consumer.h>
#include <Gaudi/Accumulators.h>

#include <Dumpers/Utils.h>

#include <Dumpers/Utils.h>

#include "AllenUpdater.h"

namespace Allen {

  /** @class TESProducer
   *  Dump beamline position.
   *
   *  @author Roel Aaij
   *  @date   2019-04-27
   */
  class TESProducer final : public Gaudi::Functional::Consumer<void(std::vector<char> const&, std::string const&)> {
  public:
    TESProducer(const std::string& name, ISvcLocator* svcLoc);

    void operator()(std::vector<char> const& data, std::string const& id) const override;

    StatusCode initialize() override;

  private:
    Gaudi::Property<std::string> m_id {this, "ID"};
    Gaudi::Property<std::string> m_outputDirectory {this, "OutputDirectory", "geometry"};
    Gaudi::Property<std::string> m_filename {this, "Filename", ""};

    mutable std::optional<Gaudi::Accumulators::Counter<>> m_bytesWritten = std::nullopt;

    mutable std::mutex m_dataMutex;
    mutable std::vector<char> m_data;
  };
} // namespace Allen

DECLARE_COMPONENT_WITH_ID(Allen::TESProducer, "AllenTESProducer")

Allen::TESProducer::TESProducer(const std::string& name, ISvcLocator* svcLoc) :
  Consumer(name, svcLoc, {KeyValue {"InputData", ""}, KeyValue {"InputID", ""}})
{}

StatusCode Allen::TESProducer::initialize()
{
  auto sc = Consumer::initialize();
  if (!sc.isSuccess()) {
    return sc;
  }

  if (!m_filename.empty() && !DumpUtils::createDirectory(m_outputDirectory.value())) {
    error() << "Failed to create directory " << m_outputDirectory.value() << endmsg;
    return StatusCode::FAILURE;
  }

  using namespace std::string_literals;
  m_bytesWritten.emplace(this, "BytesWritten_"s + m_id.value());

  auto updater = service<AllenUpdater>("AllenUpdater", false);
  if (!updater) {
    error() << "Failed to retrieve AllenUpdater" << endmsg;
    return StatusCode::FAILURE;
  }
  updater->registerProducer(m_id.value(), [this]() -> std::optional<std::vector<char>> { return {m_data}; });
  return StatusCode::SUCCESS;
}

void Allen::TESProducer::operator()(std::vector<char> const& data, std::string const& id) const
{
  using namespace std::string_literals;
  if (id != m_id.value()) {
    throw GaudiException {
      "ID from TES is not what was expected: "s + id + " " + m_id.value(), name(), StatusCode::FAILURE};
  }

  std::unique_lock<std::mutex> lock {m_dataMutex};
  m_data = data;

  if (msgLevel(MSG::DEBUG)) {
    debug() << std::setw(20) << id << ": " << std::setw(7) << data.size() << " bytes." << endmsg;
  }

  auto filename = m_outputDirectory.value() + "/" + m_filename.value() + ".bin";
  if (!m_filename.value().empty() && !std::filesystem::exists(filename)) {
    std::ofstream output {filename, std::ios::out | std::ios::binary};
    output.write(data.data(), data.size());
    if (m_bytesWritten) (*m_bytesWritten) += data.size();
  }
}
