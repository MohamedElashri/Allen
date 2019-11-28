#include "RateChecker.h"

std::string const RateChecker::RateTag::name = "RateChecker";

void RateChecker::accumulate(
  const bool* one_track_decisions,
  const bool* two_track_decisions,
  const bool* single_muon_decisions,
  const bool* disp_dimuon_decisions,
  const bool* high_mass_dimuon_decisions,
  const bool* dimuon_soft_decisions,
  const int* track_atomics,
  const uint* sv_atomics,
  const uint selected_events)
{
  // Event loop.
  for (uint i_event = 0; i_event < selected_events; i_event++) {

    // Check one track decisions.
    bool one_track_pass = false;
    bool single_muon_pass = false;
    const int* event_tracks_offsets = track_atomics + selected_events;
    const bool* event_one_track_decisions = one_track_decisions + event_tracks_offsets[i_event];
    const bool* event_single_muon_decisions = single_muon_decisions + event_tracks_offsets[i_event];
    const int n_tracks_event = track_atomics[i_event];
    for (int i_track = 0; i_track < n_tracks_event; i_track++) {
      if (event_one_track_decisions[i_track]) {
        one_track_pass = true;
      }
      if (event_single_muon_decisions[i_track]) {
        single_muon_pass = true;
      }
    }

    // Check two track decisions.
    bool two_track_pass = false;
    bool disp_dimuon_pass = false;
    bool high_mass_dimuon_pass = false;
    bool dimuon_soft_pass = false;

    const bool* event_two_track_decisions = two_track_decisions + sv_atomics[i_event];
    const bool* event_disp_dimuon_decisions = disp_dimuon_decisions + sv_atomics[i_event];
    const bool* event_high_mass_dimuon_decisions = high_mass_dimuon_decisions + sv_atomics[i_event];
    const bool* event_dimuon_soft_decisions = dimuon_soft_decisions + sv_atomics[i_event];

    const int n_svs_event = sv_atomics[i_event + 1] - sv_atomics[i_event];
    for (int i_sv = 0; i_sv < n_svs_event; i_sv++) {
      if (event_two_track_decisions[i_sv]) {
        two_track_pass = true;
      }
      if (event_disp_dimuon_decisions[i_sv]) {
        disp_dimuon_pass = true;
      }
      if (event_high_mass_dimuon_decisions[i_sv]) {
        high_mass_dimuon_pass = true;
      }
      if (event_dimuon_soft_decisions[i_sv]) {
        dimuon_soft_pass = true;
      }
    }

    m_evts_one_track += one_track_pass;
    m_evts_two_track += two_track_pass;
    m_evts_single_muon += single_muon_pass;
    m_evts_disp_dimuon += disp_dimuon_pass;
    m_evts_high_mass_dimuon += high_mass_dimuon_pass;
    m_evts_dimuon_soft += dimuon_soft_pass;

    m_evts_inc += one_track_pass || two_track_pass || single_muon_pass || disp_dimuon_pass || high_mass_dimuon_pass ||
                  dimuon_soft_pass;
  }
}

double binomial_error(int n, int k) { return 1. / n * std::sqrt(1. * k * (1. - 1. * k / n)); }

void RateChecker::report(size_t requested_events) const
{

  // Assume 30 MHz input rate.
  const double in_rate = 30000.0;
  std::printf(
    "One track:        %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_one_track,
    requested_events,
    1. * m_evts_one_track / requested_events * in_rate,
    binomial_error(requested_events, m_evts_one_track) * in_rate);
  std::printf(
    "Two track:        %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_two_track,
    requested_events,
    1. * m_evts_two_track / requested_events * in_rate,
    binomial_error(requested_events, m_evts_two_track) * in_rate);
  std::printf(
    "Single muon:      %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_single_muon,
    requested_events,
    1. * m_evts_single_muon / requested_events * in_rate,
    binomial_error(requested_events, m_evts_single_muon) * in_rate);
  std::printf(
    "Displaced dimuon: %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_disp_dimuon,
    requested_events,
    1. * m_evts_disp_dimuon / requested_events * in_rate,
    binomial_error(requested_events, m_evts_disp_dimuon) * in_rate);
  std::printf(
    "High mass dimuon: %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_high_mass_dimuon,
    requested_events,
    1. * m_evts_high_mass_dimuon / requested_events * in_rate,
    binomial_error(requested_events, m_evts_high_mass_dimuon) * in_rate);
  std::printf(
    "Dimuon Soft: %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_evts_dimuon_soft,
    requested_events,
    1. * m_evts_dimuon_soft / requested_events * in_rate,
    binomial_error(requested_events, m_evts_dimuon_soft) * in_rate);
  std::printf(
    "Inclusive:        %6i/%6lu, (%8.2f +/- %8.2f) kHz\n\n",
    m_evts_inc,
    requested_events,
    1. * m_evts_inc / requested_events * in_rate,
    binomial_error(requested_events, m_evts_inc) * in_rate);
}
