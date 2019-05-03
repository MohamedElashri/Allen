#include "MuonRawToHitsDecoding.h"

char muon_table_raw_input[1200000];
char muon_geometry_raw_input[100000];

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector <Muon::HitsSoA>& muon_hits_events,
                         CPUMuon::MuonRawToHits* muonRawToHits) {
  for (size_t i = 0; i < muon_hits_events.size(); i++) {
    gsl::span<char> rawEventSpan = {events + offsets[i], offsets[i + 1] - offsets[i]};
    CPUMuon::MuonRawEvent rawEvent = CPUMuon::MuonRawEvent((const char*) rawEventSpan.begin());
    muonRawToHits->operator()(rawEvent, &muon_hits_events[i]);
  }
}

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector <Muon::HitsSoA>& muon_hits_events,
                         char* muon_table_raw, char* muon_geometry_raw) {
  CPUMuon::MuonTable pad, stripX, stripY;
  read_muon_table(muon_table_raw, &pad, &stripX, &stripY);
  CPUMuon::MuonGeometry muonGeometry;
  muonGeometry.read_muon_geometry(muon_geometry_raw);
  CPUMuon::MuonRawToHits muonRawToHits = CPUMuon::MuonRawToHits(&pad, &stripX, &stripY, &muonGeometry);
  muonRawToHitsDecode(events, offsets, events_size, offsets_size, muon_hits_events, &muonRawToHits);
}

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector <Muon::HitsSoA>& muon_hits_events) {
  std::string file_name_muon_table = "../input/muon/muon_table.bin";
  std::string file_name_muon_geometry = "../input/muon/muon_geometry.bin";
  memset(muon_table_raw_input, 0, sizeof(muon_table_raw_input));
  std::ifstream muon_table_file(file_name_muon_table, std::ios::binary);
  muon_table_file.read(muon_table_raw_input, sizeof(muon_table_raw_input));
  muon_table_file.close();
  memset(muon_geometry_raw_input, 0, sizeof(muon_geometry_raw_input));
  std::ifstream muon_geometry_file(file_name_muon_geometry, std::ios::binary);
  muon_geometry_file.read(muon_geometry_raw_input, sizeof(muon_geometry_raw_input));
  muon_geometry_file.close();
  muonRawToHitsDecode(events, offsets, events_size, offsets_size, muon_hits_events, muon_table_raw_input,
                      muon_geometry_raw_input);
}
