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
#include <UTClusterAndPreDecode.cuh>
#include <WarpIntrinsicsTools.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_cluster_and_pre_decode::ut_cluster_and_pre_decode_t)

void ut_cluster_and_pre_decode::ut_cluster_and_pre_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_pre_decoded_hits_t>(
    arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::PreDecodedHits::element_size);
  set_size<dev_ut_tiebreak_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments));
  set_size<dev_ut_cluster_offsets_t>(arguments, size<dev_ut_hit_offsets_t>(arguments));
  set_size<host_total_sum_holder_t>(arguments, 1);
}

void ut_cluster_and_pre_decode::ut_cluster_and_pre_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_cluster_offsets_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) { // no UT banks present in data
    Allen::memset_async<host_total_sum_holder_t>(arguments, 0, context);
    return;
  }

  auto fun = bank_version == 4 ? (runtime_options.mep_layout ? global_function(ut_cluster_and_pre_decode<4, true>) :
                                                               global_function(ut_cluster_and_pre_decode<4, false>)) :
                                 (runtime_options.mep_layout ? global_function(ut_cluster_and_pre_decode<3, true>) :
                                                               global_function(ut_cluster_and_pre_decode<3, false>));

  fun(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    std::get<0>(runtime_options.event_interval),
    constants.dev_ut_boards.data(),
    constants.dev_ut_geometry.data(),
    constants.dev_ut_sector_to_group_map.data(),
    constants.dev_ut_board_geometry_map.data(),
    m_cluster_ut_hits.value(),
    m_position_method,
    m_max_cluster_size,
    m_save_clusters_above_max.value());

  PrefixSum::prefix_sum<dev_ut_cluster_offsets_t, host_total_sum_holder_t>(*this, arguments, context);
}

/**
 * @details Given a RawBank, this function partly decodes the hits to sort them by yBegin.
 *          In case hits have the same yBegin, they are sorted by x (xAtYEq0).
 *          Hit indices in the RawBank are persisted along with the variable for sorting
 *          to enable a loop over hits later on.
 */
template<int decoding_version>
__device__ void cluster_and_pre_decode_raw_bank(
  unsigned const*,
  uint32_t const*,
  UTGeometry const&,
  UTBoards const&,
  const uint16_t*,
  UTRawBank<decoding_version> const&,
  const uint16_t,
  UT::PreDecodedHits&,
  uint32_t*,
  uint32_t*,
  const bool,
  const UT::Decoding::PositionMethod,
  const unsigned,
  const bool)
{}

template<>
__device__ void cluster_and_pre_decode_raw_bank<3>(
  unsigned const* dev_ut_sector_to_group_map,
  uint32_t const* hit_offsets,
  UTGeometry const& geometry,
  UTBoards const& boards,
  const uint16_t* dev_ut_board_geometry_map,
  UTRawBank<3> const& raw_bank,
  [[maybe_unused]] const uint16_t channel_index,
  UT::PreDecodedHits& ut_pre_decoded_hits,
  uint32_t* cluster_count,
  uint32_t* dev_tiebreak,
  const bool,
  const UT::Decoding::PositionMethod,
  const unsigned,
  const bool)
{
  const uint32_t m_nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];
  for (unsigned i = 0; i < raw_bank.number_of_hits[0]; i++) {
    // Extract values from raw_data
    const uint16_t value = raw_bank.data[i];
    const uint32_t fracStrip = (value & UT::Decoding::v4::frac_mask) >> UT::Decoding::v4::frac_offset;
    const uint32_t channelID = (value & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;

    // Calculate the relative index of the corresponding board
    const uint32_t index = channelID / m_nStripsPerHybrid;
    const uint32_t stripID = channelID - (index * m_nStripsPerHybrid) + 1;

    const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;
    if (fullChanIndex >= boards.number_of_channels) continue;
    const auto chanID = boards.chanIDs[fullChanIndex];
    const auto sec = dev_ut_board_geometry_map[fullChanIndex];

    const uint32_t firstStrip = geometry.firstStrip[sec];
    const float numstrips = 0.25f * fracStrip + stripID - firstStrip;

    const uint32_t LHCbID = lhcb_id::set_detector_type_id(lhcb_id::LHCbIDType::UT, (chanID + stripID - 1));

    const unsigned base_sector_group_offset = dev_ut_sector_to_group_map[sec];
    unsigned* clusters_count_sector_group = cluster_count + base_sector_group_offset;

    const unsigned current_cluster_count = Allen::warp::atomic_increment(clusters_count_sector_group);
    assert(current_cluster_count < hit_offsets[base_sector_group_offset + 1] - hit_offsets[base_sector_group_offset]);

    const unsigned cluster_index = hit_offsets[base_sector_group_offset] + current_cluster_count;
    // No clustering for old UT
    ut_pre_decoded_hits.geometry_index(cluster_index) = sec;
    ut_pre_decoded_hits.id(cluster_index) = LHCbID;
    ut_pre_decoded_hits.num_strips(cluster_index) = numstrips;

    dev_tiebreak[cluster_index] = LHCbID;
  }
}

