/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "VertexFitDeviceFunctions.cuh"
#include "AssociateConsolidated.cuh"
#include "ParticleTypes.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"

#include "AllenMonitoring.h"

namespace VertexFit {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_INPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_INPUT(dev_sv_poca_t, float) dev_sv_poca;
    // TODO: Choose a better name for the input particles, because they don't
    // necessarily need to be long tracks.
    DEVICE_INPUT(dev_long_track_particles_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_long_track_particles;
    DEVICE_OUTPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_OUTPUT(dev_sv_pv_ip_t, char) dev_sv_pv_ip;
    DEVICE_OUTPUT(dev_sv_fit_results_t, char) dev_sv_fit_results;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_fit_results_view_t,
      DEPENDENCIES(dev_sv_fit_results_t),
      Allen::Views::Physics::SecondaryVertices)
    dev_sv_fit_results_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(dev_sv_pv_tables_t, DEPENDENCIES(dev_sv_pv_ip_t), Allen::Views::Physics::PVTable)
    dev_sv_pv_tables;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_sv_track_pointers_t,
      DEPENDENCIES(dev_long_track_particles_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_two_track_sv_track_pointers;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_composite_view_t,
      DEPENDENCIES(
        dev_two_track_sv_track_pointers_t,
        dev_long_track_particles_t,
        dev_sv_fit_results_view_t,
        dev_sv_pv_tables_t,
        dev_multi_final_vertices_t),
      Allen::Views::Physics::CompositeParticle)
    dev_two_track_composite_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_composites_view_t,
      DEPENDENCIES(dev_two_track_composite_view_t),
      Allen::Views::Physics::CompositeParticles)
    dev_two_track_composites_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_composites_view_t,
      DEPENDENCIES(dev_two_track_composites_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_composites_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_composites_ptr_t,
      DEPENDENCIES(dev_multi_event_composites_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_composites_ptr;
  };

  __global__ void
  fit_secondary_vertices(Parameters, const float max_assoc_ipchi2, Allen::Monitoring::Histogram<>::DeviceType);

  struct vertex_fit_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct fit_secondary_vertices_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_maxassocipchi2 {this, "max_assoc_ipchi2", 16.0f, "maximum IP chi2 to associate to PV"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};

    Allen::Monitoring::Histogram<> m_histogram_nsvs {this,
                                                     "number_of_svs",
                                                     "NSVs",
                                                     {VertexFit::max_svs + 1, -0.5f, VertexFit::max_svs + 0.5}};
  };
} // namespace VertexFit
