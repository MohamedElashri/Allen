#include "MuonRawToHits.cuh"
#include <stdio.h>

__device__ void recalculateNumberOfHitsPerStationAndStationOffsets(Muon::HitsSoA* hitsSoA, size_t totalNumberOfHits) {
  hitsSoA->station_offsets[0] = 0;
  int currentStation = Muon::MuonTileID::station(hitsSoA->tile[0]);
  int initialCurrentStation = currentStation;
  for (int i = 1; i < totalNumberOfHits; i++) {
    auto id = static_cast<unsigned int>(hitsSoA->tile[i]);
    if (Muon::MuonTileID::station(id) != currentStation) {
      hitsSoA->station_offsets[currentStation + 1] = i;
      currentStation++;
    }
  }

  for (int j = currentStation; j + 1 < Muon::Constants::n_stations; j++) {
    hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
  }
  if (initialCurrentStation == currentStation) {
    for (int j = initialCurrentStation; j + 1 < Muon::Constants::n_stations; j++) {
      hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
    }
  }
  for (currentStation = 0; currentStation + 1 < Muon::Constants::n_stations; currentStation++) {
    hitsSoA->number_of_hits_per_station[currentStation] =
        hitsSoA->station_offsets[currentStation + 1] - hitsSoA->station_offsets[currentStation];
  }
  hitsSoA->number_of_hits_per_station[Muon::Constants::n_stations - 1] =
      totalNumberOfHits - hitsSoA->station_offsets[Muon::Constants::n_stations - 1];
}

__device__ size_t regionAndQuarter(const Digit& i) {
  return i.tile.region() * Muon::Constants::n_quarters + i.tile.quarter();
}

__device__ void MuonRawToHits::operator()(Muon::MuonRawEvent& rawEvent, Muon::HitsSoA* hitsSoA) const {
  size_t currentHitsIndex = 0;
  Digit decoding[Muon::Constants::max_numhits_per_event];
  Digit sortedDecoding[Muon::Constants::max_numhits_per_event];
  bool used[Muon::Constants::max_numhits_per_event] = {false};
  size_t decodingOffset[Muon::Constants::n_stations + 1] = {0};
  decodeTileAndTDC(rawEvent, decoding, decodingOffset);
  for (size_t currentStation = 0; currentStation < Muon::Constants::n_stations; currentStation++) {
    size_t regionAndQuarterOccurrences[Muon::Constants::n_quarters * Muon::Constants::n_regions] = {0};
    for (size_t i = decodingOffset[currentStation]; i < decodingOffset[currentStation + 1]; i++) {
      regionAndQuarterOccurrences[regionAndQuarter(decoding[i])]++;
    }
    size_t regionAndQuarterOccurrencesOffset[Muon::Constants::n_quarters * Muon::Constants::n_regions + 1] = {0};
    size_t originalRegionAndQuarterOccurrencesOffset[Muon::Constants::n_quarters * Muon::Constants::n_regions + 1] = {0};
    for (size_t i = 0; i <= Muon::Constants::n_quarters * Muon::Constants::n_regions; i++) {
      regionAndQuarterOccurrencesOffset[i + 1] = regionAndQuarterOccurrencesOffset[i] + regionAndQuarterOccurrences[i];
      originalRegionAndQuarterOccurrencesOffset[i + 1] = regionAndQuarterOccurrencesOffset[i + 1];
    }
    for (size_t i = decodingOffset[currentStation]; i < decodingOffset[currentStation + 1]; i++) {
      size_t currentRegionAndQuarter = regionAndQuarter(decoding[i]);
      size_t index = regionAndQuarterOccurrencesOffset[currentRegionAndQuarter] + decodingOffset[currentStation];
      regionAndQuarterOccurrencesOffset[currentRegionAndQuarter]++;
      sortedDecoding[index] = decoding[i];
    }
    for (size_t i = 0; i < Muon::Constants::n_quarters * Muon::Constants::n_regions; i++) {
      addCoordsCrossingMap(
          sortedDecoding,
          used,
          decodingOffset[currentStation] + originalRegionAndQuarterOccurrencesOffset[i],
          decodingOffset[currentStation] + originalRegionAndQuarterOccurrencesOffset[i + 1],
          hitsSoA,
          currentHitsIndex
      );
    }
  }
  recalculateNumberOfHitsPerStationAndStationOffsets(hitsSoA, currentHitsIndex);
}

