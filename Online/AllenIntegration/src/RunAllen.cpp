
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

  // Initialize stream
  const bool print_memory_usage = false;
  const uint start_event_offset = 0;
  const size_t reserve_mb = 5; // to do: how much do we need maximally for one event?
  m_stream = new Stream();
  m_stream->initialize(print_memory_usage, start_event_offset, reserve_mb, m_constants, &m_host_buffers_manager);

  // Set verbosity level
  logger::ll.verbosityLevel = 5;
  
  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
std::tuple<LHCb::Tracks, LHCb::Tracks> RunAllen::operator()(const std::array<std::tuple<std::vector<uint32_t>, std::vector<uint32_t>>, LHCb::RawBank::LastType>& allen_banks, const LHCb::ODIN& odin ) const {

  // Get raw input and offsets for every detector
  std::array<BanksAndOffsets, LHCb::RawBank::LastType> banks_and_offsets; 
  for ( const auto bankType : m_bankTypes ) {
    // to do: catch that raw bank type was not dumped
    std::vector<uint32_t> bankData = std::get<0>(allen_banks[bankType]);
    std::vector<uint32_t> bankOffsets = std::get<1>(allen_banks[bankType]);
    banks_and_offsets[bankType] = std::make_tuple(gsl::span{reinterpret_cast<char const*>(bankData.data()), gsl::span<uint32_t>{bankData}.size_bytes()}, gsl::span{reinterpret_cast<unsigned int const*>(bankOffsets.data()), gsl::span<uint32_t>{bankOffsets}.size_bytes()});
  }
  
  // initialize RuntimeOptions
  RuntimeOptions runtime_options (
    std::move(banks_and_offsets[LHCb::RawBank::VP]),
    std::move(banks_and_offsets[LHCb::RawBank::UT]),
    std::move(banks_and_offsets[LHCb::RawBank::FTCluster]),
    std::move(banks_and_offsets[LHCb::RawBank::Muon]),
    m_number_of_events,
    m_number_of_repetitions,
    m_do_check,
    m_cpu_offload);

  const uint buf_idx = 0;
  cudaError_t rv = m_stream->run_sequence(buf_idx, runtime_options);
  
  LHCb::Tracks VeloTracks;
  LHCb::Tracks UTTracks;

  return std::make_tuple( std::move( VeloTracks ), std::move( UTTracks ) );
}
