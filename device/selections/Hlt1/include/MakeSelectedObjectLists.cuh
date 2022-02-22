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

namespace make_selected_object_lists {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_active_lines_t, unsigned) host_number_of_active_lines;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    DEVICE_INPUT(dev_number_of_active_lines_t, unsigned) dev_number_of_active_lines;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_multi_event_particle_containers_t, Allen::Views::Physics::IMultiEventParticleContainer*)
    dev_multi_event_particle_containers;
    // Need the LHCbID container type because we can't dynamic_cast in device code.
    DEVICE_INPUT(dev_lhcbid_containers_t, uint8_t) dev_lhcbid_containers;
    DEVICE_INPUT(dev_selections_t, bool) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_OUTPUT(dev_candidate_count_t, unsigned) dev_candidate_count;
    DEVICE_OUTPUT(dev_sel_track_count_t, unsigned) dev_sel_track_count;
    DEVICE_OUTPUT(dev_sel_track_indices_t, unsigned) dev_sel_track_indices;
    DEVICE_OUTPUT(dev_sel_sv_count_t, unsigned) dev_sel_sv_count;
    DEVICE_OUTPUT(dev_sel_sv_indices_t, unsigned) dev_sel_sv_indices;
    DEVICE_OUTPUT(dev_track_duplicate_map_t, int) dev_track_duplicate_map;
    DEVICE_OUTPUT(dev_sv_duplicate_map_t, int) dev_sv_duplicate_map;
    DEVICE_OUTPUT(dev_unique_track_list_t, unsigned) dev_unique_track_list;
    DEVICE_OUTPUT(dev_unique_sv_list_t, unsigned) dev_unique_sv_list;
    DEVICE_OUTPUT(dev_unique_track_count_t, unsigned) dev_unique_track_count;
    DEVICE_OUTPUT(dev_unique_sv_count_t, unsigned) dev_unique_sv_count;
    DEVICE_OUTPUT(dev_sel_count_t, unsigned) dev_sel_count;
    DEVICE_OUTPUT(dev_sel_list_t, unsigned) dev_sel_list;
    DEVICE_OUTPUT(dev_hits_bank_size_t, unsigned) dev_hits_bank_size;
    DEVICE_OUTPUT(dev_substr_bank_size_t, unsigned) dev_substr_bank_size;
    DEVICE_OUTPUT(dev_substr_sel_size_t, unsigned) dev_substr_sel_size;
    DEVICE_OUTPUT(dev_substr_sv_size_t, unsigned) dev_substr_sv_size;
    DEVICE_OUTPUT(dev_stdinfo_bank_size_t, unsigned) dev_stdinfo_bank_size;
    DEVICE_OUTPUT(dev_objtyp_bank_size_t, unsigned) dev_objtyp_bank_size;
    DEVICE_OUTPUT(dev_selrep_size_t, unsigned) dev_selrep_size;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_selected_basic_particle_ptrs_t,
      DEPENDENCIES(dev_multi_event_particle_containers_t),
      Allen::Views::Physics::BasicParticle*)
    dev_selected_basic_particle_ptrs;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_selected_composite_particle_ptrs_t,
      DEPENDENCIES(dev_multi_event_particle_containers_t),
      Allen::Views::Physics::CompositeParticle*)
    dev_selected_composite_particle_ptrs;
    PROPERTY(max_selected_tracks_t, "max_selected_tracks", "Maximum number of selected tracks per event.", unsigned)
    max_selected_tracks;
    PROPERTY(max_selected_svs_t, "max_selected_svs", "Maximum number of selected SVs per event.", unsigned)
    max_selected_svs;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_selected_object_lists(Parameters, const unsigned total_events);

  __global__ void calc_rb_sizes(Parameters);

  struct make_selected_object_lists_t : public DeviceAlgorithm, Parameters {
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
    Property<max_selected_tracks_t> m_max_selected_tracks {this, 100};
    Property<max_selected_svs_t> m_max_selected_svs {this, 100};
  };

} // namespace make_selected_object_lists