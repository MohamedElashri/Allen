#include "catch.hpp"
#include "MuonRawToHits.test.cuh"

SCENARIO("General case") {
  const std::string SLASH = "/";
  const std::string MUON_RAW_FOLDER = "../input/minbias/banks/Muon";
  const std::string MUON_COMMON_HITS_FOLDER = "../input/minbias/muon_common_hits";
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

  for (size_t i = 0; i < DATA_FILES.size(); i++) {
    const auto& data_file = DATA_FILES[i];
    std::ifstream muon_raw_file(MUON_RAW_FOLDER + SLASH + data_file, std::ios::in | std::ios::binary);
    if (muon_raw_file.fail()) {
      std::cout << "MUON RAW FAIL\n";
    }
    std::vector<char> muon_raw_raw_input(MUON_RAW_SIZES[i], 0);
    muon_raw_file.read(muon_raw_raw_input.data(), MUON_RAW_SIZES[i]);
    muon_raw_file.close();

    gsl::span<char> muon_raw_span(muon_raw_raw_input);
    std::vector<unsigned int> muon_raw_offsets = {static_cast<unsigned int>(0), static_cast<unsigned int>(MUON_RAW_SIZES[i])};
    gsl::span<unsigned int> muon_raw_offsets_span(muon_raw_offsets);
    std::vector<Muon::HitsSoA> actual_vector(1);
    decode(muon_raw_span, muon_raw_offsets_span, actual_vector);
    Muon::HitsSoA actual = actual_vector[0];
/*
    std::ifstream muon_common_hits_file(MUON_COMMON_HITS_FOLDER + "/" + data_file, std::ios::in | std::ios::binary);
    std::vector<char> muon_common_hits_raw_input(MUON_COMMON_HITS_SIZES[i], 0);
    muon_common_hits_file.read(muon_common_hits_raw_input.data(), MUON_COMMON_HITS_SIZES[i]);
    muon_common_hits_file.close();

    Muon::HitsSoA expected;
    read_muon_events_into_arrays(&expected, muon_common_hits_raw_input.data(), {0}, 1);

    for (int i = 0; i < Muon::Constants::n_stations; i++) {
      std::cout << expected.number_of_hits_per_station[i] << " " << actual.number_of_hits_per_station[i] << "\n";
    }
*/
  }
}
