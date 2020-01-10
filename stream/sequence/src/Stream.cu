#include "Stream.cuh"

// Include the sequence checker specializations
#include "VeloSequenceCheckers_impl.cuh"
#include "UTSequenceCheckers_impl.cuh"
#include "SciFiSequenceCheckers_impl.cuh"
#include "PVSequenceCheckers_impl.cuh"
#include "KalmanSequenceCheckers_impl.cuh"
#include "RateCheckers_impl.cuh"

/**
 * @brief Sets up the chain that will be executed later.
 */
cudaError_t Stream::initialize(
  const bool param_do_print_memory_manager,
  const uint param_start_event_offset,
  const size_t reserve_mb,
  const uint param_stream_number,
  const Constants& param_constants,
  HostBuffersManager const* buffers_manager)
{
  // Set stream and events
  cudaCheck(cudaStreamCreate(&cuda_stream));
  cudaCheck(cudaEventCreateWithFlags(&cuda_generic_event, cudaEventBlockingSync));

  // Set stream options
  stream_number = param_stream_number;
  do_print_memory_manager = param_do_print_memory_manager;
  start_event_offset = param_start_event_offset;
  constants = param_constants;
  
  // Reserve host buffers
  host_buffers_manager = buffers_manager;

  // Malloc a configurable reserved memory
  cudaCheck(cudaMalloc((void**) &dev_base_pointer, reserve_mb * 1024 * 1024));

  // Prepare scheduler
  scheduler.initialize(do_print_memory_manager, reserve_mb * 1024 * 1024, dev_base_pointer);

  return cudaSuccess;
}

cudaError_t Stream::run_sequence(const uint buf_idx, const RuntimeOptions& runtime_options)
{
  host_buffers = host_buffers_manager->getBuffers(buf_idx);
  // The sequence is only run if there are events to run on
  number_of_input_events = runtime_options.number_of_events;
  if (runtime_options.number_of_events > 0) {
    for (uint repetition = 0; repetition < runtime_options.number_of_repetitions; ++repetition) {
      // Initialize selected_number_of_events with requested_number_of_events
      host_buffers->host_number_of_selected_events[0] = runtime_options.number_of_events;

      // Reset scheduler
      scheduler.reset();

      try {
        // Visit all algorithms in configured sequence
        Sch::RunSequenceTuple<
          scheduler_t,
          SequenceVisitor,
          configured_sequence_t,
          std::tuple<const RuntimeOptions&, const Constants&, const HostBuffers&>,
          std::tuple<const RuntimeOptions&, const Constants&, HostBuffers&, cudaStream_t&, cudaEvent_t&>>::
          run(
            scheduler,
            sequence_visitor,
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
    SequenceVisitor,
    configured_sequence_t,
    std::tuple<HostBuffers&, const Constants&, const CheckerInvoker&, const MCEvents&>>::
    check(sequence_visitor, *host_buffers, constants, invoker, mc_events);

  if (forward_tracks.size() > 0) {
    info_cout << "Running test on imported tracks" << std::endl;
    auto& checker = invoker.checker<TrackCheckerForward>("PrCheckerPlots.root");
    checker.accumulate<TrackCheckerForward>(mc_events, forward_tracks);
  }
}

cudaError_t Stream::free(const bool do_check)
{
  if (host_buffers)
    host_buffers->free(do_check);
  cudaCheck(cudaFree(dev_base_pointer));
  
  return cudaSuccess;
}
