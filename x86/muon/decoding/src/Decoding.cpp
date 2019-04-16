#include "Decoding.h"
#include <iostream>

char muon_table_raw_input[1200000];
char muon_geometry_raw_input[100000];

void decode(gsl::span<char> events, gsl::span<unsigned int> offsets, std::vector<Muon::HitsSoA>& muon_hits_events,
    char* muon_table_raw, char* muon_geometry_raw) {
  MuonTable pad = MuonTable();
  MuonTable stripX = MuonTable();
  MuonTable stripY = MuonTable();
  read_muon_table(muon_table_raw, &pad, &stripX, &stripY);
  Muon::MuonGeometry muonGeometry = Muon::MuonGeometry();
  muonGeometry.read_muon_geometry(muon_geometry_raw);
  MuonRawToHits muonRawToHits = MuonRawToHits(&pad, &stripX, &stripY, &muonGeometry);
  for (size_t i = 0; i < muon_hits_events.size(); i++) {
    gsl::span<char> rawEventSpan = {events.begin() + offsets[i], offsets[i + 1] - offsets[i]};
    Muon::MuonRawEvent rawEvent = Muon::MuonRawEvent((const char *) rawEventSpan.begin());
    muonRawToHits(rawEvent, &muon_hits_events[i]);
  }
}

void decode(gsl::span<char> events, gsl::span<unsigned int> offsets, std::vector<Muon::HitsSoA>& muon_hits_events) {
  std::string file_name_muon_table = "../input/muon/muon_table.bin";
  std::string file_name_muon_geometry = "../input/muon/muon_geometry.bin";
  memset(muon_table_raw_input, 0, sizeof(muon_table_raw_input));
  std::ifstream muon_table_file(file_name_muon_table, std::ios::binary);
  muon_table_file.read(muon_table_raw_input, sizeof(muon_table_raw_input));
  muon_table_file.close();
  memset(muon_geometry_raw_input, 0, sizeof(muon_geometry_raw_input));
  std::ifstream muon_gometry_file(file_name_muon_geometry, std::ios::binary);
  muon_gometry_file.read(muon_geometry_raw_input, sizeof(muon_geometry_raw_input));
  muon_gometry_file.close();
  decode(events, offsets, muon_hits_events, muon_table_raw_input, muon_geometry_raw_input);
}
