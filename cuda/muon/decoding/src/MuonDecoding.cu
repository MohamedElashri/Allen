#include "MuonDecoding.cuh"

__global__ void muon_decoding(char* events, unsigned int* offsets, size_t number_of_events,
                              MuonRawToHits* muon_raw_to_hits, Muon::HitsSoA* muon_hits) {

  for (size_t i = 0; i < number_of_events; i++) {
    Muon::MuonRawEvent rawEvent = Muon::MuonRawEvent((const char*) events + offsets[i]);
    muon_raw_to_hits->operator()(rawEvent, &muon_hits[i]);
  }
}
