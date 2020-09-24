/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_copy_track_hit_number {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_velo_tracks_at_least_four_hits_t, unsigned), host_number_of_velo_tracks_at_least_four_hits),
    (HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, unsigned), host_number_of_three_hit_tracks_filtered),
    (HOST_OUTPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (DEVICE_INPUT(dev_tracks_t, Velo::TrackHits), dev_tracks),
    (DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned), dev_offsets_velo_tracks),
    (DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned), dev_offsets_number_of_three_hit_tracks_filtered),
    (DEVICE_OUTPUT(dev_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_OUTPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_offsets_all_velo_tracks),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void velo_copy_track_hit_number(Parameters);

  struct velo_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{512, 1, 1}}};
  };
} // namespace velo_copy_track_hit_number