#include "catch.hpp"
#include "MuonRawToHits.test.cuh"

SCENARIO("General case") {
  const std::string SLASH = "/";
  const std::string MUON_RAW_FOLDER = "../input/minbias/banks/Muon";
  const std::string MUON_COMMON_HITS_FOLDER = "../input/minbias/muon_common_hits";
  const std::string MUON_TABLE_FILE_NAME = "../input/muon/muon_table.bin";
  const std::string MUON_GEOMETRY_FILE_NAME = "../input/muon/muon_geometry.bin";
  const std::vector<std::string> DATA_FILES = {
      "6718861_6001.bin",
      "6718861_6002.bin",
      "6718861_6003.bin",
      "6718861_6004.bin",
      "6718861_6005.bin",
      "6718861_6006.bin",
      "6718861_6007.bin",
      "6718861_6008.bin",
      "6718861_6009.bin",
      "6718861_6010.bin"
  };
  const std::vector<size_t> MUON_RAW_SIZES = {2152, 440, 1036, 1412, 1240, 580, 1244, 896, 1464, 1740};
  const std::vector<size_t> MUON_COMMON_HITS_SIZES = {26320, 2320, 10096, 14560, 11344, 4096, 12544, 7360, 14368, 18160};
  const size_t MUON_TABLE_SIZE = 1200000;
  const size_t MUON_GEOMETRY_SIZE = 100000;

  std::vector<char> muon_table_raw_input(MUON_TABLE_SIZE, 0);
  read_binary_file(muon_table_raw_input, MUON_TABLE_FILE_NAME);
  std::vector<char> muon_geometry_raw_input(MUON_GEOMETRY_SIZE, 0);
  read_binary_file(muon_geometry_raw_input, MUON_GEOMETRY_FILE_NAME);

  for (size_t i = 0; i < DATA_FILES.size(); i++) {
    const auto& data_file = DATA_FILES[i];
    std::vector<char> muon_raw_raw_input(MUON_RAW_SIZES[i], 0);
    std::string muon_raw_file_name = MUON_RAW_FOLDER + SLASH + data_file;
    read_binary_file(muon_raw_raw_input, muon_raw_file_name);

    unsigned int muon_raw_offsets[] = {static_cast<unsigned int>(0), static_cast<unsigned int>(MUON_RAW_SIZES[i])};
    std::vector<Muon::HitsSoA> actual_vector(1);

    CPUMuon::MuonTable pad, stripX, stripY;
    read_muon_table(muon_table_raw_input.data(), &pad, &stripX, &stripY);
    CPUMuon::MuonGeometry muonGeometry;
    muonGeometry.read_muon_geometry(muon_geometry_raw_input.data());
    CPUMuon::MuonRawToHits muonRawToHits = CPUMuon::MuonRawToHits(&pad, &stripX, &stripY, &muonGeometry);
    for (int it = 0; it < 100; it++) {
      muonRawToHitsDecode(muon_raw_raw_input.data(), muon_raw_offsets, MUON_RAW_SIZES[i], 2, actual_vector, &muonRawToHits);
    }
    Muon::HitsSoA actual = actual_vector[0];

    std::vector<char> muon_common_hits_raw_input(MUON_COMMON_HITS_SIZES[i], 0);
    std::string muon_common_hits_file_name = MUON_COMMON_HITS_FOLDER + SLASH + data_file;
    read_binary_file(muon_common_hits_raw_input, muon_common_hits_file_name);
    Muon::HitsSoA expected;
    unsigned int offsets[] = {0};
    read_muon_events_into_arrays(&expected, muon_common_hits_raw_input.data(), offsets, 1);
    for (int j = 0; j < Muon::Constants::n_stations; j++) {
      CHECK(expected.number_of_hits_per_station[j] == actual.number_of_hits_per_station[j]);
      std::vector<int> expected_tiles;
      for (int k = expected.station_offsets[j]; k < expected.station_offsets[j] + expected.number_of_hits_per_station[j]; k++) {
        expected_tiles.push_back(expected.tile[k]);
      }
      std::vector<int> actual_tiles;
      for (int k = actual.station_offsets[j]; k < actual.station_offsets[j] + actual.number_of_hits_per_station[j]; k++) {
        actual_tiles.push_back(actual.tile[k]);
      }
      std::sort(expected_tiles.begin(), expected_tiles.end());
      std::sort(actual_tiles.begin(), actual_tiles.end());
      CHECK(expected_tiles.size() == actual_tiles.size());
      for (int j = 0; j < expected_tiles.size(); j++) {
        CHECK(expected_tiles[j] == actual_tiles[j]);
      }
    }
  }
}
