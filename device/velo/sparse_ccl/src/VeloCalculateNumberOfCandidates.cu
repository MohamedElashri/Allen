/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <MEPTools.h>
#include <VeloCalculateNumberOfCandidates.cuh>
#include <PrefixSum.cuh>
#include <SegSort.h>

INSTANTIATE_ALGORITHM(velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t)

template<int decoding_version, bool mep_layout>
__global__ void velo_count_sp_per_sensor(
  velo_calculate_number_of_candidates::Parameters parameters,
  const unsigned event_start)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_raw_event = Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_raw_input,
                                                                            parameters.dev_velo_raw_input_offsets,
                                                                            parameters.dev_velo_raw_input_sizes,
                                                                            parameters.dev_velo_raw_input_types,
                                                                            event_number + event_start};

  for (unsigned raw_bank_number = threadIdx.y; raw_bank_number < velo_raw_event.number_of_raw_banks();
       raw_bank_number += blockDim.y) {
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);

    unsigned* superpixels_offsets = parameters.dev_superpixels_offsets + event_number * Velo::Constants::n_sensors;

    if (raw_bank.type != LHCb::RawBank::VP && raw_bank.type != LHCb::RawBank::Velo) continue;

    if constexpr (decoding_version == 2 || decoding_version == 3) {
      unsigned number_of_sp = raw_bank.count;
      if (threadIdx.x == 0) {
        superpixels_offsets[raw_bank.sensor_pair()] = number_of_sp;
      }
    }
    else {
      unsigned number_of_sp = raw_bank.size / 4;

      unsigned sensor0_count = 0;
      unsigned sensor1_count = 0;
      for (unsigned sp_index = threadIdx.x; sp_index < number_of_sp; sp_index += blockDim.x) {
        unsigned sp_word = raw_bank.word[sp_index];
        unsigned sp = sp_word & 0xFF;
        unsigned sensor_bit = (sp_word >> 23) & 0x1;

        if (sp == 0) continue;

        unsigned count = VP::number_of_clusters_in_SP(sp); // One or 2 clusters ?
        if (sensor_bit == 0) {
          sensor0_count += count;
        }
        else {
          sensor1_count += count;
        }
      }
      atomicAdd(&superpixels_offsets[raw_bank.sensor_index0()], sensor0_count);
      atomicAdd(&superpixels_offsets[raw_bank.sensor_index1()], sensor1_count);
    }
  }
}

template<int decoding_version, bool mep_layout>
__global__ void velo_partition_superpixels(
  velo_calculate_number_of_candidates::Parameters parameters,
  const unsigned event_start)
{
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto velo_raw_event = Velo::RawEvent<decoding_version, mep_layout> {parameters.dev_velo_raw_input,
                                                                            parameters.dev_velo_raw_input_offsets,
                                                                            parameters.dev_velo_raw_input_sizes,
                                                                            parameters.dev_velo_raw_input_types,
                                                                            event_number + event_start};
  __shared__ unsigned sensor_index[Velo::Constants::n_sensors];
  for (unsigned i = threadIdx.y * blockDim.x + threadIdx.x; i < Velo::Constants::n_sensors;
       i += blockDim.y * blockDim.x) {
    sensor_index[i] = 0;
  }
  __syncthreads();

  for (unsigned raw_bank_number = threadIdx.y; raw_bank_number < velo_raw_event.number_of_raw_banks();
       raw_bank_number += blockDim.y) {
    const auto raw_bank = velo_raw_event.raw_bank(raw_bank_number);

    unsigned* superpixels_offsets = parameters.dev_superpixels_offsets + event_number * Velo::Constants::n_sensors;

    if (raw_bank.type != LHCb::RawBank::VP && raw_bank.type != LHCb::RawBank::Velo) continue;

    if constexpr (decoding_version == 2 || decoding_version == 3) {
      unsigned number_of_sp = raw_bank.count;
      unsigned* out_sp = parameters.dev_superpixels + superpixels_offsets[raw_bank.sensor_pair()];
      for (unsigned sp_index = threadIdx.x; sp_index < number_of_sp; sp_index += blockDim.x) {
        out_sp[sp_index] = raw_bank.word[sp_index] | (raw_bank.sensor_pair() << 24);
      }
    }
    else {
      unsigned number_of_sp = raw_bank.size / 4;

      unsigned sensor_base = raw_bank.sensor_index0();
      unsigned* out_sensor0 = parameters.dev_superpixels + superpixels_offsets[raw_bank.sensor_index0()];
      unsigned* out_sensor1 = parameters.dev_superpixels + superpixels_offsets[raw_bank.sensor_index1()];

      for (unsigned sp_index = threadIdx.x; sp_index < number_of_sp; sp_index += blockDim.x) {
        unsigned sp_word = raw_bank.word[sp_index];
        unsigned sp = sp_word & 0xFF;
        unsigned sensor_bit = (sp_word >> 23) & 0x1;

        if (sp == 0) continue;

        sp_word |= (sensor_base + sensor_bit) << 24;

        unsigned count = VP::number_of_clusters_in_SP(sp); // One or 2 clusters ?
        unsigned out_index = atomicAdd(&sensor_index[sensor_base + sensor_bit], count);
        if (count == 1) {
          if (sensor_bit == 0)
            out_sensor0[out_index] = sp_word;
          else
            out_sensor1[out_index] = sp_word;
        }
        else {
          if (sensor_bit == 0) {
            out_sensor0[out_index] = sp_word & ~0x33;
            out_sensor0[out_index + 1] = sp_word & ~0xCC;
          }
          else {
            out_sensor1[out_index] = sp_word & ~0x33;
            out_sensor1[out_index + 1] = sp_word & ~0xCC;
          }
        }
      }
    }
  }
}

