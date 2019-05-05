#include "MuonRawToHits.cuh"
#include <stdio.h>

namespace Muon {
  __device__ void setAtIndex(HitsSoA* hitsSoA, size_t index, int tile, float x, float dx, float y, float dy,
      float z, float dz, int uncrossed, unsigned int time, int delta_time, int cluster_size, int region) {
    hitsSoA->tile[index] = tile;
    hitsSoA->x[index] = x;
    hitsSoA->dx[index] = dx;
    hitsSoA->y[index] = y;
    hitsSoA->dy[index] = dy;
    hitsSoA->z[index] = z;
    hitsSoA->dz[index] = dz;
    hitsSoA->uncrossed[index] = uncrossed;
    hitsSoA->time[index] = time;
    hitsSoA->delta_time[index] = delta_time;
    hitsSoA->cluster_size[index] = cluster_size;
    hitsSoA->region_id[index] = region;
  }

  __device__ void recalculateNumberOfHitsPerStationAndStationOffsets(HitsSoA* hitsSoA,
      size_t totalNumberOfHits) {
    hitsSoA->station_offsets[0] = 0;
    int currentStation = MuonTileID::station(hitsSoA->tile[0]);
    int initialCurrentStation = currentStation;
    for (int i = 1; i < totalNumberOfHits; i++) {
      auto id = static_cast<unsigned int>(hitsSoA->tile[i]);
      if (MuonTileID::station(id) != currentStation) {
        hitsSoA->station_offsets[currentStation + 1] = i;
        currentStation++;
      }
    }

    for (int j = currentStation; j + 1 < Constants::n_stations; j++) {
      hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
    }
    if (initialCurrentStation == currentStation) {
      for (int j = initialCurrentStation; j + 1 < Constants::n_stations; j++) {
        hitsSoA->station_offsets[j + 1] = totalNumberOfHits;
      }
    }
    for (currentStation = 0; currentStation + 1 < Constants::n_stations; currentStation++) {
      hitsSoA->number_of_hits_per_station[currentStation] =
          hitsSoA->station_offsets[currentStation + 1] - hitsSoA->station_offsets[currentStation];
    }
    hitsSoA->number_of_hits_per_station[Constants::n_stations - 1] =
        totalNumberOfHits - hitsSoA->station_offsets[Constants::n_stations - 1];
  }

  __device__ size_t regionAndQuarter(const Digit& i) {
    return i.tile.region() * Constants::n_quarters + i.tile.quarter();
  }

