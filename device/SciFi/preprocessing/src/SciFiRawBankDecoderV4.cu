/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <SciFiRawBankDecoderV4.cuh>
#include <assert.h>

void scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_hits_t>(
    arguments,
    first<host_accumulated_number_of_scifi_hits_t>(arguments) * SciFi::Hits::number_of_arrays * sizeof(uint32_t));
}

void scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  if (runtime_options.mep_layout) {
    global_function(scifi_raw_bank_decoder_v4_mep)(
      dim3(size<dev_event_list_t>(arguments)), property<raw_bank_decoder_block_dim_t>(), context)(
      arguments, constants.dev_scifi_geometry);
    global_function(scifi_direct_decoder_v4_mep)(
      dim3(size<dev_event_list_t>(arguments)), property<direct_decoder_block_dim_t>(), context)(
      arguments, constants.dev_scifi_geometry);
  }
  else {
    global_function(scifi_raw_bank_decoder_v4)(
      dim3(size<dev_event_list_t>(arguments)), property<raw_bank_decoder_block_dim_t>(), context)(
      arguments, constants.dev_scifi_geometry);
    global_function(scifi_direct_decoder_v4)(
      dim3(size<dev_event_list_t>(arguments)), property<direct_decoder_block_dim_t>(), context)(
      arguments, constants.dev_scifi_geometry);
  }
}

using namespace SciFi;

// Merge of PrStoreFTHit and RawBankDecoder.
__device__ void make_cluster_v4(
  const int hit_index,
  const SciFiGeometry& geom,
  uint32_t chan,
  uint8_t fraction,
  uint8_t pseudoSize,
  SciFi::Hits& hits)
{
  const SciFi::SciFiChannelID id {chan};

  // Offset to save space in geometry structure, see DumpFTGeometry.cpp
  const uint32_t mat = id.uniqueMat() - 512;
  const uint32_t planeCode = id.uniqueLayer() - 4;
  const float dxdy = geom.dxdy[mat];
  const float dzdy = geom.dzdy[mat];
  float uFromChannel = geom.uBegin[mat] + (2 * id.channel() + 1 + fraction) * geom.halfChannelPitch[mat];
  if (id.die()) uFromChannel += geom.dieGap[mat];
  uFromChannel += id.sipm() * geom.sipmPitch[mat];
  const float endPointX = geom.mirrorPointX[mat] + geom.ddxX[mat] * uFromChannel;
  const float endPointY = geom.mirrorPointY[mat] + geom.ddxY[mat] * uFromChannel;
  const float endPointZ = geom.mirrorPointZ[mat] + geom.ddxZ[mat] * uFromChannel;
  const float x0 = endPointX - dxdy * endPointY;
  const float z0 = endPointZ - dzdy * endPointY;

  assert(pseudoSize < 9 && "Pseudosize of cluster is > 8. Out of range.");

  // Apparently the unique* methods are not designed to start at 0, therefore -16
  const uint32_t uniqueZone = ((id.uniqueQuarter() - 16) >> 1);

  const unsigned plane_code = 2 * planeCode + (uniqueZone % 2);
  hits.x0(hit_index) = x0;
  hits.z0(hit_index) = z0;
  hits.channel(hit_index) = chan;
  hits.endPointY(hit_index) = endPointY;
  assert(fraction <= 0x1 && plane_code <= 0x1f && pseudoSize <= 0xf && mat <= 0x7ff);
  hits.assembled_datatype(hit_index) = fraction << 20 | plane_code << 15 | pseudoSize << 11 | mat;
}

__global__ void scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4(
  scifi_raw_bank_decoder_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const SciFiGeometry geom {scifi_geometry};
  const auto event =
    SciFiRawEvent(parameters.dev_scifi_raw_input + parameters.dev_scifi_raw_input_offsets[event_number]);

  SciFi::Hits hits {parameters.dev_scifi_hits,
                    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_mat_groups_and_mats]};
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};
  const unsigned number_of_hits_in_last_zones = hit_count.number_of_hits_in_zones_without_mat_groups();

  for (unsigned i = threadIdx.x; i < number_of_hits_in_last_zones; i += blockDim.x) {
    const uint32_t cluster_reference =
      parameters.dev_cluster_references[hit_count.offset_zones_without_mat_groups() + i];
    const int raw_bank_number = (cluster_reference >> 8) & 0xFF;
    const int it_number = (cluster_reference) &0xFF;
    const auto rawbank = event.getSciFiRawBank(raw_bank_number);
    const uint16_t* it = rawbank.data + 2;
    it += it_number;

    const uint16_t c = *it;
    const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);

    // Call parameters for make_cluster
    uint32_t cluster_chan = ch;
    uint8_t cluster_fraction = fraction(c);
    uint8_t pseudoSize = cSize(c) ? 0 : 4;

    make_cluster_v4(
      hit_count.offset_zones_without_mat_groups() + i, geom, cluster_chan, cluster_fraction, pseudoSize, hits);
  }
}

__global__ void scifi_raw_bank_decoder_v4::scifi_raw_bank_decoder_v4_mep(
  scifi_raw_bank_decoder_v4::Parameters parameters,
  const char* scifi_geometry)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const SciFiGeometry geom {scifi_geometry};

  SciFi::Hits hits {parameters.dev_scifi_hits,
                    parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_mat_groups_and_mats]};
  SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};
  const unsigned number_of_hits_in_last_zones = hit_count.number_of_hits_in_zones_without_mat_groups();

  for (unsigned i = threadIdx.x; i < number_of_hits_in_last_zones; i += blockDim.x) {
    const uint32_t cluster_reference =
      parameters.dev_cluster_references[hit_count.offset_zones_without_mat_groups() + i];

    const int raw_bank_number = (cluster_reference >> 8) & 0xFF;
    const int it_number = (cluster_reference) &0xFF;

    // Create SciFi raw bank from MEP layout
    auto const raw_bank = MEP::raw_bank<SciFiRawBank>(
      parameters.dev_scifi_raw_input, parameters.dev_scifi_raw_input_offsets, event_number, raw_bank_number);

    const uint16_t* it = raw_bank.data + 2;
    it += it_number;

    const uint16_t c = *it;
    const uint32_t ch = geom.bank_first_channel[raw_bank.sourceID] + channelInBank(c);

    // Call parameters for make_cluster
    uint32_t cluster_chan = ch;
    uint8_t cluster_fraction = fraction(c);
    uint8_t pseudoSize = cSize(c) ? 0 : 4;

    make_cluster_v4(
      hit_count.offset_zones_without_mat_groups() + i, geom, cluster_chan, cluster_fraction, pseudoSize, hits);
  }
}
