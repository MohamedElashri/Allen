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
//#include "ConfiguredInputAggregates.h"
#include "CandidateTable.cuh"

namespace calc_rb_hits_size {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    HOST_INPUT_OPTIONAL(host_number_of_reconstructed_scifi_tracks_t, unsigned)
    host_number_of_reconstructed_scifi_tracks;
    HOST_INPUT_OPTIONAL(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT_OPTIONAL(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_INPUT_OPTIONAL(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_INPUT_OPTIONAL(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT_OPTIONAL(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT_OPTIONAL(dev_track_hits_offsets_t, unsigned) dev_track_hits_offsets;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_INPUT(dev_lhcbid_containers_t, uint8_t) dev_lhcbid_containers;
    DEVICE_OUTPUT(dev_candidate_count_t, unsigned) dev_candidate_count;
    DEVICE_OUTPUT(dev_track_tags_t, unsigned) dev_track_tags;
    DEVICE_OUTPUT(dev_sel_track_count_t, unsigned) dev_sel_track_count;
    DEVICE_OUTPUT(dev_sel_track_indices_t, unsigned) dev_sel_track_indices;
    DEVICE_OUTPUT(dev_sel_track_inserts_t, unsigned) dev_sel_track_inserts;
    DEVICE_OUTPUT(
      dev_sel_track_tables_t,
      Selections::CandidateTable,
      dev_sel_track_count_t,
      dev_sel_track_indices_t,
      dev_sel_track_inserts_t)
    dev_sel_track_tables;
    DEVICE_OUTPUT(dev_sv_tags_t, unsigned) dev_sv_tags;
    DEVICE_OUTPUT(dev_sel_sv_count_t, unsigned) dev_sel_sv_count;
    DEVICE_OUTPUT(dev_sel_sv_indices_t, unsigned) dev_sel_sv_indices;
    DEVICE_OUTPUT(dev_sel_sv_inserts_t, unsigned) dev_sel_sv_inserts;
    DEVICE_OUTPUT(
      dev_sel_sv_tables_t,
      Selections::CandidateTable,
      dev_sel_sv_count_t,
      dev_sel_sv_indices_t,
      dev_sel_sv_inserts_t)
    dev_sel_sv_tables;
    DEVICE_OUTPUT(dev_tag_hits_counts_t, unsigned) dev_tag_hits_counts;
    DEVICE_OUTPUT(dev_hits_bank_size_t, unsigned) dev_hits_bank_size;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void calc_size(Parameters, const unsigned total_events);

  struct calc_rb_hits_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
  };

} // namespace calc_rb_hits_size