__device__ void store_predecoded_ut_cluster(
  const float mean_strip,
  const uint16_t stripID,
  const uint32_t fullSectorID,
  const uint16_t sec,
  const float p0Z,
  unsigned const* dev_ut_sector_to_group_map,
  uint32_t const* hit_offsets,
  uint32_t* cluster_count,
  uint32_t* dev_tiebreak,
  UT::PreDecodedHits ut_pre_decoded_hits)
{
  // we need to know whether or not a "stripflip" canges the numbering
  const auto numstrips = p0Z < 0 ? UT::Decoding::v5::strips_per_hybrid - mean_strip : mean_strip;

  const uint32_t LHCbID = lhcb_id::set_detector_type_id(lhcb_id::LHCbIDType::UT, (fullSectorID + stripID));

  // Finally we need to fill the global containers correctly
  const unsigned base_sector_group_offset =
    dev_ut_sector_to_group_map[sec]; // idx; //dev_ut_sector_to_group_map[idx_offset];
  unsigned* clusters_count_sector_group = cluster_count + base_sector_group_offset;

  const unsigned current_cluster_count = Allen::warp::atomic_increment(clusters_count_sector_group);
  assert(current_cluster_count < hit_offsets[base_sector_group_offset + 1] - hit_offsets[base_sector_group_offset]);

  const unsigned cluster_index = hit_offsets[base_sector_group_offset] + current_cluster_count;
  ut_pre_decoded_hits.geometry_index(cluster_index) = sec;
  ut_pre_decoded_hits.id(cluster_index) = LHCbID;
  ut_pre_decoded_hits.num_strips(cluster_index) = numstrips;

  dev_tiebreak[cluster_index] = LHCbID;
}

__device__ bool nonzero_adc_count(const int sum_adc_counts)
{
  const bool has_adc_count = sum_adc_counts > 0;

  return has_adc_count;
}

