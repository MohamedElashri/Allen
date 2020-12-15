/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <array>
#include <vector>

#include <boost/filesystem.hpp>
#include <boost/math/special_functions/relative_difference.hpp>

#include "TestMuonTable.h"
#include "Utils.h"

namespace {
  using std::array;
  using std::string;
  using std::to_string;
  using std::tuple;
  using std::vector;

  namespace fs = boost::filesystem;
} // namespace

// Declaration of the Algorithm Factory
DECLARE_COMPONENT(TestMuonTable)

unsigned int pad_offset(MuonTable const& table, LHCb::MuonTileID const& tile)
{
  int idx = 4 * tile.station() + tile.region();
  int perQuarter = 3 * table.gridX[idx] * table.gridY[idx];
  return static_cast<unsigned int>((4 * tile.region() + tile.quarter()) * perQuarter);
}

unsigned int strip_offset(MuonTable const& table, LHCb::MuonTileID const& tile)
{
  int idx = 4 * tile.station() + tile.region();
  int perQuarter = 3 * table.gridX[idx] * table.gridY[idx];
  return table.offset[4 * tile.station() + tile.region()] + tile.quarter() * perQuarter;
}

size_t lookup_index(MuonTable const& table, LHCb::MuonTileID const& tile)
{
  int station = tile.station();
  int region = tile.region();
  int idx = 4 * station + region;
  int xpad = static_cast<int>(tile.nX());
  int ypad = static_cast<int>(tile.nY());
  auto index = table.offset_fun(table, tile);

  if (ypad < table.gridY[idx]) {
    index = index + table.gridX[idx] * ypad + xpad - table.gridX[idx];
  }
  else {
    index = index + table.gridX[idx] * table.gridY[idx] + 2 * table.gridX[idx] * (ypad - table.gridY[idx]) + xpad;
  }
  return index;
}

void lookup(
  MuonTable const& table,
  LHCb::MuonTileID const& tile,
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
  LHCb::MuonTileID const& tile,
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
        table = tuple {std::cref(stripX), "stripX"};
      }
      else {
        table = tuple {std::cref(stripY), "stripY"};
      }
    }
  }
  return table;
}

void coord_position(
  LHCb::MuonTileID const& tile,
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

void read_muon_table(const char* raw_input, MuonTable& pad, MuonTable& stripX, MuonTable& stripY)
{

  size_t n = 0;
  for (MuonTable& muonTable : {std::ref(pad), std::ref(stripX), std::ref(stripY)}) {
    for_each(
      make_tuple(
        std::ref(muonTable.gridX),
        std::ref(muonTable.gridY),
        std::ref(muonTable.sizeX),
        std::ref(muonTable.sizeY),
        std::ref(muonTable.offset)),
      [&n, &raw_input](auto& table) {
        size_t s = 0;
        std::copy_n((size_t*) raw_input, 1, &s);

        // Some metaprogramming to resize the underlying
        // container if it is a vector and get the underlying
        // value type
        using table_t = typename std::remove_reference_t<decltype(table)>;
        using T = typename table_t::value_type;
        optional_resize<table_t> {}(table, s);
        assert(s == table.size());

        // Read the data into the container
        raw_input += sizeof(size_t);
        std::copy_n((T*) raw_input, s, table.data());
        raw_input += sizeof(T) * s;
        ++n;
      });

    for (size_t i = 0; i < muonTable.gridY.size() - 1; ++i) {
      muonTable.sizeOffset[i + 1] = muonTable.sizeOffset[i] + 24 * muonTable.gridY[i];
    }
    assert((muonTable.sizeOffset.back() + 24 * muonTable.gridY.back()) == muonTable.sizeX.size());

    size_t tableSize = 0;
    std::copy_n((size_t*) raw_input, 1, &tableSize);
    raw_input += sizeof(size_t);
    assert(tableSize == 4);

    for (size_t i = 0; i < tableSize; i++) {
      size_t stationTableSize = 0;
      std::copy_n((size_t*) raw_input, 1, &stationTableSize);
      raw_input += sizeof(size_t);
      (muonTable.table)[i].resize(stationTableSize);
      for (size_t j = 0; j < stationTableSize; j++) {
        std::copy_n((float*) raw_input, 3, muonTable.table[i][j].data());
        raw_input += sizeof(float) * 3;
      }
    }
  }
}

TestMuonTable::TestMuonTable(const string& name, ISvcLocator* pSvcLocator) :
  Consumer(name, pSvcLocator, {KeyValue {"MuonCoordsLocation", LHCb::MuonCoordLocation::MuonCoords}})
{}

StatusCode TestMuonTable::initialize()
{
  m_det = getDet<DeMuonDetector>("/dd/Structure/LHCb/DownstreamRegion/Muon");

  fs::path p {m_table.value()};
  auto read_size = fs::file_size(p);
  std::vector<char> raw_input(read_size);

  std::ifstream input(p.c_str(), std::ios::binary);
  input.read(&raw_input[0], read_size);
  input.close();

  read_muon_table(raw_input.data(), m_pad, m_stripX, m_stripY);

  return StatusCode::SUCCESS;
}

void TestMuonTable::operator()(const LHCb::MuonCoords& muonCoords) const
{

  double xp = 0., dxp = 0., yp = 0., dyp = 0., zp = 0., dzp = 0.;
  double xt = 0., dxt = 0., yt = 0., dyt = 0., zt = 0.;

  size_t n = 0;

  for (auto coord : muonCoords) {

    m_det->Tile2XYZ(coord->key(), xp, dxp, yp, dyp, zp, dzp).ignore();

    coord_position(coord->key(), m_pad, m_stripX, m_stripY, coord->uncrossed(), xt, dxt, yt, dyt, zt);

    array<tuple<char const*, double, double>, 5> values {
      {{"x ", xp, xt}, {"dx", dxp, dxt}, {"y ", yp, yt}, {"dy", dyp, dyt}, {"z ", zp, zt}}};

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
