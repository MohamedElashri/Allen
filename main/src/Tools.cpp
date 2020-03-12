#include "Tools.h"
#include "Common.h"

/**
 * @brief Obtains results statistics.
 */
std::map<std::string, float> calcResults(std::vector<float>& times)
{
  // sqrt ( E( (X - m)2) )
  std::map<std::string, float> results;
  float deviation = 0.0f, variance = 0.0f, mean = 0.0f, min = FLT_MAX, max = 0.0f;

  for (auto it = times.begin(); it != times.end(); it++) {
    const float seconds = (*it);
    mean += seconds;
    variance += seconds * seconds;

    if (seconds < min) min = seconds;
    if (seconds > max) max = seconds;
  }

  mean /= times.size();
  variance = (variance / times.size()) - (mean * mean);
  deviation = std::sqrt(variance);

  results["variance"] = variance;
  results["deviation"] = deviation;
  results["mean"] = mean;
  results["min"] = min;
  results["max"] = max;

  return results;
}

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
    for (uint i_station = 1; i_station < Muon::Constants::n_stations; ++i_station) {
      muon_station_hits[i_event].station_offsets[i_station] =
        muon_station_hits[i_event].station_offsets[i_station - 1] +
        muon_station_hits[i_event].number_of_hits_per_station[i_station - 1];
    }
    uint n_hits_per_event = 0;
    for (uint i_station = 0; i_station < Muon::Constants::n_stations; ++i_station) {
      const int station_offset = muon_station_hits[i_event].station_offsets[i_station];
      const uint n_hits_per_station = muon_station_hits[i_event].number_of_hits_per_station[i_station];
      n_hits_per_event += n_hits_per_station;
      if (n_hits_per_event > Muon::Constants::max_numhits_per_event) {
        throw StrException(
          "Read Muon Events: Number of hits exceeds maximum number of hits per event (" +
          std::to_string(Muon::Constants::max_numhits_per_event) + ")");
      }
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
void check_muon_events(const Muon::HitsSoA* muon_station_hits, const int n_output_hits_per_event, const int n_events)
{
  int total_number_of_hits = 0;
  for (int i_event = 0; i_event < n_events; ++i_event) {
    float n_hits_per_event = 0;
    for (uint i_station = 0; i_station < Muon::Constants::n_stations; ++i_station) {
      const int station_offset = muon_station_hits[i_event].station_offsets[i_station];
      const uint n_hits_per_station = muon_station_hits[i_event].number_of_hits_per_station[i_station];
      n_hits_per_event += n_hits_per_station;
      debug_cout << "checks on station " << i_station << ", with " << n_hits_per_station << " hits" << std::endl;
      for (int i_hit = 0; i_hit < n_output_hits_per_event; ++i_hit) {
        if (logger::verbosity() >= logger::debug) {
          debug_cout << "\t at hit " << i_hit << ", "
                     << "tile = " << muon_station_hits[i_event].tile[station_offset + i_hit] << ", "
                     << "x = " << muon_station_hits[i_event].x[station_offset + i_hit] << ", "
                     << "dx = " << muon_station_hits[i_event].dx[station_offset + i_hit] << ", "
                     << "y = " << muon_station_hits[i_event].y[station_offset + i_hit] << ", "
                     << "dy = " << muon_station_hits[i_event].dy[station_offset + i_hit] << ", "
                     << "z = " << muon_station_hits[i_event].z[station_offset + i_hit] << ", "
                     << "dz = " << muon_station_hits[i_event].dz[station_offset + i_hit] << ", "
                     << "uncrossed = " << muon_station_hits[i_event].uncrossed[station_offset + i_hit] << ", "
                     << "time = " << muon_station_hits[i_event].time[station_offset + i_hit] << ", "
                     << "delta_time = " << muon_station_hits[i_event].delta_time[station_offset + i_hit] << ", "
                     << "cluster_size = " << muon_station_hits[i_event].cluster_size[station_offset + i_hit] << ", "
                     << "region_id = " << muon_station_hits[i_event].region_id[station_offset + i_hit] << ", "
                     << std::endl;
        }
      }
    }
    total_number_of_hits += n_hits_per_event;
    debug_cout << "# of Muon hits = " << n_hits_per_event << std::endl;
  }
  debug_cout << "average # of Muon hits / event = " << (float) total_number_of_hits / n_events << std::endl;
}

std::vector<Checker::Tracks> read_forward_tracks(const char* events, const uint* event_offsets, const int n_events)
{

  std::vector<Checker::Tracks> all_tracks;

  for (int i_event = 0; i_event < n_events; ++i_event) {
    const char* raw_input = events + event_offsets[i_event];
    const uint32_t n_tracks = *((uint32_t*) raw_input);
    raw_input += sizeof(uint32_t);
    Checker::Tracks tracks_event;
    for (uint i_track = 0; i_track < n_tracks; ++i_track) {
      Checker::Track track;
      track.eta = *((float*) raw_input);
      raw_input += sizeof(float);
      track.p = *((float*) raw_input);
      raw_input += sizeof(float);
      track.pt = *((float*) raw_input);
      raw_input += sizeof(float);

      const uint32_t n_IDs = *((uint32_t*) raw_input);
      raw_input += sizeof(uint32_t);
      for (uint i_ID = 0; i_ID < n_IDs; ++i_ID) {
        const uint32_t ID = *((uint32_t*) raw_input);
        raw_input += sizeof(uint32_t);
        track.addId(ID);
      }
      tracks_event.push_back(track);
    }
    all_tracks.push_back(tracks_event);
  }

  return all_tracks;
}
