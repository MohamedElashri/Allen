/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <string>
#include <ArgumentOps.cuh>
#include <DeterministicScaler.cuh>
#include "Event/ODIN.h"
#include "ODINBank.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <tuple>

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(LINE, PARAMETERS)                                                                                    \
  template void Line<LINE, PARAMETERS>::operator()(                                                                           \
    const ArgumentReferences<PARAMETERS>&,                                                                                    \
    const RuntimeOptions&,                                                                                                    \
    const Constants&,                                                                                                         \
    HostBuffers&,                                                                                                             \
    const Allen::Context&) const;                                                                                             \
  template __device__ void process_line<LINE, PARAMETERS>(char*, bool*, unsigned*, Allen::IMultiEventContainer**, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned); \
  INSTANTIATE_ALGORITHM(LINE)

// Type-erased line function type
using line_fn_t = void (*)(char*, bool*, unsigned*, Allen::IMultiEventContainer**, unsigned, unsigned, unsigned, unsigned, unsigned, unsigned);

/**
 * @brief A generic Line.
 * @detail It assumes the line has the following parameters:
 *
 *  HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
 *  MASK_INPUT(dev_event_list_t) dev_event_list;
 *  MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
 *  HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
 *  DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
 *  DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
 *  DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
 *  DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
 *  DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
 *  DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
 *  HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
 *  HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
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
 */
template<typename Derived, typename Parameters>
struct Line {
private:
  uint32_t m_pre_scaler_hash;
  uint32_t m_post_scaler_hash;

public:
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
    set_size<typename Parameters::dev_decisions_t>(arguments, Derived::get_decisions_size(arguments));
    set_size<typename Parameters::dev_decisions_offsets_t>(
      arguments, first<typename Parameters::host_number_of_events_t>(arguments));
    set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
    set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);
    set_size<typename Parameters::dev_particle_container_ptr_t>(arguments, 1);

    // Set the size of the type-erased fn parameters
    set_size<typename Parameters::host_fn_parameters_t>(
      arguments, sizeof(std::tuple<Parameters, size_t, unsigned, unsigned>));
  }

  void operator()(
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    const Allen::Context& context) const;

  /**
   * @brief Default monitor function.
   */
  static void init_monitor(const ArgumentReferences<Parameters>&, const Allen::Context&) {}
  template<typename INPUT>
  static __device__ void monitor(const Parameters&, INPUT, unsigned, bool)
  {}
  static __host__ void
  output_monitor(const ArgumentReferences<Parameters>&, const RuntimeOptions&, const Allen::Context&)
  {}
};

template<typename Derived, typename Parameters>
__device__ void
process_line(char* input, bool* decisions, unsigned* decisions_offsets, Allen::IMultiEventContainer** particle_container_ptr, unsigned run_no, unsigned evt_hi, unsigned evt_lo, unsigned gps_hi, unsigned gps_lo, unsigned line_offset)
{
  const auto& type_casted_input = *reinterpret_cast<const std::tuple<Parameters, size_t, unsigned, unsigned>*>(input);
  const auto& parameters = std::get<0>(type_casted_input);
  const auto event_list_size = std::get<1>(type_casted_input);
  const auto number_of_events = std::get<2>(type_casted_input);

  // Check if blockIdx.x (event_number) is in dev_event_list
  unsigned mask = 0;
  for (unsigned i = 0; i < (event_list_size + warp_size - 1) / warp_size; ++i) {
    const auto index = i * warp_size + threadIdx.x;
    mask |= __ballot_sync(0xFFFFFFFF, index < event_list_size ? threadIdx.x == parameters.dev_event_list[i] : false);
  }

  // Do initialization for all events, regardless of mask
  // * Populate offsets in first block
  if (blockIdx.x == 0) {
    for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
      decisions_offsets[i] = (mask ? Derived::offset(parameters, i) : 0) + line_offset;
    }
  }

  // * Populate IMultiEventContainer* if relevant
  if (blockIdx.x == 0 && threadIdx.x == 0 && threadIdx.y == 0) {
    if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
      const auto ptr = static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
      *particle_container_ptr = const_cast<Allen::IMultiEventContainer*>(ptr);
    } else {
      *particle_container_ptr = nullptr;
    }
  }

  // * Populate decisions
  const auto pre_scaler_hash = std::get<3>(type_casted_input);
  const bool pre_scaler_result = deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  const unsigned input_size = Derived::input_size(parameters, blockIdx.x);

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const bool sel = mask && pre_scaler_result && Derived::select(parameters, Derived::get_input(parameters, blockIdx.x, i));
    unsigned index = Derived::offset(parameters, blockIdx.x) + i;
    decisions[index] = sel;
  }

  // * Populate IMultiEventContainer* if relevant
  if (blockIdx.x == 0 && threadIdx.x == 0 && threadIdx.y == 0) {
    if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
      const auto particle_container_ptr =
        static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
      parameters.dev_particle_container_ptr[0] = const_cast<Allen::IMultiEventContainer*>(particle_container_ptr);
    } else {
      parameters.dev_particle_container_ptr[0] = nullptr;
    }
  }

  // * Populate decisions
  const auto pre_scaler_hash = std::get<3>(type_casted_input);
  const bool pre_scaler_result = deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  const unsigned input_size = Derived::input_size(parameters, blockIdx.x);

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const bool sel = mask > 0 && pre_scaler_result && Derived::select(parameters, Derived::get_input(parameters, blockIdx.x, i));
    unsigned index = Derived::offset(parameters, blockIdx.x) + i;
    parameters.dev_decisions[index] = sel;
  }
}

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy post scaler and hash to an output, such that GatherSelections can later
  // perform the postscaling
  data<typename Parameters::host_post_scaler_t>(arguments)[0] =
    derived_instance->template property<typename Parameters::post_scaler_t>();
  data<typename Parameters::host_post_scaler_hash_t>(arguments)[0] = m_post_scaler_hash;

  // Delay the execution of the line: Pass the parameters
  auto parameters = std::make_tuple(
    derived_instance->make_parameters(1, 1, 0, arguments),
    size<typename Parameters::dev_event_list_t>(arguments),
    first<typename Parameters::host_number_of_events_t>(arguments),
    m_pre_scaler_hash);

  auto fn_parameters_pointer =
    reinterpret_cast<decltype(parameters)*>(data<typename Parameters::host_fn_parameters_t>(arguments));
  fn_parameters_pointer[0] = parameters;
}
