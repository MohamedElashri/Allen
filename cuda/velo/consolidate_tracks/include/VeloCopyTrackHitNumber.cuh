#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"

namespace velo_copy_track_hit_number {
  // Arguments
  HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint)
  DEVICE_INPUT(dev_tracks_t, Velo::TrackHits)
  DEVICE_INPUT(dev_atomics_velo_t, uint)
  DEVICE_OUTPUT(dev_velo_track_hit_number_t, uint)

  __global__ void velo_copy_track_hit_number(
    dev_tracks_t dev_tracks,
    dev_atomics_velo_t dev_atomics_storage,
    dev_velo_track_hit_number_t dev_velo_track_hit_number);

  template<typename Arguments>
  struct velo_copy_track_hit_number_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_copy_track_hit_number_t"};
    decltype(global_function(velo_copy_track_hit_number)) function {velo_copy_track_hit_number};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_velo_track_hit_number_t>(arguments, offset<host_number_of_reconstructed_velo_tracks_t>(arguments)[0] + 1);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<dev_tracks_t>(arguments),
        offset<dev_atomics_velo_t>(arguments),
        offset<dev_velo_track_hit_number_t>(arguments));

      arguments.template print<dev_velo_track_hit_number_t>();
    }
  };
} // namespace velo_copy_track_hit_number