#include "StreamWrapper.cuh"
#include "Stream.cuh"
#include "SchedulerMachinery.cuh"

void StreamWrapper::initialize_streams(
  const uint n,
  const uint number_of_events,
  const bool print_memory_usage,
  const uint start_event_offset,
  const size_t reserve_mb,
  const Constants& constants,
  const bool do_check)
{
  for (uint i = 0; i < n; ++i) {
    streams.push_back(new Stream());
  }

  for (size_t i = 0; i < streams.size(); ++i) {
    streams[i]->initialize(
      number_of_events, print_memory_usage, start_event_offset, reserve_mb, i, constants, do_check);
  }
}

void StreamWrapper::run_stream(const uint i, const RuntimeOptions& runtime_options)
{
  streams[i]->run_sequence(runtime_options);
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
