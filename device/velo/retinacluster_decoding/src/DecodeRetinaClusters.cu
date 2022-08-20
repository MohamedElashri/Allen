/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <DecodeRetinaClusters.cuh>
#include <VeloTools.cuh>
#include <BinarySearch.cuh>

INSTANTIATE_ALGORITHM(decode_retinaclusters::decode_retinaclusters_t)

template<int decoding_version>
__global__ void populate_module_pair_offsets_and_sizes(
  decode_retinaclusters::Parameters parameters,
  const unsigned module_pair_cluster_num_size)
{
  unsigned step_size;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    step_size = (Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module) / Velo::Constants::n_module_pairs;
  }
  else {
    step_size =
      (Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2) / Velo::Constants::n_module_pairs;
  }

  auto offsets = parameters.dev_offsets_each_sensor_pair_size;

  for (unsigned i = threadIdx.x; i < Velo::Tracking::block_dim_x_populate_module_pair_offsets_and_sizes;
       i += blockDim.x) {
    const auto element = blockIdx.x * Velo::Tracking::block_dim_x_populate_module_pair_offsets_and_sizes + i;
    if (element < module_pair_cluster_num_size) {
      //       const auto current_offset_index = element * step_size;
      const auto next_offset_index = (element + 1) * step_size;

      parameters.dev_offsets_module_pair_cluster[element + 1] = offsets[next_offset_index];
      //       parameters.dev_module_pair_cluster_num[element] = offsets[next_offset_index] -
      //       offsets[current_offset_index];
    }
  }
}

template<bool mep_layout>
__global__ void velo_calculate_permutations(decode_retinaclusters::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned* module_pair_hit_start =
    parameters.dev_offsets_module_pair_cluster + event_number * Velo::Constants::n_module_pairs;
  const unsigned* module_pair_hit_num =
    parameters.dev_module_pair_cluster_num + event_number * Velo::Constants::n_module_pairs;

  for (unsigned module_pair = threadIdx.x; module_pair < Velo::Constants::n_module_pairs; module_pair += blockDim.x) {
    const auto hit_start = module_pair_hit_start[module_pair];
    const auto hit_num = module_pair_hit_num[module_pair];

    // Decrease divergences
    __syncthreads();

    // Find the permutations with sorting key
    // Use insertion sort
    for (unsigned hit_rel_id = threadIdx.y; hit_rel_id < hit_num; hit_rel_id += blockDim.y) {
      const auto hit_index = hit_start + hit_rel_id;
      const auto key = parameters.dev_hit_sorting_key[hit_index];

      unsigned position = 0;
      for (unsigned j = 0; j < hit_num; ++j) {
        if (hit_rel_id == j) continue;

        const auto other_hit_index = hit_start + j;
        const auto other_key = parameters.dev_hit_sorting_key[other_hit_index];

        // Ensure sorting is reproducible
        position += key > other_key;
      }

      // Store it in hit permutations
      const auto global_position = hit_start + position;
      parameters.dev_hit_permutations[hit_index] = global_position;
    }
  }
}

