#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"
#include "LineTraverser.cuh"

void checkHlt1Rate(
  const bool* decisions,
  const unsigned* decisions_atomics,
  const unsigned* track_offsets,
  const unsigned* sv_offsets,
  const unsigned selected_events,
  const unsigned requested_events);

double binomial_error(int n, int k);

class RateChecker : public Checker::BaseChecker {

private:
  // Event counters.
  std::vector<bool> m_event_decs;
  std::vector<unsigned> m_counters;
  std::vector<std::string> m_line_names;
  unsigned m_tot;

public:
  struct RateTag {
    static std::string const name;
  };

  using subdetector_t = RateTag;

  RateChecker(CheckerInvoker const*, std::string const&) { m_tot = 0; }

  virtual ~RateChecker() = default;

  template<typename T>
  void accumulate(
    const bool* decisions,
    const unsigned* decisions_offsets,
    const unsigned* event_tracks_offsets,
    const unsigned* sv_offsets,
    const unsigned total_number_of_events,
    const unsigned selected_number_of_events)
  {
    const bool counters_initialized = m_counters.size() > 0;

    m_event_decs.resize(std::tuple_size<T>::value);
    m_counters.resize(std::tuple_size<T>::value);
    m_line_names.resize(std::tuple_size<T>::value);

    const auto lambda_all_tracks_fn0 = [&](const unsigned long i, const std::string& line_name) {
      if (!counters_initialized) {
        m_counters[i] = 0;
      }
      m_line_names[i] = line_name;
    };
    Hlt1::TraverseLinesNames<T, Hlt1::Line>::traverse(lambda_all_tracks_fn0);

    // Event loop.
    for (unsigned i_event = 0; i_event < total_number_of_events; i_event++) {

      // Initialize counters
      const auto lambda_all_tracks_fn2 = [&](const unsigned long i) { m_event_decs[i] = false; };
      Hlt1::TraverseLines<T, Hlt1::Line>::traverse(lambda_all_tracks_fn2);

      if (i_event < selected_number_of_events) {

        // Check one track decisions
        const int n_tracks_event = event_tracks_offsets[i_event + 1] - event_tracks_offsets[i_event];
        const auto lambda_one_track_fn = [&](const unsigned long i_line) {
          const bool* decs = decisions + decisions_offsets[i_line] + event_tracks_offsets[i_event];
          for (int i_track = 0; i_track < n_tracks_event; i_track++) {
            if (decs[i_track]) m_event_decs[i_line] = true;
          }
        };
        Hlt1::TraverseLines<T, Hlt1::OneTrackLine>::traverse(lambda_one_track_fn);

        // Check two track decisions.
        const unsigned int n_svs_event = sv_offsets[i_event + 1] - sv_offsets[i_event];
        const auto lambda_two_track_fn = [&](const unsigned long i_line) {
          const bool* decs = decisions + decisions_offsets[i_line] + sv_offsets[i_event];
          for (unsigned int i_sv = 0; i_sv < n_svs_event; i_sv++) {
            if (decs[i_sv]) m_event_decs[i_line] = true;
          }
        };
        Hlt1::TraverseLines<T, Hlt1::TwoTrackLine>::traverse(lambda_two_track_fn);

        // Check velo line decisions.
        const auto lambda_velo_fn = [&](const unsigned long i_line) {
          const bool* decs = decisions + decisions_offsets[i_line] + i_event;
          if (decs[0]) m_event_decs[i_line] = true;
        };
        Hlt1::TraverseLines<T, Hlt1::VeloLine>::traverse(lambda_velo_fn);
      }

      // Check special decisions.
      const auto lambda_special_fn = [&](const unsigned long i_line) {
        const bool* decs = decisions + decisions_offsets[i_line] + i_event;
        if (decs[0]) m_event_decs[i_line] = true;
      };
      Hlt1::TraverseLines<T, Hlt1::SpecialLine>::traverse(lambda_special_fn);

      // See if an event passes.
      bool inc_dec = false;
      const auto lambda_all_tracks_fn1 = [&](const unsigned long i_line) {
        if (m_event_decs[i_line]) {
          inc_dec = true;
          m_counters[i_line] += 1;
        }
      };
      Hlt1::TraverseLines<T, Hlt1::Line>::traverse(lambda_all_tracks_fn1);

      if (inc_dec) {
        m_tot += 1;
      }
    }
  }

  void report(const size_t requested_events) const override;
};
