/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MuonFeaturesExtraction.cuh"
#include "MuonEventModel.cuh"

void muon_catboost_features_extraction::muon_catboost_features_extraction_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_catboost_features_t>(
    arguments, Muon::Constants::n_catboost_features * first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void muon_catboost_features_extraction::muon_catboost_features_extraction_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(muon_catboost_features_extraction)(
    size<dev_event_list_t>(arguments), Muon::Constants::n_stations, context)(
    arguments);
}

__global__ void muon_catboost_features_extraction::muon_catboost_features_extraction(
  muon_catboost_features_extraction::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_id = parameters.dev_event_list[blockIdx.x];
  const unsigned station_id = blockIdx.y;

  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_id,
                                                 number_of_events};

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + event_id * Muon::Constants::n_stations;
  const auto muon_event_offset = station_ocurrences_offset[0];
  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits, muon_total_number_of_hits};

  const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_id);
  const unsigned event_offset = scifi_tracks.tracks_offset(event_id);
  for (unsigned track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    float min_dist = 1e10;
    int index_of_closest_hit = -1;

    const int number_of_hits = station_ocurrences_offset[station_id + 1] - station_ocurrences_offset[station_id];
    const float station_z = muon_hits.z(muon_event_offset);
    const float station_z0 = muon_hits.z(0);

    const float extrapolation_x = scifi_tracks.states(track_id).x +
                                  scifi_tracks.states(track_id).tx * (station_z - scifi_tracks.states(track_id).z);
    const float extrapolation_y = scifi_tracks.states(track_id).y +
                                  scifi_tracks.states(track_id).ty * (station_z - scifi_tracks.states(track_id).z);
    const float extrapolation_x0 = scifi_tracks.states(track_id).x +
                                   scifi_tracks.states(track_id).tx * (station_z0 - scifi_tracks.states(track_id).z);
    const float extrapolation_y0 = scifi_tracks.states(track_id).y +
                                   scifi_tracks.states(track_id).ty * (station_z0 - scifi_tracks.states(track_id).z);

    for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
      const int idx = muon_event_offset + i_hit;

      const float dx = muon_hits.x(idx) - extrapolation_x;
      const float dy = muon_hits.y(idx) - extrapolation_y;
      const float hit_track_distance = dx * dx + dy * dy;

      if (hit_track_distance < min_dist) {
        // todo: possible mutex lock
        min_dist = hit_track_distance;
        index_of_closest_hit = i_hit;
      }
    }

    const unsigned tracks_features_offset = (event_offset + track_id) * Muon::Constants::n_catboost_features;
    if (index_of_closest_hit > -1) {
      const float common_factor = Muon::Constants::MSFACTOR * fabsf(scifi_tracks.qop(track_id));

      const int idx = muon_event_offset + index_of_closest_hit;

      parameters.dev_muon_catboost_features[tracks_features_offset + offset::TIMES + station_id] = muon_hits.time(idx);
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::DTS + station_id] =
        muon_hits.delta_time(idx);
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::CROSS + station_id] =
        (muon_hits.uncrossed(idx) == 0) ? 2.f : muon_hits.uncrossed(idx);

      const float trav_dist = sqrtf(
        (station_z - station_z0) * (station_z - station_z0) +
        (extrapolation_x - extrapolation_x0) * (extrapolation_x - extrapolation_x0) +
        (extrapolation_y - extrapolation_y0) * (extrapolation_y - extrapolation_y0));
      const float errMS = common_factor * trav_dist * sqrtf(trav_dist);

      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_X + station_id] =
        (extrapolation_x - muon_hits.x(idx)) /
        sqrtf(
          (muon_hits.dx(idx) * Muon::Constants::INVSQRT3) * (muon_hits.dx(idx) * Muon::Constants::INVSQRT3) +
          errMS * errMS);
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_Y + station_id] =
        (extrapolation_y - muon_hits.y(idx)) /
        sqrtf(
          (muon_hits.dy(idx) * Muon::Constants::INVSQRT3) * (muon_hits.dy(idx) * Muon::Constants::INVSQRT3) +
          errMS * errMS);
    }
    else {
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::TIMES + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::DTS + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::CROSS + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_X + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_Y + station_id] = 0.f;
    }
  }
}
