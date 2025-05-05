/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// Gaudi
#include "GaudiAlg/Transformer.h"

// Allen
#include <Dumpers/IUpdater.h>
#include "InputTools.h"
#include "InputReader.h"
#include "MVAModelsManager.h"
#include "RegisterConsumers.h"
#include "Constants.cuh"
#include "BankTypes.h"
#include "Logger.h"

#include "MVAModelsManager.h"

#include "AllenUpdater.h"

namespace {
  std::string resolveEnvVars(std::string s)
  {
    std::regex envExpr {"\\$\\{([A-Za-z0-9_]+)\\}"};
    std::smatch m;
    while (std::regex_search(s, m, envExpr)) {
      std::string rep;
      System::getEnv(m[1].str(), rep);
      s = s.replace(m[1].first - 2, m[1].second + 1, rep);
    }
    return s;
  }
} // namespace

class ProvideConstants final : public Gaudi::Functional::Transformer<Constants const*(LHCb::ODIN const&)> {

public:
  /// Standard constructor
  ProvideConstants(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  Constants const* operator()(LHCb::ODIN const& odin) const override;

private:
  SmartIF<AllenUpdater> m_updater;

  Constants m_constants;

  Gaudi::Property<std::string> m_paramDir {
    this,
    "ParamDir",
    "${PARAMFILESROOT}"}; // set this explicitly, must match with the Condition tags.
  Gaudi::Property<std::string> m_updaterName {this, "UpdaterName", "AllenUpdater"};
};

ProvideConstants::ProvideConstants(const std::string& name, ISvcLocator* pSvcLocator) :
  Transformer(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"ODINLocation", LHCb::ODINLocation::Default}},
    // Outputs
    {KeyValue {"ConstantsLocation", "Allen/Stream/Constants"}})
{}

StatusCode ProvideConstants::initialize()
{
  auto sc = Transformer::initialize();
  if (sc.isFailure()) return sc;

  // Get updater service and register all consumers
  m_updater = service<AllenUpdater>("AllenUpdater", true);
  if (!m_updater) {
    error() << "Failed to retrieve AllenUpdater" << endmsg;
    return StatusCode::FAILURE;
  }

  // initialize Allen Constants
  std::string geometry_path = resolveEnvVars(m_paramDir) + "/data";

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, geometry_path + "/allen_muon_field_of_interest_params.bin");

  m_constants.reserve_and_initialize(muon_field_of_interest_params, geometry_path);

  // Allen Consumers
  std::unordered_set<BankTypes> subdetectors;
  for (unsigned bt = 0; bt < NBankTypes; ++bt) {
    subdetectors.insert(static_cast<BankTypes>(bt));
  }
  register_consumers(m_updater.get(), m_constants, subdetectors);

  std::unordered_set<BankTypes> GenCrossingAngles;
  if (m_updater->getProdiveGenCrossingAngles()) {
    GenCrossingAngles.insert(static_cast<BankTypes>(NBankTypes));
    register_consumers(m_updater.get(), m_constants, GenCrossingAngles);
  }
  return StatusCode::SUCCESS;
}

Constants const* ProvideConstants::operator()(LHCb::ODIN const& odin) const
{
  // Trigger an update of non-event-data
  m_updater->update(odin.data);

  return &m_constants;
}

DECLARE_COMPONENT(ProvideConstants)
