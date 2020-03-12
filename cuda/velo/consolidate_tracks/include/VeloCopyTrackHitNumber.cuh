#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_copy_track_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_velo_tracks_at_least_four_hits_t, uint);
    HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, uint);
    HOST_OUTPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, uint) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, uint) dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_OUTPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_OUTPUT(dev_offsets_all_velo_tracks_t, uint) dev_offsets_all_velo_tracks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {512, 1, 1});
  };

  __global__ void velo_copy_track_hit_number(Parameters);

  template<typename T, char... S>
  struct velo_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(velo_copy_track_hit_number)) function {velo_copy_track_hit_number};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const {
      set_size<host_number_of_reconstructed_velo_tracks_t>(arguments, 1);
      set_size<dev_velo_track_hit_number_t>(arguments, value<host_number_of_velo_tracks_at_least_four_hits_t>(arguments)
        + value<host_number_of_three_hit_tracks_filtered_t>(arguments));

      // Note: Size is "+ 1" due to it storing offsets.
      set_size<dev_offsets_all_velo_tracks_t>(arguments, value<host_number_of_selected_events_t>(arguments) + 1);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const {
      cudaCheck(cudaMemsetAsync(
        begin<dev_offsets_all_velo_tracks_t>(arguments),
        0,
        sizeof(uint), // Note: Only the first element needs to be initialized here.
        cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters{
          begin<dev_tracks_t>(arguments),
          begin<dev_offsets_velo_tracks_t>(arguments),
          begin<dev_offsets_number_of_three_hit_tracks_filtered_t>(arguments),
          begin<dev_velo_track_hit_number_t>(arguments),
          begin<dev_offsets_all_velo_tracks_t>(arguments)
        });

      cudaCheck(cudaMemcpyAsync(
        begin<host_number_of_reconstructed_velo_tracks_t>(arguments),
        begin<dev_offsets_all_velo_tracks_t>(arguments) + (size<dev_offsets_all_velo_tracks_t>(arguments) / sizeof(uint)) - 1,
        sizeof(uint), // Note: Only the last element needs to be copied here.
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace velo_copy_track_hit_number