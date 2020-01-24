#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>

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
    uint const* track_offsets,
    uint const* sv_offsets,
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
