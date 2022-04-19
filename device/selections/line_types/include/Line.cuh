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
#define INSTANTIATE_LINE(LINE, PARAMETERS)                                                                          \
  template void Line<LINE, PARAMETERS>::operator()(                                                                 \
    const ArgumentReferences<PARAMETERS>&,                                                                          \
    const RuntimeOptions&,                                                                                          \
    const Constants&,                                                                                               \
    HostBuffers&,                                                                                                   \
    const Allen::Context&) const;                                                                                   \
  template __device__ void process_line<LINE, PARAMETERS>(char*, unsigned, unsigned, unsigned, unsigned, unsigned); \
  INSTANTIATE_ALGORITHM(LINE)

// "Enum of types" to determine dispatch to global_function
namespace LineIteration {
  struct default_iteration_tag {
  };
  struct event_iteration_tag {
  };
} // namespace LineIteration

// Type-erased line function type
using line_fn_t = void (*)(char*, unsigned, unsigned, unsigned, unsigned, unsigned);

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
    DEVICE_OUTPUT(dev_fn_parameters_t, char) dev_fn_parameters;
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
    set_size<typename Parameters::dev_decisions_t>(arguments, Derived::get_decisions_size(arguments));
    set_size<typename Parameters::dev_decisions_offsets_t>(
      arguments, first<typename Parameters::host_number_of_events_t>(arguments));
    set_size<typename Parameters::dev_selected_events_t>(
      arguments, first<typename Parameters::host_number_of_events_t>(arguments));
    set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
    set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);
    set_size<typename Parameters::host_selected_events_size_t>(arguments, 1);
    set_size<typename Parameters::dev_selected_events_size_t>(arguments, 1);
    set_size<typename Parameters::dev_particle_container_ptr_t>(arguments, 1);

    // Set the size of the type-erased fn parameters
    set_size<typename Parameters::host_fn_parameters_t>(
      arguments, sizeof(std::tuple<Parameters, size_t, unsigned, unsigned>));
    set_size<typename Parameters::dev_fn_parameters_t>(
      arguments, size<typename Parameters::host_fn_parameters_t>(arguments));
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
process_line(char* input, unsigned run_no, unsigned evt_hi, unsigned evt_lo, unsigned gps_hi, unsigned gps_lo)
{
  if constexpr (!std::is_same_v<typename Derived::iteration_t, LineIteration::event_iteration_tag>) {
    const auto& type_casted_input = *reinterpret_cast<const std::tuple<Parameters, size_t, unsigned, unsigned>*>(input);
    const auto& parameters = std::get<0>(type_casted_input);
    const auto number_of_events = std::get<2>(type_casted_input);

    // Check if blockIdx.x (event_number) is in dev_event_list
    unsigned mask = 0;
    for (unsigned i = 0; i < (number_of_events + 31) / 32; ++i) {
      const auto index = i * 32 + threadIdx.x;
      mask |= __ballot_sync(0xFFFFFFFF, index < number_of_events ? threadIdx.x == parameters.dev_event_list[i] : false);
    }

    if (mask) {
      const auto pre_scaler_hash = std::get<3>(type_casted_input);

      // Populate IMultiEventContainer* if relevant
      if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
        if (blockIdx.x == 0 && threadIdx.x == 0) {
          const auto particle_container_ptr =
            static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
          parameters.dev_particle_container_ptr[0] = const_cast<Allen::IMultiEventContainer*>(particle_container_ptr);
        }
      }

      // Pre-scaler
      if (deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
        // Do selection
        const unsigned input_size = Derived::input_size(parameters, blockIdx.x);
        for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
          auto input = Derived::get_input(parameters, blockIdx.x, i);
          bool sel = Derived::select(parameters, input);
          unsigned index = Derived::offset(parameters, blockIdx.x) + i;
          parameters.dev_decisions[index] = sel;
        }
      }

      // Populate offsets in first block
      if (blockIdx.x == 0) {
        for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
          parameters.dev_decisions_offsets[i] = Derived::offset(parameters, i);
        }
      }
    }
  }

  // if constexpr (std::is_same_v<typename Derived::iteration_t, LineIteration::event_iteration_tag>) {
  //   if (blockIdx.x == 0) {
  //     // Iterates over events and processes the line
  //     const auto& type_casted_input =
  //       *reinterpret_cast<const std::tuple<Parameters, size_t, unsigned, unsigned>*>(input);
  //     const auto& [parameters, number_of_events_in_event_list, number_of_events, pre_scaler_hash] =
  //     type_casted_input;

  //     // Populate IMultiEventContainer* if relevant
  //     if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
  //       if (blockIdx.x == 0 && threadIdx.x == 0) {
  //         const auto particle_container_ptr =
  //           static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
  //         parameters.dev_particle_container_ptr[0] =
  //         const_cast<Allen::IMultiEventContainer*>(particle_container_ptr);
  //       }
  //     }

  //     // Do selection
  //     for (unsigned i = threadIdx.x; i < number_of_events_in_event_list; i += blockDim.x) {
  //       const auto event_number = parameters.dev_event_list[i];

  //       // ODIN data
  //       const LHCb::ODIN odin {
  //         {*parameters.dev_mep_layout ?
  //            odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets,
  //            event_number) : odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets,
  //            event_number),
  //          10}};

  //       const uint32_t run_no = odin.runNumber();
  //       const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
  //       const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
  //       const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
  //       const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

  //       bool decision = false;
  //       if (deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
  //         auto input = Derived::get_input(parameters, event_number);
  //         decision = Derived::select(parameters, input);
  //         parameters.dev_decisions[event_number] = decision;
  //         Derived::monitor(parameters, input, event_number, decision);
  //       }
  //     }

  //     // Populate offsets
  //     for (unsigned event_number = threadIdx.x; event_number < number_of_events; event_number += blockDim.x) {
  //       parameters.dev_decisions_offsets[event_number] = event_number;
  //     }
  //   }
  // }
  // else {

  // Processes a line by iterating over all events and all "input sizes" (ie. tracks, vertices, etc.).

  // }
}

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
  initialize<typename Parameters::dev_selected_events_size_t>(arguments, 0, context);
  initialize<typename Parameters::dev_particle_container_ptr_t>(arguments, 0, context);

  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy post scaler and hash to an output, such that GatherSelections can later
  // perform the postscaling
  data<typename Parameters::host_post_scaler_t>(arguments)[0] =
    derived_instance->template property<typename Parameters::post_scaler_t>();
  data<typename Parameters::host_post_scaler_hash_t>(arguments)[0] = m_post_scaler_hash;

  // Delay the execution of the line:
  // * Pass the parameters
  auto parameters = std::make_tuple(
    derived_instance->make_parameters(1, 1, 0, arguments),
    size<typename Parameters::dev_event_list_t>(arguments),
    first<typename Parameters::host_number_of_events_t>(arguments),
    m_pre_scaler_hash);

  auto fn_parameters_pointer =
    reinterpret_cast<decltype(parameters)*>(data<typename Parameters::host_fn_parameters_t>(arguments));
  fn_parameters_pointer[0] = parameters;

  // * Prepare the function and parameters on the device
  Allen::copy_async<typename Parameters::dev_fn_parameters_t, typename Parameters::host_fn_parameters_t>(
    arguments, context);
}
