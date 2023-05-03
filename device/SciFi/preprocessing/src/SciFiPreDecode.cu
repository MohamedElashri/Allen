/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SciFiPreDecode.cuh"
#include <MEPTools.h>
#include "assert.h"

INSTANTIATE_ALGORITHM(scifi_pre_decode::scifi_pre_decode_t)

__device__ void store_sorted_cluster_reference(
  SciFi::ConstHitCount& hit_count,
  const uint32_t uniqueMat,
  const uint32_t chan,
  const uint32_t mat_offset,
  uint32_t& mat_count,
  const int raw_bank,
  const int it,
  uint32_t* cluster_references,
  const int condition,
  const int delta)
{
  uint32_t hitIndex = mat_count++;

  const SciFi::SciFiChannelID id {chan};
  assert(hitIndex < hit_count.mat_group_or_mat_number_of_hits(uniqueMat));
  if (id.reversedZone()) {
    hitIndex = hit_count.mat_group_or_mat_number_of_hits(uniqueMat) - 1 - hitIndex;
  }
  assert(uniqueMat < SciFi::Constants::n_mat_groups_and_mats);
  hitIndex += mat_offset;

  cluster_references[hitIndex] = SciFi::ClusterReference::makeClusterReference(raw_bank, it, condition, delta);
}

template<typename F>
__device__ void insertionSort(uint32_t* arr, int n, F&& f)
{
  for (int i = 1; i < n; i++) {
    uint32_t key = arr[i];
    int j = i - 1;
    while (j >= 0 && f(arr[j]) > f(key)) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

template<int decoding_version, bool mep_layout>
__global__ void scifi_pre_decode_kernel(
  scifi_pre_decode::Parameters parameters,
  const unsigned event_start,
  const char* scifi_geometry,
  unsigned* n_hits_in_mat_all_evts)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  unsigned* n_hits_in_mat = n_hits_in_mat_all_evts + event_number * SciFi::Constants::max_corrected_mat;

  SciFi::SciFiGeometry geom(scifi_geometry);
  const auto scifi_raw_event = SciFi::RawEvent<mep_layout>(
    parameters.dev_scifi_raw_input,
    parameters.dev_scifi_raw_input_offsets,
    parameters.dev_scifi_raw_input_sizes,
    event_number + event_start);

  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

  // Main execution loop
  for (unsigned iRawBank = threadIdx.x; iRawBank < scifi_raw_event.number_of_raw_banks(); iRawBank += blockDim.x) {
    auto rawbank = scifi_raw_event.raw_bank(iRawBank);
    const auto iRowInMap = SciFi::getRowInMap(rawbank, geom);
    if (iRowInMap == geom.number_of_banks) continue;
    const auto [starting_it_2, last] = SciFi::readAndCheckRawBank(rawbank);
    if (last == starting_it_2) continue;
    const auto starting_it = starting_it_2; // FIXME: necessary due to lambda capture issues
    const unsigned number_of_iterations = last - starting_it;
    int last_uniqueMat = -1;
    unsigned mat_offset = 0;
    [[maybe_unused]] bool reversedZone = false;
    for (unsigned it_number = 0; it_number < number_of_iterations; ++it_number) {
      auto it = starting_it + it_number;
      const uint16_t c = *it;
      uint32_t ch;
      if constexpr (decoding_version == 4 || decoding_version == 6) {
        ch = geom.bank_first_channel[iRawBank] + SciFi::channelInBank(c); //---LoH: only works for versions 4-6
      }
      else { // Decoding v7 and v8
        auto globalSiPM = SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c);
        if (globalSiPM == SciFi::SciFiChannelID::kInvalidChannelID) // Link not found or local link > 24. Should never
                                                                    // happen but seen in early data.
          continue;
        ch = globalSiPM + SciFi::channelInLink(c);
      }
      const auto chid = SciFi::SciFiChannelID(ch);
      uint32_t correctedMat = chid.globalMatIdx_Xorder();
      // adaptation to hybrid decoding
      if (correctedMat < SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank)
        correctedMat = correctedMat / SciFi::Constants::n_mats_per_consec_raw_bank;
      else
        correctedMat = correctedMat - SciFi::Constants::mat_index_substract;
      if ((int) correctedMat != last_uniqueMat) {
        if constexpr (decoding_version == 7 || decoding_version == 8) {
          if (
            last_uniqueMat != -1 &&
            n_hits_in_mat[correctedMat] == hit_count.mat_group_or_mat_number_of_hits(last_uniqueMat)) {
            // array is small and already almost sorted, using an insertion sort is enough
            if (reversedZone) {
              insertionSort(
                parameters.dev_cluster_references + mat_offset, n_hits_in_mat[correctedMat], [&](uint32_t val) {
                  const uint16_t c = starting_it[SciFi::ClusterReference::getICluster(val)];
                  return -(SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c) + SciFi::channelInLink(c));
                });
            }
            else {
              insertionSort(
                parameters.dev_cluster_references + mat_offset, n_hits_in_mat[correctedMat], [&](uint32_t val) {
                  const uint16_t c = starting_it[SciFi::ClusterReference::getICluster(val)];
                  return (SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c) + SciFi::channelInLink(c));
                });
            }
          }
        }
        last_uniqueMat = correctedMat;
        mat_offset = *hit_count.mat_offsets_p(correctedMat);
        reversedZone = chid.reversedZone();
      }
      const auto store_sorted_fn = [&](const int condition, const int delta) {
        store_sorted_cluster_reference(
          hit_count,
          correctedMat,
          ch,
          mat_offset,
          n_hits_in_mat[correctedMat],
          iRawBank,
          it_number,
          parameters.dev_cluster_references,
          condition,
          delta);
      };

      if constexpr (decoding_version == 4) {
        store_sorted_fn(SciFi::ClusterTypes::SmallCluster, 0x00);
      }
      else if constexpr (decoding_version >= 6) {
        if (!SciFi::cSize(c)) {
          // Single cluster
          store_sorted_fn(SciFi::ClusterTypes::SmallCluster, 0x00);
        }
        else {
          const unsigned c2 = *(it + 1);
          if (SciFi::lastClusterSiPM(c, c2, it, last))
            // last cluster in bank or in sipm
            store_sorted_fn(SciFi::ClusterTypes::LastCluster, 0x00);
          else if (SciFi::wellOrdered(c, c2) && SciFi::startLargeCluster<decoding_version>(c)) {
            if (SciFi::endLargeCluster<decoding_version>(c2)) {
              const unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
              if (widthClus > 8) {
                uint16_t j = 0;
                for (; j < widthClus - 4; j += 4)
                  // big cluster(s)
                  store_sorted_fn(SciFi::ClusterTypes::BigCluster, j);
                // add the last edge
                store_sorted_fn(SciFi::ClusterTypes::EdgeCluster, j);
              }
              else
                store_sorted_fn(SciFi::ClusterTypes::SizeLt8Cluster, 0x00);
              ++it_number;
            }
            else { /* Corrupt cluster type 1 */
              ++it_number;
            }
          }
          else { /* ERROR */
            if (!SciFi::wellOrdered(c, c2))
              ++it_number;
            else {
            }
          }
        }
      }
    }
    if constexpr (decoding_version == 7 || decoding_version == 8) {
      if (last_uniqueMat != -1 && hit_count.mat_group_or_mat_number_of_hits(last_uniqueMat)) {
        // array is small and already almost sorted, using an insertion sort is enough
        if (reversedZone) {
          insertionSort(
            parameters.dev_cluster_references + mat_offset, n_hits_in_mat[last_uniqueMat], [&](uint32_t val) {
              const uint16_t c = starting_it[SciFi::ClusterReference::getICluster(val)];
              return -(SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c) + SciFi::channelInLink(c));
            });
        }
        else {
          insertionSort(
            parameters.dev_cluster_references + mat_offset, n_hits_in_mat[last_uniqueMat], [&](uint32_t val) {
              const uint16_t c = starting_it[SciFi::ClusterReference::getICluster(val)];
              return (SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c) + SciFi::channelInLink(c));
            });
        }
      }
    }
  }
}

