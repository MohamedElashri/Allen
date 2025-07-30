/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "VertexDefinitions.cuh"
#include "States.cuh"

// Event Model
#include "UTDefinitions.cuh"

// Local
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"

#include "AllenMonitoring.h"

namespace downstream_make_secondary_vertices {
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Size of downstream tracks
    HOST_INPUT(host_number_of_downstream_secondary_vertices_t, unsigned) host_number_of_downstream_secondary_vertices;
    // PV input
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    // Secondary vertices
    DEVICE_INPUT(dev_downstream_secondary_vertices_t, VertexFit::MiniVertex) dev_downstream_secondary_vertices;
    DEVICE_INPUT(dev_offsets_downstream_secondary_vertices_t, unsigned) dev_offsets_downstream_secondary_vertices;
    // Downstream tracks
    DEVICE_INPUT(dev_multi_event_downstream_track_particles_view_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_multi_event_downstream_track_particles_view;
    // Output
    DEVICE_OUTPUT(dev_sv_fit_results_t, char) dev_sv_fit_results;
    DEVICE_OUTPUT(dev_downstream_secondary_vertices_pv_t, const PV::Vertex*) dev_downstream_secondary_vertices_pv;
    DEVICE_OUTPUT(dev_downstream_secondary_vertices_ip_t, float) dev_downstream_secondary_vertices_ip;

    // Views
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_fit_results_view_t,
      DEPENDENCIES(dev_sv_fit_results_t),
      Allen::Views::Physics::SecondaryVertices)
    dev_sv_fit_results_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_sv_track_pointers_t,
      DEPENDENCIES(dev_multi_event_downstream_track_particles_view_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_two_track_sv_track_pointers;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_composite_view_t,
      DEPENDENCIES(
        dev_two_track_sv_track_pointers_t,
        dev_multi_event_downstream_track_particles_view_t,
        dev_sv_fit_results_view_t,
        dev_multi_final_vertices_t,
        dev_downstream_secondary_vertices_ip_t),
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

    // Property
  };

  __global__ void downstream_make_secondary_vertices(Parameters);

  __global__ void downstream_make_secondary_vertices_views(Parameters, Allen::Monitoring::Histogram<>::DeviceType);

  struct downstream_make_secondary_vertices_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 1, 1}, "block dimensions"};

    Allen::Monitoring::Histogram<> m_histogram_nsvs {this,
                                                     "number_of_svs",
                                                     "NSVs",
                                                     {VertexFit::max_svs, 0, VertexFit::max_svs}};
  };
} // namespace downstream_make_secondary_vertices