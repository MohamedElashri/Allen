#include "Stream.cuh"
#include "StreamWrapper.cuh"

// Include the sequence checker specializations
#include "VeloSequenceCheckers_impl.cuh"
#include "UTSequenceCheckers_impl.cuh"
#include "SciFiSequenceCheckers_impl.cuh"
#include "PVSequenceCheckers_impl.cuh"
#include "KalmanSequenceCheckers_impl.cuh"
//#include "RateCheckers_impl.cuh"

StreamWrapper::StreamWrapper() {
  number_of_hlt1_lines = std::tuple_size<configured_lines_t>::value;
  uint passthrough_line_index = 0;
  const auto lambda_fn = [&] (const unsigned long i) {
    passthrough_line_index = i;
  };
  Hlt1::TraverseLines<configured_lines_t, Hlt1::SpecialLine, decltype(lambda_fn)>::traverse(lambda_fn);
  passthrough_line = passthrough_line_index;
}

void StreamWrapper::initialize_streams(
  const uint n,
  const bool print_memory_usage,
  const uint start_event_offset,
  const size_t reserve_mb,
  const Constants& constants,
  const std::map<std::string, std::map<std::string, std::string>>& config)
{
  for (uint i = 0; i < n; ++i) {
    streams.push_back(new Stream());
    streams.back()->configure_algorithms(config);
  }

  for (size_t i = 0; i < streams.size(); ++i) {
    streams[i]->initialize(
      print_memory_usage, start_event_offset, reserve_mb, constants);
  }
}

void StreamWrapper::initialize_streams_host_buffers_manager(
  HostBuffersManager* buffers_manager) {
  for (size_t i = 0; i < streams.size(); ++i) {
    streams[i]->set_host_buffer_manager(buffers_manager);
  }
}

cudaError_t StreamWrapper::run_stream(const uint i, const uint buf_idx, const RuntimeOptions& runtime_options)
{
  return streams[i]->run_sequence(buf_idx, runtime_options);
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

/**
 * @brief Sets up the chain that will be executed later.
 */
cudaError_t Stream::initialize(
  const bool param_do_print_memory_manager,
  const uint param_start_event_offset,
  const size_t reserve_mb,
  const Constants& param_constants)
{
  // Set stream and events
  cudaCheck(cudaStreamCreate(&cuda_stream));
  cudaCheck(cudaEventCreateWithFlags(&cuda_generic_event, cudaEventBlockingSync));

  // Set stream options
  do_print_memory_manager = param_do_print_memory_manager;
  start_event_offset = param_start_event_offset;
  constants = param_constants;

  // Malloc a configurable reserved memory on the host
  // TODO: Make configurable
  cudaCheck(cudaMallocHost((void**) &host_base_pointer, 10 * 1024 * 1024));

  // Malloc a configurable reserved memory on the device
  cudaCheck(cudaMalloc((void**) &dev_base_pointer, reserve_mb * 1024 * 1024));

  // Prepare scheduler
  scheduler.initialize(do_print_memory_manager, reserve_mb * 1024 * 1024, dev_base_pointer, 10 * 1024 * 1024, host_base_pointer);

  return cudaSuccess;
}

void Stream::set_host_buffer_manager(HostBuffersManager* buffers_manager) {
  // Set host buffers manager
  host_buffers_manager = buffers_manager;
}

cudaError_t Stream::run_sequence(const uint buf_idx, const RuntimeOptions& runtime_options)
{
  host_buffers = host_buffers_manager->getBuffers(buf_idx);
  // The sequence is only run if there are events to run on
  auto event_start = std::get<0>(runtime_options.event_interval);
  auto event_end = std::get<1>(runtime_options.event_interval);

  number_of_input_events = event_end - event_start;
  if (event_end > event_start) {
    for (uint repetition = 0; repetition < runtime_options.number_of_repetitions; ++repetition) {
      // Initialize selected_number_of_events with requested_number_of_events
      host_buffers->host_number_of_selected_events[0] = event_end - event_start;

      // Reset scheduler
      scheduler.reset();

      try {
        // Visit all algorithms in configured sequence
        Sch::RunSequenceTuple<
          scheduler_t,
          configured_sequence_t,
          std::tuple<const RuntimeOptions&, const Constants&, const HostBuffers&>,
          std::tuple<const RuntimeOptions&, const Constants&, HostBuffers&, cudaStream_t&, cudaEvent_t&>>::
          run(
            scheduler,
            scheduler.sequence_tuple,
            // Arguments to set_arguments_size
            runtime_options,
            constants,
            *host_buffers,
            // Arguments to visit
            runtime_options,
            constants,
            *host_buffers,
            cuda_stream,
            cuda_generic_event);

        // Synchronize CUDA device
        cudaEventRecord(cuda_generic_event, cuda_stream);
        cudaEventSynchronize(cuda_generic_event);
      } catch (const MemoryException& e) {
        warning_cout << "Insufficient memory to process slice - will sub-divide and retry." << std::endl;
        return cudaErrorMemoryAllocation;
      }
    }
  }

  return cudaSuccess;
}

std::vector<bool> Stream::reconstructed_events() const
{
  std::vector<bool> mask(number_of_input_events, false);
  for (uint i = 0; i < host_buffers->host_number_of_selected_events[0]; ++i) {
    mask[host_buffers->host_event_list[i]] = true;
  }
  return mask;
}

void Stream::run_monte_carlo_test(
  CheckerInvoker& invoker,
  MCEvents const& mc_events,
  std::vector<Checker::Tracks> const& forward_tracks)
{
  Sch::RunChecker<
    configured_sequence_t,
    std::tuple<HostBuffers&, const Constants&, const CheckerInvoker&, const MCEvents&>>::
    check(*host_buffers, constants, invoker, mc_events);

  if (forward_tracks.size() > 0) {
    info_cout << "Running test on imported tracks" << std::endl;
    auto& checker = invoker.checker<TrackCheckerForward>("PrCheckerPlots.root");
    checker.accumulate<TrackCheckerForward>(mc_events, forward_tracks);
  }
}