__global__ void make_module_pair_offset(
  velo_calculate_number_of_candidates::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned i = blockIdx.x * blockDim.x + threadIdx.x; i <= number_of_events * Velo::Constants::n_module_pairs;
       i += blockDim.x * gridDim.x) {
    parameters.dev_superpixels_module_pair_offsets[i] = parameters.dev_superpixels_offsets[i * 8];
  }
}

void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_superpixels_t>(
    arguments, 1); // this will get resized, set_size to avoid warning (the allocator will set size to 1 anyway)
  set_size<dev_superpixels_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_sensors + 1);
  set_size<dev_superpixels_module_pair_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs + 1);
  set_size<host_total_number_of_superpixels_t>(arguments, 1);
}

void velo_calculate_number_of_candidates::velo_calculate_number_of_candidates_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_superpixels_offsets_t>(arguments, 0, context);
  Allen::memset_async<host_total_number_of_superpixels_t>(arguments, 0, context);

  const auto bank_version = first<host_raw_bank_version_t>(arguments);

  if (bank_version < 0) return; // no VP banks present in data

  auto count_fn = (bank_version == 2) ?
                    (runtime_options.mep_layout ? global_function(velo_count_sp_per_sensor<2, true>) :
                                                  global_function(velo_count_sp_per_sensor<2, false>)) :
                    (bank_version == 3) ?
                    (runtime_options.mep_layout ? global_function(velo_count_sp_per_sensor<3, true>) :
                                                  global_function(velo_count_sp_per_sensor<3, false>)) :
                    (runtime_options.mep_layout ? global_function(velo_count_sp_per_sensor<4, true>) :
                                                  global_function(velo_count_sp_per_sensor<4, false>));

  auto partition_fn = (bank_version == 2) ?
                        (runtime_options.mep_layout ? global_function(velo_partition_superpixels<2, true>) :
                                                      global_function(velo_partition_superpixels<2, false>)) :
                        (bank_version == 3) ?
                        (runtime_options.mep_layout ? global_function(velo_partition_superpixels<3, true>) :
                                                      global_function(velo_partition_superpixels<3, false>)) :
                        (runtime_options.mep_layout ? global_function(velo_partition_superpixels<4, true>) :
                                                      global_function(velo_partition_superpixels<4, false>));

  count_fn(dim3(size<dev_event_list_t>(arguments)), dim3(16, 16), context)(
    arguments, std::get<0>(runtime_options.event_interval));

  PrefixSum::prefix_sum<dev_superpixels_offsets_t, host_total_number_of_superpixels_t>(*this, arguments, context);

  resize<dev_superpixels_t>(arguments, first<host_total_number_of_superpixels_t>(arguments));

  partition_fn(dim3(size<dev_event_list_t>(arguments)), dim3(16, 16), context)(
    arguments, std::get<0>(runtime_options.event_interval));

  global_function(make_module_pair_offset)(
    dim3((first<host_number_of_events_t>(arguments) * Velo::Constants::n_module_pairs + 256) / 256),
    dim3(256),
    context)(arguments, first<host_number_of_events_t>(arguments));

  SegSort::segsort_keys<uint32_t>(
    *this,
    arguments,
    context,
    data<dev_superpixels_t>(arguments),
    data<dev_superpixels_module_pair_offsets_t>(arguments),
    size<dev_superpixels_module_pair_offsets_t>(arguments) - 1);
}
