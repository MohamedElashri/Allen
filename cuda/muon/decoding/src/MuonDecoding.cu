#include "MuonDecoding.cuh"
#include <cstdio>
#include <cstring>

/**
 * This method decodes raw muon events into muon hits.
 * This method runs on a grid of `number of events` X `n_stations * n_regions * n_quarters`.
 *
 * Firstly, threads with numbers [`0` .. `Muon::MuonRawEvent::number_of_raw_banks`) stores pointers to the beginning of
 * every batch in the corresponding raw bank(thread with number `n` populates `batchSizePointers`[`n *
 * Muon::MuonRawEvent::batches_per_bank` .. `(n + 1) * Muon::MuonRawEvent::batches_per_bank`)).
 *
 * Then, threads with numbers [`0` .. `Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank`)
 * decode the corresponding batch (thread with number `n` decodes the batch that starts at `frontValuePointers`[`n`]).
 *   Tile ids are stored in the `storageTileId` array. Tdcs are stored in the `storageTdcValue` array.
 *
 * Then, the `0`th thread reorders tiles ("zipped" `storageTileId` and `storageTdcValue` arrays)
 *   by station, region, and quarter. Reordering is done by inplace count sort.
 *
 * Then, tiles are converted into hits (`muon_raw_to_hits->addCoordsCrossingMap` method is called).
 *   Thread with number `n` converts tiles for which `station * n_regions * n_quarters + region * n_quarters + quarter`
 * equals to `n`.
 *
 * Finally, the `0`th thread reorders hits (`muon_hits[eventId]` structure) by station.
 *   Reordering is done by inplace count sort.
 *
 * @param event_list numbers of events that should be decoded
 * @param events concatenated raw events in binary format
 * @param offsets offset[i] is a position where i-th event starts
 * @param muon_raw_to_hits structure that contains muon geometry and muon lookup tables
 * @param muon_hits output array for hits
 */
