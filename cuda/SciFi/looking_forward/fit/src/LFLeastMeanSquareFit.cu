#include "LFLeastMeanSquareFit.cuh"

void lf_least_mean_square_fit_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_scifi_hits>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_atomics_ut>(),
    arguments.offset<dev_scifi_lf_x_filtered_tracks>(),
    arguments.offset<dev_scifi_lf_x_filtered_atomics>(),
    constants.dev_scifi_geometry,
    constants.dev_looking_forward_constants,
    constants.dev_inv_clus_res,
    arguments.offset<dev_scifi_lf_parametrization_x_filter>());
}

__global__ void lf_least_mean_square_fit(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_tracks,
  const uint* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  float* dev_scifi_lf_parametrization_x_filter)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {
    const_cast<uint32_t*>(dev_scifi_hits), total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();
  const auto number_of_tracks = dev_atomics_scifi[event_number];

  float s00 = 0.f;
  float s01 = 0.f;
  float s02 = 0.f;
  float s11 = 0.f;
  float s12 = 0.f;
  float s22 = 0.f;
  float b0 = 0.f;
  float b1 = 0.f;
  float b2 = 0.f;

  for (uint i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index =
      ut_event_tracks_offset * LookingForward::maximum_number_of_candidates_per_ut_track + i;
    SciFi::TrackHits& track = dev_scifi_tracks[scifi_track_index];

    // Load parametrization
    const auto prev_curvature = dev_scifi_lf_parametrization_x_filter[scifi_track_index];
    const auto prev_tx = dev_scifi_lf_parametrization_x_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
       scifi_track_index];
    const auto prev_offset = dev_scifi_lf_parametrization_x_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
       scifi_track_index];
    const auto d_ratio = dev_scifi_lf_parametrization_x_filter
      [3 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
       scifi_track_index];

    for (uint i_hit = 0; i_hit < track.hitsNum; ++i_hit) {
      const auto hit_index = event_offset + track.hits[i_hit];
      const auto layer_index = scifi_hits.planeCode(hit_index) / 2;
      const auto x = scifi_hits.x0[hit_index];
      const auto z = dev_looking_forward_constants->Zone_zPos[layer_index];

      const auto dz = z - LookingForward::z_mid_t;
      const auto predicted_x = prev_offset + prev_tx * dz + prev_curvature * dz * dz * (1.f + d_ratio * dz);

      const auto dz2 = dz * dz;
      const auto deta = dz2 * (1.f + d_ratio * dz);
      const auto dzeta = dz * deta;
      const auto deta2 = deta * deta;

      s01 += dz;
      s02 += deta;
      s11 += dz2;
      s12 += dzeta;
      s22 += deta2;

      const auto dx = x - predicted_x;
      const auto dzdx = dz * dx;
      const auto detadx = deta * dx;

      b0 += dx;
      b1 += dzdx;
      b2 += detadx;
    }

    s00 = track.hitsNum;

    const auto d = s00 * (s11 * s22 - s12 * s12) - s01 * (s01 * s22 - s12 * s02) + s02 * (s01 * s12 - s11 * s02);
    const auto d_a = b0 * (s11 * s22 - s12 * s12) - b1 * (s01 * s22 - s12 * s02) + b2 * (s01 * s12 - s11 * s02);
    const auto d_b = -b0 * (s01 * s22 - s12 * s02) + b1 * (s00 * s22 - s02 * s02) - b2 * (s00 * s12 - s02 * s01);
    const auto d_c = b0 * (s01 * s12 - s11 * s02) - b1 * (s00 * s12 - s01 * s02) + b2 * (s00 * s11 - s01 * s01);

    const auto d_inv = 1.f / d;
    const auto offset = prev_offset + d_a * d_inv;
    const auto tx = prev_tx + d_b * d_inv;
    const auto curvature = prev_curvature + d_c * d_inv;

    // Update parametrization
    dev_scifi_lf_parametrization_x_filter[scifi_track_index] = curvature;
    dev_scifi_lf_parametrization_x_filter
      [ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
       scifi_track_index] = tx;
    dev_scifi_lf_parametrization_x_filter
      [2 * ut_total_number_of_tracks * LookingForward::maximum_number_of_candidates_per_ut_track +
       scifi_track_index] = offset;

    // Update track quality
    track.quality = 0.f;
    for (uint i_hit = 0; i_hit < track.hitsNum; ++i_hit) {
      const auto hit_index = event_offset + track.hits[i_hit];
      const auto layer_index = scifi_hits.planeCode(hit_index) / 2;
      const auto x = scifi_hits.x0[hit_index];
      const auto z = dev_looking_forward_constants->Zone_zPos[layer_index];

      const auto dz = z - LookingForward::z_mid_t;
      const auto predicted_x = offset + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz);

      track.quality += (x - predicted_x) * (x - predicted_x);
    }
  }
}
