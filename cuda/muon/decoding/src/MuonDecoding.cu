#include "MuonDecoding.cuh"
#include <stdio.h>

__global__ void muon_decoding(char* events, unsigned int* offsets, size_t number_of_events,
                              MuonRawToHits* muon_raw_to_hits, Muon::HitsSoA* muon_hits) {

  printf("number_of_events = %d\n", number_of_events);
  for (size_t i = 0; i < number_of_events; i++) {
    Muon::MuonRawEvent rawEvent = Muon::MuonRawEvent((const char*) events + offsets[i]);
    muon_raw_to_hits->operator()(rawEvent, &muon_hits[i]);
    for (int j = 0; j < 4; j++) {
      printf("%d %d %d %d\n", i, j, muon_hits[i].station_offsets[j], muon_hits[i].number_of_hits_per_station[j]);
    }
  }
}
