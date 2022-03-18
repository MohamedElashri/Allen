/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "VertexDefinitions.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "PV_Definitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "ParticleTypes.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"

namespace VertexFit {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_INPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_kalman_pv_tables_t, Allen::Views::Physics::PVTable) dev_kalman_pv_tables;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_INPUT(dev_sv_poca_t, float) dev_sv_poca;
    DEVICE_OUTPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_OUTPUT(dev_sv_pv_ipchi2_t, char) dev_sv_pv_ipchi2;
    DEVICE_OUTPUT(dev_sv_fit_results_t, char) dev_sv_fit_results;

    // Long track particles view and dependencies.
    DEVICE_INPUT(dev_long_track_particles_t, Allen::Views::Physics::BasicParticles) dev_long_track_particles;
    DEVICE_INPUT(dev_long_track_particle_view_t, Allen::Views::Physics::BasicParticle) dev_long_track_particle;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_INPUT(dev_kalman_fit_results_t, char) dev_kalman_fit_results;
    DEVICE_INPUT(dev_kalman_states_view_t, Allen::Views::Physics::KalmanStates) dev_kalman_states_view;

    // SciFi tracks view and dependencies.
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;
    DEVICE_INPUT(dev_scifi_track_view_t, Allen::Views::SciFi::Consolidated::Track) dev_scifi_track_view;
    DEVICE_INPUT(dev_scifi_hits_view_t, Allen::Views::SciFi::Consolidated::Hits) dev_scifi_hits_view;
    DEVICE_INPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    // DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, unsigned) dev_offsets_scifi_track_hit_number; // Saved in the Track view.
    // DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned) dev_atomics_scifi; // Saved in the Tracks view.
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned) dev_scifi_track_ut_indices;
    

    // UT tracks view and dependencies.
    DEVICE_INPUT(dev_ut_tracks_view_t, Allen::Views::UT::Consolidated::Tracks) dev_ut_tracks_view;
    DEVICE_INPUT(dev_ut_track_view_t, Allen::Views::UT::Consolidated::Track) dev_ut_track_view;
    DEVICE_INPUT(dev_ut_hits_view_t, Allen::Views::UT::Consolidated::Hits) dev_ut_hits_view;
    DEVICE_INPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    // DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned) dev_offsets_ut_tracks; // Saved in the Tracks view.
    // DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned) dev_offsets_ut_track_hit_number; // Saved in the Track view.
    DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned) dev_ut_track_velo_indices;

    // VELO tracks view and dependencies.
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_track_view_t, Allen::Views::Velo::Consolidated::Track) dev_velo_track_view;
    DEVICE_INPUT(dev_velo_hits_view_t, Allen::Views::Velo::Consolidated::Hits) dev_velo_hits_view;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    // DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks; // Saved in the Tracks view.
    // DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number; // Saved in the Track view.

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_fit_results_view_t,
      DEPENDENCIES(dev_sv_fit_results_t),
      Allen::Views::Physics::SecondaryVertices)
    dev_sv_fit_results_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_sv_pv_tables_t,
      DEPENDENCIES(dev_sv_pv_ipchi2_t),
      Allen::Views::Physics::PVTable)
    dev_sv_pv_tables;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_sv_track_pointers_t,
      DEPENDENCIES(dev_long_track_particles_t),
      Allen::ILHCbIDStructure*)
    dev_two_track_sv_track_pointers;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_composite_view_t,
      DEPENDENCIES(
        dev_two_track_sv_track_pointers_t,
        dev_long_track_particles_t,
        dev_sv_fit_results_view_t,
        dev_multi_final_vertices_t,
        dev_long_track_particles_t),
      Allen::Views::Physics::CompositeParticle)
    dev_two_track_composite_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_two_track_composites_view_t, 
      DEPENDENCIES(
        // SV dependencies.
        dev_two_track_composite_view_t,
        dev_two_track_sv_track_pointers_t,
        dev_sv_fit_results_view_t,
        dev_sv_fit_results_t,
        dev_sv_pv_tables_t,
        dev_sv_pv_ipchi2_t,
        dev_multi_final_vertices_t,
        
        // Long track dependencies.
        dev_long_track_particles_t,
        dev_long_track_particle_view_t,
        dev_is_muon_t,
        dev_kalman_fit_results_t,
        dev_kalman_states_view_t,

        // SciFi track dependencies.
        dev_scifi_tracks_view_t,
        dev_scifi_track_view_t,
        dev_scifi_hits_view_t,
        dev_scifi_track_hits_t,
        dev_scifi_track_ut_indices_t,

        // UT track dependencies.
        dev_ut_tracks_view_t,
        dev_ut_track_view_t,
        dev_ut_hits_view_t,
        dev_ut_track_hits_t,
        dev_ut_track_velo_indices_t,

        // Velo track dependencies.
        dev_velo_tracks_view_t,
        dev_velo_track_view_t,
        dev_velo_hits_view_t,
        dev_velo_track_hits_t),
      Allen::Views::Physics::CompositeParticles)
    dev_two_track_composites_view;
    PROPERTY(max_assoc_ipchi2_t, "max_assoc_ipchi2", "maximum IP chi2 to associate to PV", float) max_assoc_ipchi2;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void fit_secondary_vertices(Parameters);

  struct vertex_fit_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct fit_secondary_vertices_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<max_assoc_ipchi2_t> m_maxassocipchi2 {this, 16.0f};
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace VertexFit
