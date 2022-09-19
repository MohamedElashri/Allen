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
  const unsigned event_start,
  const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto scifi_raw_event = SciFi::RawEvent<mep_layout>(
    parameters.dev_scifi_raw_input,
    parameters.dev_scifi_raw_input_offsets,
    parameters.dev_scifi_raw_input_sizes,
    event_number + event_start);
  const SciFi::SciFiGeometry geom(scifi_geometry);
  SciFi::HitCount hit_count {parameters.dev_scifi_hit_count, event_number};
  for (unsigned iRawBank = threadIdx.x; iRawBank < scifi_raw_event.number_of_raw_banks(); iRawBank += blockDim.x) {
    uint32_t* hits_module;
    const auto rawbank = scifi_raw_event.raw_bank(iRawBank);
    const auto sourceID = rawbank.sourceID;
    const auto iRowInMap = iSource(geom, sourceID);
    if (iRowInMap == geom.number_of_banks) {
      printf("ERROR: Invalid row for sourceID %i\n", sourceID); // FIXME: better error handling
      auto* counter = parameters.link_error_counter + event_number;
      atomicAdd(counter, 1);
      continue;
    }

    uint16_t const* it = rawbank.data;
    uint16_t const* last = rawbank.last;
    // Skip empty raw banks: very unlikely, as there should always be a header. But it has been seen in early data
    // taking.
    if (it == last) continue;
    it += 2; // skip header
    // For details see RawBankDecoder
    if (it != last && *(last - 1) == 0) --last; // Remove padding at the end
    if (it >= last || it >= rawbank.last) continue;
    if (
      (last - it + 1) >
      SciFi::SciFiRawBankParams::nbClusMaximum * SciFi::SciFiRawBankParams::BankProperties::NbLinksPerBank)
      continue;               // Absurd number of clusters
    for (; it < last; ++it) { // loop over the clusters
      uint16_t c = *it;
      SciFi::SciFiChannelID chid(SciFi::SciFiChannelID::kInvalidChannelID);
      if constexpr (decoding_version != 7 && decoding_version != 8) {
        uint32_t ch = geom.bank_first_channel[iRawBank] + SciFi::channelInBank(c);
        chid = SciFi::SciFiChannelID(ch);
      }
      else {
        chid = SciFi::SciFiChannelID(SciFi::getGlobalSiPMFromIndex(geom, iRowInMap, c));
        if (chid.channelID == SciFi::SciFiChannelID::kInvalidChannelID) /*FIX*/ {
          auto* counter = parameters.link_error_counter + event_number;
          atomicAdd(counter, 1);
          continue;
        }
      }
      const uint32_t uniqueMat = chid.globalMatIdx_Xorder();
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
      else if constexpr (decoding_version >= 6) {
        if (!SciFi::cSize(c)) { // Not flagged as large
          atomicAdd(hits_module, 1);
        }
        else { // flagged as first edge of large cluster
          unsigned c2 = *(it + 1);
          // last cluster in bank or in sipm
          if (it + 1 == last || SciFi::getLinkInBank(c) != SciFi::getLinkInBank(c2))
            atomicAdd(hits_module, 1);
          else if (SciFi::cell(c2) < SciFi::cell(c)) { /* Misordered clusters*/
            ++it;
          }
          else {
            if constexpr (decoding_version == 6 || decoding_version == 8) {
              if (SciFi::fraction(c)) {
                if (SciFi::cSize(c2) && !SciFi::fraction(c2)) {
                  unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
                  if (widthClus > 8)
                    // number of for loop passes in decoder + one additional
                    atomicAdd(hits_module, (widthClus - 1) / 4 + 1);
                  else
                    atomicAdd(hits_module, 1);
                  ++it;
                }
                else { /* Corrupt cluster type 1 */
                  ++it;
                }
              }
            }
            else {
              if (!SciFi::fraction(c)) {
                if (SciFi::cSize(c2)) {
                  unsigned int widthClus = (SciFi::cell(c2) - SciFi::cell(c) + 2);
                  if (widthClus > 8)
                    // number of for loop passes in decoder + one additional
                    atomicAdd(hits_module, (widthClus - 1) / 4 + 1);
                  else
                    atomicAdd(hits_module, 1);
                  ++it;
                }
                else { /* Corrupt cluster type 1 */
                  ++it;
                }
              }
            }
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
  set_size<dev_scifi_link_error_counter_t>(arguments, first<host_number_of_events_t>(arguments));
}

void scifi_calculate_cluster_count::scifi_calculate_cluster_count_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_hit_count_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_link_error_counter_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data

  auto kernel_fn = (bank_version == 4 || bank_version == 5) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<4, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<4, false>)) :
                     (bank_version == 6) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<6, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<6, false>)) :
                     (bank_version == 7) ?
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<7, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<7, false>)) :
                     (runtime_options.mep_layout ? global_function(scifi_calculate_cluster_count_kernel<8, true>) :
                                                   global_function(scifi_calculate_cluster_count_kernel<8, false>));

  kernel_fn(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, std::get<0>(runtime_options.event_interval), constants.dev_scifi_geometry);
}
