#include "RateChecker.h"

template<>
void SequenceVisitor::check<run_hlt1_t>(
  const uint& start_event_offset,
  const uint& number_of_events_requested,
  HostBuffers& host_buffers,
  const Constants& constants,
  const CheckerInvoker& checker_invoker) const
{
  info_cout << "Checking Hlt1 rate." << std::endl;
  checkHlt1Rate(
    host_buffers.host_one_track_decisions,
    host_buffers.host_two_track_decisions,
    host_buffers.host_atomics_scifi,
    host_buffers.host_sv_offsets,
    host_buffers.host_number_of_selected_events[0],
    number_of_events_requested);
}
