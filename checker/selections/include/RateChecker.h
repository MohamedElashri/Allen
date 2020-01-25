#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"

void checkHlt1Rate(
  const bool* decisions,
  const uint* decisions_atomics,
  const uint* track_offsets,
  const uint* sv_offsets,
  const uint selected_events,
  const uint requested_events);

class RateChecker : public Checker::BaseChecker {

private:
  // Event counters.
  bool m_event_decs[Hlt1::Hlt1Lines::End];
  uint m_counters[Hlt1::Hlt1Lines::End];
  uint m_tot;

  
public:
  struct RateTag {
    static std::string const name;
  };

  using subdetector_t = RateTag;

  RateChecker(CheckerInvoker const*, std::string const&)
  {
    for (uint i_line = 0; i_line < Hlt1::Hlt1Lines::End; i_line++) {
      m_counters[i_line] = 0;
    }
    m_tot = 0;
  }

  virtual ~RateChecker() = default;

  void accumulate(
    bool const* decisions,
    uint const* decisions_atomics,
    uint const* track_atomics,
    uint const* sv_atomics,
    uint const selected_events);

  void report(size_t n_events) const override;
};
