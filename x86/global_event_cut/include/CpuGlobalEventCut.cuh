#pragma once

#include "Common.h"
#include "Handler.cuh"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "ArgumentsCommon.cuh"
#include "GlobalEventCutConfiguration.cuh"
// #include "CpuFunction.cuh"

void cpu_global_event_cut(
  char const* ut_raw_input,
  uint const* ut_raw_input_offsets,
  char const* scifi_raw_input,
  uint const* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events);

// struct cpu_global_event_cut_t {
//   constexpr static auto name {"cpu_global_event_cut_t"};

//   using Arguments = std::tuple<
//     dev_ut_raw_input,
//     dev_ut_raw_input_offsets,
//     dev_scifi_raw_input,
//     dev_scifi_raw_input_offsets,
//     dev_number_of_selected_events,
//     dev_event_list>;
//   using arguments_t = ArgumentRefManager<Arguments>;

//   decltype(make_cpu_handler(cpu_global_event_cut)) handler {cpu_global_event_cut};

//   template<typename... T>
//   auto invoke(T&&... arguments)
//   {
//     return handler.function(std::forward<T>(arguments));
//   }
// };
