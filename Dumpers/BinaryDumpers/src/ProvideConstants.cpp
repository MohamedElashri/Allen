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
#include "RegisterConsumers.h"
#include "Constants.cuh"
#include "NeuralNetworkDefinition.cuh"
#include "BankTypes.h"
#include "Logger.h"

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

  CatboostModelReader muon_catboost_model_reader {geometry_path + "/allen_muon_catboost_model.json"};
  m_constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader.n_trees(),
    muon_catboost_model_reader.tree_depths(),
    muon_catboost_model_reader.tree_offsets(),
    muon_catboost_model_reader.leaf_values(),
    muon_catboost_model_reader.leaf_offsets(),
    muon_catboost_model_reader.split_border(),
    muon_catboost_model_reader.split_feature());

  LipschitzNNModelReader two_track_mva_model_reader {geometry_path + "/allen_two_track_mva_model_June22.json"};

  m_constants.initialize_two_track_mva_model_constants(
    two_track_mva_model_reader.weights(),
    two_track_mva_model_reader.biases(),
    two_track_mva_model_reader.layer_sizes(),
    two_track_mva_model_reader.n_layers(),
    two_track_mva_model_reader.monotone_constraints(),
    two_track_mva_model_reader.nominal_cut(),
    two_track_mva_model_reader.lambda());
  LipschitzNNModelReader electronid_mva_model_reader {geometry_path + "/CaloPID/electron_mva_AllenJune2024.json"};

  m_constants.initialize_electronid_mva_model_constants(
    electronid_mva_model_reader.weights(),
    electronid_mva_model_reader.biases(),
    electronid_mva_model_reader.layer_sizes(),
    electronid_mva_model_reader.n_layers(),
    electronid_mva_model_reader.monotone_constraints(),
    electronid_mva_model_reader.min_rescales(),
    electronid_mva_model_reader.max_rescales(),
    electronid_mva_model_reader.nominal_cut(),
    electronid_mva_model_reader.lambda());
  LipschitzNNModelReader muonid_mva_model_reader {geometry_path + "/muonid_mva_AllenJune2024.json"};

  m_constants.initialize_muonid_mva_model_constants(
    muonid_mva_model_reader.weights(),
    muonid_mva_model_reader.biases(),
    muonid_mva_model_reader.layer_sizes(),
    muonid_mva_model_reader.n_layers(),
    muonid_mva_model_reader.monotone_constraints(),
    muonid_mva_model_reader.min_rescales(),
    muonid_mva_model_reader.max_rescales(),
    muonid_mva_model_reader.nominal_cut(),
    muonid_mva_model_reader.lambda());

  // Ghost killers
  SingleLayerFCNNReader forward_ghostkiller_reader {geometry_path +
                                                    "/GhostProbability/Hlt1_LongGhostKiller_Forward.json"};
  m_constants.initialize_forward_ghostkiller_constants(
    forward_ghostkiller_reader.mean(),
    forward_ghostkiller_reader.std(),
    forward_ghostkiller_reader.weights1(),
    forward_ghostkiller_reader.bias1(),
    forward_ghostkiller_reader.weights2(),
    forward_ghostkiller_reader.bias2());
  SingleLayerFCNNReader forward_no_ut_ghostkiller_reader {geometry_path +
                                                          "/GhostProbability/Hlt1_LongGhostKiller_noUT_Forward.json"};
  m_constants.initialize_forward_no_ut_ghostkiller_constants(
    forward_no_ut_ghostkiller_reader.mean(),
    forward_no_ut_ghostkiller_reader.std(),
    forward_no_ut_ghostkiller_reader.weights1(),
    forward_no_ut_ghostkiller_reader.bias1(),
    forward_no_ut_ghostkiller_reader.weights2(),
    forward_no_ut_ghostkiller_reader.bias2());
  SingleLayerFCNNReader matching_ghostkiller_reader {geometry_path +
                                                     "/GhostProbability/Hlt1_LongGhostKiller_Matching.json"};
  m_constants.initialize_matching_ghostkiller_constants(
    matching_ghostkiller_reader.mean(),
    matching_ghostkiller_reader.std(),
    matching_ghostkiller_reader.weights1(),
    matching_ghostkiller_reader.bias1(),
    matching_ghostkiller_reader.weights2(),
    matching_ghostkiller_reader.bias2());

  SingleLayerFCNNReader downstream_ghostkiller_reader {geometry_path +
                                                       "/GhostProbability/Hlt1_DownstreamGhostKiller.json"};
  m_constants.initialize_downstream_ghostkiller_constants(
    downstream_ghostkiller_reader.mean(),
    downstream_ghostkiller_reader.std(),
    downstream_ghostkiller_reader.weights1(),
    downstream_ghostkiller_reader.bias1(),
    downstream_ghostkiller_reader.weights2(),
    downstream_ghostkiller_reader.bias2());

  SingleLayerFCNNReader matching_with_ut_ghostkiller_reader {
    geometry_path + "/GhostProbability/Hlt1_LongGhostKiller_MatchingWithUT.json"};
  m_constants.initialize_matching_with_ut_ghostkiller_constants(
    matching_with_ut_ghostkiller_reader.mean(),
    matching_with_ut_ghostkiller_reader.std(),
    matching_with_ut_ghostkiller_reader.weights1(),
    matching_with_ut_ghostkiller_reader.bias1(),
    matching_with_ut_ghostkiller_reader.weights2(),
    matching_with_ut_ghostkiller_reader.bias2());
  SingleLayerFCNNReader matching_no_ut_v2_ghostkiller_reader {
    geometry_path + "/GhostProbability/Hlt1_LongGhostKiller_MatchingNoUT_V2.json"};

  m_constants.initialize_matching_no_ut_v2_ghostkiller_constants(
    matching_no_ut_v2_ghostkiller_reader.mean(),
    matching_no_ut_v2_ghostkiller_reader.std(),
    matching_no_ut_v2_ghostkiller_reader.weights1(),
    matching_no_ut_v2_ghostkiller_reader.bias1(),
    matching_no_ut_v2_ghostkiller_reader.weights2(),
    matching_no_ut_v2_ghostkiller_reader.bias2());

  // std::unique_ptr<SingleLayerFCNNReader> forward_no_ut_ghostkiller_reader, matching_no_ut_ghostkiller_reader,
  // forward_ghostkiller_reader, matching_ghostkiller_reader;

  SingleLayerFCNNReader ttrack_selector_reader {geometry_path + "/HLT1Downstream/Hlt1_Downstream_TTrackSelector.json"};
  m_constants.initialize_ttrack_selector_constants(
    ttrack_selector_reader.mean(),
    ttrack_selector_reader.std(),
    ttrack_selector_reader.weights1(),
    ttrack_selector_reader.bias1(),
    ttrack_selector_reader.weights2(),
    ttrack_selector_reader.bias2());

  SingleLayerFCNNReader downstream_composite_quality_reader {geometry_path +
                                                             "/HLT1Downstream/Hlt1_Downstream_Composite_Quality.json"};
  m_constants.initialize_downstream_composite_quality_evaluator_constants(
    downstream_composite_quality_reader.mean(),
    downstream_composite_quality_reader.std(),
    downstream_composite_quality_reader.weights1(),
    downstream_composite_quality_reader.bias1(),
    downstream_composite_quality_reader.weights2(),
    downstream_composite_quality_reader.bias2());

  SingleLayerFCNNReader downstream_lambda_selector_reader {geometry_path +
                                                           "/HLT1Downstream/Hlt1_Downstream_LambdaSelector.json"};
  m_constants.initialize_downstream_lambda_selector_constants(
    downstream_lambda_selector_reader.mean(),
    downstream_lambda_selector_reader.std(),
    downstream_lambda_selector_reader.weights1(),
    downstream_lambda_selector_reader.bias1(),
    downstream_lambda_selector_reader.weights2(),
    downstream_lambda_selector_reader.bias2());

  SingleLayerFCNNReader downstream_kshort_selector_reader {geometry_path +
                                                           "/HLT1Downstream/Hlt1_Downstream_KshortSelector.json"};
  m_constants.initialize_downstream_kshort_selector_constants(
    downstream_kshort_selector_reader.mean(),
    downstream_kshort_selector_reader.std(),
    downstream_kshort_selector_reader.weights1(),
    downstream_kshort_selector_reader.bias1(),
    downstream_kshort_selector_reader.weights2(),
    downstream_kshort_selector_reader.bias2());

  SingleLayerFCNNReader downstream_detached_lambda_selector_reader {
    geometry_path + "/HLT1Downstream/Hlt1_Downstream_DetachedLambdaSelector.json"};
  m_constants.initialize_downstream_detached_lambda_selector_constants(
    downstream_detached_lambda_selector_reader.mean(),
    downstream_detached_lambda_selector_reader.std(),
    downstream_detached_lambda_selector_reader.weights1(),
    downstream_detached_lambda_selector_reader.bias1(),
    downstream_detached_lambda_selector_reader.weights2(),
    downstream_detached_lambda_selector_reader.bias2());

  SingleLayerFCNNReader downstream_detached_kshort_selector_reader {
    geometry_path + "/HLT1Downstream/Hlt1_Downstream_DetachedKshortSelector.json"};
  m_constants.initialize_downstream_detached_kshort_selector_constants(
    downstream_detached_kshort_selector_reader.mean(),
    downstream_detached_kshort_selector_reader.std(),
    downstream_detached_kshort_selector_reader.weights1(),
    downstream_detached_kshort_selector_reader.bias1(),
    downstream_detached_kshort_selector_reader.weights2(),
    downstream_detached_kshort_selector_reader.bias2());

  // Allen Consumers
  std::unordered_set<BankTypes> subdetectors;
  for (unsigned bt = 0; bt < NBankTypes; ++bt) {
    subdetectors.insert(static_cast<BankTypes>(bt));
  }
  register_consumers(m_updater.get(), m_constants, subdetectors);

  return StatusCode::SUCCESS;
}

Constants const* ProvideConstants::operator()(LHCb::ODIN const& odin) const
{
  // Trigger an update of non-event-data
  m_updater->update(odin.data);

  return &m_constants;
}

DECLARE_COMPONENT(ProvideConstants)