__global__ void muon_decoding::muon_decoding(muon_decoding::Parameters parameters)
{
  __shared__ uint currentHitIndex;
  const size_t eventId = parameters.dev_event_list[blockIdx.x];
  const size_t output_event = blockIdx.x;
  __shared__ unsigned int storageTileId[Muon::Constants::max_numhits_per_event];
  __shared__ unsigned int storageTdcValue[Muon::Constants::max_numhits_per_event];
  __shared__ int currentStorageIndex;
  __shared__ int storageStationRegionQuarterOccurrencesOffset
    [Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters + 1];
  __shared__ int originalStorageStationRegionQuarterOccurrencesOffset
    [Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters + 1];
  __shared__ bool used[Muon::Constants::max_numhits_per_event];
  __shared__ int stationOccurrencesOffset[Muon::Constants::n_stations + 1];
  const Muon::MuonRawEvent rawEvent =
    Muon::MuonRawEvent(parameters.dev_muon_raw + parameters.dev_muon_raw_offsets[eventId]);
  __shared__ uint16_t*
    batchSizePointers[Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank];
  __shared__ unsigned int tell1Numbers[Muon::MuonRawEvent::number_of_raw_banks];
  if (threadIdx.x == 0) {
    currentHitIndex = 0;
    currentStorageIndex = 0;
    memset(storageStationRegionQuarterOccurrencesOffset, 0, sizeof(storageStationRegionQuarterOccurrencesOffset));
    memset(
      originalStorageStationRegionQuarterOccurrencesOffset,
      0,
      sizeof(originalStorageStationRegionQuarterOccurrencesOffset));
    memset(used, false, sizeof(used));
    memset(stationOccurrencesOffset, 0, sizeof(stationOccurrencesOffset));
  }
  if (threadIdx.x < Muon::MuonRawEvent::number_of_raw_banks) {
    const size_t bank_index = threadIdx.x;
    const unsigned int tell1Number = rawEvent.getMuonBank(bank_index).sourceID;
    tell1Numbers[bank_index] = tell1Number;
    Muon::MuonRawBank rawBank = rawEvent.getMuonBank(bank_index);
    uint16_t* p = rawBank.data;
    const int preamble_size = 2 * ((*p + 3) / 2);
    p += preamble_size;
    for (size_t i = 0; i < Muon::MuonRawEvent::batches_per_bank; i++) {
      const uint16_t batchSize = *p;
      batchSizePointers[bank_index * Muon::MuonRawEvent::batches_per_bank + i] = p;
      p += 1 + batchSize;
    }
  }
  __syncthreads();

  if (threadIdx.x < Muon::MuonRawEvent::number_of_raw_banks * Muon::MuonRawEvent::batches_per_bank) {
    uint16_t batchSize = *batchSizePointers[threadIdx.x];
    for (int shift = 1; shift < 1 + batchSize; shift++) {
      const unsigned int pp = *(batchSizePointers[threadIdx.x] + shift);
      const unsigned int add = (pp & 0x0FFF);
      const unsigned int tdc_value = ((pp & 0xF000) >> 12);
      const unsigned int tileId = parameters.dev_muon_raw_to_hits.get()->muonGeometry->getADDInTell1(
        tell1Numbers[threadIdx.x / Muon::MuonRawEvent::batches_per_bank], add);
      if (tileId != 0) {
        int localCurrentStorageIndex = atomicAdd(&currentStorageIndex, 1);
        storageTileId[localCurrentStorageIndex] = tileId;
        storageTdcValue[localCurrentStorageIndex] = tdc_value;
      }
    }
  }
  __syncthreads();

  if (threadIdx.x == 0) {
    for (int i = 0; i < currentStorageIndex; i++) {
      size_t stationRegionQuarter = Muon::MuonTileID::stationRegionQuarter(storageTileId[i]);
      storageStationRegionQuarterOccurrencesOffset[stationRegionQuarter + 1]++;
    }
    for (size_t i = 0; i < Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
         i++) {
      storageStationRegionQuarterOccurrencesOffset[i + 1] += storageStationRegionQuarterOccurrencesOffset[i];
      originalStorageStationRegionQuarterOccurrencesOffset[i + 1] = storageStationRegionQuarterOccurrencesOffset[i + 1];
    }

    for (int i = currentStorageIndex - 1; i > -1; i--) {
      int currentStorageTileId = storageTileId[i];
      int currentStorageTdcValue = storageTdcValue[i];
      int currentStationRegionQuarter = Muon::MuonTileID::stationRegionQuarter(currentStorageTileId);
      int j = storageStationRegionQuarterOccurrencesOffset[currentStationRegionQuarter];
      if (j < i) {
        do {
          storageStationRegionQuarterOccurrencesOffset[currentStationRegionQuarter]++;
          int tmpCurrentStorageTileId = currentStorageTileId;
          int tmpCurrentStorageTdcValue = currentStorageTdcValue;
          currentStorageTileId = storageTileId[j];
          currentStorageTdcValue = storageTdcValue[j];
          storageTileId[j] = tmpCurrentStorageTileId;
          storageTdcValue[j] = tmpCurrentStorageTdcValue;
          currentStationRegionQuarter = Muon::MuonTileID::stationRegionQuarter(currentStorageTileId);
          j = storageStationRegionQuarterOccurrencesOffset[currentStationRegionQuarter];
        } while (j < i);
        storageTileId[i] = currentStorageTileId;
        storageTdcValue[i] = currentStorageTdcValue;
      }
    }
  }
  __syncthreads();

  // When storing the results, use the output_event
  Muon::HitsSoA* event_muon_hits = &parameters.dev_muon_hits[output_event];

  parameters.dev_muon_raw_to_hits.get()->addCoordsCrossingMap(
    storageTileId,
    storageTdcValue,
    used,
    originalStorageStationRegionQuarterOccurrencesOffset[threadIdx.x],
    originalStorageStationRegionQuarterOccurrencesOffset[threadIdx.x + 1],
    event_muon_hits,
    currentHitIndex);
  __syncthreads();

  if (threadIdx.x == 0) {
    for (size_t i = 0; i < currentHitIndex; i++) {
      size_t currentStation = Muon::MuonTileID::station(parameters.dev_muon_hits[output_event].tile[i]);
      stationOccurrencesOffset[currentStation + 1]++;
    }
    for (size_t i = 0; i < Muon::Constants::n_stations; i++) {
      parameters.dev_muon_hits[output_event].number_of_hits_per_station[i] = stationOccurrencesOffset[i + 1];
    }
    for (size_t i = 0; i < Muon::Constants::n_stations; i++) {
      stationOccurrencesOffset[i + 1] += stationOccurrencesOffset[i];
    }
    for (size_t i = 0; i < Muon::Constants::n_stations; i++) {
      parameters.dev_muon_hits[output_event].station_offsets[i] = stationOccurrencesOffset[i];
    }

    for (int i = currentHitIndex - 1; i > -1; i--) {
      Muon::Hit currentHit = Muon::Hit(event_muon_hits, i);
      size_t currentStation = Muon::MuonTileID::station(currentHit.tile);
      int j = stationOccurrencesOffset[currentStation];
      if (j < i) {
        do {
          stationOccurrencesOffset[currentStation]++;
          Muon::Hit tmpHit = currentHit;
          currentHit = Muon::Hit(event_muon_hits, j);
          setAtIndex(event_muon_hits, j, &tmpHit);
          currentStation = Muon::MuonTileID::station(currentHit.tile);
          j = stationOccurrencesOffset[currentStation];
        } while (j < i);
        setAtIndex(event_muon_hits, i, &currentHit);
      }
    }
  }
}
