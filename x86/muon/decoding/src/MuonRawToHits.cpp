#include "MuonRawToHits.h"
#include <iostream>

namespace MuonRawHits {

  enum class ErrorCode {
    BAD_MAGIC = 10,
    BANK_TOO_SHORT,
    PADDING_TOO_LONG,
    TOO_MANY_HITS,
    INVALID_TELL1
  };

  struct ErrorCategory {
    const char *name() const { return "MuonRawBankDecoding"; }

    std::string message(ErrorCode code) const {
      switch (code) {
        case ErrorCode::BAD_MAGIC:
          return "Incorrect Magic pattern in raw bank";
        case ErrorCode::BANK_TOO_SHORT:
          return "Muon bank is too short";
        case ErrorCode::PADDING_TOO_LONG:
          return "Muon bank has too much padding for its size";
        case ErrorCode::TOO_MANY_HITS:
          return "Muon bank has too many hits for its size";
        case ErrorCode::INVALID_TELL1:
          return "Invalid TELL1 source ID";
        default:
          return "unknown exception";
      }
    }
  };
} // namespace MuonRawHits

namespace {
  [[gnu::noreturn]] void throw_exception(MuonRawHits::ErrorCode ec, const char *tag) {
    throw tag;
  }
}
#define OOPS(x) throw_exception( x, __PRETTY_FUNCTION__ )

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

  int currentStation = Muon::MuonTileID::station(hitsSoA->tile[0]);
  int initialCurrentStation = currentStation;
  for (int i = 1; i < currentHitsIndex; i++) {
    auto id = static_cast<unsigned int>(hitsSoA->tile[i]);
    if (Muon::MuonTileID::station(id) != currentStation) {
      hitsSoA->station_offsets[currentStation + 1] = i;
      currentStation++;
    }
  }
  if (initialCurrentStation == currentStation) {
    for (int j = initialCurrentStation; j + 1 < Muon::Constants::n_stations; j++) {
      hitsSoA->station_offsets[j + 1] = currentHitsIndex;
    }
  }
  for (currentStation = 0; currentStation + 1 < m_nStations; currentStation++) {
    hitsSoA->number_of_hits_per_station[currentStation] = hitsSoA->station_offsets[currentStation + 1] - hitsSoA->station_offsets[currentStation];
  }
  hitsSoA->number_of_hits_per_station[m_nStations - 1] = currentHitsIndex - hitsSoA->station_offsets[m_nStations - 1];
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
//        commonHits.emplace_back( std::move( padTile ), x, dx, y, dy, z, 0, 0, one.tdc, one.tdc - two.tdc );
        used[i] = used[j] = true;
      }
      ++j;
    }
    ++i;
  }

  // copy over "uncrossed" digits

  unsigned m = 0;
  for (Digits::iterator digits_it = digitsOne.first; digits_it != digitsOne.second; digits_it++) {
    Digit &digit = *digits_it;
    if (!used[m]) {
      double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
      if (digit.tile.station() > (m_nStations - 3) && digit.tile.region() == 0) {
        calcTilePos(pad, digit.tile, x, dx, y, dy, z);
      } else {
        calcStripPos(stripX, digit.tile, x, dx, y, dy, z);
      }
      unsigned int uncrossed = 1;
      int clusterSize = 0;
      int region = digit.tile.region();
      hitsSoA->addAtIndex(currentHitIndex, digit.tile.id(), x, dx, y, dy, z, dz, uncrossed, digit.tdc, digit.tdc,
                          clusterSize, region);
      currentHitIndex++;
//      commonHits.emplace_back( digit.tile, x, dx, y, dy, z, 0, 1, digit.tdc, digit.tdc );
    }
    ++m;
  }
  for (Digits::iterator digits_it = digitsTwo.first; digits_it != digitsTwo.second; digits_it++) {
    Digit &digit = *digits_it;
    if (!used[m]) {
      double x = 0., dx = 0., y = 0., dy = 0., z = 0., dz = 0.;
      if (digit.tile.station() > (m_nStations - 3) && digit.tile.region() == 0) {
        calcTilePos(pad, digit.tile, x, dx, y, dy, z);
      } else {
        calcStripPos(stripY, digit.tile, x, dx, y, dy, z);
      }
      unsigned int uncrossed = 1;
      int clusterSize = 0;
      int region = digit.tile.region();
      hitsSoA->addAtIndex(currentHitIndex, digit.tile.id(), x, dx, y, dy, z, dz, uncrossed, digit.tdc, digit.tdc,
                          clusterSize, region);
      currentHitIndex++;
      //commonHits.emplace_back( digit.tile, x, dx, y, dy, z, 0, 1, digit.tdc, digit.tdc );
    }
    ++m;
  }

}


void MuonRawToHits::decodeTileAndTDC(Muon::MuonRawEvent &rawEvent, std::array<std::vector<Digit>, 4> &storage) const {

  // array of vectors of hits
  // each element of the array correspond to hits from a single station
  // this will ease the sorting after

  for (uint32_t bank_index = 0; bank_index < rawEvent.number_of_raw_banks; bank_index++) {
    auto r = rawEvent.getMuonBank(bank_index);
    unsigned int tell1Number = r.sourceID;
    //if ( tell1Number >= MuonDAQHelper_maxTell1Number ) { OOPS( MuonRawHits::ErrorCode::INVALID_TELL1 ); }

    // decide in which array put the digits according to the Tell1 they come from
    const int inarray = (tell1Number < 4 ? 0 : tell1Number < 6 ? 1 : tell1Number < 8 ? 2 : 3);

    // minimum length is 3 words --> 12 bytes
    auto range = r.range<unsigned short>();
    auto preamble_size = 2 * ((range[0] + 3) / 2);
    //if ( range.size() < preamble_size ) { OOPS( MuonRawHits::ErrorCode::PADDING_TOO_LONG ); }
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
