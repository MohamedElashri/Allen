#pragma once

#include "TrackMVALines.cuh"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"

#include "DeviceAlgorithm.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_secondary_vertices,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results,
  bool* dev_single_muon_results,
  bool* dev_disp_dimuon_results,
  bool* dev_high_mass_dimuon_results,
  bool* dev_dimuon_soft_results);

struct run_hlt1_t : public DeviceAlgorithm {
  constexpr static auto name {"run_hlt1_t"};
  decltype(global_function(run_hlt1)) function {run_hlt1};
  using Arguments = std::tuple<
    dev_kf_tracks,
    dev_secondary_vertices,
    dev_atomics_scifi,
    dev_sv_offsets,
    dev_one_track_results,
    dev_two_track_results,
    dev_single_muon_results,
    dev_disp_dimuon_results,
    dev_high_mass_dimuon_results,
    dev_dimuon_soft_results>;

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
