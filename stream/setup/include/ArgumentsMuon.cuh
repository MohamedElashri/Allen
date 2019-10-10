#pragma once

#include "Argument.cuh"
#include "ArgumentsCommon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"

/**
 * @brief Definition of arguments. All arguments should be defined here,
 *        with their associated type.
 */
ARGUMENT(dev_muon_raw, char)
ARGUMENT(dev_muon_raw_offsets, unsigned int)
ARGUMENT(dev_muon_raw_to_hits, Muon::MuonRawToHits)
ARGUMENT(dev_muon_hits, Muon::HitsSoA)
ARGUMENT(dev_muon_track_occupancies, int)
ARGUMENT(dev_is_muon, bool)
ARGUMENT(dev_muon_catboost_features, float)
ARGUMENT(dev_muon_catboost_output, float)
ARGUMENT(dev_storage_station_region_quarter_offsets, uint)
ARGUMENT(dev_storage_tile_id, uint)
ARGUMENT(dev_storage_tdc_value, uint)
ARGUMENT(dev_atomics_muon, uint)
ARGUMENT(dev_permutation_srq, uint)
ARGUMENT(dev_permutation_station, uint)
ARGUMENT(dev_station_ocurrences_offset, uint)
ARGUMENT(dev_muon_compact_hit, uint64_t)