template<int decoding_version>
__device__ void populate_sorting_key(
  int64_t* hit_sorting_key,
  VeloGeometry const& g,
  unsigned const cluster_index,
  const unsigned raw_bank_sensor_index0,
  const unsigned raw_bank_sensor_index1,
  const unsigned raw_bank_sourceID,
  const unsigned raw_bank_word,
  unsigned* module_pair_cluster_num)
{
  unsigned raw_bank_sensor_index;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    raw_bank_sensor_index = raw_bank_sourceID;
  }
  else {
    raw_bank_sensor_index = raw_bank_sensor_index0;
    if ((raw_bank_word >> 22) & 0x1) {
      raw_bank_sensor_index = raw_bank_sensor_index1;
    }
  }

  if (raw_bank_word != 0) {
    atomicAdd(module_pair_cluster_num + raw_bank_sensor_index / 8, 1);
  }

  const float* ltg = g.ltg + g.n_trans * raw_bank_sensor_index;

  uint32_t cx, cy, or_fx, or_fy;
  float fx, fy;

  // Decode cluster
  if constexpr (decoding_version == 2) {
    cx = (raw_bank_word >> 14) & 0x3FF;
    fx = ((raw_bank_word >> 11) & 0x7) / 8.f;
    cy = (raw_bank_word >> 3) & 0xFF;
    fy = (raw_bank_word & 0x7FF) / 8.f;
    or_fx = (0);
    or_fy = (0);
  }
  else {
    cx = (raw_bank_word >> 12) & 0x3FF;
    uint32_t cx_frac_half = (raw_bank_word >> 11) & 0x1;
    uint32_t cx_frac_quarter = (raw_bank_word >> 10) & 0x1;
    fx = ((raw_bank_word >> 10) & 0x3) / 4.f;
    cy = (raw_bank_word >> 2) & 0xFF;
    uint32_t cy_frac_half = (raw_bank_word >> 1) & 0x1;
    uint32_t cy_frac_quarter = (raw_bank_word) &0x1;
    fy = (raw_bank_word & 0x3FF) / 4.f;

    or_fx = (cx_frac_half | cx_frac_quarter);
    or_fy = (cy_frac_half | cy_frac_quarter);
  }

  // Decode ID
  const uint32_t chip = cx >> VP::ChipColumns_division;
  const unsigned cid = get_channel_id(raw_bank_sensor_index, chip, cx & VP::ChipColumns_mask, cy, or_fx, or_fy);
  const uint32_t id = get_lhcb_id(cid);

  // Calculate phi
  const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
  const float local_y = (0.5f + fy) * Velo::Constants::pixel_size;
  const float gx = (ltg[0] * local_x + ltg[1] * local_y + ltg[9]);
  const float gy = (ltg[3] * local_x + ltg[4] * local_y + ltg[10]);
  const int16_t phi = hit_phi_16(gx, gy);

  // Create sorting key
  int64_t sorting_key = 0xFFFFFFFF;
  if (raw_bank_word != 0) {
    sorting_key = static_cast<int64_t>(phi) << 48 | id;
  }

  hit_sorting_key[cluster_index] = sorting_key;
}

template<int decoding_version, bool mep_layout>
__global__ void velo_calculate_sorting_key(
  decode_retinaclusters::Parameters parameters,
  const VeloGeometry* dev_velo_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  unsigned offset;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    offset = event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
  }
  else {
    offset = event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2;
  }

  unsigned* module_pair_cluster_num =
    parameters.dev_module_pair_cluster_num + event_number * Velo::Constants::n_module_pairs;

  const unsigned* sensor_pair_offsets = parameters.dev_offsets_each_sensor_pair_size + offset;

  // Load Velo geometry (assume it is the same for all events)
  const VeloGeometry& g = *dev_velo_geometry;

  // Read raw event
  const auto velo_raw_event =
    Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_retina_raw_input,
                                                  parameters.dev_velo_retina_raw_input_offsets,
                                                  parameters.dev_velo_retina_raw_input_sizes,
                                                  parameters.dev_velo_retina_raw_input_types,
                                                  event_number};

  // Populate retina clusters
  const auto event_clusters_offset = sensor_pair_offsets[0];
  unsigned number_of_clusters_in_event;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    number_of_clusters_in_event =
      sensor_pair_offsets[Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module] - event_clusters_offset;
  }
  else {
    number_of_clusters_in_event =
      sensor_pair_offsets[Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2] -
      event_clusters_offset;
  }

  for (unsigned cluster_number = threadIdx.x; cluster_number < number_of_clusters_in_event;
       cluster_number += blockDim.x) {
    unsigned sensor_pair = 0;
    if constexpr (decoding_version == 2 || decoding_version == 3) {
      sensor_pair = binary_search_rightmost(
        sensor_pair_offsets,
        Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module,
        cluster_number + event_clusters_offset);
    }
    else {
      sensor_pair = binary_search_rightmost(
        sensor_pair_offsets,
        Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2,
        cluster_number + event_clusters_offset);
    }
    unsigned raw_bank_number = parameters.dev_retina_bank_index[sensor_pair];

    unsigned index_within_raw_bank = cluster_number - (sensor_pair_offsets[sensor_pair] - event_clusters_offset);
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);
    if (raw_bank.type == LHCb::RawBank::VPRetinaCluster) {
      populate_sorting_key<decoding_version>(
        parameters.dev_hit_sorting_key,
        g,
        event_clusters_offset + cluster_number,
        raw_bank.sensor_index0(),
        raw_bank.sensor_index1(),
        raw_bank.sourceID,
        raw_bank.word[index_within_raw_bank],
        module_pair_cluster_num);
    }
  }
}

