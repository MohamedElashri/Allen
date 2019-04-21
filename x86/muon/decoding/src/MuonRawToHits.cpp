#include "MuonRawToHits.h"

void recalculateNumberOfHitsPerStationAndStationOffsets(Muon::HitsSoA* hitsSoA, size_t totalNumberOfHits) {
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

void MuonRawToHits::operator()(Muon::MuonRawEvent &rawEvent, Muon::HitsSoA *hitsSoA) const {
  size_t currentHitsIndex = 0;
  std::array<std::vector<Digit>, 4> decoding;
  decodeTileAndTDC(rawEvent, decoding);
  constexpr auto regionAndQuarter = [](const Digit &i) { return i.tile.region() * 4 + i.tile.quarter(); };
  for (auto &decode : decoding) {
    std::sort(decode.begin(), decode.end(),
              [&](const Digit &a, const Digit &b) { return regionAndQuarter(a) < regionAndQuarter(b); });
  }

  for (auto &decode : decoding) {
    std::vector<DigitsRange> perRegQua;
    unsigned nReg = 0;
    auto it = decode.begin();
    for (auto jt = it; jt != decode.end(); ++jt) {
      if (regionAndQuarter(*jt) != regionAndQuarter(*it)) {
        perRegQua.push_back(make_pair(it, jt));
        it = jt;
      }
    }
    perRegQua.push_back(make_pair(it, decode.end()));
    for (auto &coordsPerRegQua : perRegQua) {
      addCoordsCrossingMap(coordsPerRegQua, hitsSoA, currentHitsIndex);
    }
  }

  recalculateNumberOfHitsPerStationAndStationOffsets(hitsSoA, currentHitsIndex);
}

std::array<MuonLayout, 2> MuonRawToHits::makeStripLayouts(const unsigned int station,
                                                          const unsigned int region) const {
  unsigned int x1 = getLayoutX(stripX, station, region);
  unsigned int y1 = getLayoutY(stripX, station, region);
  unsigned int x2 = getLayoutX(stripY, station, region);
  unsigned int y2 = getLayoutY(stripY, station, region);
  if (x1 > x2) {
    return {MuonLayout(x1, y1), MuonLayout(x2, y2)};
  } else {
    return {MuonLayout(x2, y2), MuonLayout(x1, y1)};
  }
}

void MuonRawToHits::addCoordsCrossingMap(DigitsRange &digits, Muon::HitsSoA *hitsSoA, size_t &currentHitIndex) const {
  if (std::distance(digits.first, digits.second) == 0) {
    return;
  }
  const auto&[layoutOne, layoutTwo] = makeStripLayouts((*(digits.first)).tile.station(),
                                                       (*(digits.first)).tile.region());
  std::vector<bool> used(std::distance(digits.first, digits.second), false);

  const auto mid = std::partition(digits.first, digits.second,
                                  [&layoutOne](const Digit &digit) { return digit.tile.layout() == layoutOne; });
  auto digitsOne = make_pair(digits.first, mid);
  auto digitsTwo = make_pair(mid, digits.second);

  unsigned i = 0;
  int thisGridX = layoutOne.xGrid();
  int thisGridY = layoutOne.yGrid();
  int otherGridX = layoutTwo.xGrid();
  int otherGridY = layoutTwo.yGrid();
  for (Digits::iterator digits_it = digitsOne.first; digits_it != digitsOne.second; digits_it++) {
    const Digit &one = *digits_it;
    unsigned j = mid - digits.first;
    for (Digits::iterator digits_it2 = digitsTwo.first; digits_it2 != digitsTwo.second; digits_it2++) {
      const Digit &two = *digits_it2;
      if ((one.tile.nX() / thisGridX == two.tile.nX() / otherGridX) &&
          (one.tile.nY() / thisGridY == two.tile.nY() / otherGridY)) {
        unsigned int calcX = one.tile.nX() * otherGridX / thisGridX;
        if (calcX != two.tile.nX()) {
          ++j;
          continue;
        }

        unsigned int calcY = two.tile.nY() * thisGridY / otherGridY;
        if (calcY != one.tile.nY()) {
          ++j;
          continue;
        }

        Muon::MuonTileID padTile(one.tile);
        padTile.setY(two.tile.nY());
        padTile.setLayout(MuonLayout(thisGridX, otherGridY));

        double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
        calcTilePos(pad, padTile, x, dx, y, dy, z);
        unsigned int uncrossed = 0;
        int clusterSize = 0;
        int region = padTile.region();
        hitsSoA->addAtIndex(currentHitIndex, padTile.id(), x, dx, y, dy, z, dz, uncrossed, one.tdc, one.tdc - two.tdc,
                            clusterSize, region);
        currentHitIndex++;
        used[i] = used[j] = true;
      }
      ++j;
    }
    ++i;
  }

  unsigned m = 0;
  std::array<std::pair<DigitsRange, MuonTable*>, 2> digitsRangeAndMuonTable = {
      std::make_pair(digitsOne, stripX),
      std::make_pair(digitsTwo, stripY)
  };
  for (auto currentDigitsRangeAndMuonTable: digitsRangeAndMuonTable) {
    auto currentDigits = currentDigitsRangeAndMuonTable.first;
    auto currentMuonTable = currentDigitsRangeAndMuonTable.second;
    for (Digits::iterator digits_it = currentDigits.first; digits_it != currentDigits.second; digits_it++) {
      Digit &digit = *digits_it;
      if (!used[m]) {
        double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
        if (digit.tile.station() > (Muon::Constants::n_stations - 3) && digit.tile.region() == 0) {
          calcTilePos(pad, digit.tile, x, dx, y, dy, z);
        } else {
          calcStripPos(currentMuonTable, digit.tile, x, dx, y, dy, z);
        }
        unsigned int uncrossed = 1;
        int clusterSize = 0;
        int region = digit.tile.region();
        hitsSoA->addAtIndex(currentHitIndex, digit.tile.id(), x, dx, y, dy, z, dz, uncrossed, digit.tdc, digit.tdc,
                            clusterSize, region);
        currentHitIndex++;
      }
      ++m;
    }
  }
}

void MuonRawToHits::decodeTileAndTDC(Muon::MuonRawEvent &rawEvent, std::array<std::vector<Digit>, 4> &storage) const {
  for (uint32_t bank_index = 0; bank_index < rawEvent.number_of_raw_banks; bank_index++) {
    auto r = rawEvent.getMuonBank(bank_index);
    unsigned int tell1Number = r.sourceID;
    const int inarray = (tell1Number < 4 ? 0 : tell1Number < 6 ? 1 : tell1Number < 8 ? 2 : 3);
    auto range = r.range<unsigned short>();
    auto preamble_size = 2 * ((range[0] + 3) / 2);
    range = range.subspan(preamble_size);

    for (int i = 0; i < 4; i++) {
      for (unsigned int pp : range.subspan(1, range[0])) {
        unsigned int add = (pp & 0x0FFF);
        unsigned int tdc_value = ((pp & 0xF000) >> 12);
        Muon::MuonTileID tile = Muon::MuonTileID(muonGeometry->getADDInTell1(tell1Number, add));
        unsigned int pippo = tile.id();
        if (pippo != 0) {
          storage[inarray].push_back(Digit{tile, tdc_value});
        }
      }
      range = range.subspan(1 + range[0]);
    }
    //assert(range.empty());
  }
}
