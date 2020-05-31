/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "HltSelReport.cuh"
#include "ParKalmanDefinitions.cuh"
#include "RawBanksDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace package_sel_reports {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_sel_rep_words_t, unsigned), host_number_of_sel_rep_words),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned), dev_offsets_forward_tracks),
    (DEVICE_INPUT(dev_sel_rb_hits_t, unsigned), dev_sel_rb_hits),
    (DEVICE_INPUT(dev_sel_rb_stdinfo_t, unsigned), dev_sel_rb_stdinfo),
    (DEVICE_INPUT(dev_sel_rb_objtyp_t, unsigned), dev_sel_rb_objtyp),
    (DEVICE_INPUT(dev_sel_rb_substr_t, unsigned), dev_sel_rb_substr),
    (DEVICE_INPUT(dev_sel_rep_offsets_t, unsigned), dev_sel_rep_offsets),
    (DEVICE_OUTPUT(dev_sel_rep_raw_banks_t, unsigned), dev_sel_rep_raw_banks),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned), block_dim_x))

  __global__ void package_sel_reports(Parameters, const unsigned number_of_events, const unsigned selected_number_of_events, const unsigned event_start);

  struct package_sel_reports_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 64};
  };
} // namespace package_sel_reports