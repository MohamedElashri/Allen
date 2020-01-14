#include "RateChecker.h"

std::string const RateChecker::RateTag::name = "RateChecker";

void RateChecker::accumulate(
  const bool* decisions,
  const uint* decisions_atomics,
  const int* track_atomics,
  const uint* sv_atomics,
  const uint selected_events)
{
  // Event loop.
  for (uint i_event = 0; i_event < selected_events; i_event++) {

    // Sel results.
    const uint* decisions_offsets = decisions_atomics + Hlt1::Hlt1Lines::End;
    
    // Check one track decisions.
    const int* event_tracks_offsets = track_atomics + selected_events;

    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      m_event_decs[i_line] = false;
    }

    const int n_tracks_event = track_atomics[i_event];
    for (uint i_line = Hlt1::Hlt1Lines::StartOneTrackLines; i_line < Hlt1::Hlt1Lines::StartTwoTrackLines; i_line++) {
      const bool* decs = decisions + decisions_offsets[i_line] + event_tracks_offsets[i_event];
      for (int i_track = 0; i_track < n_tracks_event; i_track++) {
        if (decs[i_track]) m_event_decs[i_line] = true;
      }
    }

    // Check two track decisions.
    const uint* sv_offsets = sv_atomics + selected_events;
    const uint n_svs_event = sv_atomics[i_event];
    for (uint i_line = Hlt1::Hlt1Lines::StartTwoTrackLines + 1; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      const bool* decs = decisions + decisions_offsets[i_line] + sv_offsets[i_event];
      for (int i_sv = 0; i_sv < n_svs_event; i_sv++) {
        if (decs[i_sv]) m_event_decs[i_line] = true;
      }
    }
    
    // See if an event passes.
    bool inc_dec = false;
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      if (m_event_decs[i_line]) {
        inc_dec = true;
        m_counters[i_line] += 1;
      }
    }
    if (inc_dec) {
      m_tot += 1;
    }
  }
}

double binomial_error(int n, int k) { return 1. / n * std::sqrt(1. * k * (1. - 1. * k / n)); }

void RateChecker::report(size_t requested_events) const
{
  // Assume 30 MHz input rate.
  const double in_rate = 30000.0;
  for (uint i_line = Hlt1::Hlt1Lines::StartOneTrackLines + 1; i_line < Hlt1::Hlt1Lines::End; i_line++) {
    if (i_line == Hlt1::Hlt1Lines::StartTwoTrackLines) continue;
    std::printf(
      "%20s: %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
      m_line_names[i_line].c_str(),
      m_counters[i_line],
      requested_events,
      1. * m_counters[i_line] / requested_events * in_rate,
      binomial_error(requested_events, m_counters[i_line]) * in_rate);
  }
  std::printf(
    "Inclusive: %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_tot,
    requested_events,
    1. * m_tot / requested_events * in_rate,
    binomial_error(requested_events, m_tot) * in_rate);  
}