template<int decoding_version>
__device__ void populate_retinacluster(
  Velo::Clusters& velo_cluster_container,
  VeloGeometry const& g,
  unsigned const cluster_index,
  const unsigned raw_bank_sensor_index0,
  const unsigned raw_bank_sensor_index1,
  const unsigned raw_bank_sourceID,
  const unsigned raw_bank_word)
{
  unsigned raw_bank_sensor_index;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    raw_bank_sensor_index = raw_bank_sourceID;
  }
  else {
    raw_bank_sensor_index = raw_bank_sensor_index0;
    if ((raw_bank_word >> 22) & 0x1) {
      raw_bank_sensor_index = raw_bank_sensor_index1;
    }
  }
  const float* ltg = g.ltg + g.n_trans * raw_bank_sensor_index;

  uint32_t cx, cy, or_fx, or_fy;
  float fx, fy;

  // Decode cluster
  if constexpr (decoding_version == 2) {
    cx = (raw_bank_word >> 14) & 0x3FF;
    fx = ((raw_bank_word >> 11) & 0x7) / 8.f;
    cy = (raw_bank_word >> 3) & 0xFF;
    fy = (raw_bank_word & 0x7FF) / 8.f;
    or_fx = (0);
    or_fy = (0);
  }
  else {
    cx = (raw_bank_word >> 12) & 0x3FF;
    uint32_t cx_frac_half = (raw_bank_word >> 11) & 0x1;
    uint32_t cx_frac_quarter = (raw_bank_word >> 10) & 0x1;
    fx = ((raw_bank_word >> 10) & 0x3) / 4.f;
    cy = (raw_bank_word >> 2) & 0xFF;
    uint32_t cy_frac_half = (raw_bank_word >> 1) & 0x1;
    uint32_t cy_frac_quarter = (raw_bank_word) &0x1;
    fy = (raw_bank_word & 0x3FF) / 4.f;

    or_fx = (cx_frac_half | cx_frac_quarter);
    or_fy = (cy_frac_half | cy_frac_quarter);
  }

  const uint32_t chip = cx >> VP::ChipColumns_division;
  const float local_x = g.local_x[cx] + fx * g.x_pitch[cx];
  const float local_y = (0.5f + fy) * Velo::Constants::pixel_size;

  const float gx = (ltg[0] * local_x + ltg[1] * local_y + ltg[9]);
  const float gy = (ltg[3] * local_x + ltg[4] * local_y + ltg[10]);
  const float gz = (ltg[6] * local_x + ltg[7] * local_y + ltg[11]);

  const unsigned cid = get_channel_id(raw_bank_sensor_index, chip, cx & VP::ChipColumns_mask, cy, or_fx, or_fy);

  velo_cluster_container.set_id(cluster_index, get_lhcb_id(cid));
  velo_cluster_container.set_x(cluster_index, gx);
  velo_cluster_container.set_y(cluster_index, gy);
  velo_cluster_container.set_z(cluster_index, gz);
  velo_cluster_container.set_phi(cluster_index, hit_phi_16(gx, gy));
}

template<int decoding_version, bool mep_layout>
__global__ void decode_retinaclusters_sorted(
  decode_retinaclusters::Parameters parameters,
  const VeloGeometry* dev_velo_geometry)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  unsigned offset;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    offset = event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module;
  }
  else {
    offset = event_number * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2;
  }

  const unsigned* sensor_pair_offsets = parameters.dev_offsets_each_sensor_pair_size + offset;

  // Local pointers to parameters.dev_velo_cluster_container
  unsigned total_number_of_clusters;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    total_number_of_clusters =
      parameters.dev_offsets_each_sensor_pair_size
        [number_of_events * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module];
  }
  else {
    total_number_of_clusters =
      parameters.dev_offsets_each_sensor_pair_size
        [number_of_events * Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2];
  }

  auto velo_cluster_container = Velo::Clusters {parameters.dev_velo_cluster_container, total_number_of_clusters};
  if (threadIdx.x == 0 && threadIdx.y == 0) {
    parameters.dev_velo_clusters[event_number] = velo_cluster_container;
  }

  // Load Velo geometry (assume it is the same for all events)
  const VeloGeometry& g = *dev_velo_geometry;

  // Read raw event
  const auto velo_raw_event =
    Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_retina_raw_input,
                                                  parameters.dev_velo_retina_raw_input_offsets,
                                                  parameters.dev_velo_retina_raw_input_sizes,
                                                  parameters.dev_velo_retina_raw_input_types,
                                                  event_number};

  // Populate retina clusters
  const auto event_clusters_offset = sensor_pair_offsets[0];

  unsigned number_of_clusters_in_event = 0;
  if constexpr (decoding_version == 2 || decoding_version == 3) {
    number_of_clusters_in_event =
      sensor_pair_offsets[Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module] - event_clusters_offset;
  }
  else {
    number_of_clusters_in_event =
      sensor_pair_offsets[Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2] -
      event_clusters_offset;
  }

  for (unsigned i = threadIdx.x; i < number_of_clusters_in_event; i += blockDim.x) {
    const auto cluster_number = event_clusters_offset + i;

    unsigned sensor_pair = 0;
    if constexpr (decoding_version == 2 || decoding_version == 3) {
      sensor_pair = binary_search_rightmost(
        sensor_pair_offsets, Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module, cluster_number);
    }
    else {
      sensor_pair = binary_search_rightmost(
        sensor_pair_offsets, Velo::Constants::n_modules * Velo::Constants::n_sensors_per_module / 2, cluster_number);
    }
    unsigned raw_bank_number = parameters.dev_retina_bank_index[sensor_pair];

    unsigned index_within_raw_bank = cluster_number - sensor_pair_offsets[sensor_pair];
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);
    if (raw_bank.type == LHCb::RawBank::VPRetinaCluster) {
      populate_retinacluster<decoding_version>(
        velo_cluster_container,
        g,
        parameters.dev_hit_permutations[cluster_number],
        raw_bank.sensor_index0(),
        raw_bank.sensor_index1(),
        raw_bank.sourceID,
        raw_bank.word[index_within_raw_bank]);
    }
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
  set_size<dev_hit_permutations_t>(arguments, first<host_total_number_of_velo_clusters_t>(arguments));
  set_size<dev_hit_sorting_key_t>(arguments, first<host_total_number_of_velo_clusters_t>(arguments));
}

