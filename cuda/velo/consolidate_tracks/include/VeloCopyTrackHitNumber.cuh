#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"

namespace velo_copy_track_hit_number {
  // Arguments
  struct dev_tracks_t : input_datatype<Velo::TrackHits> {};
  struct dev_atomics_velo_t : input_datatype<uint> {};
  struct dev_velo_track_hit_number_t : output_datatype<uint> {};

  __global__ void velo_copy_track_hit_number(
    dev_tracks_t dev_tracks,
    dev_atomics_velo_t dev_atomics_storage,
    dev_velo_track_hit_number_t dev_velo_track_hit_number);

  template<typename Arguments>
  struct velo_copy_track_hit_number_t : public GpuAlgorithm {
    constexpr static auto name {"velo_copy_track_hit_number_t"};
    decltype(gpu_function(velo_copy_track_hit_number)) function {velo_copy_track_hit_number};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_velo_track_hit_number_t>(arguments, host_buffers.velo_track_hit_number_size());
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<dev_tracks_t>(arguments),
        offset<dev_atomics_velo_t>(arguments),
        offset<dev_velo_track_hit_number_t>(arguments));
    }
  };
} // namespace velo_copy_track_hit_number