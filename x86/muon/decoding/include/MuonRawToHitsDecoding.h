#pragma once

#include <vector>
#include <fstream>
#include <cstring>

#include "MuonGeometry.h"
#include "MuonTable.h"
#include "MuonRawToHits.h"
#include "MuonRaw.h"
#include "MuonDefinitions.cuh"

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector<Muon::HitsSoA>& muon_hits_events,
                         MuonRawToHits* muonRawToHits);

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector<Muon::HitsSoA>& muon_hits_events,
                         char* muon_table_raw, char* muon_geometry_raw);

void muonRawToHitsDecode(char* events, unsigned int* offsets, size_t events_size, size_t offsets_size,
                         std::vector<Muon::HitsSoA>& muon_hits_events);


