#include "LineInfo.cuh"

#include "RunPostscale.cuh"
#include "DeterministicPostscaler.cuh"

#include "odin.hpp"

__global__ void run_postscale::run_postscale(run_postscale::Parameters parameters)
{
  const uint event_number = blockIdx.x;

  const auto n_tracks_event =
    parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];
  const auto n_vertices_event = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];

  const uint hdr_size(8);
  const unsigned int* odinData = reinterpret_cast<const uint*>(parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number] + hdr_size);

  uint32_t run_no = odinData[LHCb::ODIN::Data::RunNumber];
  uint32_t evt_hi = odinData[LHCb::ODIN::Data::L0EventIDHi];
  uint32_t evt_lo = odinData[LHCb::ODIN::Data::L0EventIDLo];
  uint32_t gps_hi = odinData[LHCb::ODIN::Data::GPSTimeHi];
  uint32_t gps_lo = odinData[LHCb::ODIN::Data::GPSTimeLo];

  // Process 1-track lines.
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + parameters.dev_offsets_forward_tracks[event_number];
    DeterministicPostscaler ps(i_line, 1.);//TODO
    ps(n_tracks_event, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  }

  // Process 2-track lines.
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + parameters.dev_sv_offsets[event_number];
    DeterministicPostscaler ps(i_line, 1.);//TODO
    ps(n_vertices_event, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  }
}
