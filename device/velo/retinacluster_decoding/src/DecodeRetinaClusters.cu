/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <DecodeRetinaClusters.cuh>
#include <VeloTools.cuh>
#include <BinarySearch.cuh>

__global__ void populate_module_pair_offsets_and_sizes(
  decode_retinaclusters::Parameters parameters,
  const unsigned module_pair_cluster_num_size)
{
  constexpr unsigned step_size =
    (Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module) / Velo::Constants::n_module_pairs;
  auto offsets = parameters.dev_offsets_each_sensor_size;

  for (unsigned element = threadIdx.x; element < module_pair_cluster_num_size; element += blockDim.x) {
    const auto current_offset_index = element * step_size;
    const auto next_offset_index = (element + 1) * step_size;

    parameters.dev_offsets_module_pair_cluster[element + 1] = offsets[next_offset_index];
    parameters.dev_module_pair_cluster_num[element] = offsets[next_offset_index] - offsets[current_offset_index];
  }
}

__device__ void put_retinaclusters_into_container(
  Velo::Clusters velo_cluster_container,
  VeloGeometry const& g,
  unsigned const cluster_index,
  const unsigned raw_bank_sensor_index,
  const unsigned raw_bank_word)
{
  const float* ltg = g.ltg + g.n_trans * raw_bank_sensor_index;

  // Decode cluster
  const uint32_t cx = (raw_bank_word >> 14) & 0x3FF;
  const float fx = ((raw_bank_word >> 11) & 0x7) / 8.f;
  const uint32_t cy = (raw_bank_word >> 3) & 0xFF;
  const float fy = (raw_bank_word & 0x7FF) / 8.f;

  const uint32_t chip = cx >> VP::ChipColumns_division;
  const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
  const float local_y = (0.5f + fy) * Velo::Constants::pixel_size;

  const float gx = (ltg[0] * local_x + ltg[1] * local_y + ltg[9]);
  const float gy = (ltg[3] * local_x + ltg[4] * local_y + ltg[10]);
  const float gz = (ltg[6] * local_x + ltg[7] * local_y + ltg[11]);
  const unsigned cid = get_channel_id(raw_bank_sensor_index, chip, cx & VP::ChipColumns_mask, cy);

  velo_cluster_container.set_id(cluster_index, get_lhcb_id(cid));
  velo_cluster_container.set_x(cluster_index, gx);
  velo_cluster_container.set_y(cluster_index, gy);
  velo_cluster_container.set_z(cluster_index, gz);
  velo_cluster_container.set_phi(cluster_index, hit_phi_16(gx, gy));
}

template<bool mep_layout>
__global__ void decode_retinaclusters_kernel(
  decode_retinaclusters::Parameters parameters,
  const VeloGeometry* dev_velo_geometry)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned* sensor_offsets = parameters.dev_offsets_each_sensor_size +
                                   event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;

  // Local pointers to parameters.dev_velo_cluster_container
  const unsigned total_number_of_clusters =
    parameters.dev_offsets_each_sensor_size
      [number_of_events * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module];

  auto velo_cluster_container = Velo::Clusters {parameters.dev_velo_cluster_container, total_number_of_clusters};
  if (threadIdx.x == 0 && threadIdx.y == 0) {
    parameters.dev_velo_clusters[event_number] = velo_cluster_container;
  }

  // Load Velo geometry (assume it is the same for all events)
  const VeloGeometry& g = *dev_velo_geometry;

  // Read raw event
  const auto velo_raw_event = Velo::RawEvent<mep_layout> {
    parameters.dev_velo_retina_raw_input, parameters.dev_velo_retina_raw_input_offsets, event_number};

  unsigned number_of_raw_banks = velo_raw_event.number_of_raw_banks();

  // Populate retina clusters
  const auto event_clusters_offset = sensor_offsets[0];
  const auto number_of_clusters_in_event =
    sensor_offsets[Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module] - event_clusters_offset;

  for (unsigned cluster_number = threadIdx.x; cluster_number < number_of_clusters_in_event;
       cluster_number += blockDim.x) {
    const unsigned raw_bank_number = binary_search_rightmost(
      sensor_offsets,
      Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module,
      cluster_number + event_clusters_offset);
    unsigned index_within_raw_bank = cluster_number - (sensor_offsets[raw_bank_number] - event_clusters_offset);
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);

    put_retinaclusters_into_container(
      velo_cluster_container,
      g,
      event_clusters_offset + cluster_number,
      raw_bank.sensor_index,
      raw_bank.word[index_within_raw_bank]);
  }
}

void decode_retinaclusters::decode_retinaclusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_module_cluster_num_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs);
  set_size<dev_velo_cluster_container_t>(
    arguments, first<host_total_number_of_velo_clusters_t>(arguments) * Velo::Clusters::element_size);
  set_size<dev_offsets_module_pair_cluster_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs + 1);
  set_size<dev_velo_clusters_t>(arguments, first<host_number_of_events_t>(arguments));
}

void decode_retinaclusters::decode_retinaclusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_module_cluster_num_t>(arguments, 0, context);
  initialize<dev_offsets_module_pair_cluster_t>(arguments, 0, context);

  global_function(
    runtime_options.mep_layout ? decode_retinaclusters_kernel<true> : decode_retinaclusters_kernel<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments, constants.dev_velo_geometry);

  global_function(populate_module_pair_offsets_and_sizes)(1, 1024, context)(
    arguments, size<dev_module_cluster_num_t>(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "VELO clusters after decode_retina_clusters:\n";
    print_velo_clusters<
      dev_velo_cluster_container_t,
      dev_offsets_module_pair_cluster_t,
      dev_module_cluster_num_t,
      host_total_number_of_velo_clusters_t,
      host_number_of_events_t>(arguments);
  }
}
