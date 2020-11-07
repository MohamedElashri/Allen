/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <string>
#include <ArgumentOps.cuh>
#include <DeterministicScaler.cuh>
#include "Event/ODIN.h"
#include "ODINBank.cuh"

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(LINE, PARAMETERS)          \
  template void Line<LINE, PARAMETERS>::operator()( \
    const ArgumentReferences<PARAMETERS>&,          \
    const RuntimeOptions&,                          \
    const Constants&,                               \
    HostBuffers&,                                   \
    const Allen::Context&) const;

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
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
 *  DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
 *  DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
 *  DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
 *  DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
 *  DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
 *  HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
 *  HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
 *  PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
 *  PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
 *  PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
 *  PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
 *
 * The inheriting line must also provide the following methods:
 *
 *     __device__ unsigned offset(const Parameters& parameters, const unsigned event_number) const;
 *
 *     unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const;
 *
 *     __device__ std::tuple<types...>
 *     get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const;
 *
 *     __device__ bool select(const Parameters& parameters, std::tuple<types...> input) const;
 *
 *     where "types..." is a list of types that can be freely configured.
 *
 *
 * The following methods can optionally be defined in an inheriting class:
 *
 *     unsigned get_grid_dim_x(const ArgumentReferences<Parameters>&) const;
 *
 *     unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const;
 */
template<typename Derived, typename Parameters>
struct Line {
private:
  uint32_t m_pre_scaler_hash;
  uint32_t m_post_scaler_hash;

public:
  using iteration_t = LineIteration::default_iteration_tag;

  void init()
  {
    auto derived_instance = static_cast<const Derived*>(this);
    const std::string pre_scaler_hash_string =
      derived_instance->template property<typename Parameters::pre_scaler_hash_string_t>();
    const std::string post_scaler_hash_string =
      derived_instance->template property<typename Parameters::post_scaler_hash_string_t>();

    if (pre_scaler_hash_string.empty() || post_scaler_hash_string.empty()) {
      throw HashNotPopulatedException(derived_instance->name());
    }

    m_pre_scaler_hash = mixString(pre_scaler_hash_string.size(), pre_scaler_hash_string);
    m_post_scaler_hash = mixString(post_scaler_hash_string.size(), post_scaler_hash_string);
  }

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
    set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
    set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);
  }

  void operator()(
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    const Allen::Context& context) const;

  /**
   * @brief Grid dimension of kernel call. get_grid_dim returns the size of the event list.
   */
  unsigned get_grid_dim_x(const ArgumentReferences<Parameters>& arguments) const
  {
    if constexpr (std::is_same<typename Derived::iteration_t, LineIteration::default_iteration_tag>::value) {
      return size<typename Parameters::dev_event_list_t>(arguments);
    }
    // else if (std::is_same<typename Derived::iteration_t, LineIteration::event_iteration_tag>::value) {
    return 1;
  }

  /**
   * @brief Default block dim x of kernel call. Can be "overriden".
   */
  unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { return 256; }
};

#if defined(DEVICE_COMPILER)

/**
 * @brief Processes a line by iterating over all events and all "input sizes" (ie. tracks, vertices, etc.).
 *        The way process line parallelizes is highly configurable.
 */
