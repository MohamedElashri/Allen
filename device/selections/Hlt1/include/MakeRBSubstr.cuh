/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "CandidateTable.cuh"

namespace make_rb_substr {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_substr_bank_size_t, unsigned) host_substr_bank_size;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    DEVICE_INPUT_OPTIONAL(dev_offsets_forward_tracks_t, unsigned) dev_offsets_forward_tracks;
    DEVICE_INPUT_OPTIONAL(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_sel_sv_tables_t, Selections::CandidateTable) dev_sel_sv_tables;
    DEVICE_INPUT(dev_sel_track_tables_t, Selections::CandidateTable) dev_sel_track_tables;
    DEVICE_INPUT_OPTIONAL(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_INPUT_OPTIONAL(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_INPUT(dev_sel_count_t, unsigned) dev_sel_count;
    DEVICE_INPUT(dev_sel_list_t, unsigned) dev_sel_list;
    DEVICE_INPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    DEVICE_INPUT(dev_substr_sel_size_t, unsigned) dev_substr_sel_size;
    DEVICE_INPUT(dev_candidate_count_t, unsigned) dev_candidate_count;
    DEVICE_INPUT(dev_candidate_offsets_t, unsigned) dev_candidate_offsets;
    DEVICE_INPUT(dev_lhcbid_containers_t, uint8_t) dev_lhcbid_containers;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_OUTPUT(dev_rb_substr_t, unsigned) dev_rb_substr;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_substr_bank(Parameters, const unsigned number_of_events);

  struct make_rb_substr_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };

} // namespace make_rb_substr