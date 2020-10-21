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
    {KeyValue {"AllenOutput", "Allen/Out/HostBuffers"}, KeyValue {"DecReportsLocation", "Allen/Out/DecReports"}})
{}

StatusCode RunAllen::initialize()
{
  auto sc = MultiTransformerFilter::initialize();
  if (sc.isFailure()) return sc;
  if (msgLevel(MSG::DEBUG)) debug() << "==> Initialize" << endmsg;

  /* initialize Allen */

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
  const unsigned start_event_offset = 0;
  const size_t reserve_mb = 10; // to do: how much do we need maximally for one event?

  m_stream_wrapper.reset(new StreamWrapper());
  m_stream_wrapper->initialize_streams(
    m_number_of_streams,
    print_memory_usage,
    start_event_offset,
    reserve_mb,
    reserve_mb, // host memory same as "device"
    m_constants,
    configuration_reader.params());

  // Initialize host buffers (where Allen output is stored)
  m_host_buffers_manager.reset(new HostBuffersManager(
    m_n_buffers, 2, m_do_check, m_stream_wrapper->errorevent_line));
  m_stream_wrapper->initialize_streams_host_buffers_manager(m_host_buffers_manager.get());

  // Initialize input provider
  const size_t number_of_slices = 1;
  const size_t events_per_slice = 1;
  const size_t n_events = 1;
  m_tes_input_provider.reset(
    new TESProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>(
      number_of_slices, events_per_slice, n_events));

  // Get HLT1 selection names from configuration and initialize rate counters
  m_line_names = configuration_reader.params()["configured_lines"];
  m_hlt1_line_rates.reserve(m_line_names.size());
  for (unsigned i = 0; i < m_line_names.size(); ++i) {
    const auto it = m_line_names.find(std::to_string(i));
    const std::string name = "Hlt1" + it->second + "Decision";
    m_hlt1_line_rates.emplace_back(this, "Selected by " + name);
  }

  // Set verbosity level
  logger::setVerbosity(6 - this->msgLevel());

  return StatusCode::SUCCESS;
}

/** Calls Allen for one event
 */
std::tuple<bool, HostBuffers, LHCb::HltDecReports> RunAllen::operator()(
  const std::array<std::vector<char>, LHCb::RawBank::LastType>& allen_banks,
  const LHCb::ODIN&) const
{

  int rv = m_tes_input_provider.get()->set_banks(allen_banks, m_bankTypes);
  if (rv > 0) {
    error() << "Error in reading dumped raw banks" << endmsg;
  }

  // initialize RuntimeOptions
  const unsigned event_start = 0;
  const unsigned event_end = 1;
  const size_t slice_index = 0;
  const bool mep_layout = false;
  const uint inject_mem_fail = 0;
  RuntimeOptions runtime_options(
    m_tes_input_provider.get(),
    slice_index,
    {event_start, event_end},
    m_number_of_repetitions,
    m_do_check,
    m_cpu_offload,
    mep_layout,
    inject_mem_fail);

  const unsigned buf_idx = m_n_buffers - 1;
  const unsigned stream_index = m_number_of_streams - 1;
  cudaError_t cuda_rv = m_stream_wrapper->run_stream(stream_index, buf_idx, runtime_options);
  if (cuda_rv != cudaSuccess) {
    error() << "Allen exited with errorCode " << rv << endmsg;
    // how to exit a filter with failure?
  }
  bool filter = true;
  HostBuffers* buffer = m_host_buffers_manager->getBuffers(buf_idx);
  if (m_filter_hlt1.value()) {
    filter = buffer->host_passing_event_list[0];
  }

  // Get line decisions from DecReports
  // First two words contain the TCK and taskID, then one word per HLT1 line
  LHCb::HltDecReports reports {};
  reports.reserve(buffer->host_number_of_lines);
  uint32_t dec_mask = HltDecReport::decReportMasks::decisionMask;
  for (unsigned int i = 0; i < buffer->host_number_of_lines; i++) {
    const uint32_t line_report = buffer->host_dec_reports[2 + i];
    const bool dec = line_report & dec_mask;
    const auto it = m_line_names.find(std::to_string(i));
    const std::string name = it->second;
    const std::string modified_name = "Hlt1" + name + "Decision";
    m_hlt1_line_rates[i].buffer() += int(dec);
    // Note: the line index in a DecReport cannot be zero -> start at 1
    const int dec_rep_index = i + 1;
    verbose() << "Adding Allen line " << dec_rep_index << " with name " << modified_name << " to HltDecReport with decision "
              << int(dec) << endmsg;

    reports.insert(modified_name, {dec, 0, 0, 0, dec_rep_index}).ignore(/* AUTOMATICALLY ADDED FOR gaudi/Gaudi!763 */);
  }
  if (msgLevel(MSG::DEBUG)) debug() << "Event selected by Allen: " << unsigned(filter) << endmsg;
  return std::make_tuple(filter, *buffer, reports);
}

StatusCode RunAllen::finalize()
{
  if (msgLevel(MSG::DEBUG)) debug() << "Finalizing Allen..." << endmsg;

  return MultiTransformerFilter::finalize();
}
