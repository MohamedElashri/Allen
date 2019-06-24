#include "RateChecker.h"

template<>
void SequenceVisitor::check<run_hlt1_t>(
  HostBuffers& host_buffers,
  const Constants& constants,
  const CheckerInvoker& checker_invoker,
  const MCEvents& mc_events) const
{
  info_cout << "Checking Hlt1 rate." << std::endl;
  auto& checker = checker_invoker.checker<RateChecker>();
  checker.accumulate(
    host_buffers.host_one_track_decisions,
    host_buffers.host_two_track_decisions,
    host_buffers.host_single_muon_decisions,
    host_buffers.host_disp_dimuon_decisions,
    host_buffers.host_high_mass_dimuon_decisions,
    host_buffers.host_atomics_scifi,
    host_buffers.host_sv_offsets,
    host_buffers.host_number_of_selected_events[0]);

}
