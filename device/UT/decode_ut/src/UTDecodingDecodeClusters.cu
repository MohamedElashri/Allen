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
#include <UTDecodingDecodeClusters.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_decoding_decode_clusters::ut_decoding_decode_clusters_t)

void ut_decoding_decode_clusters::ut_decoding_decode_clusters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto num_clusters = first<host_ut_num_clusters_t>(arguments);
  set_size<dev_ut_hits_t>(arguments, num_clusters * UT::Hits::element_size);
}

void ut_decoding_decode_clusters::ut_decoding_decode_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Basics
  const auto num_clusters = first<host_ut_num_clusters_t>(arguments);

  // Bank dependent info
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  {
    constexpr unsigned MaxSize = 2048;
    const auto nblocks = (num_clusters + MaxSize - 1) / MaxSize;
    auto global_func = (bank_version == 3) ? global_function(ut_decoding_decode_clusters<MaxSize, 3>) :
                                             global_function(ut_decoding_decode_clusters<MaxSize, 4>);
    global_func(dim3(nblocks), dim3(256), context)(
      arguments,
      num_clusters,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_board_to_sector_group_map.data(),
      constants.dev_ut_board_geometry_map.data());
  }
}

template<unsigned N, unsigned version>
__global__ void ut_decoding_decode_clusters::ut_decoding_decode_clusters(
  Parameters parameters,
  const unsigned total_number_of_clusters,
  const char* ut_boards,
  const char* ut_geometry,
  const uint8_t* board_to_sector_group_map,
  const uint16_t* board_to_geometry_map)
{
  const auto offset = N * blockIdx.x;
  const auto size = std::min(total_number_of_clusters - offset, N);

  // Alias
  using UT::Constants::hardcoded_dxdy;
  using UTDecoding::UTClusterInfo;

  // Geometry info
  const UTGeometry geometry(ut_geometry);
  const UTBoards boards(ut_boards);

  // Output
  UT::Hits ut_hits {parameters.dev_ut_hits, total_number_of_clusters};

  for (unsigned i = threadIdx.x; i < size; i += blockDim.x) {
    const auto cluster_number = offset + i;
    const auto cluster_idx = parameters.dev_ut_clusters_permutations[cluster_number];

    UTClusterInfo cluster {parameters.dev_ut_clusters[cluster_idx]};
    const auto board_idx = cluster.board_idx();
    const auto mean_strip = cluster.mean_strip();
    const auto word = cluster.word();

    // Layer index, it's need when we use hardcoded_dxdy
    const auto layer = board_to_sector_group_map[board_idx] / UT::Constants::n_groups_in_layer;

    // Geometry info
    const auto geometry_idx = board_to_geometry_map[board_idx];
    const float pitch = geometry.pitch[geometry_idx];
    const float dy = geometry.dy[geometry_idx];
    const float dp0diX = geometry.dp0diX[geometry_idx];
    const float dp0diY = geometry.dp0diY[geometry_idx];
    const float dp0diZ = geometry.dp0diZ[geometry_idx];
    const float p0X = geometry.p0X[geometry_idx];
    const float p0Y = geometry.p0Y[geometry_idx];
    const float p0Z = geometry.p0Z[geometry_idx];
    const float dxDy = geometry.dxDy ? geometry.dxDy[geometry_idx] : hardcoded_dxdy(layer);

    // Board info
    const auto chanID = boards.chanIDs[board_idx];

    // Decode key informations from word
    float numstrips;
    uint32_t LHCbID;
    if constexpr (version == 4) {
      const uint32_t fullSectorID = chanID & 0xFFFFFE00;
      const uint16_t stripID = (word & UT::Decoding::v5::strip_mask) >> UT::Decoding::v5::strip_offset;

      // we need to know whether or not a "stripflip" canges the numbering
      numstrips = p0Z < 0 ? UT::Decoding::v5::strips_per_hybrid - mean_strip : mean_strip;

      // compute LHCb ID
      LHCbID = lhcb_id::set_detector_type_id(lhcb_id::LHCbIDType::UT, (fullSectorID + stripID));
    }
    else {
      const uint32_t m_nStripsPerHybrid =
        boards.stripsPerHybrids[board_idx / UT::Decoding::ut_number_of_sectors_per_board];

      const uint32_t fracStrip = (word & UT::Decoding::v4::frac_mask) >> UT::Decoding::v4::frac_offset;
      const uint32_t channelID = (word & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;

      // Calculate the relative index of the corresponding board
      const uint32_t index = channelID / m_nStripsPerHybrid;
      const uint32_t stripID = channelID - (index * m_nStripsPerHybrid) + 1;

      // Num strips
      const uint32_t firstStrip = geometry.firstStrip[geometry_idx];
      numstrips = 0.25f * fracStrip + stripID - firstStrip;

      // compute LHCb ID
      LHCbID = lhcb_id::set_detector_type_id(lhcb_id::LHCbIDType::UT, (chanID + stripID - 1));
    }

    // Compute hit informations
    const float yBegin = p0Y + numstrips * dp0diY;
    const float yEnd = dy + yBegin;
    const float zAtYEq0 = fabsf(p0Z) + numstrips * dp0diZ;
    const float xAtYEq0 = p0X + numstrips * dp0diX;
    const float weight = 12.f / (pitch * pitch);

    // Fill results
    ut_hits.yBegin(cluster_number) = yBegin;
    ut_hits.yEnd(cluster_number) = yEnd;
    ut_hits.zAtYEq0(cluster_number) = zAtYEq0;
    ut_hits.xAtYEq0(cluster_number) = xAtYEq0;
    ut_hits.dxDy(cluster_number) = dxDy;
    ut_hits.weight(cluster_number) = weight;
    ut_hits.id(cluster_number) = LHCbID;
  }
}
