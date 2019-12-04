#include "StreamWrapper.cuh"
#include "Stream.cuh"
#include "SchedulerMachinery.cuh"

void StreamWrapper::initialize_streams(
  const uint n,
  const bool print_memory_usage,
  const uint start_event_offset,
  const size_t reserve_mb,
  const Constants& constants,
  HostBuffersManager const * buffers_manager,
  const std::map<std::string, std::map<std::string, std::string>>& config)
{
  for (uint i = 0; i < n; ++i) {
    streams.push_back(new Stream());
    streams.back()->configure_algorithms(config);
  }

  for (size_t i = 0; i < streams.size(); ++i) {
    streams[i]->initialize(
      print_memory_usage, start_event_offset, reserve_mb, i, constants, buffers_manager);
  }

  // for (const auto& kv : config) {
  //   info_cout << kv.first << "\n";

  //   for (const auto& kv2 : kv.second) {
  //     info_cout << " " << kv2.first << ", " << kv2.second << "\n";
  //   }
  // }
}

void StreamWrapper::run_stream(const uint i, const uint buf_idx, const RuntimeOptions& runtime_options)
{
  streams[i]->run_sequence(buf_idx, runtime_options);
}

std::vector<bool> StreamWrapper::reconstructed_events(const uint i) const { return streams[i]->reconstructed_events(); }

void StreamWrapper::run_monte_carlo_test(
  uint const i,
  CheckerInvoker& invoker,
  MCEvents const& mc_events,
  std::vector<Checker::Tracks> const& forward_tracks)
{
  streams[i]->run_monte_carlo_test(invoker, mc_events, forward_tracks);
}

std::map<std::string, std::map<std::string, std::string>> StreamWrapper::get_algorithm_configuration()
{
  return streams.front()->get_algorithm_configuration();
}

StreamWrapper::~StreamWrapper()
{
  for (auto& stream : streams) {
    delete stream;
  }
}

void print_configured_sequence()
{
  info_cout << "\nConfigured sequence of algorithms:\n";
  Sch::PrintAlgorithmSequence<configured_sequence_t>::print();
  info_cout << std::endl;
}
