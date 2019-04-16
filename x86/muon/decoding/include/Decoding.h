#pragma once

#include "MuonGeometry.h"
#include "MuonTable.h"
#include "MuonRawToHits.h"
#include "MuonRaw.h"
#include "MuonDefinitions.cuh"

#include <vector>
#include <fstream>
#include <cstring>

void decode(gsl::span<char> events, gsl::span<unsigned int> offsets, std::vector<Muon::HitsSoA>& muon_hits_events,
            char* muon_table_raw, char* muon_geometry_raw);

void decode(gsl::span<char> events, gsl::span<unsigned int> offsets, std::vector<Muon::HitsSoA>& muon_hits_events);
