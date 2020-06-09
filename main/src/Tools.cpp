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
