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
  __device__ inline bool poca(
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    float& x,
    float& y,
    float& z);

  __device__ inline float ip(float x0, float y0, float z0, float x, float y, float z, float tx, float ty);

  __device__ inline float addToDerivatives(
    const Allen::Views::Physics::BasicParticle& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22);

  __device__ inline float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22);

  __device__ inline bool doFit(
    const Allen::Views::Physics::BasicParticle& trackA, 
    const Allen::Views::Physics::BasicParticle& trackB, 
    TrackMVAVertex& vertex);

  __device__ inline void fill_extra_info(
    TrackMVAVertex& sv,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB);

  __device__ inline void fill_extra_pv_info(
    TrackMVAVertex& sv,
    const PV::Vertex& pv,
    const Allen::Views::Physics::BasicParticle& trackA,
    const Allen::Views::Physics::BasicParticle& trackB,
    const float max_assoc_ipchi2);

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_long_track_particles_t, Allen::Views::Physics::BasicParticles) dev_long_track_particles;
    DEVICE_INPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_INPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_OUTPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_consolidated_svs;
    DEVICE_OUTPUT(dev_sv_pv_ipchi2_t, char) dev_sv_pv_ipchi2;
    DEVICE_OUTPUT(dev_sv_fit_results_t, char) dev_sv_fit_results;
    DEVICE_OUTPUT(
      dev_sv_fit_results_view_t,
      Allen::Views::Physics::SecondaryVertices,
      dev_sv_fit_results_t)
    dev_sv_fit_results_view;
    DEVICE_OUTPUT(
      dev_sv_pv_tables_t,
      Allen::Views::Physics::PVTable,
      dev_sv_pv_ipchi2_t)
    dev_sv_pv_tables;
    DEVICE_OUTPUT(
      dev_two_track_svs_tracks_t, 
      Allen::Views::Physics::BasicParticle,
      dev_long_track_particles_t)
    dev_two_track_svs_tracks;
    DEVICE_OUTPUT(
      dev_two_track_svs_t, 
      Allen::Views::Physics::CompositeParticles,
      dev_two_track_svs_tracks_t,
      dev_sv_fit_results_view_t,
      dev_multi_final_vertices_t)
    dev_two_track_svs;
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
