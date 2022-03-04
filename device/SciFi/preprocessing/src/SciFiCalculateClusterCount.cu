/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <SciFiCalculateClusterCount.cuh>

INSTANTIATE_ALGORITHM(scifi_calculate_cluster_count::scifi_calculate_cluster_count_t)

/**
 * @brief This function calculates the amount of clusters in all mats.
 * @details More details about the SciFi format:
 *          https://cds.cern.ch/record/2630154/files/LHCb-INT-2018-024.pdf
 *
 * Kernel for decoding from MEP layout
 */
template<int decoding_version, bool mep_layout>
__global__ void scifi_calculate_cluster_count_kernel(
  scifi_calculate_cluster_count::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto scifi_raw_event =
    SciFi::RawEvent<mep_layout>(parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, parameters.dev_scifi_raw_input_sizes, event_number);
  const SciFi::SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};

  // NO version checking of the decoding - to be improved later
  for (unsigned i = threadIdx.x; i < scifi_raw_event.number_of_raw_banks(); i += blockDim.x) {
    const unsigned current_raw_bank = SciFi::getRawBankIndexOrderedByX(i);
    uint32_t* hits_module = nullptr;
    const auto rawbank = scifi_raw_event.raw_bank(current_raw_bank);
    uint16_t const* it = rawbank.data + 2;
    uint16_t const* last = rawbank.last;

    // For details see RawBankDecoder
    if (*(last - 1) == 0) --last; // Remove padding at the end
    for (; it < last; ++it) {     // loop over the clusters
      uint16_t c = *it;
      uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + SciFi::channelInBank(c);

      const auto chid = SciFi::SciFiChannelID(ch);
      const uint32_t uniqueMat = chid.correctedUniqueMat();
      unsigned uniqueGroupOrMat;
      if (uniqueMat < SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank)
        uniqueGroupOrMat = uniqueMat / SciFi::Constants::n_mats_per_consec_raw_bank;
      else
        uniqueGroupOrMat = uniqueMat - SciFi::Constants::mat_index_substract;

      hits_module = hit_count.mat_offsets_p(uniqueGroupOrMat);

      if constexpr (decoding_version == 4) {
        // v4 code does not use a special format for a large clusters, then can be added directly
        atomicAdd(hits_module, 1);
      }
      else if constexpr (decoding_version == 6) {
        if (!SciFi::cSize(c)) { // Not flagged as large
          atomicAdd(hits_module, 1);
        }
        else if (SciFi::fraction(c)) { // flagged as first edge of large cluster
          // last cluster in bank or in sipm
          if (it + 1 == last || SciFi::getLinkInBank(c) != SciFi::getLinkInBank(*(it + 1)))
            atomicAdd(hits_module, 1);
          else {
            unsigned c2 = *(it + 1);
            assert(SciFi::cSize(c2) && !SciFi::fraction(c2));
            unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
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
}

void scifi_calculate_cluster_count::scifi_calculate_cluster_count_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_hit_count_t>(
    arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::n_mat_groups_and_mats);
}

void scifi_calculate_cluster_count::scifi_calculate_cluster_count_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_scifi_hit_count_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<4, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<4, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<6, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<6, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_scifi_geometry);
}
