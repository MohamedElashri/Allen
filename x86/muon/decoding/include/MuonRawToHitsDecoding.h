#pragma once

#include "MuonGeometry.h"
#include "MuonTable.h"
#include "MuonRawToHits.h"
#include "MuonRaw.h"
#include "MuonDefinitions.cuh"

#include "Handler.cuh"

#include <vector>
#include <fstream>
#include <cstring>

void muonRawToHitsDecode(gsl::span<char> events, gsl::span<unsigned int> offsets,
                         std::vector<Muon::HitsSoA>& muon_hits_events,
                         MuonRawToHits* muonRawToHits);

ALGORITHM(muonRawToHitsDecode, muon_raw_to_hits_decode_t,
    ARGUMENTS(
        dev_events,
        dev_offsets,
        dev_muon_hits_events,
        dev_muonRawToHits
))

void muonRawToHitsDecode(gsl::span<char> events, gsl::span<unsigned int> offsets,
                         std::vector<Muon::HitsSoA>& muon_hits_events,
                         char* muon_table_raw, char* muon_geometry_raw);

void muonRawToHitsDecode(gsl::span<char> events, gsl::span<unsigned int> offsets,
                         std::vector<Muon::HitsSoA>& muon_hits_events);