void decode_retinaclusters::decode_retinaclusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_module_cluster_num_t>(arguments, 0, context);
  Allen::memset_async<dev_offsets_module_pair_cluster_t>(arguments, 0, context);

  // Ensure the bank version is supported
  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no VP banks present in data

  if (bank_version != 2 && bank_version != 3 && bank_version != 4) {
    throw StrException("Velo cluster bank version not supported (" + std::to_string(bank_version) + ")");
  }

  const auto grid_dim_x = (size<dev_module_cluster_num_t>(arguments) +
                           Velo::Tracking::block_dim_x_populate_module_pair_offsets_and_sizes - 1) /
                          Velo::Tracking::block_dim_x_populate_module_pair_offsets_and_sizes;

  auto kernel_fn0 = (bank_version == 2) ?
                      (global_function(populate_module_pair_offsets_and_sizes<2>)) :
                      (bank_version == 3) ? (global_function(populate_module_pair_offsets_and_sizes<3>)) :
                                            (global_function(populate_module_pair_offsets_and_sizes<4>));

  kernel_fn0(grid_dim_x, Velo::Tracking::block_dim_x_populate_module_pair_offsets_and_sizes, context)(
    arguments, size<dev_module_cluster_num_t>(arguments));

  auto kernel_fn1 = (bank_version == 2) ?
                      (runtime_options.mep_layout ? global_function(velo_calculate_sorting_key<2, true>) :
                                                    global_function(velo_calculate_sorting_key<2, false>)) :
                      (bank_version == 3) ?
                      (runtime_options.mep_layout ? global_function(velo_calculate_sorting_key<3, true>) :
                                                    global_function(velo_calculate_sorting_key<3, false>)) :
                      (runtime_options.mep_layout ? global_function(velo_calculate_sorting_key<4, true>) :
                                                    global_function(velo_calculate_sorting_key<4, false>));

  kernel_fn1(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_calculate_key_t>().get(), context)(
    arguments, constants.dev_velo_geometry);

  global_function(runtime_options.mep_layout ? velo_calculate_permutations<true> : velo_calculate_permutations<false>)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_calculate_permutations_t>(), context)(arguments);

  auto kernel_fn3 = (bank_version == 2) ?
                      (runtime_options.mep_layout ? global_function(decode_retinaclusters_sorted<2, true>) :
                                                    global_function(decode_retinaclusters_sorted<2, false>)) :
                      (bank_version == 3) ?
                      (runtime_options.mep_layout ? global_function(decode_retinaclusters_sorted<3, true>) :
                                                    global_function(decode_retinaclusters_sorted<3, false>)) :
                      (runtime_options.mep_layout ? global_function(decode_retinaclusters_sorted<4, true>) :
                                                    global_function(decode_retinaclusters_sorted<4, false>));

  kernel_fn3(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_decode_retina_t>().get(), context)(
    arguments, constants.dev_velo_geometry);

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "VELO clusters after decode_retina_clusters:\n";
    print_velo_clusters<
      dev_velo_cluster_container_t,
      dev_offsets_module_pair_cluster_t,
      dev_module_cluster_num_t,
      host_total_number_of_velo_clusters_t,
      host_number_of_events_t>(arguments, context);
  }
}