template<>
__device__ void cluster_and_pre_decode_raw_bank<4>(
  unsigned const* dev_ut_sector_to_group_map,
  uint32_t const* hit_offsets,
  UTGeometry const& geometry,
  UTBoards const& boards,
  const uint16_t* dev_ut_board_geometry_map,
  UTRawBank<4> const& raw_bank,
  const uint16_t channel_index,
  UT::PreDecodedHits& ut_pre_decoded_hits,
  uint32_t* cluster_count,
  uint32_t* dev_tiebreak,
  const bool cluster_ut_hits,
  const UT::Decoding::PositionMethod position_method,
  const unsigned max_cluster_size,
  const bool save_clusters_above_max)
{
  // Lane inside raw bank
  const uint16_t lane_index = channel_index % UT::Decoding::v5::n_lanes;
  const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + lane_index;

  // chanID will include a subsector bit at the 9th position
  // stripID can range from [0, 511]
  // If stripID is between [256, 511], the bit on the 9th position will be 1
  // But so would the chanID subsector bit (9th bit)
  // To calculate LHCbID, we have to mask the last 9 bits from channelID to get full sector ID
  // This is so that the last 9 bits can be reserved for UT sector stripID
  const uint32_t chanID = boards.chanIDs[fullChanIndex];
  const uint32_t fullSectorID = chanID & 0xFFFFFE00;
  const auto sec = dev_ut_board_geometry_map[fullChanIndex];
  const float p0Z = geometry.p0Z[sec];

  // Define this lambda function so that store cluster calls are more compact
  auto store_cluster = [=](const int number_of_strips, const int sum_adc_counts, const int sum_position) {
    const unsigned sum_weights =
      cluster_ut_hits ?
        ((position_method == UT::Decoding::PositionMethod::AdcWeighting) ? sum_adc_counts : number_of_strips) :
        1u;
    // mean_strip is used to calculate UT hits geometry, so we do a direct cast to float and division
    // stripID used to be calculated from mean_strip as floor( mean_strip + 0.5 )
    //   but this would cause stripID calculation to be sensitive to floating point division
    //   https://indico.cern.ch/event/1370609/contributions/5930503/attachments/2847596/4979440/WP2_UT_decoding_240430.pdf
    //   See https://gitlab.cern.ch/lhcb/Allen/-/merge_requests/1607 for better explanation of stripID formula.
    //   instead of floor( sum_position / sum_weights + 0.5 ), we can rewrite the formula in integers
    //   sum_position / sum_weights + 1 / 2 = ( sum_position * 2 ) / ( sum_weights * 2 ) + sum_weights / ( sum_weights
    //   * 2 )
    //                                      = ( sum_position * 2 + sum_weights ) / ( 2 * sum_weights )
    const float mean_strip = static_cast<float>(sum_position) / static_cast<float>(sum_weights);
    const unsigned stripID = (sum_position * 2 + sum_weights) / 2 / sum_weights;
    store_predecoded_ut_cluster(
      mean_strip,
      stripID,
      fullSectorID,
      sec,
      p0Z,
      dev_ut_sector_to_group_map,
      hit_offsets,
      cluster_count,
      dev_tiebreak,
      ut_pre_decoded_hits);
  };

  // Perform clustering by summing neighbouring strips
  uint16_t previous_stripID; // Probably enough
  uint16_t sum_adc_counts = 0;
  unsigned sum_position = 0;
  uint16_t number_of_strips = 0;
  bool exceeded_max_size = false;

  // Now we can start decoding hits from the v5 RawBank. The RawBank header (64 bits) tells you how many hits there
  // are. The RawBank data itself contains lane-wise zero-padded "words". When casting to 32 bits, this looks like
  // 1280  0  0  0  0  669913862 for example. So there is something in lane 5 (1280) and 0 (669913862), all other
  // lanes don't have hits. These words have been encoded as 32 bit integers with the corresponding bitshifts that
  // allow reading them as 16 bit integers, which is what we will do. This means we can loop individual hits but have
  // to do slighty more complicated indexing gymnastics.
  for (uint16_t ihit = 0; ihit < static_cast<uint16_t>(raw_bank.number_of_hits[lane_index]); ihit++) { // loop hits
    const uint16_t hit_index_inside_raw_bank = 16 * (ihit / 2) + 2 * (5 - lane_index) + ihit % 2;
    const uint16_t word = raw_bank.data[hit_index_inside_raw_bank];
    // this is the magic step that tells us which strip was hit
    const uint16_t stripID = (word & UT::Decoding::v5::strip_mask) >> UT::Decoding::v5::strip_offset;
    const uint16_t adc_count = (word & UT::Decoding::v5::adc_mask) >> UT::Decoding::v5::adc_offset;

    // Store each UT hit and continue if we are not clustering
    if (!cluster_ut_hits) {
      store_cluster(1, adc_count, stripID);
      continue;
    }

    // Do not store anything during first strip, when counters are empty
    const bool not_first_hit = ihit != 0;

    const bool start_of_new_cluster = previous_stripID + 1 != stripID && not_first_hit;
    const bool just_exceeded_max_size = number_of_strips >= max_cluster_size && (!exceeded_max_size);
    const bool last_hit_in_lane = (ihit + 1 == static_cast<uint16_t>(raw_bank.number_of_hits[lane_index]));
    // Either adc count is non-zero when ADC weighted or UT clusters are geometrically weighted
    const bool has_adc_count = nonzero_adc_count(sum_adc_counts);

    if (start_of_new_cluster) {
      const bool should_cluster = !exceeded_max_size && has_adc_count;
      if (should_cluster) store_cluster(number_of_strips, sum_adc_counts, sum_position);

      // flush clustering accumulators
      number_of_strips = 0;
      sum_adc_counts = 0;
      sum_position = 0;
      exceeded_max_size = false;
    }
    else if (just_exceeded_max_size) {
      const bool should_cluster = save_clusters_above_max && has_adc_count;
      if (should_cluster) store_cluster(number_of_strips, sum_adc_counts, sum_position);
      // Stop considering clusters above this limit
      exceeded_max_size = true;
    }

    // Accumulate hit information to cluster
    previous_stripID = stripID;
    number_of_strips++;
    sum_adc_counts += adc_count;
    // Max value of adc_count * stripID is 16384, well below 65535 limit of 16-bit unsigned integer
    // Compiler should do auto-conversion to 32-bit integers when summing sum_position
    sum_position += (position_method == UT::Decoding::PositionMethod::AdcWeighting) ? adc_count * stripID : stripID;

    if (!exceeded_max_size && last_hit_in_lane) {
      const bool should_cluster = nonzero_adc_count(sum_adc_counts);
      if (should_cluster) store_cluster(number_of_strips, sum_adc_counts, sum_position);
    }
  } // end loop hits
}

