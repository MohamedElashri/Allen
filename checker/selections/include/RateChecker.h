#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>

void checkHlt1Rate(
  const bool* one_track_decisions,
  const bool* two_track_decisions,
  const bool* single_muon_decisions,
  const bool* disp_dimuon_decisions,
  const bool* high_mass_dimuon_decisions,
  const bool* dimuon_soft_decisions,
  const int* track_atomics,
  const uint* sv_atomics,
  const uint selected_events,
  const uint requested_events);

class RateChecker : public Checker::BaseChecker {
public:
  struct RateTag {
    static std::string const name;
  };

  using subdetector_t = RateTag;

  RateChecker(CheckerInvoker const*, std::string const&) {}

  virtual ~RateChecker() = default;

  void accumulate(
    bool const* one_track_decisions,
    bool const* two_track_decisions,
    bool const* single_muon_decisions,
    bool const* disp_dimuon_decisions,
    bool const* high_mass_dimuon_decisions,
    bool const* dimuon_soft_decisions,
    int const* track_atomics,
    uint const* sv_atomics,
    uint const selected_events);

  void report(size_t n_events) const override;

private:
  // Event counters.
  uint m_evts_one_track = 0;
  uint m_evts_two_track = 0;
  uint m_evts_single_muon = 0;
  uint m_evts_disp_dimuon = 0;
  uint m_evts_high_mass_dimuon = 0;
  uint m_evts_dimuon_soft = 0;
  uint m_evts_inc = 0;
};
