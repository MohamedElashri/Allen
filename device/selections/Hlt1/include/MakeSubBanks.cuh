/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace make_subbanks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_substr_bank_size_t, unsigned) host_substr_bank_size;
    HOST_INPUT(host_hits_bank_size_t, unsigned) host_hits_bank_size;
    HOST_INPUT(host_objtyp_bank_size_t, unsigned) host_objtyp_bank_size;
    HOST_INPUT(host_stdinfo_bank_size_t, unsigned) host_stdinfo_bank_size;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_INPUT(dev_sel_count_t, unsigned) dev_sel_count;
    DEVICE_INPUT(dev_sel_list_t, unsigned) dev_sel_list;
    DEVICE_INPUT(dev_candidate_count_t, unsigned) dev_candidate_count;
    DEVICE_INPUT(dev_candidate_offsets_t, unsigned) dev_candidate_offsets;
    DEVICE_INPUT(dev_unique_track_list_t, unsigned) dev_unique_track_list;
    DEVICE_INPUT(dev_unique_sv_list_t, unsigned) dev_unique_sv_list;
    DEVICE_INPUT(dev_unique_track_count_t, unsigned) dev_unique_track_count;
    DEVICE_INPUT(dev_unique_sv_count_t, unsigned) dev_unique_sv_count;
    DEVICE_INPUT(dev_track_duplicate_map_t, int) dev_track_duplicate_map;
    DEVICE_INPUT(dev_sv_duplicate_map_t, int) dev_sv_duplicate_map;
    DEVICE_INPUT(dev_sel_track_indices_t, unsigned) dev_sel_track_indices;
    DEVICE_INPUT(dev_sel_sv_indices_t, unsigned) dev_sel_sv_indices;
    DEVICE_INPUT(dev_multi_event_particle_containers_t, Allen::IMultiEventContainer*)
    dev_multi_event_particle_containers;
    DEVICE_INPUT(dev_basic_particle_ptrs_t, Allen::Views::Physics::BasicParticle*) dev_basic_particle_ptrs;
    DEVICE_INPUT(dev_composite_particle_ptrs_t, Allen::Views::Physics::CompositeParticle*) dev_composite_particle_ptrs;
    DEVICE_INPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    DEVICE_INPUT(dev_substr_sel_size_t, unsigned) dev_substr_sel_size;
    DEVICE_INPUT(dev_substr_sv_size_t, unsigned) dev_substr_sv_size;
    DEVICE_INPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    DEVICE_INPUT(dev_rb_objtyp_offsets_t, unsigned) dev_rb_objtyp_offsets;
    DEVICE_INPUT(dev_rb_stdinfo_offsets_t, unsigned) dev_rb_stdinfo_offsets;
    DEVICE_OUTPUT(dev_rb_substr_t, unsigned) dev_rb_substr;
    DEVICE_OUTPUT(dev_rb_hits_t, unsigned) dev_rb_hits;
    DEVICE_OUTPUT(dev_rb_objtyp_t, unsigned) dev_rb_objtyp;
    DEVICE_OUTPUT(dev_rb_stdinfo_t, unsigned) dev_rb_stdinfo;
    // TODO: This needs to be the same as the properties in
    // MakeSelectedObjectLists. These should be saved as constants somewhere.
    PROPERTY(max_selected_tracks_t, "max_selected_tracks", "Maximum number of selected tracks per event.", unsigned)
    max_selected_tracks;
    PROPERTY(max_selected_svs_t, "max_selected_svs", "Maximum number of selected SVs per event.", unsigned)
    max_selected_svs;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_rb_substr(Parameters, const unsigned number_of_events);

  __global__ void make_rb_hits(Parameters);

  struct make_subbanks_t : public DeviceAlgorithm, Parameters {
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
    Property<max_selected_tracks_t> m_max_selected_tracks {this, 100};
    Property<max_selected_svs_t> m_max_selected_svs {this, 100};
  };
} // namespace make_subbanks