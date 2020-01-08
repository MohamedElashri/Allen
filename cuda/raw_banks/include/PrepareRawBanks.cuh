#pragma once

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"

#include "DeviceAlgorithm.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsRawBanks.cuh"

__global__ void prepare_raw_banks(
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  const bool* dev_one_track_results,
  const bool* dev_two_track_results,
  const bool* dev_single_muon_results,
  const bool* dev_disp_dimuon_results,
  const bool* dev_high_mass_dimuon_results,
  uint32_t* dev_dec_reports,
  uint* number_of_passing_events,
  uint* event_list);

struct prepare_raw_banks_t : public DeviceAlgorithm {
  constexpr static auto name {"prepare_raw_banks_t"};
  decltype(global_function(prepare_raw_banks)) function {prepare_raw_banks};
  using Arguments = std::tuple<
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results,
    dev_dec_reports,
    dev_number_of_passing_events,
    dev_passing_event_list>;

  void set_arguments_size(
    ArgumentRefManager<T> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<T>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
