#include "RateChecker.h"

std::string const RateChecker::RateTag::name = "RateChecker";

void RateChecker::accumulate(
  const bool* decisions,
  const uint* decisions_offsets,
  const uint* event_tracks_offsets,
  const uint* sv_offsets,
  const uint selected_events)
{
  // Event loop.
  for (uint i_event = 0; i_event < selected_events; i_event++) {

    // Check one track decisions.
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      m_event_decs[i_line] = false;
    }

    const int n_tracks_event = event_tracks_offsets[i_event + 1] - event_tracks_offsets[i_event];
    for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
      const bool* decs = decisions + decisions_offsets[i_line] + event_tracks_offsets[i_event];
      for (int i_track = 0; i_track < n_tracks_event; i_track++) {
        if (decs[i_track]) m_event_decs[i_line] = true;
      }
    }

    // Check two track decisions.
    const uint n_svs_event = sv_offsets[i_event + 1] - sv_offsets[i_event];
    for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
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
  auto longest_string = 10;
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::Hlt1Lines::End; i_line++) {
    if (Hlt1::Hlt1LineNames[i_line].length() > longest_string) {
      longest_string = Hlt1::Hlt1LineNames[i_line].length();
    }
  }

  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::Hlt1Lines::End; i_line++) {
    std::printf("%s:", Hlt1::Hlt1LineNames[i_line].c_str());
    for (int i = 0; i < longest_string - Hlt1::Hlt1LineNames[i_line].length(); ++i) {
      std::printf(" ");
    }

    std::printf(
      " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
      m_counters[i_line],
      requested_events,
      1. * m_counters[i_line] / requested_events * in_rate,
      binomial_error(requested_events, m_counters[i_line]) * in_rate);
  }

  std::printf("Inclusive:");
  for (int i = 0; i < longest_string - 9; ++i) {
    std::printf(" ");
  }

  std::printf(
    " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_tot,
    requested_events,
    1. * m_tot / requested_events * in_rate,
    binomial_error(requested_events, m_tot) * in_rate);
}
