#pragma once

#include "Handler.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"

__global__ void muon_decoding(uint* event_list, char* events, unsigned int* offsets,
    Muon::MuonRawToHits* muon_raw_to_hits, Muon::HitsSoA* muon_hits);

ALGORITHM(
    muon_decoding,
    muon_decoding_t,
    ARGUMENTS(
        dev_event_list,
        dev_muon_raw,
        dev_muon_raw_offsets,
        dev_muon_raw_to_hits,
        dev_muon_hits
    )
)
