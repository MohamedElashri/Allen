/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <string>
#include <ArgumentOps.cuh>
#include <DeterministicScaler.cuh>
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <tuple>

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(DERIVED, PARAMETERS)                                                                  \
  template void Line<DERIVED, PARAMETERS>::operator()(                                                         \
    const ArgumentReferences<PARAMETERS>&,                                                                     \
    const RuntimeOptions&,                                                                                     \
    const Constants&,                                                                                          \
    HostBuffers&,                                                                                              \
    const Allen::Context&) const;                                                                              \
  template __device__ void process_line<DERIVED, PARAMETERS>(                                                  \
    char*,                                                                                                     \
    bool*,                                                                                                     \
    unsigned*,                                                                                                 \
    Allen::IMultiEventContainer**,                                                                             \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned);                                                                                                 \
  template void line_output_monitor<DERIVED, PARAMETERS>(char*, const RuntimeOptions&, const Allen::Context&); \
  INSTANTIATE_ALGORITHM(DERIVED)

// Type-erased line function type
using line_fn_t = void (*)(
  char*,
  bool*,
  unsigned*,
  Allen::IMultiEventContainer**,
  unsigned,
  unsigned,
  unsigned,
  unsigned,
  unsigned,
  unsigned);

template<typename Derived, typename Parameters>
using type_erased_tuple_t =
  std::tuple<Parameters, size_t, unsigned, unsigned, ArgumentReferences<Parameters>, const Derived*>;

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
    set_size<typename Parameters::host_decisions_size_t>(arguments, 1);
    set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
    set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);

    // Set the size of the type-erased fn parameters
    set_size<typename Parameters::host_fn_parameters_t>(arguments, sizeof(type_erased_tuple_t<Derived, Parameters>));
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
  void init_monitor(const ArgumentReferences<Parameters>&, const Allen::Context&) const {}

  template<typename T>
  static __device__ void monitor(const Parameters&, T, unsigned, bool)
  {}

  void output_monitor(const ArgumentReferences<Parameters>&, const RuntimeOptions&, const Allen::Context&) const {}
};

template<typename Derived, typename Parameters>
void line_output_monitor(char* input, const RuntimeOptions& runtime_options, const Allen::Context& context)
{
  if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
    if (input != nullptr) {
      const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
      const auto& parameters = std::get<0>(type_casted_input);
      auto derived_instance = std::get<5>(type_casted_input);
      if (parameters.enable_monitoring) {
        derived_instance->output_monitor(std::get<4>(type_casted_input), runtime_options, context);
      }
    }
  }
}

template<typename Derived, typename Parameters>
__device__ void process_line(
  char* input,
  bool* decisions,
  unsigned* decisions_offsets,
  Allen::IMultiEventContainer** particle_container_ptr,
  unsigned run_no,
  unsigned evt_hi,
  unsigned evt_lo,
  unsigned gps_hi,
  unsigned gps_lo,
  unsigned line_offset)
{
  const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
  const auto& parameters = std::get<0>(type_casted_input);
  const auto event_list_size = std::get<1>(type_casted_input);
  const auto number_of_events = std::get<2>(type_casted_input);
  const auto event_number = blockIdx.x;

  // Check if blockIdx.x (event_number) is in dev_event_list
  unsigned mask = 0;
  for (unsigned i = 0; i < (event_list_size + warp_size - 1) / warp_size; ++i) {
    const auto index = i * warp_size + threadIdx.x;
    mask |=
      __ballot_sync(0xFFFFFFFF, index < event_list_size ? event_number == parameters.dev_event_list[index] : false);
  }

  // Do initialization for all events, regardless of mask
  // * Populate offsets in first block
  if (blockIdx.x == 0) {
    for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
      decisions_offsets[i] = line_offset + Derived::offset(parameters, i);
    }
  }

  // * Populate IMultiEventContainer* if relevant
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
      const auto ptr = static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
      *particle_container_ptr = const_cast<Allen::IMultiEventContainer*>(ptr);
    }
    else {
      *particle_container_ptr = nullptr;
    }
  }

  // * Populate decisions
  const auto pre_scaler_hash = std::get<3>(type_casted_input);
  const bool pre_scaler_result =
    deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  const unsigned input_size = Derived::input_size(parameters, event_number);

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const auto input = Derived::get_input(parameters, event_number, i);
    const bool decision = mask > 0 && pre_scaler_result && Derived::select(parameters, input);
    unsigned index = Derived::offset(parameters, event_number) + i;
    decisions[index] = decision;
    if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
      if (parameters.enable_monitoring) {
        Derived::monitor(parameters, input, index, decision);
      }
    }
  }
}

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  [[maybe_unused]] const Allen::Context& context) const
{
  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy post scaler and hash to an output, such that GatherSelections can later
  // perform the postscaling
  data<typename Parameters::host_post_scaler_t>(arguments)[0] =
    derived_instance->template property<typename Parameters::post_scaler_t>();
  data<typename Parameters::host_post_scaler_hash_t>(arguments)[0] = m_post_scaler_hash;
  data<typename Parameters::host_decisions_size_t>(arguments)[0] = Derived::get_decisions_size(arguments);

  // Delay the execution of the line: Pass the parameters
  auto parameters = std::make_tuple(
    derived_instance->make_parameters(1, 1, 0, arguments),
    size<typename Parameters::dev_event_list_t>(arguments),
    first<typename Parameters::host_number_of_events_t>(arguments),
    m_pre_scaler_hash,
    arguments,
    derived_instance);

  assert(sizeof(type_erased_tuple_t<Derived, Parameters>) == sizeof(parameters));
  std::memcpy(data<typename Parameters::host_fn_parameters_t>(arguments), &parameters, sizeof(parameters));

  if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
    if (derived_instance->template property<typename Parameters::enable_monitoring_t>()) {
      derived_instance->init_monitor(arguments, context);
    }
  }
}
