/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateUT.cuh"

void ut_consolidate_tracks::ut_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_track_hits_t>(
    arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::Consolidated::Hits::element_size);
  set_size<dev_ut_qop_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_track_velo_indices_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_x_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_z_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_tx_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
}

void ut_consolidate_tracks::ut_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(ut_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_unique_x_sector_layer_offsets.data());

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_offsets_ut_tracks_t>(host_buffers.host_atomics_ut, arguments, stream);
    assign_to_host_buffer<dev_offsets_ut_track_hit_number_t>(host_buffers.host_ut_track_hit_number, arguments, stream);
    assign_to_host_buffer<dev_ut_track_hits_t>(host_buffers.host_ut_track_hits, arguments, stream);
    assign_to_host_buffer<dev_ut_qop_t>(host_buffers.host_ut_qop, arguments, stream);
    assign_to_host_buffer<dev_ut_x_t>(host_buffers.host_ut_x, arguments, stream);
    assign_to_host_buffer<dev_ut_tx_t>(host_buffers.host_ut_tx, arguments, stream);
    assign_to_host_buffer<dev_ut_z_t>(host_buffers.host_ut_z, arguments, stream);
    assign_to_host_buffer<dev_ut_track_velo_indices_t>(host_buffers.host_ut_track_velo_indices, arguments, stream);
  }
}

template<typename F>
__device__ void populate(const UT::TrackHits& track, const F& assign)
{
  int hit_number = 0;
  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = track.hits[i];
    if (hit_index != -1) {
      assign(hit_number++, hit_index);
    }
  }
}

template<typename F>
__device__ void populate_plane_code(const UT::TrackHits& track, const F& assign)
{
  int hit_number = 0;
  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = track.hits[i];
    if (hit_index != -1) {
      assign(hit_number++, i);
    }
  }
}

__global__ void ut_consolidate_tracks::ut_consolidate_tracks(
  ut_consolidate_tracks::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::TrackHits* event_veloUT_tracks = parameters.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_offset = ut_hit_offsets.event_offset();

  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};

  // Create consolidated SoAs.
  UT::Consolidated::ExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                              parameters.dev_ut_track_hit_number,
                                              parameters.dev_ut_qop,
                                              parameters.dev_ut_track_velo_indices,
                                              event_number,
                                              number_of_events};

  const unsigned number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = ut_tracks.tracks_offset(event_number);

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const UT::TrackHits& track = event_veloUT_tracks[i];

    ut_tracks.velo_track(i) = track.velo_track_index;
    ut_tracks.qop(i) = track.qop;

    const int track_index = event_tracks_offset + i;
    parameters.dev_ut_x[track_index] = track.x;
    parameters.dev_ut_z[track_index] = track.z;
    parameters.dev_ut_tx[track_index] = track.tx;

    UT::Consolidated::Hits consolidated_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i);

    // Populate the consolidated hits.
    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.yBegin(hit_number) = ut_hits.yBegin(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.yEnd(hit_number) = ut_hits.yEnd(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.zAtYEq0(hit_number) = ut_hits.zAtYEq0(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.xAtYEq0(hit_number) = ut_hits.xAtYEq0(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.id(hit_number) = ut_hits.id(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.weight(hit_number) = ut_hits.weight(j + event_offset);
    });

    populate_plane_code(track, [&consolidated_hits](const unsigned hit_number, const unsigned j) {
      consolidated_hits.plane_code(hit_number) = static_cast<uint8_t>(j);
    });
  }
}
