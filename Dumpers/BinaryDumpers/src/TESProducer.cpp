/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <tuple>
#include <vector>
#include <string>

#include <DetDesc/Condition.h>
#include <DetDesc/ConditionAccessorHolder.h>
#include <GaudiAlg/Consumer.h>

#include "AllenUpdater.h"

namespace Allen {

/** @class TESProducer
 *  Dump beamline position.
 *
 *  @author Roel Aaij
 *  @date   2019-04-27
 */
class TESProducer final
  : public Gaudi::Functional::Consumer<void(std::vector<char> const&, std::string const&)> {
public:

  TESProducer( const std::string& name, ISvcLocator* svcLoc );

  void operator()(std::vector<char> const& data, std::string const& id) const override;

  StatusCode initialize() override;

private:

  Gaudi::Property<std::string> m_id{this, "ID"};

  mutable std::vector<char> m_data;
};
}

DECLARE_COMPONENT_WITH_ID( Allen::TESProducer, "AllenTESProducer" )

Allen::TESProducer::TESProducer( const std::string& name, ISvcLocator* svcLoc )
    : Consumer( name, svcLoc,
                {KeyValue{"InputData", ""},
                 KeyValue{"InputID", ""}} ) {}

StatusCode Allen::TESProducer::initialize()
{
  auto sc = Consumer::initialize();
  if (!sc.isSuccess()) {
    return sc;
  }
  auto updater = service<AllenUpdater>("AllenUpdater", false);
  if (!updater) {
    error() << "Failed to retrieve AllenUpdater" << endmsg;
    return StatusCode::FAILURE;
  }
  updater->registerProducer(m_id.value(), [this] () -> std::optional<std::vector<char>> { return {m_data}; });
  return StatusCode::SUCCESS;
}

void Allen::TESProducer::operator()(std::vector<char> const& data, std::string const& id) const
{
  using namespace std::string_literals;
  if (id != m_id.value()) {
        throw GaudiException{"ID from TES is not what was expected: "s + id + " " + m_id.value(), name(), StatusCode::FAILURE};
    }
    m_data = data;
}
