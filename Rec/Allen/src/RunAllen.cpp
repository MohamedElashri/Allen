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

/**
 * Call Allen to run at one event at a time
 *
 * author Dorothea vom Bruch
 *
 */
#include "RunAllen.h"

DECLARE_COMPONENT(RunAllen)

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

RunAllen::RunAllen(const std::string& name, ISvcLocator* pSvcLocator) :
  MultiTransformerFilter(
    name,
    pSvcLocator,
    // Inputs
    {KeyValue {"AllenRawInput", "Allen/Raw/Input"}, KeyValue {"ODINLocation", LHCb::ODINLocation::Default}},
    // Outputs
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}})
{}

StatusCode RunAllen::initialize()
{
  auto sc = MultiTransformerFilter::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  // initialize Allen

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

  // get constants
  std::string geometry_path = resolveEnvVars(m_paramDir);

  std::vector<float> muon_field_of_interest_params;
  read_muon_field_of_interest(muon_field_of_interest_params, geometry_path + "/field_of_interest_params.bin");

  m_constants.reserve_and_initialize(muon_field_of_interest_params, geometry_path + "/params_kalman_FT6x2/");

  std::unique_ptr<CatboostModelReader> muon_catboost_model_reader =
    std::make_unique<CatboostModelReader>(geometry_path + "/muon_catboost_model.json");
  m_constants.initialize_muon_catboost_model_constants(
    muon_catboost_model_reader->n_trees(),
    muon_catboost_model_reader->tree_depths(),
    muon_catboost_model_reader->tree_offsets(),
    muon_catboost_model_reader->leaf_values(),
    muon_catboost_model_reader->leaf_offsets(),
    muon_catboost_model_reader->split_border(),
    muon_catboost_model_reader->split_feature());

  // Allen Consumers
  register_consumers(updater, m_constants);

  // Run all registered producers and consumers
  updater->update(0);

  // Read configuration
  std::string conf_file = resolveEnvVars(m_json);
  ConfigurationReader configuration_reader(conf_file);

  // Initialize stream
  const bool print_memory_usage = false;
  const uint start_event_offset = 0;
  const size_t reserve_mb = 10; // to do: how much do we need maximally for one event?

  m_number_of_hlt1_lines = std::tuple_size<configured_lines_t>::value;

  uint passthrough_line = 0;
  const auto lambda_fn = [&passthrough_line](const unsigned long i) { passthrough_line = i; };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::SpecialLine, decltype(lambda_fn)>::traverse(lambda_fn);

  m_host_buffers_manager.reset(
    new HostBuffersManager(m_n_buffers, m_number_of_events, m_do_check, m_number_of_hlt1_lines, passthrough_line));
  m_stream.reset(new Stream());
  m_stream->configure_algorithms(configuration_reader.params());
  m_stream->initialize(print_memory_usage, start_event_offset, reserve_mb, m_constants);
  m_stream->set_host_buffer_manager(m_host_buffers_manager.get());

  // Set verbosity level
  logger::setVerbosity(3);

  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
std::tuple<bool, HostBuffers> RunAllen::operator()(
  const std::array<std::vector<char>, LHCb::RawBank::LastType>& allen_banks,
  const LHCb::ODIN&) const
{

  // Get raw input and event offsets for every detector
  std::array<BanksAndOffsets, LHCb::RawBank::LastType> banks_and_offsets;
  std::array<std::array<unsigned int, 2>, LHCb::RawBank::LastType> event_offsets;
  for (const auto bankType : m_bankTypes) {
    // to do: catch that raw bank type was not dumped

    // Offsets to events (we only process one event)
    // unsigned int offsets_mem[2];
    event_offsets[bankType][0] = 0;
    event_offsets[bankType][1] = allen_banks[bankType].size();
    gsl::span<unsigned int const> offsets {event_offsets[bankType].data(), 2};
    using data_span = gsl::span<char const>;
    auto data_size = static_cast<data_span::index_type>(allen_banks[bankType].size());
    std::vector<data_span> spans(1, data_span {allen_banks[bankType].data(), data_size});
    banks_and_offsets[bankType] = std::make_tuple(std::move(spans), data_size, std::move(offsets));
  }

  // initialize RuntimeOptions
  RuntimeOptions runtime_options(
    banks_and_offsets[LHCb::RawBank::VP],
    banks_and_offsets[LHCb::RawBank::UT],
    banks_and_offsets[LHCb::RawBank::FTCluster],
    banks_and_offsets[LHCb::RawBank::Muon],
    banks_and_offsets[LHCb::RawBank::ODIN],
    {0u, m_number_of_events},
    m_number_of_repetitions,
    m_do_check,
    m_cpu_offload,
    false);

  const uint buf_idx = m_n_buffers - 1;
  cudaError_t rv = m_stream->run_sequence(buf_idx, runtime_options);
  if (rv != cudaSuccess) {
    error() << "Allen exited with errorCode " << rv << endmsg;
    // how to exit a filter with failure?
  }
  bool filter = m_stream->host_buffers_manager->getBuffers(buf_idx)->host_number_of_selected_events[0];
  if (m_filter_hlt1) {
    filter = m_stream->host_buffers_manager->getBuffers(buf_idx)->host_number_of_passing_events[0];
  }
  info() << "Event selected by Allen: " << uint(filter) << endmsg;
  return std::make_tuple(filter, *(m_stream->host_buffers_manager->getBuffers(buf_idx)));
}

StatusCode RunAllen::finalize()
{
  info() << "Finalizing Allen..." << endmsg;

  return MultiTransformerFilter::finalize();
}
