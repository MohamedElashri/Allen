
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

#include "RunAllen.h"

DECLARE_COMPONENT( RunAllen )

RunAllen::RunAllen( const std::string& name, ISvcLocator* pSvcLocator )
: MultiTransformer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenRawInput", "Allen/Raw/Input"},
                     KeyValue{"ODINLocation", LHCb::ODINLocation::Default}},
                    // Outputs
                    {KeyValue{"VeloTracks", "Allen/Track/Velo"},
                     KeyValue{"UTTracks", "Allen/Track/UT"}} ) {}

StatusCode RunAllen::initialize() {
  auto sc = MultiTransformer::initialize();
  if ( sc.isFailure() ) return sc;
  if ( msgLevel( MSG::DEBUG ) ) debug() << "==> Initialize" << endmsg;

  // initialize Allen
  
  // get constants
  std::string folder_detector_configuration = m_configurationPath;

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(
    muon_field_of_interest_params, folder_detector_configuration + "field_of_interest_params.bin");
  
  m_constants.reserve_and_initialize(
    muon_field_of_interest_params, folder_detector_configuration + "params_kalman_FT6x2/");

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader = std::make_unique<CatboostModelReader>(folder_detector_configuration + "muon_catboost_model.json");
  m_constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader->n_trees(),
    muon_catboost_model_reader->tree_depths(),
    muon_catboost_model_reader->tree_offsets(),
    muon_catboost_model_reader->leaf_values(),
    muon_catboost_model_reader->leaf_offsets(),
    muon_catboost_model_reader->split_border(),
    muon_catboost_model_reader->split_feature());
  
  // Get updater service and register all consumers
  auto svc = service( m_updaterName ); 
  if ( !svc ) {
    error() << "Failed get updater " << m_updaterName.value() << endmsg;
    return StatusCode::FAILURE;
  }
  auto* updater = dynamic_cast<Allen::NonEventData::IUpdater*>( svc.get() );
  if ( !updater ) {
    error() << "Failed cast updater " << m_updaterName.value() << " to Allen::NonEventData::IUpdater " << endmsg;
    return StatusCode::FAILURE;
  }
  
  register_consumers(updater, m_constants);

  // Run all registered producers and consumers
  updater->update(0);
  
  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
std::tuple<LHCb::Tracks, LHCb::Tracks> RunAllen::operator()(const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const {

  // get raw input data

  // call run_stream

  
  LHCb::Tracks VeloTracks;
  LHCb::Tracks UTTracks;

  return std::make_tuple( std::move( VeloTracks ), std::move( UTTracks ) );
}
