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
    DEVICE_INPUT(dev_max_objects_offsets_t, unsigned) dev_max_objects_offsets;
    DEVICE_INPUT(dev_sel_count_t, unsigned) dev_sel_count;
    DEVICE_INPUT(dev_sel_list_t, unsigned) dev_sel_list;
    DEVICE_INPUT(dev_candidate_offsets_t, unsigned) dev_candidate_offsets;
    DEVICE_INPUT(dev_unique_track_list_t, unsigned) dev_unique_track_list;
    DEVICE_INPUT(dev_unique_calo_list_t, unsigned) dev_unique_calo_list;
    DEVICE_INPUT(dev_unique_sv_list_t, unsigned) dev_unique_sv_list;
    DEVICE_INPUT(dev_unique_track_count_t, unsigned) dev_unique_track_count;
    DEVICE_INPUT(dev_unique_calo_count_t, unsigned) dev_unique_calo_count;
    DEVICE_INPUT(dev_unique_sv_count_t, unsigned) dev_unique_sv_count;
    DEVICE_INPUT(dev_track_duplicate_map_t, int) dev_track_duplicate_map;
    DEVICE_INPUT(dev_calo_duplicate_map_t, int) dev_calo_duplicate_map;
    DEVICE_INPUT(dev_sv_duplicate_map_t, int) dev_sv_duplicate_map;
    DEVICE_INPUT(dev_sel_track_indices_t, unsigned) dev_sel_track_indices;
    DEVICE_INPUT(dev_sel_calo_indices_t, unsigned) dev_sel_calo_indices;
    DEVICE_INPUT(dev_sel_sv_indices_t, unsigned) dev_sel_sv_indices;
    DEVICE_INPUT(dev_multi_event_particle_containers_t, Allen::IMultiEventContainer*)
    dev_multi_event_particle_containers;
    DEVICE_INPUT(dev_basic_particle_ptrs_t, Allen::Views::Physics::BasicParticle*) dev_basic_particle_ptrs;
    DEVICE_INPUT(dev_neutral_basic_particle_ptrs_t, Allen::Views::Physics::NeutralBasicParticle*)
    dev_neutral_basic_particle_ptrs;
    DEVICE_INPUT(dev_composite_particle_ptrs_t, Allen::Views::Physics::CompositeParticle*) dev_composite_particle_ptrs;
    DEVICE_INPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    DEVICE_INPUT(dev_substr_sel_size_t, unsigned) dev_substr_sel_size;
    DEVICE_INPUT(dev_substr_sv_size_t, unsigned) dev_substr_sv_size;
    DEVICE_INPUT(dev_substr_track_size_t, unsigned) dev_substr_track_size;
    DEVICE_INPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    DEVICE_INPUT(dev_rb_objtyp_offsets_t, unsigned) dev_rb_objtyp_offsets;
    DEVICE_INPUT(dev_rb_stdinfo_offsets_t, unsigned) dev_rb_stdinfo_offsets;
    DEVICE_OUTPUT(dev_rb_substr_t, unsigned) dev_rb_substr;
    DEVICE_OUTPUT(dev_rb_hits_t, unsigned) dev_rb_hits;
    DEVICE_OUTPUT(dev_rb_objtyp_t, unsigned) dev_rb_objtyp;
    DEVICE_OUTPUT(dev_rb_stdinfo_t, unsigned) dev_rb_stdinfo;
  };

  __host__ __device__ void make_rb_substr_bank(
    unsigned* event_rb_substr,
    const unsigned event_rb_substr_size,
    const unsigned n_children,
    const unsigned n_sels,
    const unsigned n_tracks,
    const unsigned n_calos,
    const unsigned n_svs,
    const unsigned substr_sel_size,
    const unsigned substr_sv_size,
    const unsigned substr_track_size,
    Allen::IMultiEventContainer* const* mecs,
    Allen::Views::Physics::BasicParticle* const* const event_track_ptrs,
    Allen::Views::Physics::NeutralBasicParticle* const* const event_calo_ptrs,
    Allen::Views::Physics::CompositeParticle* const* const event_sv_ptrs,
    const unsigned* line_object_offsets,
    const unsigned* event_unique_track_list,
    const unsigned* event_unique_calo_list,
    const unsigned* event_unique_sv_list,
    const unsigned* event_candidate_offsets,
    const unsigned* event_sel_list,
    const unsigned* sel_track_indices,
    const unsigned* sel_calo_indices,
    const unsigned* sel_sv_indices,
    const int* track_duplicate_map,
    const int* calo_duplicate_map,
    const int* sv_duplicate_map);

  __host__ __device__ void make_rb_objtyp_bank(
    unsigned* event_rb_objtyp,
    const unsigned n_objtyps,
    const unsigned n_sels,
    const unsigned n_tracks,
    const unsigned n_calos,
    const unsigned n_svs);

  __host__ __device__ void make_rb_stdinfo_bank(
    unsigned* event_rb_stdinfo,
    const unsigned stdinfo_size,
    const unsigned n_sels,
    const unsigned n_tracks,
    const unsigned n_calos,
    const unsigned n_svs,
    const unsigned* event_sel_list,
    const unsigned* event_unique_track_list,
    const unsigned* event_unique_calo_list,
    const unsigned* event_unique_sv_list,
    Allen::Views::Physics::BasicParticle* const* const event_track_ptrs,
    Allen::Views::Physics::NeutralBasicParticle* const* const event_calo_ptrs,
    Allen::Views::Physics::CompositeParticle* const* const event_sv_ptrs);

  __global__ void make_rb_substr(Parameters, const unsigned, const unsigned);

  __global__ void make_rb_hits(Parameters, const unsigned);

  struct make_subbanks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {64, 1, 1}, "block dimensions"};
    // TODO: This needs to be the same as the properties in
    // MakeSelectedObjectLists. These should be saved as constants somewhere.
    Allen::Property<unsigned> m_max_children_per_object {this,
                                                         "max_children_per_object",
                                                         4,
                                                         "Maximum number of children per selected object"};
  };
} // namespace make_subbanks
