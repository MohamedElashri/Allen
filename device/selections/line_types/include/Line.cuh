#pragma once

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(LINE, PARAMETERS)          \
  template void Line<LINE, PARAMETERS>::operator()( \
    const ArgumentReferences<PARAMETERS>&,          \
    const RuntimeOptions&,                          \
    const Constants&,                               \
    HostBuffers&,                                   \
    cudaStream_t&,                                  \
    cudaEvent_t&) const;

/**
 * @brief A generic Line.
 * @detail It assumes the line has the following parameters:
 * 
 *  (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
 *  (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
 *  (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
 * 
 * The inheriting line must also provide the following methods:
 *
 *     __device__ unsigned get_input_size(const Parameters& parameters, const unsigned event_number) const;
 *
 *     __device__ bool* get_decision(const Parameters& parameters, const unsigned event_number) const;
 *
 *     unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const;
 *
 *     __device__ std::tuple<const ParKalmanFilter::FittedTrack&>
 *     get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const;
 * 
 *     __device__ bool select(const Parameters& parameters, std::tuple<const ParKalmanFilter::FittedTrack&> input) const;
 *
 * The following methods can optionally be defined in an inheriting class:
 *
 *     unsigned get_grid_dim_x(const ArgumentReferences<Parameters>&) const;
 *
 *     unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const;
 */
template<typename Derived, typename Parameters>
struct Line {
  void set_arguments_size(
    ArgumentReferences<Parameters> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const
  {
    auto derived_instance = static_cast<const Derived*>(this);
    set_size<typename Parameters::dev_decisions_t>(arguments, derived_instance->get_decisions_size(arguments));
  }

  void operator()(
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    cudaStream_t&,
    cudaEvent_t&) const;

  /**
   * @brief Grid dimension of kernel call. By default, get_grid_dim returns the size of the event list.
   */
  unsigned get_grid_dim_x(const ArgumentReferences<Parameters>& arguments) const
  {
    return size<typename Parameters::dev_event_list_t>(arguments);
  }

  /**
   * @brief Default block dim x of kernel call.
   */
  unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { return 256; }
};

// This #if statement means: If compiling with the device compiler
#if defined(TARGET_DEVICE_CPU) || (defined(TARGET_DEVICE_HIP) && (defined(__HCC__) || defined(__HIP__))) || \
  ((defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__)) || (defined(TARGET_DEVICE_CUDACLANG) && defined(__CUDA__)))

/**
 * @brief Processes a line by iterating over all events and all "get_input_size" (ie. tracks, vertices, etc.).
 *        The way process line parallelizes is highly configurable.
 */
template<typename Line, typename Parameters>
__global__ void process_line(Line line, Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  for (unsigned i = threadIdx.x; i < line.get_input_size(parameters, event_number); i += blockDim.x) {
    line.get_decision(parameters, event_number)[i] =
      line.select(parameters, line.get_input(parameters, event_number, i));
  }
}

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  initialize<typename Parameters::dev_decisions_t>(arguments, 0, stream);

  auto derived_instance = static_cast<const Derived*>(this);
  derived_instance->global_function(process_line<Derived, Parameters>)(
    derived_instance->get_grid_dim_x(arguments), derived_instance->get_block_dim_x(arguments), stream)(
    *derived_instance, arguments);
}

#endif