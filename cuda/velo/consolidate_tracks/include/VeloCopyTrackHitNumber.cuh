#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"

__global__ void velo_copy_track_hit_number(
  const Velo::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number);

struct velo_copy_track_hit_number_t : public GpuAlgorithm {
  constexpr static auto name {"velo_copy_track_hit_number_t"};
  decltype(gpu_function(velo_copy_track_hit_number)) function {velo_copy_track_hit_number};
  using Arguments = std::tuple<dev_tracks, dev_atomics_velo, dev_velo_track_hit_number>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
