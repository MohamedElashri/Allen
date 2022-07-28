/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// Gaudi
#include "GaudiAlg/Transformer.h"

// Allen
#include <Allen.h>
#include <Dumpers/IUpdater.h>
#include "InputTools.h"
#include "InputReader.h"
#include "Constants.cuh"
#include "Logger.h"

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
  Allen::NonEventData::IUpdater* m_updater = nullptr;

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

  // initialize Allen Constants
  // Get updater service and register all consumers
  auto svc = service(m_updaterName);
  if (!svc) {
    error() << "Failed get updater " << m_updaterName.value() << endmsg;
    return StatusCode::FAILURE;
  }
  m_updater = dynamic_cast<Allen::NonEventData::IUpdater*>(svc.get());
  if (!m_updater) {
    error() << "Failed cast updater " << m_updaterName.value() << " to Allen::NonEventData::IUpdater " << endmsg;
    return StatusCode::FAILURE;
  }

  std::string geometry_path = resolveEnvVars(m_paramDir) + "/data";

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, geometry_path + "/allen_muon_field_of_interest_params.bin");

  m_constants.reserve_and_initialize(muon_field_of_interest_params, geometry_path);

  CatboostModelReader muon_catboost_model_reader {geometry_path + "/allen_muon_catboost_model.json"};
  m_constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader.n_trees(),
    muon_catboost_model_reader.tree_depths(),
    muon_catboost_model_reader.tree_offsets(),
    muon_catboost_model_reader.leaf_values(),
    muon_catboost_model_reader.leaf_offsets(),
    muon_catboost_model_reader.split_border(),
    muon_catboost_model_reader.split_feature());
  TwoTrackMVAModelReader two_track_mva_model_reader {geometry_path + "/allen_two_track_mva_model_June22.json"};
  m_constants.initialize_two_track_mva_model_constants(
    two_track_mva_model_reader.weights(),
    two_track_mva_model_reader.biases(),
    two_track_mva_model_reader.layer_sizes(),
    two_track_mva_model_reader.n_layers(),
    two_track_mva_model_reader.monotone_constraints(),
    two_track_mva_model_reader.nominal_cut(),
    two_track_mva_model_reader.lambda());

  // Allen Consumers
  register_consumers(
    m_updater, m_constants, {BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::ECal, BankTypes::MUON});

  return StatusCode::SUCCESS;
}

Constants const* ProvideConstants::operator()(LHCb::ODIN const& odin) const
{
  // Trigger an update of non-event-data
  m_updater->update(odin.data);

  return &m_constants;
}

DECLARE_COMPONENT(ProvideConstants)
