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
#include "GaudiAlg/Producer.h"

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

class ProvideConstants final : public Gaudi::Functional::Producer<std::tuple<Constants const*>()> {

public:
  /// Standard constructor
  ProvideConstants(const std::string& name, ISvcLocator* pSvcLocator);

  /// initialization
  StatusCode initialize() override;

  /// Algorithm execution
  std::tuple<Constants const*> operator()() const override;

private:
  Constants m_constants;

  Gaudi::Property<std::string> m_paramDir {this,
                                           "ParamDir",
                                           ""}; // set this explicitly, must match with the Condition tags.
  Gaudi::Property<std::string> m_updaterName {this, "UpdaterName", "AllenUpdater"};
};

ProvideConstants::ProvideConstants(const std::string& name, ISvcLocator* pSvcLocator) :
  Producer(
    name,
    pSvcLocator,
    // Outputs
    {KeyValue {"ConstantsLocation", "Allen/Stream/Constants"}})
{}

StatusCode ProvideConstants::initialize()
{
  auto sc = Producer::initialize();
  if (sc.isFailure()) return sc;

  // initialize Allen Constants
  // Get updater service and register all consumers
  auto svc = service(m_updaterName);
  if (!svc) {
    error() << "Failed get updater " << m_updaterName.value() << endmsg;
    return StatusCode::FAILURE;
  }
  auto* updater = dynamic_cast<Allen::NonEventData::IUpdater*>(svc.get());
  if (!updater) {
    error() << "Failed cast updater " << m_updaterName.value() << " to Allen::NonEventData::IUpdater " << endmsg;
    return StatusCode::FAILURE;
  }

  std::string geometry_path = resolveEnvVars(m_paramDir);

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(muon_field_of_interest_params, geometry_path + "/field_of_interest_params.bin");

  m_constants.reserve_and_initialize(muon_field_of_interest_params, geometry_path + "/params_kalman_FT6x2/");

  CatboostModelReader muon_catboost_model_reader {geometry_path + "/muon_catboost_model.json"};
  m_constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader.n_trees(),
    muon_catboost_model_reader.tree_depths(),
    muon_catboost_model_reader.tree_offsets(),
    muon_catboost_model_reader.leaf_values(),
    muon_catboost_model_reader.leaf_offsets(),
    muon_catboost_model_reader.split_border(),
    muon_catboost_model_reader.split_feature());
  TwoTrackMVAModelReader two_track_mva_model_reader {geometry_path + "/two_track_mva_model.json"};
  m_constants.initialize_two_track_mva_model_constants(
    two_track_mva_model_reader.weights(),
    two_track_mva_model_reader.biases(),
    two_track_mva_model_reader.layer_sizes(),
    two_track_mva_model_reader.n_layers(),
    two_track_mva_model_reader.monotone_constraints(),
    two_track_mva_model_reader.nominal_cut(),
    two_track_mva_model_reader.lambda());

  // Allen Consumers
  register_consumers(updater, m_constants);

  // Run all registered producers and consumers
  LHCb::ODIN odin{};
  odin.setRunNumber(0);
  updater->update(odin.data);

  return StatusCode::SUCCESS;
}

std::tuple<Constants const*> ProvideConstants::operator()() const { return {&m_constants}; }

DECLARE_COMPONENT(ProvideConstants)
