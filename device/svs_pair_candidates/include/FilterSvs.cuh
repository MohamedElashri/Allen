/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VertexDefinitions.cuh"

#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

// #include "ParKalmanDefinitions.cuh"
// #include "ParKalmanMath.cuh"
// #include "ParKalmanFittedTrack.cuh"
// #include "VertexDefinitions.cuh"
// #include "PV_Definitions.cuh"
// #include "SciFiConsolidated.cuh"
// #include "UTConsolidated.cuh"
// #include "VeloConsolidated.cuh"
// #include "AssociateConsolidated.cuh"
// #include "States.cuh"
// #include "AlgorithmTypes.cuh"
// #include "ParticleTypes.cuh"
//
namespace FilterSvs {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_tracks_t, unsigned) host_number_of_tracks;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_secondary_vertices_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_secondary_vertices;
    DEVICE_OUTPUT(dev_sv_atomics_t, unsigned) dev_sv_atomics;
    DEVICE_OUTPUT(dev_svs_trk1_idx_t, unsigned) dev_svs_trk1_idx;
    DEVICE_OUTPUT(dev_svs_trk2_idx_t, unsigned) dev_svs_trk2_idx;

    DEVICE_OUTPUT_WITH_DEPENDENCIES(
    dev_two_track_sv_track_pointers_t,
      DEPENDENCIES(dev_secondary_vertices_t),
      std::array<const Allen::Views::Physics::IParticle*, 4>)
    dev_two_track_sv_track_pointers;

    //Set all properties to filter svs
    PROPERTY(track_min_ipchi2_t, "track_min_ipchi2", "minimum track IP chi2", float) track_min_ipchi2;
    PROPERTY(vtx_max_chi2ndof_t, "vtx_max_chi2ndof", "max vertex chi2/ndof", float) vtx_max_chi2ndof;
    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

__global__ void filter_svs(Parameters);


struct filter_svs_t : public DeviceAlgorithm, Parameters {
  void set_arguments_size(
    ArgumentReferences<Parameters> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<track_min_ipchi2_t> m_minipchi2 {this, 7.0f};
    Property<vtx_max_chi2ndof_t> m_maxchi2ndof {this, 30.0f};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{16, 16, 1}}};

  };
}
