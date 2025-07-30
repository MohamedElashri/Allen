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
    HOST_INPUT(host_max_objects_t, unsigned) host_max_objects;
    DEVICE_INPUT(dev_dec_reports_t, unsigned) dev_dec_reports;
    HOST_INPUT(host_dec_reports_t, unsigned) host_dec_reports;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_multi_event_particle_containers_t, Allen::IMultiEventContainer*)
    dev_multi_event_particle_containers;
    DEVICE_INPUT(dev_selections_t, uint32_t) dev_selections;
    DEVICE_INPUT(dev_selections_offsets_t, unsigned) dev_selections_offsets;
    DEVICE_INPUT(dev_max_objects_offsets_t, unsigned) dev_max_objects_offsets;
    DEVICE_OUTPUT(dev_sel_track_count_t, unsigned) dev_sel_track_count;
    DEVICE_OUTPUT(dev_sel_track_indices_t, unsigned) dev_sel_track_indices;
    DEVICE_OUTPUT(dev_sel_calo_count_t, unsigned) dev_sel_calo_count;
    DEVICE_OUTPUT(dev_sel_calo_indices_t, unsigned) dev_sel_calo_indices;
    DEVICE_OUTPUT(dev_sel_sv_count_t, unsigned) dev_sel_sv_count;
    DEVICE_OUTPUT(dev_sel_sv_indices_t, unsigned) dev_sel_sv_indices;
    DEVICE_OUTPUT(dev_track_duplicate_map_t, int) dev_track_duplicate_map;
    DEVICE_OUTPUT(dev_calo_duplicate_map_t, int) dev_calo_duplicate_map;
    DEVICE_OUTPUT(dev_sv_duplicate_map_t, int) dev_sv_duplicate_map;
    DEVICE_OUTPUT(dev_unique_track_list_t, unsigned) dev_unique_track_list;
    DEVICE_OUTPUT(dev_unique_calo_list_t, unsigned) dev_unique_calo_list;
    DEVICE_OUTPUT(dev_unique_sv_list_t, unsigned) dev_unique_sv_list;
    DEVICE_OUTPUT(dev_unique_track_count_t, unsigned) dev_unique_track_count;
    DEVICE_OUTPUT(dev_unique_calo_count_t, unsigned) dev_unique_calo_count;
    DEVICE_OUTPUT(dev_unique_sv_count_t, unsigned) dev_unique_sv_count;
    DEVICE_OUTPUT(dev_sel_count_t, unsigned) dev_sel_count;
    DEVICE_OUTPUT(dev_sel_list_t, unsigned) dev_sel_list;

    DEVICE_OUTPUT(dev_candidate_offsets_t, unsigned) dev_candidate_offsets;

    DEVICE_OUTPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    HOST_OUTPUT(host_hits_bank_size_t, unsigned) host_hits_bank_size;
    DEVICE_OUTPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    HOST_OUTPUT(host_substr_bank_size_t, unsigned) host_substr_bank_size;
    DEVICE_OUTPUT(dev_rb_objtyp_offsets_t, unsigned) dev_rb_objtyp_offsets;
    HOST_OUTPUT(host_objtyp_bank_size_t, unsigned) host_objtyp_bank_size;
    DEVICE_OUTPUT(dev_rb_stdinfo_offsets_t, unsigned) dev_rb_stdinfo_offsets;
    HOST_OUTPUT(host_stdinfo_bank_size_t, unsigned) host_stdinfo_bank_size;
    DEVICE_OUTPUT(dev_selrep_offsets_t, unsigned) dev_selrep_offsets;
    HOST_OUTPUT(host_selrep_size_t, unsigned) host_selrep_size;

    DEVICE_OUTPUT(dev_substr_sel_size_t, unsigned) dev_substr_sel_size;
    DEVICE_OUTPUT(dev_substr_sv_size_t, unsigned) dev_substr_sv_size;
    DEVICE_OUTPUT(dev_substr_track_size_t, unsigned) dev_substr_track_size;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_selected_basic_particle_ptrs_t,
      DEPENDENCIES(dev_multi_event_particle_containers_t),
      Allen::Views::Physics::BasicParticle*)
    dev_selected_basic_particle_ptrs;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_selected_neutral_basic_particle_ptrs_t,
      DEPENDENCIES(dev_multi_event_particle_containers_t),
      Allen::Views::Physics::NeutralBasicParticle*)
    dev_selected_neutral_basic_particle_ptrs;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_selected_composite_particle_ptrs_t,
      DEPENDENCIES(dev_multi_event_particle_containers_t),
      Allen::Views::Physics::CompositeParticle*)
    dev_selected_composite_particle_ptrs;
  };

  __global__ void make_selected_object_lists(Parameters, const unsigned, const unsigned);

  __global__ void calc_rb_sizes(Parameters, const unsigned);

  struct make_selected_object_lists_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {64, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_max_children_per_object {this,
                                                         "max_children_per_object",
                                                         4,
                                                         "Maximum number of children per selected object"};
  };
} // namespace make_selected_object_lists
