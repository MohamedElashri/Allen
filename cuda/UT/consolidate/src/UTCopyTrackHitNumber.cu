#include "UTCopyTrackHitNumber.cuh"

void ut_copy_track_hit_number_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_ut_track_hit_number>(host_buffers.ut_track_hit_number_size());
}

void ut_copy_track_hit_number_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_ut_tracks>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_ut_track_hit_number>());
}

/**
 * @brief Copies UT track hit numbers on a consecutive container
 */
__global__ void ut_copy_track_hit_number(
  const UT::TrackHits* dev_veloUT_tracks,
  uint* dev_atomics_veloUT,
  uint* dev_ut_track_hit_number)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;
  const auto* event_tracks = dev_veloUT_tracks + event_number * UT::Constants::max_num_tracks;
  const auto accumulated_tracks = dev_atomics_veloUT[number_of_events + event_number];
  const auto number_of_tracks = dev_atomics_veloUT[event_number];

  // Pointer to ut_track_hit_number of current event.
  uint* ut_track_hit_number = dev_ut_track_hit_number + accumulated_tracks;

  // Loop over tracks.
  for (uint element = threadIdx.x; element < number_of_tracks; ++element) {
    ut_track_hit_number[element] = event_tracks[element].hits_num;
  }
}