void scifi_pre_decode::scifi_pre_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Ensure the bank version is supported
  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data
  if (bank_version < 4 || bank_version > 8) {
    throw StrException("SciFi bank version not supported (" + std::to_string(bank_version) + ")");
  }

  set_size<dev_cluster_references_t>(
    arguments, first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays);
}

void scifi_pre_decode::scifi_pre_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data

  // Mapping is:
  // * Version 4, version 5: Use v4 decoding
  // * Version 6: Use v6 decoding
  auto n_hits_in_mat = make_device_buffer<unsigned>(
    arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::max_corrected_mat);
  Allen::memset_async(n_hits_in_mat.data(), 0, n_hits_in_mat.size() * sizeof(unsigned), context);

  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<4, true>) :
                                                   global_function(scifi_pre_decode_kernel<4, false>)) :
                     (bank_version == 6) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<6, true>) :
                                                   global_function(scifi_pre_decode_kernel<6, false>)) :
                     (bank_version == 7) ?
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<7, true>) :
                                                   global_function(scifi_pre_decode_kernel<7, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_pre_decode_kernel<8, true>) :
                                                   global_function(scifi_pre_decode_kernel<8, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), dim3(SciFi::SciFiRawBankParams::NbBanksMax), context)(
    arguments, std::get<0>(runtime_options.event_interval), constants.dev_scifi_geometry, n_hits_in_mat.data());
}
