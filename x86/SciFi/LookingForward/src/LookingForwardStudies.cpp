#include "LookingForwardStudies.h"
#include "TrackUtils.cuh"
#include "FindXHits.cuh"
#include "LookingForwardSbt.h"
#include "LookingForwardConstants.cuh"
#include <numeric>
#include <iomanip>

std::vector<std::vector<SciFi::TrackHits>> looking_forward_studies(
  const uint* host_scifi_hits,
  const uint* host_scifi_hit_count,
  const char* host_scifi_geometry,
  const std::array<float, 9>& host_inv_clus_res,
  const uint* host_velo_tracks_atomics,
  const uint* host_velo_track_hit_number,
  const char* host_velo_states,
  const int* host_atomics_ut,
  const uint* host_ut_track_hit_number,
  const float* host_ut_qop,
  const float* host_ut_x,
  const float* host_ut_tx,
  const float* host_ut_z,
  const uint* host_ut_track_velo_indices,
  const std::vector<std::vector<std::vector<uint32_t>>>& scifi_ids_ut_tracks,
  const std::vector<std::vector<float>>& p_events,
  const uint number_of_events,
  const SciFi::TrackHits* host_scifi_tracks,
  const int* host_atomics_scifi)
{
  const bool run_algorithm = false;
  std::vector<std::vector<SciFi::TrackHits>> trackhits;

  // to do: read this from configuration
  const float magnet_polarity = -1.f; 

  const auto print_track = [](const SciFi::TrackHits& track) {
    info_cout << "{ut track " << track.ut_track_index << ", " << ((int) track.hitsNum) << " hits: ";

    for (int i = 0; i < track.hitsNum; ++i) {
      info_cout << track.hits[i] << ", ";
    }
    info_cout << track.get_quality() << "}";
  };

  if (run_algorithm) {
    const bool compare_cpu_gpu_tracks = false;

    const auto lhcb_id_find_id =
      [](int start_id, const int last_id, const uint32_t lhcb_id, const SciFi::Hits& scifi_hits) {
        for (; start_id < last_id; ++start_id) {
          if (scifi_hits.LHCbID(start_id) == lhcb_id) {
            return start_id;
          }
        }
        return start_id;
      };

    for (uint i_event = 0; i_event < number_of_events; ++i_event) {
      // Tracks found for this event
      std::vector<SciFi::TrackHits> event_trackhits;

      // Velo consolidated types
      const Velo::Consolidated::Tracks velo_tracks {
        (uint*) host_velo_tracks_atomics, (uint*) host_velo_track_hit_number, i_event, number_of_events};
      const uint velo_event_tracks_offset = velo_tracks.tracks_offset(i_event);
      const Velo::Consolidated::States velo_states {(char*) host_velo_states, velo_tracks.total_number_of_tracks};

      // UT consolidated types
      UT::Consolidated::Tracks ut_tracks {(uint*) host_atomics_ut,
                                          (uint*) host_ut_track_hit_number,
                                          (float*) host_ut_qop,
                                          (uint*) host_ut_track_velo_indices,
                                          i_event,
                                          number_of_events};
      const int n_veloUT_tracks_event = ut_tracks.number_of_tracks(i_event);
      const int ut_event_tracks_offset = ut_tracks.tracks_offset(i_event);

      // SciFi non-consolidated types
      const uint total_number_of_hits =
        host_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
      SciFi::HitCount scifi_hit_count {(uint32_t*) host_scifi_hit_count, i_event};

      const SciFi::SciFiGeometry scifi_geometry(host_scifi_geometry);

      SciFi::Hits scifi_hits(
        (uint*) host_scifi_hits,
        total_number_of_hits,
        &scifi_geometry,
        reinterpret_cast<const float*>(host_inv_clus_res.data()));

      // extrapolate veloUT tracks
      float tx, ty;

      // Flagging mechanism
      std::vector<bool> event_common_flag(scifi_hit_count.event_number_of_hits(), false);
      std::vector<std::vector<bool>> event_multi_flag;
      for (int i = 0; i < n_veloUT_tracks_event; ++i) {
        std::vector<bool> flag(scifi_hit_count.event_number_of_hits(), false);
        event_multi_flag.push_back(flag);
      }

      const auto event_offset = scifi_hit_count.event_offset();
      const std::array<int, 6> layers {0, 3, 4, 7, 8, 11};

      SciFiWindowsParams window_params;
      window_params.dx_slope = 1e5;
      window_params.dx_min = 300;
      window_params.dx_weight = 0.6;
      window_params.tx_slope = 1250;
      window_params.tx_min = 300;
      window_params.tx_weight = 0.4;
      window_params.max_window_layer0 = 600;
      window_params.max_window_layer1 = 2;
      window_params.max_window_layer2 = 2;
      window_params.max_window_layer3 = 20;
      window_params.chi2_cut = 4;

      // For ghost killing
      SciFi::Tracking::Arrays constArrays;
      SciFi::Tracking::TMVA tmva1;
      SciFi::Tracking::TMVA1_Init(tmva1);
      SciFi::Tracking::TMVA tmva2;
      SciFi::Tracking::TMVA2_Init(tmva2);

      // Hits in layers for every track
      std::vector<std::array<std::vector<int>, 6>> event_hits_in_layers;
      std::vector<MiniState> event_UT_state;
      std::vector<MiniState> event_velo_state;
      std::vector<float> event_qop;

      // TODO: n_veloUT_tracks_event
      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        // veloUT track variables
        const float qop = ut_tracks.qop[i_veloUT_track];
        event_qop.push_back(qop);

        const int i_velo_track = ut_tracks.velo_track[i_veloUT_track];
        const MiniState velo_state {velo_states, velo_event_tracks_offset + i_velo_track};
        event_velo_state.push_back(velo_state);

        const int ut_track_index = ut_event_tracks_offset + i_veloUT_track;
        const float ut_x = host_ut_x[ut_track_index];
        const float ut_tx = host_ut_tx[ut_track_index];
        const float ut_z = host_ut_z[ut_track_index];

        const auto make_index_list_of_reconstructible =
          [&scifi_hit_count, &scifi_hits, &lhcb_id_find_id](const std::vector<uint>& true_scifi_ids) {
            std::vector<int> indices;

            const auto event_offset = scifi_hit_count.event_offset();
            const auto n_hits = scifi_hit_count.event_number_of_hits();
            const auto last_hit = event_offset + n_hits;

            for (const auto& lhcb_id : true_scifi_ids) {
              const auto index = lhcb_id_find_id(event_offset, last_hit, lhcb_id, scifi_hits);
              if (index != last_hit) {
                indices.push_back(index);
              }
            }

            return indices;
          };

        // SciFi IDs for matched veloUT track
        const std::vector<int> true_scifi_indices =
          make_index_list_of_reconstructible(scifi_ids_ut_tracks[i_event][i_veloUT_track]);

        // extrapolate velo y & ty to z of UT x and tx
        // use ty from Velo state
        MiniState state_UT;
        state_UT.x = ut_x;
        state_UT.tx = ut_tx;
        state_UT.z = ut_z;
        state_UT.ty = velo_state.ty;
        state_UT.y = y_at_z(velo_state, ut_z);

        // extrapolate state to last UT plane (needed as input for parametrization)
        const MiniState UT_state = state_at_z(state_UT, SciFi::LookingForward::z_last_UT_plane);
        event_UT_state.push_back(UT_state);

        // propagation to first layer of T3
        const auto SciFi_state_T3 = propagate_state_from_velo(UT_state, qop, 8);

        std::array<int, 12> layer_offsets;
        std::array<int, 12> layer_number_of_hits;
        std::array<int, 12> layer_last_hits;

        for (int i = 0; i < 12; ++i) {
          const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(i * 2, scifi_hit_count, SciFi_state_T3.y);

          layer_offsets[i] = std::get<0>(layer_offset_nhits);
          layer_number_of_hits[i] = std::get<1>(layer_offset_nhits);
          layer_last_hits[i] = layer_offsets[i] + layer_number_of_hits[i];
        }

        // Monte Carlo track
        // Simplified model: One hit per layer.
        // This is not realistic though, since we could have repeated hits on stations
        std::array<int, 12> true_scifi_indices_per_layer {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        for (int i = 0; i < 12; ++i) {
          for (const auto index : true_scifi_indices) {
            if (index >= layer_offsets[i] && index < layer_last_hits[i]) {
              true_scifi_indices_per_layer[i] = index;
            }
          }
        }

        std::array<int, 2 * 6> windows_x;
        std::array<int, 2 * 6> windows_uv;
        std::array<float, 4 * 6> parameters_uv;

        for (int i = 0; i < 6; ++i) {
          windows_x[2 * i] = 0;
          windows_x[2 * i + 1] = 0;
          windows_uv[2 * i] = 0;
          windows_uv[2 * i + 1] = 0;
          parameters_uv[4 * i] = 0;
          parameters_uv[4 * i + 1] = 0;
          parameters_uv[4 * i + 2] = 0;
          parameters_uv[4 * i + 3] = 0;
        }

        const float y_projection = y_at_z(UT_state, SciFi::LookingForward::Zone_zPos[0]);
        const float zRef_track = SciFi::Tracking::zReference;
        const float xAtRef = xFromVelo(zRef_track, UT_state);
        const float yAtRef = yFromVelo(zRef_track, UT_state);

        float bs_x[4] {xAtRef, UT_state.tx, 0, 0};
        float bs_y[4] {yAtRef, UT_state.ty, 0, 0};

        // collectAllXHits_proto(
        //   scifi_hits,
        //   scifi_hit_count,
        //   bs_x,
        //   bs_y,
        //   &constArrays,
        //   magnet_polarity,
        //   UT_state,
        //   qop,
        //   (y_projection < 0 ? -1 : 1),
        //   windows_x,
        //   windows_uv,
        //   parameters_uv);

        collectAllXHits_proto_p(
          scifi_hits,
          scifi_hit_count,
          &constArrays,
          magnet_polarity,
          velo_state,
          UT_state,
          qop,
          (y_projection < 0 ? -1 : 1),
          windows_x,
          windows_uv,
          parameters_uv,
          window_params,
          true_scifi_indices_per_layer);

        // Collect all X candidates
        // std::array<std::vector<int>, 6> hits_in_layers =
        //   collect_x_candidates(scifi_hits, windows_x, windows_uv, parameters_uv);

        std::array<std::vector<int>, 6> hits_in_layers = collect_x_candidates_p(scifi_hits, windows_x, windows_uv, qop);

        // Restrict to a max number of hits
        for (int i = 0; i < 6; ++i) {
          if (hits_in_layers[i].size() > LookingForward::maximum_number_of_candidates) {
            hits_in_layers[i].resize(LookingForward::maximum_number_of_candidates);
          }
        }

        event_hits_in_layers.push_back(hits_in_layers);

        // info_cout << "#" << i_veloUT_track << ": " << std::endl;
        // for (int i = 0; i < 6; ++i) {
        //   info_cout << " {" << windows_x[2 * i] << ", " << windows_x[2 * i + 1] << "}, "
        //     << "{" << windows_uv[2 * i] << ", " << windows_uv[2 * i + 1] << "}, "
        //     << "{" << parameters_uv[4 * i] << ", " << parameters_uv[4 * i + 1] << ", "
        //            << parameters_uv[4 * i + 2] << ", " << parameters_uv[4 * i + 3] << "}"
        //     << std::endl;
        // }
        // info_cout << std::endl;

        // info_cout << "Candidates #" << i_veloUT_track << ": ";
        // for (int i=0; i<6; ++i) {
        //   info_cout << hits_in_layers[i].size() << ", ";
        // }
        // info_cout << std::endl;
      }

      // Configuration of sbt
      // Triplet creation
      const std::array<float, 4> dx_stddev_triplet_x0 {53.01f, 97.43f, 39.89f, 77.55f};
      const std::array<float, 4> dx_stddev_triplet_x2 {117.1f, 42.68f, 88.74f, 33.79f};
      const std::array<float, 4> chi2_mean_triplet {2.35f, 3.14f, 2.17f, 3.95f};
      const std::array<float, 4> chi2_stddev_triplet {14.05f, 7.49f, 9.97f, 7.97f};

      // Extrapolation
      const std::array<float, 3> dx_stddev_extrapolation_to_x_layers {1.50f, 1.40f, 1.74f};
      const std::array<float, 3> chi2_mean_extrapolation_to_x_layers {3.09f, 1.98f, 3.89f};
      const std::array<float, 3> chi2_stddev_extrapolation_to_x_layers {6.33f, 5.09f, 7.42f};

      // Extrapolation to UV
      const std::array<int, 6> extrapolation_layers {1, 2, 5, 6, 9, 10};
      const std::array<float, 6> extrapolation_stddev {1.112f, 1.148f, 2.139f, 2.566f, 6.009f, 6.683f};
      const std::array<float, 6> chi2_extrapolation_mean {1.304f, 1.384f, 4.577f, 6.587f, 36.1f, 44.67f};
      const std::array<float, 6> chi2_extrapolation_stddev {10.6f, 11.82f, 17.84f, 23.2f, 68.05f, 81.47f};

      const std::array<int, 4> max_candidates_triplets {20, 20, 20, 20};
      const float factor_chi2_triplet = 2.5f;
      const float factor_chi2_extend = 2.5f;
      const bool use_flagging = false;
      const bool use_flagging_in_l0_l3_layers = false;
      const bool use_multi_flags = true;
      const bool iterate_all_hits_uv = false;

      // Extra triplets
      // std::array<std::tuple<int, int, int>, 2> extra_triplets {{std::make_tuple(0, 1, 5), std::make_tuple(0, 4, 5)}};
      std::array<std::tuple<int, int, int>, 0> extra_triplets;

      const float dx_stddev_triplet_x0_extra = 97.43f;
      const float dx_stddev_triplet_x2_extra = 117.1f;
      const float chi2_mean_triplet_extra = 3.95f;
      const float chi2_stddev_triplet_extra = 14.05f;
      const int max_candidates_triplets_extra = 20;

      std::vector<std::vector<SciFi::TrackHits>> event_scifi_tracks(n_veloUT_tracks_event);

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        // Get triplets of layers 0, 1, 2
        const auto triplets_middle_layer = 1;
        find_triplets(
          scifi_hits,
          event_qop[i_veloUT_track],
          flag,
          event_offset,
          layers,
          event_hits_in_layers[i_veloUT_track],
          triplets_middle_layer - 1,
          triplets_middle_layer,
          triplets_middle_layer + 1,
          max_candidates_triplets[triplets_middle_layer - 1],
          chi2_mean_triplet[triplets_middle_layer - 1] +
            factor_chi2_triplet * chi2_stddev_triplet[triplets_middle_layer - 1],
          false,
          i_veloUT_track,
          event_UT_state[i_veloUT_track],
          scifi_tracks);

        // Extend to layer 3
        const auto extend_layer = 3;
        extend_tracklets(
          scifi_hits,
          event_UT_state[i_veloUT_track],
          layers,
          event_hits_in_layers[i_veloUT_track],
          extend_layer,
          event_offset,
          chi2_mean_extrapolation_to_x_layers[extend_layer - 3] +
            factor_chi2_extend * chi2_stddev_extrapolation_to_x_layers[extend_layer - 3],
          scifi_tracks,
          flag,
          i_veloUT_track);
      }

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        // Get triplets of layers 1, 2, 3
        const auto triplets_middle_layer = 2;
        find_triplets(
          scifi_hits,
          event_qop[i_veloUT_track],
          flag,
          event_offset,
          layers,
          event_hits_in_layers[i_veloUT_track],
          triplets_middle_layer - 1,
          triplets_middle_layer,
          triplets_middle_layer + 1,
          max_candidates_triplets[triplets_middle_layer - 1],
          chi2_mean_triplet[triplets_middle_layer - 1] +
            factor_chi2_triplet * chi2_stddev_triplet[triplets_middle_layer - 1],
          use_flagging,
          i_veloUT_track,
          event_UT_state[i_veloUT_track],
          scifi_tracks);

        // Extend to next layer
        const auto extend_layer = 4;
        extend_tracklets(
          scifi_hits,
          event_UT_state[i_veloUT_track],
          layers,
          event_hits_in_layers[i_veloUT_track],
          extend_layer,
          event_offset,
          chi2_mean_extrapolation_to_x_layers[extend_layer - 3] +
            factor_chi2_extend * chi2_stddev_extrapolation_to_x_layers[extend_layer - 3],
          scifi_tracks,
          flag,
          i_veloUT_track);
      }

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        // Get triplets of layers 2, 3, 4
        const auto triplets_middle_layer = 3;
        find_triplets(
          scifi_hits,
          event_qop[i_veloUT_track],
          flag,
          event_offset,
          layers,
          event_hits_in_layers[i_veloUT_track],
          triplets_middle_layer - 1,
          triplets_middle_layer,
          triplets_middle_layer + 1,
          max_candidates_triplets[triplets_middle_layer - 1],
          chi2_mean_triplet[triplets_middle_layer - 1] +
            factor_chi2_triplet * chi2_stddev_triplet[triplets_middle_layer - 1],
          use_flagging,
          i_veloUT_track,
          event_UT_state[i_veloUT_track],
          scifi_tracks);

        // Extend to next layer
        const auto extend_layer = 5;
        extend_tracklets(
          scifi_hits,
          event_UT_state[i_veloUT_track],
          layers,
          event_hits_in_layers[i_veloUT_track],
          extend_layer,
          event_offset,
          chi2_mean_extrapolation_to_x_layers[extend_layer - 3] +
            factor_chi2_extend * chi2_stddev_extrapolation_to_x_layers[extend_layer - 3],
          scifi_tracks,
          flag,
          i_veloUT_track);
      }

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        // Get triplets of layers 3, 4, 5
        const auto triplets_middle_layer = 4;
        find_triplets(
          scifi_hits,
          event_qop[i_veloUT_track],
          flag,
          event_offset,
          layers,
          event_hits_in_layers[i_veloUT_track],
          triplets_middle_layer - 1,
          triplets_middle_layer,
          triplets_middle_layer + 1,
          max_candidates_triplets[triplets_middle_layer - 1],
          chi2_mean_triplet[triplets_middle_layer - 1] +
            factor_chi2_triplet * chi2_stddev_triplet[triplets_middle_layer - 1],
          use_flagging,
          i_veloUT_track,
          event_UT_state[i_veloUT_track],
          scifi_tracks);
      }

      int total_tracks = 0;
      int cut_tracks = 0;

      // Early chi2 cut for short tracks
      // Note: By this point, about 75% of the tracks are 3-hit
      const float chi2_track_x_cut = 1.f;
      const int max_num_track = 1000;
      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        const int number_of_tracks = scifi_tracks.size();
        for (auto it = scifi_tracks.begin(); it != scifi_tracks.end();) {
          const auto& track = *it;
          if (
            track.hitsNum > 3 ||
            (track.hitsNum == 3 && track.quality < chi2_track_x_cut && number_of_tracks < max_num_track)) {
            ++it;
            total_tracks++;
          }
          else {
            cut_tracks++;
            total_tracks++;
            it = scifi_tracks.erase(it);
          }
        }
      }

      // if (total_tracks > 0) {
      //   info_cout << "Percentage of cut tracks: "
      //     << (100.f * ((float) cut_tracks) / ((float) total_tracks))
      //     << " (" << cut_tracks << " out of " << total_tracks << ")"
      //     << std::endl;
      // }

      const std::array<int, 2> final_layers {0, 3};
      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        for (int i = 0; i < final_layers.size(); ++i) {
          const auto j = 1 - i;

          const int layer = final_layers[j];
          const auto projection_y = y_at_z(event_UT_state[i_veloUT_track], SciFi::LookingForward::Zone_zPos[layer]);

          for (auto& track : scifi_tracks) {
            // single_track_propagation(
            //   scifi_hits,
            //   scifi_hit_count,
            //   layer,
            //   track,
            //   extrapolation_stddev[0],
            //   chi2_extrapolation_mean[0],
            //   chi2_extrapolation_stddev[0],
            //   event_offset,
            //   flag,
            //   projection_y,
            //   use_flagging_in_l0_l3_layers);

            single_track_propagation(
              scifi_hits,
              scifi_hit_count,
              j,
              layer,
              track,
              extrapolation_stddev[0],
              chi2_mean_extrapolation_to_x_layers[0],
              chi2_stddev_extrapolation_to_x_layers[0],
              event_offset,
              flag,
              event_hits_in_layers[i_veloUT_track],
              use_flagging_in_l0_l3_layers);
          }
        }
      }

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        auto& flag = use_multi_flags ? event_multi_flag[i_veloUT_track] : event_common_flag;

        // // Extra triplets
        // for (const auto& extra_triplet : extra_triplets) {
        //   const auto relative_layer0 = std::get<0>(extra_triplet);
        //   const auto relative_layer1 = std::get<1>(extra_triplet);
        //   const auto relative_layer2 = std::get<2>(extra_triplet);

        //   find_triplets(
        //     scifi_hits,
        //     event_qop[i_veloUT_track],
        //     flag,
        //     event_offset,
        //     layers,
        //     event_hits_in_layers[i_veloUT_track],
        //     relative_layer0,
        //     relative_layer1,
        //     relative_layer2,
        //     max_candidates_triplets_extra,
        //     chi2_mean_triplet_extra + factor_chi2_triplet * chi2_stddev_triplet_extra,
        //     use_flagging,
        //     i_veloUT_track,
        //     event_UT_state[i_veloUT_track],
        //     scifi_tracks);
        // }

        for (int i = 0; i < extrapolation_layers.size(); ++i) {
          const int layer = extrapolation_layers[i];
          const auto projection_y = y_at_z(event_UT_state[i_veloUT_track], SciFi::LookingForward::Zone_zPos[layer]);

          for (auto& track : scifi_tracks) {
            single_track_propagation(
              scifi_hits,
              scifi_hit_count,
              layer,
              track,
              extrapolation_stddev[i],
              chi2_extrapolation_mean[i],
              chi2_extrapolation_stddev[i],
              event_offset,
              flag,
              projection_y,
              false,
              iterate_all_hits_uv);
          }
        }
      }

      // Cut tracks with less than 9 hits
      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
        for (auto it = scifi_tracks.begin(); it != scifi_tracks.end();) {
          const auto& track = *it;
          if (track.hitsNum >= 9) {
            ++it;
          }
          else {
            it = scifi_tracks.erase(it);
          }
        }
      }

      for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
        auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];

        filter_tracks_with_TMVA(
            scifi_tracks,
            event_trackhits,
            event_velo_state[i_veloUT_track],
            event_qop[i_veloUT_track],
            &constArrays,
            &tmva1,
            &tmva2,
            scifi_hits,
            scifi_hit_count.event_offset());

        // for (const auto& track : scifi_tracks) {
        //   event_trackhits.push_back(track);
        // }

        // int best_track = -1;
        // float best_quality = 100000.f;
        // for (int i=0; i<scifi_tracks.size(); ++i) {
        //   auto& track = scifi_tracks[i];
        //   single_track_quality_update(
        //     track,
        //     event_velo_state[i_veloUT_track],
        //     event_qop[i_veloUT_track],
        //     &constArrays,
        //     &tmva1,
        //     &tmva2,
        //     scifi_hits,
        //     scifi_hit_count.event_offset());

        //   if (track.hitsNum >= 9 && track.quality < best_quality) {
        //     best_track = i;
        //     best_quality = track.quality;
        //   }
        // }

        // if (best_track != -1) {
        //   // auto& track = scifi_tracks[best_track];
        //   // for (int i=0; i<track.hitsNum; ++i) {
        //   //   track.hits[i] = 10000;
        //   // }

        //   // Check if track has MC hit

        //   event_trackhits.push_back(scifi_tracks[best_track]);
        // }
      }

      // float best_fit = 100.f;
      // int best_track = -1;

      // for (int i=0; i<scifi_tracks.size(); ++i) {
      //   const auto track = scifi_tracks[i];
      //   if (track.hitsNum >= 9) {
      //     if (track.get_quality() < best_fit) {
      //       best_fit = track.get_quality();
      //       best_track = i;
      //     }
      //   }
      // }

      // // Populate trackhits
      // if (best_track != -1) {
      //   event_trackhits.push_back(scifi_tracks[best_track]);
      // }

      // for (const auto& track_vector : event_scifi_tracks) {
      //   for (const auto& track : track_vector) {
      //     // if (track.hitsNum >= 9) {
      //       event_trackhits.push_back(track);
      //     // }
      //   }
      // }

      // for (int i_veloUT_track = 0; i_veloUT_track < n_veloUT_tracks_event; ++i_veloUT_track) {
      //   auto& scifi_tracks = event_scifi_tracks[i_veloUT_track];
      //   for (const auto& track : scifi_tracks) {
      //     if (track.hitsNum >= 8) {
      //       event_trackhits.push_back(track);
      //     }
      //   }
      // }

      if (compare_cpu_gpu_tracks) {
        bool validated = true;
        const auto number_of_tracks_gpu = host_atomics_scifi[i_event];
        if (event_trackhits.size() != number_of_tracks_gpu) {
          validated = false;
          info_cout << "Number of tracks CPU: " << event_trackhits.size() << std::endl
                    << "Number of tracks GPU: " << number_of_tracks_gpu << std::endl;
        }

        for (const auto& track : event_trackhits) {
          bool found = false;
          for (int i = 0; i < number_of_tracks_gpu; ++i) {
            const auto& gpu_track = host_scifi_tracks[i_event * SciFi::Constants::max_tracks + i];

            if (track.hitsNum == gpu_track.hitsNum) {
              bool same = true;
              for (int j = 0; j < track.hitsNum; ++j) {
                same &= track.hits[j] == gpu_track.hits[j];
              }
              found |= same;
            }
          }

          if (!found) {
            validated = false;
            info_cout << "Track ";
            print_track(track);
            info_cout << " not found in GPU tracks" << std::endl;
          }
        }

        if (!validated) {
          info_cout << std::endl;
        }

        for (int i = 0; i < number_of_tracks_gpu; ++i) {
          const auto& gpu_track = host_scifi_tracks[i_event * SciFi::Constants::max_tracks + i];
          bool found = false;
          for (const auto& track : event_trackhits) {

            if (track.hitsNum == gpu_track.hitsNum) {
              bool same = true;
              for (int j = 0; j < track.hitsNum; ++j) {
                same &= track.hits[j] == gpu_track.hits[j];
              }
              found |= same;
            }
          }

          if (!found) {
            validated = false;
            info_cout << "Track ";
            print_track(gpu_track);
            info_cout << " not found in CPU tracks" << std::endl;
          }
        }

        if (!validated) {
          info_cout << std::endl;
        }

        if (validated) {
          info_cout << "Event " << i_event << " validated" << std::endl;
        }
      }

      trackhits.emplace_back(event_trackhits);
    }
  }

  return trackhits;
}
