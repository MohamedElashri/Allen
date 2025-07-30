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

#include "VertexDefinitions.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "AssociateConsolidated.cuh"
#include "MassDefinitions.h"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace CombineSVTrack {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_combinations_t, unsigned) host_number_of_combinations;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_combination_offsets_t, unsigned) dev_combination_offsets;
    DEVICE_INPUT(dev_sv_idx_t, unsigned) dev_sv_idx;
    DEVICE_INPUT(dev_track_idx_t, unsigned) dev_track_idx;
    DEVICE_INPUT(dev_svs_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_svs;
    DEVICE_INPUT(dev_tracks_t, Allen::Views::Physics::MultiEventBasicParticles) dev_tracks;
    DEVICE_INPUT(dev_pvs_t, PV::Vertex) dev_pvs;
    DEVICE_INPUT(dev_npvs_t, unsigned) dev_npvs;
    DEVICE_OUTPUT(dev_sv_track_pv_ip_t, char) dev_sv_track_pv_ip;
    DEVICE_OUTPUT(dev_sv_track_fit_results_t, char) dev_sv_track_fit_results;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_track_fit_results_view_t,
      DEPENDENCIES(dev_sv_track_fit_results_t),
      Allen::Views::Physics::SecondaryVertices)
    dev_sv_track_fit_results_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_track_pv_tables_t,
      DEPENDENCIES(dev_sv_track_pv_ip_t),
      Allen::Views::Physics::PVTable)
    dev_sv_track_pv_tables;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_track_pointers_t,
      DEPENDENCIES(dev_tracks_t, dev_svs_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_sv_track_pointers;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_track_composite_view_t,
      DEPENDENCIES(
        dev_sv_track_pointers_t,
        dev_tracks_t,
        dev_sv_track_pv_tables_t,
        dev_pvs_t,
        dev_sv_track_fit_results_view_t),
      Allen::Views::Physics::CompositeParticle)
    dev_sv_track_composite_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_track_composites_view_t,
      DEPENDENCIES(dev_sv_track_composite_view_t),
      Allen::Views::Physics::CompositeParticles)
    dev_sv_track_composites_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_composites_view_t,
      DEPENDENCIES(dev_sv_track_composites_view_t),
      Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_composites_view;
  };

  __global__ void combine_sv_track(Parameters);

  struct combine_sv_track_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  };
} // namespace CombineSVTrack
