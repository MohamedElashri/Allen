/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <array>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/math/special_functions/relative_difference.hpp>

#include "TestMuonTable.h"
#include <Dumpers/Utils.h>

namespace {
  using std::array;
  using std::string;
  using std::to_string;
  using std::tuple;
  using std::vector;

  namespace fs = boost::filesystem;

  template<typename T, auto Extent>
  constexpr void pop_n(gsl::span<const char>& buffer, size_t n, gsl::span<T, Extent> out)
  {
    static_assert(std::is_trivially_copyable_v<T>);
    assert(out.size() >= n);
    auto sz = n * sizeof(T);
    assert(buffer.size() >= sz);
    std::memcpy(out.data(), buffer.data(), sz);
    buffer = buffer.subspan(sz);
  }

  template<typename Out>
  constexpr void pop_n(gsl::span<const char>& buffer, size_t n, Out& out)
  {
    pop_n(buffer, n, gsl::span {out});
  }

  template<typename Out>
  [[nodiscard]] constexpr Out pop(gsl::span<const char>& buffer)
  {
    Out out {};
    pop_n(buffer, 1, gsl::span {&out, 1});
    return out;
  }

} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TestMuonTable)

unsigned int pad_offset(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile)
{
  int idx = 4 * tile.station() + tile.region();
  int perQuarter = 3 * table.gridX[idx] * table.gridY[idx];
  return static_cast<unsigned int>((4 * tile.region() + tile.quarter()) * perQuarter);
}

unsigned int strip_offset(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile)
{
  int idx = 4 * tile.station() + tile.region();
  int perQuarter = 3 * table.gridX[idx] * table.gridY[idx];
  return table.offset[4 * tile.station() + tile.region()] + tile.quarter() * perQuarter;
}

size_t lookup_index(MuonTable const& table, LHCb::Detector::Muon::TileID const& tile)
{
  int station = tile.station();
  int region = tile.region();
  int idx = 4 * station + region;
  int xpad = static_cast<int>(tile.nX());
  int ypad = static_cast<int>(tile.nY());
  auto index = table.offset_fun(table, tile);

  if (ypad < table.gridY[idx]) {
    index += table.gridX[idx] * ypad + xpad - table.gridX[idx];
  }
  else {
    index += table.gridX[idx] * table.gridY[idx] + 2 * table.gridX[idx] * (ypad - table.gridY[idx]) + xpad;
  }
  return index;
}

void lookup(
  MuonTable const& table,
  LHCb::Detector::Muon::TileID const& tile,
  double& x,
  double& deltax,
  double& y,
  double& deltay,
  double& z)
{
  int station = tile.station();
  auto index = lookup_index(table, tile);
  auto& p = table.table[station][index];
  x = p[0];
  y = p[1];
  z = p[2];

  auto dxi = MuonUtils::size_index(table.sizeOffset, table.gridX, table.gridY, tile);
  deltax = table.sizeX[dxi];
  deltay = table.sizeY[dxi];
}

unsigned int getLayoutX(MuonTable const& table, unsigned int station, unsigned int region)
{
  return table.gridX[4 * station + region];
}

unsigned int getLayoutY(MuonTable const& table, unsigned int station, unsigned int region)
{
  return table.gridY[4 * station + region];
}

tuple<std::reference_wrapper<const MuonTable>, string> lookup_table(
  LHCb::Detector::Muon::TileID const& tile,
  bool const uncrossed,
  MuonTable const& pad,
  MuonTable const& stripX,
  MuonTable const& stripY)
{
  unsigned int x1 = getLayoutX(stripX, tile.station(), tile.region());
  unsigned int y1 = getLayoutY(stripX, tile.station(), tile.region());
  auto table = tuple {std::cref(pad), "pad"};
  if (uncrossed) {
    if (tile.station() <= 1 || tile.region() != 0) {
      if (tile.layout().xGrid() == x1 && tile.layout().yGrid() == y1) {
        table = {std::cref(stripX), "stripX"};
      }
      else {
        table = {std::cref(stripY), "stripY"};
      }
    }
  }
  return table;
}

