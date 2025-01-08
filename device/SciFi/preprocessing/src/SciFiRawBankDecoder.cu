/***************************************************************************** \
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "SciFiRawBankDecoder.cuh"
#include <MEPTools.h>
#include "assert.h"

INSTANTIATE_ALGORITHM(scifi_raw_bank_decoder::scifi_raw_bank_decoder_t)

// Merge of PrStoreFTHit and RawBankDecoder.
__device__ void make_cluster(
  const int hit_index,
  const SciFi::SciFiGeometry& geom,
  uint32_t chan,
  uint8_t fraction,
  uint8_t pseudoSize,
  SciFi::Hits& hits)
{
  const SciFi::SciFiChannelID id {chan};

  // Offset to save space in geometry structure, see DumpFTGeometry.cpp
  const uint32_t mat = (id.globalMatID() < 512) ? 0 : id.globalMatID_shift();
  const uint32_t planeCode = id.globalLayerIdx();
  const float dxdy = geom.dxdy[mat];
  const float dzdy = geom.dzdy[mat];
  float uFromChannel = geom.uBegin[mat] + (2 * id.channel() + 1 + fraction) * geom.halfChannelPitch[mat];
  if (id.die()) uFromChannel += geom.dieGap[mat];
  uFromChannel += id.sipm() * geom.sipmPitch[mat];
  const float endPointX = geom.mirrorPointX[mat] + geom.ddxX[mat] * uFromChannel;
  const float endPointY = geom.mirrorPointY[mat] + geom.ddxY[mat] * uFromChannel;
  const float endPointZ = geom.mirrorPointZ[mat] + geom.ddxZ[mat] * uFromChannel;
  const std::array<float, 128 * 4>& matContractionVector = geom.matEndCalibrationVector[mat];
  const float matContraction = matContractionVector[(id.sipm() * 128) + id.channel()];
  const float calibratedDdxX = geom.ddxX[mat] * matContraction;
  const float calibratedDdxY = geom.ddxY[mat] * matContraction;
  const float x0Calibration = calibratedDdxX - dxdy * calibratedDdxY;
  const float x0 = endPointX - dxdy * endPointY + x0Calibration;
  const float z0 = endPointZ - dzdy * endPointY;

  assert(pseudoSize < 9 && "Pseudosize of cluster is > 8. Out of range.");

  // Apparently the unique* methods are not designed to start at 0, therefore -16
  const uint32_t uniqueZone = (id.globalQuarterIdx() >> 1);

  const unsigned plane_code = 2 * planeCode + (uniqueZone % 2);
  hits.x0(hit_index) = x0;
  hits.z0(hit_index) = z0;
  hits.channel(hit_index) = chan;
  hits.endPointY(hit_index) = endPointY;
  assert(fraction <= 0x1 && plane_code <= 0x1f && pseudoSize <= 0xf && mat <= 0x7ff);
  hits.assembled_datatype(hit_index) = fraction << 20 | plane_code << 15 | pseudoSize << 11 | mat;
}

__global__ void scifi_raw_bank_decoder_kernel(
  scifi_raw_bank_decoder::Parameters parameters,
  const char* scifi_geometry,
  Allen::Monitoring::Counter<>::DeviceType invalid_chanid)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const SciFi::SciFiGeometry geom {scifi_geometry};

  SciFi::Hits hits {parameters.dev_scifi_hits,
                    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_zones]};
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};
  const unsigned number_of_hits_in_event = hit_count.event_number_of_hits();
  for (unsigned i = threadIdx.x; i < number_of_hits_in_event; i += blockDim.x) {
    const unsigned cluster_reference = parameters.dev_cluster_references[hit_count.event_offset() + i];

    unsigned cluster_chan = SciFi::ClusterReference::getChanID(cluster_reference);
    int cluster_fraction = SciFi::ClusterReference::getFraction(cluster_reference);
    int pseudoSize = SciFi::ClusterReference::getPseudoSize(cluster_reference);

    const SciFi::SciFiChannelID id {cluster_chan};
    if (id.station() == 0 || id.globalMatID() < 512) {
      invalid_chanid.increment();
    }
    else {
      make_cluster(hit_count.event_offset() + i, geom, cluster_chan, cluster_fraction, pseudoSize, hits);
    }
  }
}

__global__ void scifi_verify_decoding_kernel(scifi_raw_bank_decoder::Parameters parameters, const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const SciFi::SciFiGeometry geom {scifi_geometry};

  SciFi::Hits hits {parameters.dev_scifi_hits,
                    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_zones]};
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

  for (unsigned layer = 0; layer < SciFi::Constants::n_zones; layer++) {
    auto offset = hit_count.zone_offset(layer);
    auto size = hit_count.zone_number_of_hits(layer);
    for (unsigned i = 1; i < size; i++) {
      auto prev = hits.x0(offset + i - 1);
      auto cur = hits.x0(offset + i);

      const auto chid =
        SciFi::SciFiChannelID(SciFi::ClusterReference::getChanID(parameters.dev_cluster_references[offset + i]));

      if (blockIdx.x == 0) {
        if (cur < prev) {
          printf(
            "X: Layer %d not sorted at %d: %f %f %d q=%d l=%d mod=%d mat=%d sipm=%d reverse=%d !\n",
            layer,
            i,
            (double) prev,
            (double) cur,
            chid.globalMatIdx_Xorder(),
            chid.quarter(),
            chid.layer(),
            chid.module(),
            chid.mat(),
            chid.sipm(),
            chid.reversedZone());
        }
      }
    }
  }
}

void scifi_raw_bank_decoder::scifi_raw_bank_decoder_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_hits_t>(
    arguments,
    first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));
}

void scifi_raw_bank_decoder::scifi_raw_bank_decoder_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_hits_t>(arguments, 0, context);

  const auto bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return; // no SciFi banks present in data

  global_function(scifi_raw_bank_decoder_kernel)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_scifi_geometry, m_invalid_chanid.data(context));

#if ALLEN_DEBUG
  global_function(scifi_verify_decoding_kernel)(dim3(size<dev_event_list_t>(arguments)), dim3(1), context)(
    arguments, constants.dev_scifi_geometry);
#endif
}
