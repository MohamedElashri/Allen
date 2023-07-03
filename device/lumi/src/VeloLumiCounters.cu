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
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();

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

  global_function(velo_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments), m_offsets_and_sizes, m_shifts_and_scales);
}

__global__ void velo_lumi_counters::velo_lumi_counters(
  velo_lumi_counters::Parameters parameters,
  const unsigned number_of_events,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    std::array<unsigned, 10> velo_counters = {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};

    const auto velo_states = parameters.dev_velo_states_view[event_number];
    // first counter is the total velo tracks
    const unsigned track_offset = parameters.dev_offsets_all_velo_tracks[event_number];
    velo_counters[0] = parameters.dev_offsets_all_velo_tracks[event_number + 1] - track_offset;

    for (unsigned track_index = 0u; track_index < velo_counters[0]; ++track_index) {
      const auto velo_state = velo_states.state(track_index);

      // fiducial cut: doca<3 mm && |poca|<300 mm
      if (velo_state.z() > -300.f && velo_state.z() < 300.f) {
        if (velo_DOCAz(velo_state) < 3.f * Gaudi::Units::mm) {
          ++velo_counters[1];
        }
      }

      // fill eta bins
      float eta = velo_eta(velo_state, parameters.dev_is_backward[track_offset + track_index]);
      if (eta > parameters.tracks_eta_bins.get()[Lumi::Constants::n_velo_eta_bin_edges - 1u] * Gaudi::Units::mm) {
        ++velo_counters[9];
        continue;
      }
      for (unsigned eta_bin = 0; eta_bin < Lumi::Constants::n_velo_eta_bin_edges; ++eta_bin) {
        if (eta < parameters.tracks_eta_bins.get()[eta_bin] * Gaudi::Units::mm) {
          ++velo_counters[2u + eta_bin];
          break;
        }
      }
    }

    unsigned info_offset = Lumi::Constants::n_velo_counters * lumi_evt_index;

    for (unsigned info_index = 0u; info_index < Lumi::Constants::n_velo_counters; ++info_index) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + info_index],
        offsets_and_sizes[info_index * 2],
        offsets_and_sizes[info_index * 2 + 1],
        velo_counters[info_index],
        shifts_and_scales[2 * info_index],
        shifts_and_scales[2 * info_index + 1]);
    }
  }
}
