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
#include <UTDecodeInOrder.cuh>
#include "LHCbID.cuh"
#include <UTUniqueID.cuh>

INSTANTIATE_ALGORITHM(ut_decode_in_order::ut_decode_in_order_t)

void ut_decode_in_order::ut_decode_in_order_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_hits_t>(
    arguments, first<host_accumulated_number_of_ut_clusters_t>(arguments) * UT::Hits::element_size);
}

void ut_decode_in_order::ut_decode_in_order_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  global_function(ut_decode_in_order)(
    dim3(size<dev_event_list_t>(arguments), UT::Constants::n_layers), property<block_dim_t>(), context)(
    arguments,
    constants.dev_ut_boards,
    constants.dev_ut_geometry.data(),
    constants.dev_unique_x_sector_layer_offsets.data());

  if (property<verbosity_t>() >= logger::debug) {
    auto host_ut_hits = make_host_buffer<dev_ut_hits_t>(arguments, context);
    auto host_ut_post_clustering_offsets = make_host_buffer<dev_ut_clustering_offsets_t>(arguments, context);
    auto clusters_view = UT::Hits {host_ut_hits.data(), first<host_accumulated_number_of_ut_clusters_t>(arguments)};

    for (unsigned i = 0; i < first<host_accumulated_number_of_ut_clusters_t>(arguments); ++i) {
      debug_cout << clusters_view.id(i) << ", ";
    }
    debug_cout << "\n";
  }
}

__device__ void decode_cluster(
  UTGeometry const& geometry,
  UTBoards const& boards,
  UT::ConstPreDecodedHits const& ut_pre_decoded_hits,
  unsigned const hit_index,
  unsigned const unsorted_hit_index,
  UT::Hits& ut_hits)
{
  const auto fullChanIndex = ut_pre_decoded_hits.full_channel_index(unsorted_hit_index);
  const auto LHCbID = ut_pre_decoded_hits.id(unsorted_hit_index);
  const auto numstrips = ut_pre_decoded_hits.num_strips(unsorted_hit_index);

  const uint32_t side = boards.sides[fullChanIndex];
  const uint32_t layer = boards.layers[fullChanIndex];
  const uint32_t stave = boards.staves[fullChanIndex];
  const uint32_t face = boards.faces[fullChanIndex];
  const uint32_t module = boards.modules[fullChanIndex];
  const uint32_t sector = boards.sectors[fullChanIndex];
  int sec = sector_unique_id(side, layer, stave, face, module, sector);

  const float pitch = geometry.pitch[sec];
  const float dy = geometry.dy[sec];
  const float dp0diX = geometry.dp0diX[sec];
  const float dp0diY = geometry.dp0diY[sec];
  const float dp0diZ = geometry.dp0diZ[sec];
  const float p0X = geometry.p0X[sec];
  const float p0Y = geometry.p0Y[sec];
  const float p0Z = geometry.p0Z[sec];

  const float yBegin = p0Y + numstrips * dp0diY;
  const float yEnd = dy + yBegin;
  const float zAtYEq0 = fabsf(p0Z) + numstrips * dp0diZ;
  const float xAtYEq0 = p0X + numstrips * dp0diX;
  const float weight = 12.f / (pitch * pitch);

  ut_hits.yBegin(hit_index) = yBegin;
  ut_hits.yEnd(hit_index) = yEnd;
  ut_hits.zAtYEq0(hit_index) = zAtYEq0;
  ut_hits.xAtYEq0(hit_index) = xAtYEq0;
  ut_hits.weight(hit_index) = weight;
  ut_hits.id(hit_index) = LHCbID;
}

__global__ void ut_decode_in_order::ut_decode_in_order(
  ut_decode_in_order::Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned layer_number = blockIdx.y;
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];

  UT::ConstPreDecodedHits ut_pre_decoded_hits {
    parameters.dev_ut_pre_decoded_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  UT::Hits ut_hits {parameters.dev_ut_hits,
                    parameters.dev_ut_clustering_offsets[number_of_events * number_of_unique_x_sectors]};

  const UTBoards boards(ut_boards);
  const UTGeometry geometry(ut_geometry);

  const UT::HitOffsets ut_clustering_offsets {
    parameters.dev_ut_clustering_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};

  const unsigned layer_offset = ut_clustering_offsets.layer_offset(layer_number);
  const unsigned layer_number_of_hits = ut_clustering_offsets.layer_number_of_hits(layer_number);

  for (unsigned i = threadIdx.x; i < layer_number_of_hits; i += blockDim.x) {
    const unsigned hit_index = layer_offset + i;
    const unsigned unsorted_hit_index = parameters.dev_ut_permutations[hit_index];
    decode_cluster(geometry, boards, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
  }
}
