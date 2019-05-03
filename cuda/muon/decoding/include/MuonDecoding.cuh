#pragma once

#include "Handler.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"

__global__ void muon_decoding(const Muon::HitsSoA* muon_hits);

ALGORITHM(
    muon_decoding,
    muon_decoding_t,
    ARGUMENTS(dev_muon_hits)
)
