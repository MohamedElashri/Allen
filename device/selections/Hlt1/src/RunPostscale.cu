/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "LineInfo.cuh"
#include "RunHlt1.cuh"
#include "DeterministicPostscaler.cuh"
#include "Event/ODIN.h"
#include "DeviceLineTraverser.cuh"

__global__ void
run_hlt1::run_postscale(run_hlt1::Parameters parameters, const unsigned selected_number_of_events, const unsigned event_start)
{
  const auto event_number = blockIdx.x;

  const unsigned hdr_size(8);
  const unsigned int* odinData = reinterpret_cast<const unsigned*>(
    parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[event_number] + hdr_size);

  const uint32_t run_no = odinData[LHCb::ODIN::Data::RunNumber];
  const uint32_t evt_hi = odinData[LHCb::ODIN::Data::L0EventIDHi];
  const uint32_t evt_lo = odinData[LHCb::ODIN::Data::L0EventIDLo];
  const uint32_t gps_hi = odinData[LHCb::ODIN::Data::GPSTimeHi];
  const uint32_t gps_lo = odinData[LHCb::ODIN::Data::GPSTimeLo];

  // Process lines.
  Hlt1::DeviceTraverseLinesScaleFactors<configured_lines_t, Hlt1::SpecialLine>::traverse(
    [&](const unsigned long i_line, const float scale_factor) {
      bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + event_number;
      DeterministicPostscaler ps(i_line, scale_factor);
      ps(1, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
    });

  if (blockIdx.x < selected_number_of_events) {
    const unsigned selected_event_number = blockIdx.x;
    const unsigned event_number = parameters.dev_event_list[blockIdx.x] - event_start;

    const unsigned hdr_size(8);
    const unsigned int* odinData = reinterpret_cast<const unsigned*>(
      parameters.dev_odin_raw_input + parameters.dev_odin_raw_input_offsets[selected_event_number] + hdr_size);

    const uint32_t run_no = odinData[LHCb::ODIN::Data::RunNumber];
    const uint32_t evt_hi = odinData[LHCb::ODIN::Data::L0EventIDHi];
    const uint32_t evt_lo = odinData[LHCb::ODIN::Data::L0EventIDLo];
    const uint32_t gps_hi = odinData[LHCb::ODIN::Data::GPSTimeHi];
    const uint32_t gps_lo = odinData[LHCb::ODIN::Data::GPSTimeLo];

    const auto n_tracks_event = parameters.dev_offsets_forward_tracks[selected_event_number + 1] -
                                parameters.dev_offsets_forward_tracks[selected_event_number];
    const auto n_vertices_event =
      parameters.dev_sv_offsets[selected_event_number + 1] - parameters.dev_sv_offsets[selected_event_number];

    // Process 1-track lines.
    Hlt1::DeviceTraverseLinesScaleFactors<configured_lines_t, Hlt1::OneTrackLine>::traverse(
      [&](const unsigned long i_line, const float scale_factor) {
        bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] +
                     parameters.dev_offsets_forward_tracks[selected_event_number];
        DeterministicPostscaler ps(i_line, scale_factor);
        ps(n_tracks_event, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
      });

    // Process 2-track lines.
    Hlt1::DeviceTraverseLinesScaleFactors<configured_lines_t, Hlt1::TwoTrackLine>::traverse(
      [&](const unsigned long i_line, const float scale_factor) {
        bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] +
                     parameters.dev_sv_offsets[event_number];
        DeterministicPostscaler ps(i_line, scale_factor);
        ps(n_vertices_event, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
      });

    // Process Velo lines.
    Hlt1::DeviceTraverseLinesScaleFactors<configured_lines_t, Hlt1::VeloLine>::traverse(
      [&](const unsigned long i_line, const float scale_factor) {
        bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + selected_event_number;
        DeterministicPostscaler ps(i_line, scale_factor);
        ps(1, decs, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
      });
  }
}
