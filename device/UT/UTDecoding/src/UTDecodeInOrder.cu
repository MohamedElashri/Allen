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
  global_function(ut_decode_in_order)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_ut_geometry.data());
}

template<int layer>
__device__ void decode_cluster(
  UTGeometry const& geometry,
  UT::ConstPreDecodedHits const& ut_pre_decoded_hits,
  unsigned const hit_index,
  unsigned const unsorted_hit_index,
  UT::Hits& ut_hits)
{
  const auto sec = ut_pre_decoded_hits.geometry_index(unsorted_hit_index);
  const auto LHCbID = ut_pre_decoded_hits.id(unsorted_hit_index);
  const auto numstrips = ut_pre_decoded_hits.num_strips(unsorted_hit_index);

  const float pitch = geometry.pitch[sec];
  const float dy = geometry.dy[sec];
  const float dp0diX = geometry.dp0diX[sec];
  const float dp0diY = geometry.dp0diY[sec];
  const float dp0diZ = geometry.dp0diZ[sec];
  const float p0X = geometry.p0X[sec];
  const float p0Y = geometry.p0Y[sec];
  const float p0Z = geometry.p0Z[sec];

  // Load dxDy
  float dxDy = 0.f;
  if constexpr (layer < 0) {
    dxDy = geometry.dxDy[sec];
  }
  else {
    dxDy = UT::Constants::static_hardcoded_dxdy<layer>();
  }

  const float yBegin = p0Y + numstrips * dp0diY;
  const float yEnd = dy + yBegin;
  const float zAtYEq0 = fabsf(p0Z) + numstrips * dp0diZ;
  const float xAtYEq0 = p0X + numstrips * dp0diX;
  const float weight = 12.f / (pitch * pitch);

  ut_hits.yBegin(hit_index) = yBegin;
  ut_hits.yEnd(hit_index) = yEnd;
  ut_hits.zAtYEq0(hit_index) = zAtYEq0;
  ut_hits.xAtYEq0(hit_index) = xAtYEq0;
  ut_hits.dxDy(hit_index) = dxDy;
  ut_hits.weight(hit_index) = weight;
  ut_hits.id(hit_index) = LHCbID;
}

__global__ void ut_decode_in_order::ut_decode_in_order(
  ut_decode_in_order::Parameters parameters,
  const char* ut_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  UT::ConstPreDecodedHits ut_pre_decoded_hits {
    parameters.dev_ut_pre_decoded_hits, parameters.dev_ut_cluster_offsets[number_of_events * UT::Constants::n_groups]};

  UT::Hits ut_hits {parameters.dev_ut_hits,
                    parameters.dev_ut_cluster_offsets[number_of_events * UT::Constants::n_groups]};

  const UTGeometry geometry(ut_geometry);

  const UT::HitOffsets ut_cluster_offsets {parameters.dev_ut_cluster_offsets, event_number};

  const unsigned event_offset = ut_cluster_offsets.event_offset();
  const unsigned number_of_hits = ut_cluster_offsets.event_number_of_hits();

  for (unsigned i = threadIdx.x; i < number_of_hits; i += blockDim.x) {
    const unsigned hit_index = event_offset + i;
    const unsigned unsorted_hit_index = parameters.dev_ut_permutations[hit_index];

    if (geometry.version > 0) {
      // When version > 0, we use per-sector dxDy
      decode_cluster<-1>(geometry, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
    }
    else {
      // When version <= 0, we use hard-coded dxDy, so need to pass layer information
      if (hit_index < ut_cluster_offsets.layer_offset(1)) {
        decode_cluster<0>(geometry, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
      }
      else if (hit_index < ut_cluster_offsets.layer_offset(2)) {
        decode_cluster<1>(geometry, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
      }
      else if (hit_index < ut_cluster_offsets.layer_offset(3)) {
        decode_cluster<2>(geometry, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
      }
      else {
        decode_cluster<3>(geometry, ut_pre_decoded_hits, hit_index, unsorted_hit_index, ut_hits);
      }
    }
  }
}
