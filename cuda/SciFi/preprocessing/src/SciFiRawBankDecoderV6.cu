#include "SciFiRawBankDecoderV6.cuh"
#include "assert.h"

void scifi_raw_bank_decoder_v6_t::set_arguments_size(
  ArgumentRefManager<T> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  set_size<dev_scifi_hits_t>(arguments, host_buffers.scifi_hits_uints());
}

void scifi_raw_bank_decoder_v6_t::operator()(
  const ArgumentRefManager<T>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
    offset<dev_scifi_raw_input_t>(arguments),
    offset<dev_scifi_raw_input_offsets_t>(arguments),
    offset<dev_event_list_t>(arguments),
    offset<dev_scifi_hit_count_t>(arguments),
    offset<dev_scifi_hits_t>(arguments),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res);
}

using namespace SciFi;

// Merge of PrStoreFTHit and RawBankDecoder.
__device__ void make_cluster_v6(
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

  const uint plane_code = 2 * planeCode + (uniqueZone % 2);
  hits.x0[hit_index] = x0;
  hits.z0[hit_index] = z0;
  hits.channel[hit_index] = chan;
  hits.m_endPointY[hit_index] = endPointY;
  assert(fraction <= 0x1 && plane_code <= 0x1f && pseudoSize <= 0xf && mat <= 0x7ff);
  hits.assembled_datatype[hit_index] = fraction << 20 | plane_code << 15 | pseudoSize << 11 | mat;
}

__global__ void scifi_raw_bank_decoder_v6(
  char* scifi_events,
  uint* scifi_event_offsets,
  const uint* event_list,
  uint* scifi_hit_count,
  uint* scifi_hits,
  char* scifi_geometry,
  const float* dev_inv_clus_res)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint selected_event_number = event_list[event_number];

  const SciFiGeometry geom {scifi_geometry};
  const auto event = SciFiRawEvent(scifi_events + scifi_event_offsets[selected_event_number]);

  SciFi::Hits hits {
    scifi_hits, scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats], &geom, dev_inv_clus_res};
  SciFi::HitCount hit_count {scifi_hit_count, event_number};
  const uint number_of_hits_in_event = hit_count.event_number_of_hits();

  for (uint i = threadIdx.x; i < number_of_hits_in_event; i += blockDim.x) {
    const uint32_t cluster_reference = hits.cluster_reference[hit_count.event_offset() + i];
    const int raw_bank_number = (cluster_reference >> 24) & 0xFF;
    const int it_number = (cluster_reference >> 16) & 0xFF;
    const int condition = (cluster_reference >> 13) & 0x07;
    const int delta_parameter = cluster_reference & 0xFF;

    const auto rawbank = event.getSciFiRawBank(raw_bank_number);
    const uint16_t* it = rawbank.data + 2;
    it += it_number;

    const uint16_t c = *it;
    const uint32_t ch = geom.bank_first_channel[rawbank.sourceID] + channelInBank(c);

    // Call parameters for make_cluster
    uint32_t cluster_chan = ch;
    uint8_t cluster_fraction = fraction(c);
    uint8_t pseudoSize = 4;

    assert(condition != 0x00 && "Invalid cluster condition. Usually empty slot due to counting/decoding mismatch.");

    if (condition == 0x02) {
      pseudoSize = 0;
    }
    else if (condition > 0x02) {
      const auto c2 = *(it + 1);
      const auto widthClus = (cell(c2) - cell(c) + 2);

      if (condition == 0x03) {
        pseudoSize = 0;
        cluster_fraction = 1;
        cluster_chan += delta_parameter;
      }
      else if (condition == 0x04) {
        pseudoSize = 0;
        cluster_fraction = (widthClus - 1) % 2;
        cluster_chan += delta_parameter + (widthClus - delta_parameter - 1) / 2 - 1;
      }
      else if (condition == 0x05) {
        pseudoSize = widthClus;
        cluster_fraction = (widthClus - 1) % 2;
        cluster_chan += (widthClus - 1) / 2 - 1;
      }
    }

    make_cluster_v6(hit_count.event_offset() + i, geom, cluster_chan, cluster_fraction, pseudoSize, hits);
  }
}
