#include "SciFiCalculateClusterCountV6.cuh"
#include <MEPTools.h>

using namespace SciFi;

__global__ void scifi_calculate_cluster_count_v6::scifi_calculate_cluster_count_v6(
  scifi_calculate_cluster_count_v6::Parameters parameters,
  const char* scifi_geometry)
{
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  const SciFiRawEvent event(parameters.dev_scifi_raw_input + parameters.dev_scifi_raw_input_offsets[selected_event_number]);
  const SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  // NO version checking. Be careful, as v6 is assumed.

  for (uint i = threadIdx.x; i < event.number_of_raw_banks; i += blockDim.x) {
    const uint current_raw_bank = getRawBankIndexOrderedByX(i);
    uint32_t* hits_module;
    const auto rawbank = event.getSciFiRawBank(current_raw_bank);
    uint16_t* it = rawbank.data + 2;
    uint16_t* last = rawbank.last;

    // For details see RawBankDecoder
    if (*(last - 1) == 0) --last; // Remove padding at the end
    for (; it < last; ++it) {     // loop over the clusters
      uint16_t c = *it;
      uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);

      const auto chid = SciFiChannelID(ch);
      const uint32_t uniqueMat = chid.correctedUniqueMat();
      uint uniqueGroupOrMat;
      if (uniqueMat < SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank)
        uniqueGroupOrMat = uniqueMat / SciFi::Constants::n_mats_per_consec_raw_bank;
      else
        uniqueGroupOrMat = uniqueMat - SciFi::Constants::mat_index_substract;

      hits_module = hit_count.mat_offsets_p(uniqueGroupOrMat);
      
      if (!cSize(c)) { // Not flagged as large
        atomicAdd(hits_module, 1);
      }
      else if (fraction(c)) { // flagged as first edge of large cluster
        // last cluster in bank or in sipm
        if (it + 1 == last || getLinkInBank(c) != getLinkInBank(*(it + 1)))
          atomicAdd(hits_module, 1);
        else {
          unsigned c2 = *(it + 1);
          assert(cSize(c2) && !fraction(c2));
          unsigned int widthClus = (cell(c2) - cell(c) + 2);
          if (widthClus > 8)
            // number of for loop passes in decoder + one additional
            atomicAdd(hits_module, (widthClus - 1) / 4 + 1);
          else
            atomicAdd(hits_module, 1);
          ++it;
        }
      }
    }
  }
}

__global__ void scifi_calculate_cluster_count_v6::scifi_calculate_cluster_count_v6_mep(
  scifi_calculate_cluster_count_v6::Parameters parameters,
  const char* scifi_geometry)
{
  const uint event_number = blockIdx.x;
  const uint selected_event_number = parameters.dev_event_list[event_number];

  const SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  auto const n_scifi_banks = MEP::number_of_banks(parameters.dev_scifi_raw_input_offsets);

  // NO version checking. Be careful, as v6 is assumed.

  for (uint i = threadIdx.x; i < n_scifi_banks; i += blockDim.x) {
    uint32_t* hits_module;

    // Create SciFi raw bank from MEP layout
    auto const rawbank = MEP::raw_bank<SciFiRawBank>(parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets,
                                                      selected_event_number, i);

    uint16_t* it = rawbank.data + 2;
    uint16_t* last = rawbank.last;

    // For details see RawBankDecoder
    if (*(last - 1) == 0) --last; // Remove padding at the end
    for (; it < last; ++it) {     // loop over the clusters
      uint16_t c = *it;
      uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);
      if (i < SciFi::Constants::n_consecutive_raw_banks)
        hits_module = hit_count.mat_offsets_p(i);
      else
        hits_module =
          hit_count.mat_offsets_p(SciFiChannelID(ch).correctedUniqueMat() - SciFi::Constants::mat_index_substract);
      if (!cSize(c)) { // Not flagged as large
        atomicAdd(hits_module, 1);
      }
      else if (fraction(c)) { // flagged as first edge of large cluster
        // last cluster in bank or in sipm
        if (it + 1 == last || getLinkInBank(c) != getLinkInBank(*(it + 1)))
          atomicAdd(hits_module, 1);
        else {
          unsigned c2 = *(it + 1);
          assert(cSize(c2) && !fraction(c2));
          unsigned int widthClus = (cell(c2) - cell(c) + 2);
          if (widthClus > 8)
            // number of for loop passes in decoder + one additional
            atomicAdd(hits_module, (widthClus - 1) / 4 + 1);
          else
            atomicAdd(hits_module, 1);
          ++it;
        }
      }
    }
  }
}
