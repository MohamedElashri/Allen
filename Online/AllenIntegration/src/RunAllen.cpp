
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
: Transformer( name, pSvcLocator,
                    // Inputs
                    {KeyValue{"AllenRawInput", "Allen/Raw/Input"},
                     KeyValue{"ODINLocation", LHCb::ODINLocation::Default}},
                    // Outputs
                    {KeyValue{"AllenOutput", "Allen/Out/HostBuffers"}} ) {}

StatusCode RunAllen::initialize() {
  auto sc = Transformer::initialize();
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

  // Initialize stream
  const bool print_memory_usage = false;
  const uint start_event_offset = 0;
  const size_t reserve_mb = 5; // to do: how much do we need maximally for one event?
  m_stream = new Stream();
  m_stream->initialize(print_memory_usage, start_event_offset, reserve_mb, m_constants, &m_host_buffers_manager);

  // Set verbosity level
  logger::ll.verbosityLevel = 4;
  
  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
HostBuffers RunAllen::operator()(const std::array<std::vector<char>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const {

  // Get raw input and event offsets for every detector
  std::array<BanksAndOffsets, LHCb::RawBank::LastType> banks_and_offsets;
  std::array<uint[2], LHCb::RawBank::LastType> event_offsets;
  for ( const auto bankType : m_bankTypes ) {
    // to do: catch that raw bank type was not dumped
    
    // Offsets to events (we only process one event)
    //unsigned int offsets_mem[2];
    event_offsets[bankType][0] = 0;
    event_offsets[bankType][1] = allen_banks[bankType].size();
    gsl::span<unsigned int> offsets{event_offsets[bankType], 2};
    
    banks_and_offsets[bankType] = std::make_tuple(gsl::span{allen_banks[bankType].data(), allen_banks[bankType].size()}, offsets);
  }

  // initialize RuntimeOptions
  RuntimeOptions runtime_options (
    banks_and_offsets[LHCb::RawBank::VP],
    banks_and_offsets[LHCb::RawBank::UT],
    banks_and_offsets[LHCb::RawBank::FTCluster],
    banks_and_offsets[LHCb::RawBank::Muon],
    m_number_of_events,
    m_number_of_repetitions,
    m_do_check,
    m_cpu_offload);

  const uint buf_idx = m_n_buffers - 1;
  cudaError_t rv = m_stream->run_sequence(buf_idx, runtime_options);
  
  return *(m_stream->host_buffers_manager->getBuffers(buf_idx));
}

StatusCode RunAllen::finalize() {
  info() << "Finalizing Allen..." << endmsg;
  
  cudaError_t rv = m_stream->free(m_do_check);
  if (rv != 0) {
    error() << "Failed to free stream memory, cudaError = " << rv << endmsg;
    return StatusCode::FAILURE;
  }
  
  return Transformer::finalize(); 
}