  __device__ void MuonRawToHits::operator()(MuonRawEvent& rawEvent, HitsSoA* hitsSoA) const {
    size_t currentHitsIndex = 0;
    Digit decoding[Constants::max_numhits_per_event];
    Digit sortedDecoding[Constants::max_numhits_per_event];
    bool used[Constants::max_numhits_per_event] = {false};
    size_t decodingOffset[Constants::n_stations + 1] = {0};
    decodeTileAndTDC(rawEvent, decoding, decodingOffset);
    //printf("decodingOffset:");
    //for (size_t i = 0; i <= 5; i++) {
    //  printf("%u ", decodingOffset[i]);
    //}
    //printf("\n");
    for (size_t currentStation = 0; currentStation < Constants::n_stations; currentStation++) {
      size_t regionAndQuarterOccurrences[Constants::n_quarters * Constants::n_regions] = {0};
      for (size_t i = decodingOffset[currentStation]; i < decodingOffset[currentStation + 1]; i++) {
        regionAndQuarterOccurrences[regionAndQuarter(decoding[i])]++;
      }
      //printf("regionAndQuarterOccurrences: ");
      //for (size_t i = 0; i < Constants::n_quarters * Constants::n_regions; i++) {
      //  printf("%u ", regionAndQuarterOccurrences[i]);
      //}
      //printf("\n");
      size_t regionAndQuarterOccurrencesOffset[Constants::n_quarters * Constants::n_regions + 1] = {0};
      size_t originalRegionAndQuarterOccurrencesOffset[Constants::n_quarters * Constants::n_regions + 1] = {0};
      for (size_t i = 0; i < Constants::n_quarters * Constants::n_regions; i++) {
        regionAndQuarterOccurrencesOffset[i + 1] =
            regionAndQuarterOccurrencesOffset[i] + regionAndQuarterOccurrences[i];
        originalRegionAndQuarterOccurrencesOffset[i + 1] = regionAndQuarterOccurrencesOffset[i + 1];
      }
      //printf("regionAndQuarterOccurrencesOffset: ");
      //for (size_t i = 0; i <= Constants::n_quarters * Constants::n_regions; i++) {
      //  printf("%u ", regionAndQuarterOccurrencesOffset[i]);
      //}
      //printf("}\n");
      //printf("originalregionAndQuarterOccurrencesOffset: ");
      //for (size_t i = 0; i <= Constants::n_quarters * Constants::n_regions; i++) {
      //  printf("%u ", originalRegionAndQuarterOccurrencesOffset[i]);
      //}
      //printf("}\n");


      for (size_t i = decodingOffset[currentStation]; i < decodingOffset[currentStation + 1]; i++) {
        size_t currentRegionAndQuarter = regionAndQuarter(decoding[i]);
        size_t index = regionAndQuarterOccurrencesOffset[currentRegionAndQuarter] + decodingOffset[currentStation];
        regionAndQuarterOccurrencesOffset[currentRegionAndQuarter]++;
        sortedDecoding[index] = decoding[i];
      }
      for (size_t i = 0; i < Constants::n_quarters * Constants::n_regions; i++) {
        //printf("a = %u\n", decodingOffset[currentStation]);
        //printf("b = %u\n",  + originalRegionAndQuarterOccurrencesOffset[i]);
        //printf("call addCoordsCrossingMap: %u, ", decodingOffset[currentStation] + originalRegionAndQuarterOccurrencesOffset[i]);
        //printf("%u\n", decodingOffset[currentStation] + originalRegionAndQuarterOccurrencesOffset[i + 1]);
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

  __device__ void MuonRawToHits::makeStripLayouts(const unsigned int station, const unsigned int region,
      MuonLayout* layouts) const {
    unsigned int x1 = getLayoutX((MuonTables*) &muonTables, MuonTables::stripXTableNumber, station, region);
    unsigned int y1 = getLayoutY((MuonTables*) &muonTables, MuonTables::stripXTableNumber, station, region);
    unsigned int x2 = getLayoutX((MuonTables*) &muonTables, MuonTables::stripYTableNumber, station, region);
    unsigned int y2 = getLayoutY((MuonTables*) &muonTables, MuonTables::stripYTableNumber, station, region);
    layouts[x1 > x2] = MuonLayout(x2, y2);
    layouts[x1 <= x2] = MuonLayout(x1, y1);
  }

  __device__ void MuonRawToHits::addCoordsCrossingMap(Digit* digits, bool* used, size_t startIndex,
      size_t endIndex, HitsSoA* hitsSoA, size_t& currentHitIndex) const {
    if (startIndex == endIndex) {
      return;
    }
    //for (int i = startIndex; i < endIndex; i++) {
    //  printf("%d\n", digits[i].tile.id());
    //}
    //printf("\n");
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
    Muon::DigitHashtable digitHashtable;
    //std::cerr << startIndex << " " << midIndex << " " << endIndex << "\n";
    for (size_t digitsOneIndex = startIndex; digitsOneIndex < midIndex; digitsOneIndex++) {
      unsigned int keyX = digits[digitsOneIndex].tile.nX() * otherGridX / thisGridX;
      unsigned int keyY = digits[digitsOneIndex].tile.nY();
      digitHashtable.add(keyX, keyY, digitsOneIndex);
      //std::cerr << "keyX = " << keyX << ", keyY = " << keyY << ", digitsOneIndex = " << digitsOneIndex << "\n";
    }

    for (size_t digitsTwoIndex = midIndex; digitsTwoIndex < endIndex; digitsTwoIndex++) {
      unsigned int candidateX = digits[digitsTwoIndex].tile.nX();
      unsigned int candidateY = digits[digitsTwoIndex].tile.nY() * thisGridY / otherGridY;
      //std::cerr << "candidateX = " << candidateX << ", candidateY = " << candidateY << "\n";
      //std::cerr << "keyX = " << candidateX << ", keyY = " << candidateY << "\n";
      short foundDigitHashtableIndex = digitHashtable.find(candidateX, candidateY);
      if (foundDigitHashtableIndex == -1) {
        continue;
      }
      //std::cerr << "foundDigitHashtableIndex = " << foundDigitHashtableIndex << "\n";
      size_t digitsOneIndex;
      bool found;
      do {
        found = digitHashtable.iterateOverValues(foundDigitHashtableIndex, digitsOneIndex);
        if (found) {
          //std::cerr << "found " << digitsOneIndex << "\n";
          Muon::MuonTileID padTile(digits[digitsOneIndex].tile);
          padTile.setY(digits[digitsTwoIndex].tile.nY());
          padTile.setLayout(MuonLayout(thisGridX, otherGridY));
          double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
          calcTilePos((MuonTables*) &muonTables, padTile, x, dx, y, dy, z);
          unsigned int uncrossed = 0;
          int clusterSize = 0;
          int region = padTile.region();
          setAtIndex(hitsSoA, currentHitIndex, padTile.id(), x, dx, y, dy, z, dz, uncrossed, digits[digitsOneIndex].tdc,
                              digits[digitsOneIndex].tdc - digits[digitsTwoIndex].tdc, clusterSize, region);
          currentHitIndex++;
          used[digitsOneIndex] = used[digitsTwoIndex] = true;
        }
      } while (found);
    }
    /*
      for (size_t digitsOneIndex = startIndex; digitsOneIndex < midIndex; digitsOneIndex++) {
      unsigned int keyX = digits[digitsOneIndex].tile.nX() * otherGridX / thisGridX;
      unsigned int keyY = digits[digitsOneIndex].tile.nY();
      for (size_t digitsTwoIndex = midIndex; digitsTwoIndex < endIndex; digitsTwoIndex++) {
        unsigned int candidateX = digits[digitsTwoIndex].tile.nX();
        unsigned int candidateY = digits[digitsTwoIndex].tile.nY() * thisGridY / otherGridY;
        if (keyX == candidateX && keyY == candidateY) {
          MuonTileID padTile(digits[digitsOneIndex].tile);
          padTile.setY(digits[digitsTwoIndex].tile.nY());
          padTile.setLayout(MuonLayout(thisGridX, otherGridY));
          float x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
          calcTilePos((MuonTables*) &muonTables, padTile, x, dx, y, dy, z);
          unsigned int uncrossed = 0;
          int clusterSize = 0;
          int region = padTile.region();
          //printf("crossed: %u\n", padTile.id());
          //printf("currentHitIndex = %u\n", currentHitIndex);
          setAtIndex(hitsSoA, currentHitIndex, padTile.id(), x, dx, y, dy, z, dz, uncrossed,
                     digits[digitsOneIndex].tdc, digits[digitsOneIndex].tdc - digits[digitsTwoIndex].tdc,
                     clusterSize, region);
          currentHitIndex++;
          used[digitsOneIndex] = used[digitsTwoIndex] = true;
        }
      }
    }
    */
    size_t startIndices[] = {startIndex, midIndex};
    size_t endIndices[] = {midIndex, endIndex};
    for (size_t currentDigitsIndex = 0; currentDigitsIndex < 2; currentDigitsIndex++) {
      for (size_t currentDigitIndex = startIndices[currentDigitsIndex];
           currentDigitIndex < endIndices[currentDigitsIndex];
           currentDigitIndex++) {
        if (!used[currentDigitIndex]) {
          double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
          int region = digits[currentDigitIndex].tile.region();
          if (digits[currentDigitIndex].tile.station() > (Constants::n_stations - 3) && region == 0) {
            calcTilePos((MuonTables*) &muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
          } else {
            if (currentDigitsIndex == 0) {
              calcStripXPos((MuonTables*) &muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
            } else {
              calcStripYPos((MuonTables*) &muonTables, digits[currentDigitIndex].tile, x, dx, y, dy, z);
            }
          }
          unsigned int uncrossed = 1;
          int clusterSize = 0;
          //std::cerr << "uncrossed: " << digit.tile.id() << " " << currentHitIndex << "\n";
          //printf("uncrossed: %u\n", digits[currentDigitIndex].tile.id());
          //printf("currentHitIndex = %u\n", currentHitIndex);
          setAtIndex(hitsSoA, currentHitIndex, digits[currentDigitIndex].tile.id(), x, dx, y, dy, z, dz, uncrossed,
                     digits[currentDigitIndex].tdc, digits[currentDigitIndex].tdc, clusterSize, region);
          currentHitIndex++;
        }
      }
    }
  }

  __device__ void MuonRawToHits::decodeTileAndTDC(MuonRawEvent& rawEvent, Digit* storage, size_t* storageOffset) const {
    size_t currentStorageIndex = 0;
    //Is it true that files always contain 10 banks?
    constexpr size_t maxNumberOfRawBanks = 10;
    size_t tell1NumberByBankNumber[maxNumberOfRawBanks];
    size_t stationByBankNumber[maxNumberOfRawBanks];
    size_t stationByBankNumberOccurrences[Constants::n_stations] = {0};
    size_t stationByBankNumberOffset[Constants::n_stations] = {0};
    size_t orderOfBanks[maxNumberOfRawBanks];
    for (uint32_t bank_index = 0; bank_index < rawEvent.number_of_raw_banks; bank_index++) {
      unsigned int tell1Number = rawEvent.getMuonBank(bank_index).sourceID;
      tell1NumberByBankNumber[bank_index] = tell1Number;
      stationByBankNumber[bank_index] = (tell1Number < 4 ? 0 : tell1Number < 6 ? 1 : tell1Number < 8 ? 2 : 3);
      stationByBankNumberOccurrences[stationByBankNumber[bank_index]]++;
      //printf("PRINT: bank_index = %u\n", bank_index);
      //for (int j = 0; j < 10; j++) {
        //printf("tell1Number = %u, stationByBankNumber[%u] = %u\n", tell1Number, j, stationByBankNumber[j]);
      //}
      //for (int j = 0; j < 4; j++) {
        //printf("%u\n", stationByBankNumberOccurrences[j]);
      //}
    }

    for (size_t i = 0; i < Constants::n_stations - 1; i++) {
      stationByBankNumberOffset[i + 1] = stationByBankNumberOffset[i] + stationByBankNumberOccurrences[i];
      storageOffset[i + 1] = stationByBankNumberOffset[i + 1];
      //printf("PRINT: offset: i = %u\n", i);
      
      //for (int j = 0; j < 4; j++) {
        //printf("stationByBankNumberOffset[%u] = %u\n", j, stationByBankNumberOffset[j]);
        //printf("storageOffset[%u] = %u\n", j, storageOffset[j]);
      //}
    }
    for (size_t i = 0; i < maxNumberOfRawBanks; i++) {
      orderOfBanks[stationByBankNumberOffset[stationByBankNumber[i]]++] = i;
      //printf("PRINT: order: i = %u\n", i);
      //for (int j = 0; j < 10; j++) {
        //printf("j = %u, stationByBankNumber[%u] = %u, stationByBankNumberOffset[%u] = %u\n",
               //j, j, stationByBankNumber[j], j, stationByBankNumberOffset[j]);
      //}
    }
    size_t currentStorageOffsetIndex = 0;
    for (size_t j = 0; j < maxNumberOfRawBanks; j++) {
      uint32_t bank_index = orderOfBanks[j];
      //printf("j = %u, bank_index = %u, currentStorageOffsetIndex = %u, storageOffset[currentStorageOffsetIndex] = %u\n", j, bank_index, currentStorageOffsetIndex, storageOffset[currentStorageOffsetIndex]);
      while (currentStorageOffsetIndex < Constants::n_stations && storageOffset[currentStorageOffsetIndex] < j) {
        currentStorageOffsetIndex++;
      }
      if (storageOffset[currentStorageOffsetIndex] == j) {
        storageOffset[currentStorageOffsetIndex] = currentStorageIndex;
        currentStorageOffsetIndex++;
      }
      MuonRawBank rawBank = rawEvent.getMuonBank(bank_index);
      uint16_t* p = rawBank.data;
      int preamble_size = 2 * ((* p + 3) / 2);
      //printf("preamble_size = %u\n", preamble_size);
      
      p += preamble_size;
      for (size_t i = 0; i < 4; i++) {
        uint16_t frontValue = *p;
        //printf("frontValue = %u\n", frontValue);
        for (size_t shift = 1; shift < 1 + frontValue; shift++) {
          unsigned int pp = *(p + shift);
          unsigned int add = (pp & 0x0FFF);
          unsigned int tdc_value = ((pp & 0xF000) >> 12);
          //printf("pp = %u, add = %u, tdc_value = %u\n", pp, add, tdc_value);
          MuonTileID tile = MuonTileID(muonGeometry.getADDInTell1(tell1NumberByBankNumber[bank_index], add));
          unsigned int tileId = tile.id();
          //printf("id = %u\n", tileId);
          if (tileId != 0) {
            storage[currentStorageIndex] = {tile, tdc_value};
            currentStorageIndex++;
          }
        }
        p += 1 + frontValue;
      }
    }
    for (size_t i = currentStorageOffsetIndex; i <= Constants::n_stations; i++) {
      storageOffset[i] = currentStorageIndex;
    }
  }
};
