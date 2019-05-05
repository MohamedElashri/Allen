#include "MuonDecoding.cuh"
#include <stdio.h>

__global__ void muon_decoding(char* events, unsigned int* offsets, Muon::MuonRawToHits* muon_raw_to_hits,
    Muon::HitsSoA* muon_hits) {
  size_t i = blockIdx.x;
  printf("blockIdx.x = %u\n", blockIdx.x);
  Muon::MuonRawEvent rawEvent = Muon::MuonRawEvent((const char*) events + offsets[i]);
  muon_raw_to_hits->operator()(rawEvent, &muon_hits[i]);
  for (int i_station = 0; i_station < Muon::Constants::n_stations; ++i_station) {
    const int station_offset = muon_hits[i].station_offsets[i_station];
    const int n_hits_per_station = muon_hits[i].number_of_hits_per_station[i_station];
    const int output = (i + 1) * 10000000 + station_offset * 10000 + n_hits_per_station;
    printf("AFTER TRANSFORMATION %d\n", output);
  }
}
