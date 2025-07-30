/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "VeloLumiCounters.cuh"
#include "LumiCommon.cuh"
#include "LHCbID.cuh"

INSTANTIATE_ALGORITHM(velo_lumi_counters::velo_lumi_counters_t)

void velo_lumi_counters::velo_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments, Lumi::Constants::n_velo_counters * first<host_lumi_summaries_count_t>(arguments));
}

void velo_lumi_counters::velo_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = m_lumi_counter_schema;
  std::map<std::string, std::pair<float, float>> shifts_and_scales = m_lumi_counter_shifts_and_scales;

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::velo_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      m_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      m_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      m_shifts_and_scales[2 * c_idx] = 0.f;
      m_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      m_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      m_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
}

void velo_lumi_counters::velo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  Allen::memset_async<dev_lumi_infos_t>(arguments, 0, context);

  global_function(velo_lumi_gec_counters)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_offsets_and_sizes, m_shifts_and_scales, m_tracks_eta_bins.value());

  global_function(velo_lumi_decoding_counters)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments, m_offsets_and_sizes, m_shifts_and_scales, m_clusters_station_bin_edges);
}

__global__ void velo_lumi_counters::velo_lumi_gec_counters(
  velo_lumi_counters::Parameters parameters,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales,
  std::array<float, Lumi::Constants::n_velo_eta_bin_edges> tracks_eta_bins)
{
  auto event_number = parameters.dev_event_list[blockIdx.x];
  unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

  // skip non-lumi event
  if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) return;

  __shared__ unsigned reco_counters[Lumi::Constants::n_velo_reco_counters];

  for (unsigned i = threadIdx.x; i < Lumi::Constants::n_velo_reco_counters; i += blockDim.x) {
    reco_counters[i] = 0.f;
  }

  __syncthreads();

  const auto velo_states = parameters.dev_velo_states_view[event_number];
  // first counter is the total velo tracks
  const unsigned track_offset = parameters.dev_offsets_all_velo_tracks[event_number];
  if (threadIdx.x == 0) reco_counters[0] = parameters.dev_offsets_all_velo_tracks[event_number + 1] - track_offset;

  __syncthreads();

  for (unsigned track_index = threadIdx.x; track_index < reco_counters[0]; track_index += blockDim.x) {
    const auto velo_state = velo_states.state(track_index);

    // fiducial cut: doca<3 mm && |poca|<300 mm
    if (velo_state.z() > -300.f && velo_state.z() < 300.f) {
      if (velo_DOCAz(velo_state) < 3.f * Allen::Units::mm) {
        atomicAdd(&reco_counters[1], 1);
      }
    }

    // fill eta bins
    float eta = velo_eta(velo_state, parameters.dev_is_backward[track_offset + track_index]);
    if (eta > tracks_eta_bins[Lumi::Constants::n_velo_eta_bin_edges - 1u] * Allen::Units::mm) {
      atomicAdd(&reco_counters[2u + Lumi::Constants::n_velo_eta_bin_edges], 1);
      continue;
    }
    for (unsigned eta_bin = 0; eta_bin < Lumi::Constants::n_velo_eta_bin_edges; ++eta_bin) {
      if (eta < tracks_eta_bins[eta_bin] * Allen::Units::mm) {
        atomicAdd(&reco_counters[2u + eta_bin], 1);
        break;
      }
    }
  }

  __syncthreads();

  unsigned info_offset = Lumi::Constants::n_velo_counters * lumi_evt_index;

  for (unsigned info_index = threadIdx.x; info_index < Lumi::Constants::n_velo_reco_counters;
       info_index += blockDim.x) {
    fillLumiInfo(
      parameters.dev_lumi_infos[info_offset + info_index],
      offsets_and_sizes[info_index * 2],
      offsets_and_sizes[info_index * 2 + 1],
      reco_counters[info_index],
      shifts_and_scales[2 * info_index],
      shifts_and_scales[2 * info_index + 1]);
  }
}

__global__ void velo_lumi_counters::velo_lumi_decoding_counters(
  velo_lumi_counters::Parameters parameters,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales,
  std::array<unsigned, 4> clusters_station_bin_edges)
{

  unsigned event_number = blockIdx.x;

  // now fill 'decoding' counters, which are available even if the GEC does not pass
  unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

  // skip non-lumi event
  if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) return;

  // velo clusters
  __shared__ unsigned cluster_counters[Lumi::Constants::n_velo_cluster_counters];

  for (unsigned i = threadIdx.x; i < Lumi::Constants::n_velo_cluster_counters; i += blockDim.x) {
    cluster_counters[i] = 0.f;
  }

  __syncthreads();

  const unsigned* module_pair_cluster_start =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_module_pairs;
  const auto velo_cluster_container = parameters.dev_velo_clusters[event_number];
  const unsigned* module_hit_num = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_module_pairs;

  for (auto module_index = threadIdx.x; module_index < Velo::Constants::n_module_pairs; module_index += blockDim.x) {
    auto hit_offset = module_pair_cluster_start[module_index];
    for (auto hit_index = 0u; hit_index < module_hit_num[module_index]; ++hit_index) {
      unsigned sensor_id =
        ((velo_cluster_container.id(hit_offset + hit_index) & lhcb_id::IDMask) & Allen::VPChannelID::sensorMask) >>
        Allen::VPChannelID::sensorBits;
      unsigned station_id = sensor_id / 8;

      // sensor id out of range - skip
      if (station_id >= Velo::Constants::n_module_pairs) {
        continue;
      }

      // even id for inner; odd id for outer
      if (sensor_id % 2u == 0u) {
        atomicAdd(&cluster_counters[station_id * 2], 1);
      }
      else {
        atomicAdd(&cluster_counters[station_id * 2 + 1], 1);
      }
    }
  }

  // fill station bins consecutively
  unsigned station_bin = 0;
  if (threadIdx.x == 0) {
    for (unsigned station_id = 0; station_id < Velo::Constants::n_module_pairs; ++station_id) {
      unsigned counter_index = Velo::Constants::n_modules + station_bin * 2;
      cluster_counters[counter_index] += cluster_counters[station_id * 2];
      cluster_counters[counter_index + 1] += cluster_counters[station_id * 2 + 1];

      // go to next bin
      if (station_id == clusters_station_bin_edges[station_bin]) {
        ++station_bin;
      }
    }
  }

  __syncthreads();

  unsigned info_offset = Lumi::Constants::n_velo_counters * lumi_evt_index;
  for (unsigned info_index = Lumi::Constants::n_velo_reco_counters + threadIdx.x;
       info_index < Lumi::Constants::n_velo_reco_counters + Lumi::Constants::n_velo_cluster_counters;
       info_index += blockDim.x) {
    fillLumiInfo(
      parameters.dev_lumi_infos[info_offset + info_index],
      offsets_and_sizes[info_index * 2],
      offsets_and_sizes[info_index * 2 + 1],
      cluster_counters[info_index - Lumi::Constants::n_velo_reco_counters],
      shifts_and_scales[2 * info_index],
      shifts_and_scales[2 * info_index + 1]);
  }
}
