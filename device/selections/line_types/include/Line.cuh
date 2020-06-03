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

// "Enum of types" to determine dispatch to global_function
namespace LineIteration {
  struct default_iteration_tag {
  };
  struct event_iteration_tag {
  };
} // namespace LineIteration

/**
 * @brief A generic Line.
 * @detail It assumes the line has the following parameters:
 *
 *  (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
 *  (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
 *  (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
 *  (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
 *
 * The inheriting line must also provide the following methods:
 *
 *     __device__ unsigned offset(const Parameters& parameters, const unsigned event_number) const;
 *
 *     unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const;
 *
 *     __device__ std::tuple<const ParKalmanFilter::FittedTrack&>
 *     get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const;
 *
 *     __device__ bool select(const Parameters& parameters, std::tuple<const ParKalmanFilter::FittedTrack&> input)
 * const;
 *
 * The following methods can optionally be defined in an inheriting class:
 *
 *     unsigned get_grid_dim_x(const ArgumentReferences<Parameters>&) const;
 *
 *     unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const;
 */
template<typename Derived, typename Parameters>
struct Line {
  using iteration_t = LineIteration::default_iteration_tag;

  void set_arguments_size(
    ArgumentReferences<Parameters> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const
  {
    auto derived_instance = static_cast<const Derived*>(this);
    set_size<typename Parameters::dev_decisions_t>(arguments, derived_instance->get_decisions_size(arguments));
    set_size<typename Parameters::dev_decisions_offsets_t>(
      arguments, first<typename Parameters::host_number_of_events_t>(arguments));
  }

  void operator()(
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    cudaStream_t&,
    cudaEvent_t&) const;

  /**
   * @brief Grid dimension of kernel call. get_grid_dim returns the size of the event list.
   */
  unsigned get_grid_dim_x(const ArgumentReferences<Parameters>& arguments) const
  {
    // Note: Becomes if constexpr with C++17
    if (std::is_same<typename Derived::iteration_t, LineIteration::default_iteration_tag>::value) {
      return size<typename Parameters::dev_event_list_t>(arguments);
    }
    // else if (std::is_same<typename Derived::iteration_t, LineIteration::event_iteration_tag>::value) {
    else {
      return 1;
    }
  }

  /**
   * @brief Default block dim x of kernel call. Can be "overriden".
   */
  unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { return 256; }
};

// This #if statement means: If compiling with the device compiler
#if defined(TARGET_DEVICE_CPU) || (defined(TARGET_DEVICE_HIP) && (defined(__HCC__) || defined(__HIP__))) || \
  ((defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__)) || (defined(TARGET_DEVICE_CUDACLANG) && defined(__CUDA__)))

/**
 * @brief Processes a line by iterating over all events and all "input sizes" (ie. tracks, vertices, etc.).
 *        The way process line parallelizes is highly configurable.
 */
template<typename Line, typename Parameters>
__global__ void process_line(Line line, Parameters parameters, const unsigned number_of_events)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned input_size = line.offset(parameters, event_number + 1) - line.offset(parameters, event_number);

  // Do selection
  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    parameters.dev_decisions[line.offset(parameters, event_number) + i] =
      line.select(parameters, line.get_input(parameters, event_number, i));
  }

  // Populate offsets in first block
  if (blockIdx.x == 0) {
    for (unsigned i = threadIdx.x; i <= number_of_events; i += blockDim.x) {
      parameters.dev_decisions_offsets[i] = line.offset(parameters, i);
    }
  }
}

/**
 * @brief Processes a line by iterating over events and applying the line.
 */
template<typename Line, typename Parameters>
__global__ void process_line_iterate_events(
  Line line,
  Parameters parameters,
  const unsigned number_of_events_in_event_list,
  const unsigned number_of_events)
{
  // Do selection
  for (unsigned i = threadIdx.x; i < number_of_events_in_event_list; i += blockDim.x) {
    const auto event_number = parameters.dev_event_list[i];
    parameters.dev_decisions[event_number] = line.select(parameters, line.get_input(parameters, event_number));
  }

  // Populate offsets
  for (unsigned event_number = threadIdx.x; event_number <= number_of_events; event_number += blockDim.x) {
    parameters.dev_decisions_offsets[event_number] = event_number;
  }
}

template<typename Derived, typename Parameters, typename GlobalFunctionDispatch>
struct LineIterationDispatch;

template<typename Derived, typename Parameters>
struct LineIterationDispatch<Derived, Parameters, LineIteration::default_iteration_tag> {
  static void dispatch(
    const ArgumentReferences<Parameters>& arguments,
    cudaStream_t& stream,
    const Derived* derived_instance,
    const unsigned grid_dim_x)
  {
    derived_instance->global_function(process_line<Derived, Parameters>)(
      grid_dim_x, derived_instance->get_block_dim_x(arguments), stream)(
      *derived_instance, arguments, first<typename Parameters::host_number_of_events_t>(arguments));
  }
};

template<typename Derived, typename Parameters>
struct LineIterationDispatch<Derived, Parameters, LineIteration::event_iteration_tag> {
  static void dispatch(
    const ArgumentReferences<Parameters>& arguments,
    cudaStream_t& stream,
    const Derived* derived_instance,
    const unsigned grid_dim_x)
  {
    derived_instance->global_function(process_line_iterate_events<Derived, Parameters>)(
      grid_dim_x, derived_instance->get_block_dim_x(arguments), stream)(
      *derived_instance,
      arguments,
      size<typename Parameters::dev_event_list_t>(arguments),
      first<typename Parameters::host_number_of_events_t>(arguments));
  }
};

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
  initialize<typename Parameters::dev_decisions_offsets_t>(arguments, 0, stream);

  const auto* derived_instance = static_cast<const Derived*>(this);

  // Dispatch the executing global function.
  // Note: Simplified code prepared for "if constexpr" with C++17
  // if constexpr (std::is_same<typename Derived::iteration_t, LineIteration::default_iteration_tag>::value) {
  //   derived_instance->global_function(process_line<Derived, Parameters>)(
  //     get_grid_dim_x(arguments), derived_instance->get_block_dim_x(arguments), stream)(
  //     *derived_instance, arguments);
  // } else if constexpr (std::is_same<typename Derived::iteration_t, LineIteration::event_iteration_tag>::value) {
  //   derived_instance->global_function(process_line_iterate_events<Derived, Parameters>)(
  //     get_grid_dim_x(arguments), derived_instance->get_block_dim_x(arguments), stream)(
  //     *derived_instance, arguments);
  // }

  

  LineIterationDispatch<Derived, Parameters, typename Derived::iteration_t>::dispatch(
    arguments, stream, derived_instance, get_grid_dim_x(arguments));
}

#endif