/**
 * Iterate over raw banks / hits and store only the Y coordinate,
 * and an uint32_t encoding the following:
 * raw_bank number and hit id inside the raw bank.
 * Let's refer to this array as raw_bank_hits.
 *
 * Kernel suitable for decoding from Allen layout
 */
template<int decoding_version, bool mep>
__global__ void ut_cluster_and_pre_decode::ut_cluster_and_pre_decode(
  ut_cluster_and_pre_decode::Parameters parameters,
  const unsigned event_start,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_ut_sector_to_group_map,
  const uint16_t* dev_ut_board_geometry_map,
  const bool cluster_ut_hits,
  const int position_method,
  const unsigned max_cluster_size,
  const bool save_clusters_above_max)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const uint32_t* hit_offsets = parameters.dev_ut_hit_offsets + event_number * UT::Constants::n_groups;
  uint32_t* cluster_count = parameters.dev_ut_cluster_offsets + event_number * UT::Constants::n_groups;

  // These are meant for zero-suppression and opportunistic looping
  const uint16_t* nonempty_channels =
    parameters.dev_ut_nonempty_channels + event_number * UT::Decoding::number_of_channels;
  const uint16_t number_of_nonempty_channels = parameters.dev_ut_number_of_nonempty_channels[event_number];

  // We are allocating enough memory for number_of_ut_hits
  // This is 100% safe for clustering but will allocate too much memory
  // However, we need to do clustering first to know the exact memory size anyway
  // We will cleanup empty clusters during sorting
  UT::PreDecodedHits ut_pre_decoded_hits {parameters.dev_ut_pre_decoded_hits,
                                          parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups]};

  const UTGeometry geometry(ut_geometry);
  const UTBoards boards(ut_boards);

  const UTRawEvent<mep> raw_event {parameters.dev_ut_raw_input,
                                   parameters.dev_ut_raw_input_offsets,
                                   parameters.dev_ut_raw_input_sizes,
                                   parameters.dev_ut_raw_input_types,
                                   event_number + event_start};

  const auto function = [&](const uint16_t index) {
    const uint16_t channel_index = nonempty_channels[index];
    const uint16_t raw_bank_index = (decoding_version == 4) ? channel_index / UT::Decoding::v5::n_lanes : channel_index;
    UTRawBank<decoding_version> raw_bank = raw_event.template raw_bank<decoding_version>(raw_bank_index);
    cluster_and_pre_decode_raw_bank(
      dev_ut_sector_to_group_map,
      hit_offsets,
      geometry,
      boards,
      dev_ut_board_geometry_map,
      raw_bank,
      channel_index,
      ut_pre_decoded_hits,
      cluster_count,
      parameters.dev_ut_tiebreak,
      cluster_ut_hits,
      static_cast<UT::Decoding::PositionMethod>(position_method),
      max_cluster_size,
      save_clusters_above_max);
  };

  Allen::warp::opportunistic_loop(number_of_nonempty_channels, function);
}
