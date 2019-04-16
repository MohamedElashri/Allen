#pragma once

#include <vector>
#include <fstream>
#include <iostream>
#include "gsl-lite.hpp"
#include "Decoding.h"
#include "MuonDefinitions.cuh"

void read_muon_events_into_arrays(
    Muon::HitsSoA* muon_station_hits,
    const char* events,
    const uint* event_offsets,
    const int n_events)
{
  for (int i_event = 0; i_event < n_events; ++i_event) {
    const char* raw_input = events + event_offsets[i_event];
    std::copy_n((int*) raw_input, Muon::Constants::n_stations, muon_station_hits[i_event].number_of_hits_per_station);
    raw_input += sizeof(int) * Muon::Constants::n_stations;
    muon_station_hits[i_event].station_offsets[0] = 0;
    for (int i_station = 1; i_station < Muon::Constants::n_stations; ++i_station) {
      muon_station_hits[i_event].station_offsets[i_station] =
          muon_station_hits[i_event].station_offsets[i_station - 1] +
          muon_station_hits[i_event].number_of_hits_per_station[i_station - 1];
    }
    int n_hits_per_event = 0;
    for (int i_station = 0; i_station < Muon::Constants::n_stations; ++i_station) {
      const int station_offset = muon_station_hits[i_event].station_offsets[i_station];
      const int n_hits_per_station = muon_station_hits[i_event].number_of_hits_per_station[i_station];
      n_hits_per_event += n_hits_per_station;
      std::copy_n((int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].tile[station_offset]));
      raw_input += sizeof(int) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].x[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].dx[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].y[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].dy[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].z[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((float*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].dz[station_offset]));
      raw_input += sizeof(float) * n_hits_per_station;
      std::copy_n((int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].uncrossed[station_offset]));
      raw_input += sizeof(int) * n_hits_per_station;
      std::copy_n((unsigned int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].time[station_offset]));
      raw_input += sizeof(unsigned int) * n_hits_per_station;
      std::copy_n((int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].delta_time[station_offset]));
      raw_input += sizeof(int) * n_hits_per_station;
      std::copy_n((int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].cluster_size[station_offset]));
      raw_input += sizeof(int) * n_hits_per_station;
      std::copy_n((int*) raw_input, n_hits_per_station, &(muon_station_hits[i_event].region_id[station_offset]));
      raw_input += sizeof(int) * n_hits_per_station;
    }
  }
}