template<typename Line, typename Parameters>
__global__ void
process_line(Line line, Parameters parameters, const unsigned number_of_events, const unsigned pre_scaler_hash)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned input_size = line.offset(parameters, event_number + 1) - line.offset(parameters, event_number);

  // ODIN data
  const unsigned int* odin =
    *parameters.dev_mep_layout ?
      odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number) :
      odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);

  const uint32_t run_no = odin[LHCb::ODIN::Data::RunNumber];
  const uint32_t evt_hi = odin[LHCb::ODIN::Data::L0EventIDHi];
  const uint32_t evt_lo = odin[LHCb::ODIN::Data::L0EventIDLo];
  const uint32_t gps_hi = odin[LHCb::ODIN::Data::GPSTimeHi];
  const uint32_t gps_lo = odin[LHCb::ODIN::Data::GPSTimeLo];

  // Pre-scaler
  if (deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
    // Do selection
    for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
      parameters.dev_decisions[line.offset(parameters, event_number) + i] =
        line.select(parameters, line.get_input(parameters, event_number, i));
    }
  }

  // Populate offsets in first block
  if (blockIdx.x == 0) {
    for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
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
  const unsigned number_of_events,
  const unsigned pre_scaler_hash)
{
  // Do selection
  for (unsigned i = threadIdx.x; i < number_of_events_in_event_list; i += blockDim.x) {
    const auto event_number = parameters.dev_event_list[i];

    // ODIN data
    const unsigned int* odin =
      *parameters.dev_mep_layout ?
        odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number) :
        odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);

    const uint32_t run_no = odin[LHCb::ODIN::Data::RunNumber];
    const uint32_t evt_hi = odin[LHCb::ODIN::Data::L0EventIDHi];
    const uint32_t evt_lo = odin[LHCb::ODIN::Data::L0EventIDLo];
    const uint32_t gps_hi = odin[LHCb::ODIN::Data::GPSTimeHi];
    const uint32_t gps_lo = odin[LHCb::ODIN::Data::GPSTimeLo];

    if (deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
      parameters.dev_decisions[event_number] = line.select(parameters, line.get_input(parameters, event_number));
    }
  }

  // Populate offsets
  for (unsigned event_number = threadIdx.x; event_number < number_of_events; event_number += blockDim.x) {
    parameters.dev_decisions_offsets[event_number] = event_number;
  }
}

template<typename Derived, typename Parameters, typename GlobalFunctionDispatch>
struct LineIterationDispatch;

template<typename Derived, typename Parameters>
struct LineIterationDispatch<Derived, Parameters, LineIteration::default_iteration_tag> {
  static void dispatch(
    const ArgumentReferences<Parameters>& arguments,
    const Allen::Context& context,
    const Derived* derived_instance,
    const unsigned grid_dim_x,
    const unsigned pre_scaler_hash)
  {
    derived_instance->global_function(process_line<Derived, Parameters>)(
      grid_dim_x, derived_instance->get_block_dim_x(arguments), context)(
      *derived_instance, arguments, first<typename Parameters::host_number_of_events_t>(arguments), pre_scaler_hash);
  }
};

template<typename Derived, typename Parameters>
struct LineIterationDispatch<Derived, Parameters, LineIteration::event_iteration_tag> {
  static void dispatch(
    const ArgumentReferences<Parameters>& arguments,
    const Allen::Context& context,
    const Derived* derived_instance,
    const unsigned grid_dim_x,
    const unsigned pre_scaler_hash)
  {
    derived_instance->global_function(process_line_iterate_events<Derived, Parameters>)(
      grid_dim_x, derived_instance->get_block_dim_x(arguments), context)(
      *derived_instance,
      arguments,
      size<typename Parameters::dev_event_list_t>(arguments),
      first<typename Parameters::host_number_of_events_t>(arguments),
      pre_scaler_hash);
  }
};

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<typename Parameters::dev_decisions_t>(arguments, 0, context);
  initialize<typename Parameters::dev_decisions_offsets_t>(arguments, 0, context);

  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy post scaler and hash to an output, such that GatherSelections can later
  // perform the postscaling
  data<typename Parameters::host_post_scaler_t>(arguments)[0] =
    derived_instance->template property<typename Parameters::post_scaler_t>();
  data<typename Parameters::host_post_scaler_hash_t>(arguments)[0] = m_post_scaler_hash;

  // Dispatch the executing global function.
  LineIterationDispatch<Derived, Parameters, typename Derived::iteration_t>::dispatch(
    arguments, context, derived_instance, get_grid_dim_x(arguments), m_pre_scaler_hash);
}

#endif