void coord_position(
  LHCb::Detector::Muon::TileID const& tile,
  MuonTable const& pad,
  MuonTable const& stripX,
  MuonTable const& stripY,
  bool const uncrossed,
  double& x,
  double& dx,
  double& y,
  double& dy,
  double& z)
{
  auto r = lookup_table(tile, uncrossed, pad, stripX, stripY);
  lookup(std::get<0>(r).get(), tile, x, dx, y, dy, z);
}

void read_muon_table(gsl::span<const char> raw_input, MuonTable& pad, MuonTable& stripX, MuonTable& stripY)
{
  size_t n = 0;
  for (MuonTable& muonTable : {std::ref(pad), std::ref(stripX), std::ref(stripY)}) {
    for_each(
      std::tie(muonTable.gridX, muonTable.gridY, muonTable.sizeX, muonTable.sizeY, muonTable.offset),
      [&n, &raw_input](auto& table) {
        auto s = pop<size_t>(raw_input);

        optional_resize(table, s);
        assert(s == table.size());

        // Read the data into the container
        pop_n(raw_input, s, table);
        ++n;
      });

    for (size_t i = 0; i < muonTable.gridY.size() - 1; ++i) {
      muonTable.sizeOffset[i + 1] = muonTable.sizeOffset[i] + 24 * muonTable.gridY[i];
    }
    assert((muonTable.sizeOffset.back() + 24 * muonTable.gridY.back()) == muonTable.sizeX.size());

    auto tableSize = pop<size_t>(raw_input);
    assert(tableSize == 4);

    for (size_t i = 0; i < tableSize; i++) {
      auto stationTableSize = pop<size_t>(raw_input);
      muonTable.table[i].resize(stationTableSize);
      for (auto& tbl : muonTable.table[i]) {
        pop_n(raw_input, 3, tbl);
      }
    }
  }
}

TestMuonTable::TestMuonTable(const string& name, ISvcLocator* pSvcLocator) :
  Consumer(name, pSvcLocator, {KeyValue {"MuonCoordsLocation", LHCb::MuonCoordLocation::MuonCoords}})
{}

StatusCode TestMuonTable::initialize()
{
  m_det = getDet<DeMuonDetector>(DeMuonLocation::Default);

  fs::path p {m_table.value()};
  auto read_size = fs::file_size(p);
  std::vector<char> raw_input(read_size);

  std::ifstream input(p.c_str(), std::ios::binary);
  input.read(raw_input.data(), read_size);
  input.close();

  read_muon_table(raw_input, m_pad, m_stripX, m_stripY);

  return StatusCode::SUCCESS;
}

void TestMuonTable::operator()(const LHCb::MuonCoords& muonCoords) const
{
 
  double xt = 0., dxt = 0., yt = 0., dyt = 0., zt = 0.;

  size_t n = 0;

  for (auto coord : muonCoords) {

    auto pos = m_det->position(coord->key());

    coord_position(coord->key(), m_pad, m_stripX, m_stripY, coord->uncrossed(), xt, dxt, yt, dyt, zt);

    array<tuple<char const*, double, double>, 5> values {{{"x ", pos->x(), xt},
                                                          {"dx", pos->dX(), dxt},
                                                          {"y ", pos->y(), yt},
                                                          {"dy", pos->dY(), dyt},
                                                          {"z ", pos->z(), zt}}};

    boost::format msg {"%|4d| %|8d| %|6s| %|d| %|d| %|d| %|2d| %|2d| %|d| %|5d| %|5d|"};

    for (auto [w, a, b] : values) {
      if (boost::math::relative_difference(a, b) > 0.01) {
        auto const& tile = coord->key();
        auto [table, tt] = lookup_table(tile, coord->uncrossed(), m_pad, m_stripX, m_stripY);
        const auto index = lookup_index(table.get(), tile);

        auto dx_index = MuonUtils::size_index(table.get().sizeOffset, table.get().gridX, table.get().gridY, tile);

        // positions are always indexed by station
        error() << (msg % n % static_cast<unsigned int>(tile) % tt % tile.station() % tile.region() % tile.quarter() %
                    tile.nX() % tile.nY() % coord->uncrossed() % index % dx_index)
                << endmsg;
        error() << w << " " << a << " " << b << endmsg;
      }
    }
    ++n;
  }
}