__device__ void MuonRawToHits::makeStripLayouts(const unsigned int station, const unsigned int region, MuonLayout* layouts) const {
  unsigned int x1 = getLayoutX((Muon::MuonTables*)&muonTables, Muon::MuonTables::stripXTableNumber, station, region);
  unsigned int y1 = getLayoutY((Muon::MuonTables*)&muonTables, Muon::MuonTables::stripXTableNumber, station, region);
  unsigned int x2 = getLayoutX((Muon::MuonTables*)&muonTables, Muon::MuonTables::stripYTableNumber, station, region);
  unsigned int y2 = getLayoutY((Muon::MuonTables*)&muonTables, Muon::MuonTables::stripYTableNumber, station, region);
  layouts[x1 > x2] = MuonLayout(x2, y2);
  layouts[x1 <= x2] = MuonLayout(x1, y1);
}

__device__ void MuonRawToHits::addCoordsCrossingMap(Digit* digits, bool* used, size_t startIndex, size_t endIndex,
                                         Muon::HitsSoA* hitsSoA, size_t& currentHitIndex) const {
  if (startIndex == endIndex) {
    return;
  }
  MuonLayout layouts[2];
  makeStripLayouts(digits[startIndex].tile.station(), digits[startIndex].tile.region(), layouts);
  MuonLayout& layoutOne = layouts[0];
  MuonLayout& layoutTwo = layouts[1];
  size_t midIndex = startIndex;
  Digit tmpDigit;
  for (size_t i = startIndex; i < endIndex; i++) {
    if (digits[i].tile.layout() == layoutOne) {
      if (midIndex != i) {
        tmpDigit = digits[i];
        digits[i] = digits[midIndex];
        digits[midIndex] = tmpDigit;
      }
      midIndex++;
    }
  }
  int thisGridX = layoutOne.xGrid();
  int thisGridY = layoutOne.yGrid();
  int otherGridX = layoutTwo.xGrid();
  int otherGridY = layoutTwo.yGrid();
  for (size_t digitsOneIndex = startIndex; digitsOneIndex < midIndex; digitsOneIndex++) {
    unsigned int keyX = digits[digitsOneIndex].tile.nX() * otherGridX / thisGridX;
    unsigned int keyY = digits[digitsOneIndex].tile.nY();
    for (size_t digitsTwoIndex = midIndex; digitsTwoIndex < endIndex; digitsTwoIndex++) {
      unsigned int candidateX = digits[digitsTwoIndex].tile.nX();
      unsigned int candidateY = digits[digitsTwoIndex].tile.nY() * thisGridY / otherGridY;
      if (keyX == candidateX && keyY == candidateY) {
        Muon::MuonTileID padTile(digits[digitsOneIndex].tile);
        padTile.setY(digits[digitsTwoIndex].tile.nY());
        padTile.setLayout(MuonLayout(thisGridX, otherGridY));
        double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
        calcTilePos((Muon::MuonTables*)&muonTables, padTile, x, dx, y, dy, z);
        unsigned int uncrossed = 0;
        int clusterSize = 0;
        int region = padTile.region();
        hitsSoA->setAtIndex(currentHitIndex, padTile.id(), x, dx, y, dy, z, dz, uncrossed,
                            digits[digitsOneIndex].tdc, digits[digitsOneIndex].tdc - digits[digitsTwoIndex].tdc,
                            clusterSize, region);
        currentHitIndex++;
        used[digitsOneIndex] = used[digitsTwoIndex] = true;
      }
    }
  }
  size_t startIndices[] = {startIndex, midIndex};
  size_t endIndices[] = {midIndex, endIndex};
  for (size_t currentDigitsIndex = 0; currentDigitsIndex < 2; currentDigitsIndex++) {
    for (size_t currentDigitIndex = startIndices[currentDigitsIndex];
         currentDigitIndex < endIndices[currentDigitsIndex];
         currentDigitIndex++) {
      if (!used[currentDigitIndex]) {
        double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
        int region = digits[currentDigitIndex].tile.region();
        if (digits[currentDigitIndex].tile.station() > (Muon::Constants::n_stations - 3) && region == 0) {
          calcTilePos((Muon::MuonTables*)&muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
        } else {
          if (currentDigitsIndex == 0) {
            calcStripXPos((Muon::MuonTables*)&muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
          } else {
            calcStripYPos((Muon::MuonTables*)&muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
          }
        }
        unsigned int uncrossed = 1;
        int clusterSize = 0;
        hitsSoA->setAtIndex(currentHitIndex, digits[currentDigitIndex].tile.id(), x, dx, y, dy, z, dz, uncrossed,
                            digits[currentDigitIndex].tdc, digits[currentDigitIndex].tdc, clusterSize, region);
        currentHitIndex++;
      }
    }
  }
}

//TODO перенести на сервер
__device__ void MuonRawToHits::decodeTileAndTDC(Muon::MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const {
  size_t currentStorageIndex = 0;
  //Is it true that files always contain 10 banks?
  constexpr size_t maxNumberOfRawBanks = 10;
  size_t tell1NumberByBankNumber[maxNumberOfRawBanks];
  size_t stationByBankNumber[maxNumberOfRawBanks];
  size_t stationByBankNumberOccurrences[Muon::Constants::n_stations];
  size_t stationByBankNumberOffset[Muon::Constants::n_stations];
  size_t orderOfBanks[maxNumberOfRawBanks];
  for (size_t i = 0; i < Muon::Constants::n_stations; i++) {
    stationByBankNumberOccurrences[i] = 0;
    stationByBankNumberOffset[i] = 0;
  }
  for (uint32_t bank_index = 0; bank_index < rawEvent.number_of_raw_banks; bank_index++) {
    unsigned int tell1Number = rawEvent.getMuonBank(bank_index).sourceID;
    tell1NumberByBankNumber[bank_index] = tell1Number;
    stationByBankNumber[bank_index] = (tell1Number < 4 ? 0 : tell1Number < 6 ? 1 : tell1Number < 8 ? 2 : 3);
    stationByBankNumberOccurrences[stationByBankNumber[bank_index]]++;
  }
  for (size_t i = 0; i < Muon::Constants::n_stations - 1; i++) {
    stationByBankNumberOffset[i + 1] = stationByBankNumberOffset[i] + stationByBankNumberOccurrences[i];
    storageOffset[i + 1] = stationByBankNumberOffset[i + 1];
  }
  for (size_t i = 0; i < maxNumberOfRawBanks; i++) {
    orderOfBanks[stationByBankNumberOffset[stationByBankNumber[i]]++] = i;
  }
  size_t currentStorageOffsetIndex = 0;
  for (size_t j = 0; j < maxNumberOfRawBanks; j++) {
    uint32_t bank_index = orderOfBanks[j];
    while (currentStorageOffsetIndex < Muon::Constants::n_stations && storageOffset[currentStorageOffsetIndex] < j) {
      currentStorageOffsetIndex++;
    }
    if (storageOffset[currentStorageOffsetIndex] == j) {
      storageOffset[currentStorageOffsetIndex] = currentStorageIndex;
      currentStorageOffsetIndex++;
    }
    Muon::MuonRawBank rawBank = rawEvent.getMuonBank(bank_index);
    uint16_t* p = rawBank.data;
    int preamble_size = 2 * ((*p + 3) / 2);
    p += preamble_size;
    for (size_t i = 0; i < 4; i++) {
      uint16_t frontValue = *p;
      for (size_t shift = 1; shift < 1 + frontValue; shift++) {
        unsigned int pp = *(p + shift);
        unsigned int add = (pp & 0x0FFF);
        unsigned int tdc_value = ((pp & 0xF000) >> 12);
        Muon::MuonTileID tile = Muon::MuonTileID(
            muonGeometry.getADDInTell1(tell1NumberByBankNumber[bank_index], add)
        );
        unsigned int tileId = tile.id();
        if (tileId != 0) {
          storage[currentStorageIndex] = Digit(tile, tdc_value);
          currentStorageIndex++;
        }
      }
      p += 1 + frontValue;
    }
  }
  for (size_t i = currentStorageOffsetIndex; i <= Muon::Constants::n_stations; i++) {
    storageOffset[i] = currentStorageIndex;
  }
}
