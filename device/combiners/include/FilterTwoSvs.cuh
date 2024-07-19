/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VertexDefinitions.cuh"

#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace FilterTwoSvs {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_1_t, unsigned) host_number_of_svs_1;
    HOST_INPUT(host_number_of_svs_2_t, unsigned) host_number_of_svs_2;
    HOST_INPUT(host_max_combos_t, unsigned) host_max_combos;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_secondary_vertices_1_t, Allen::Views::Physics::MultiEventCompositeParticles)
    dev_secondary_vertices_1;
    DEVICE_INPUT(dev_secondary_vertices_2_t, Allen::Views::Physics::MultiEventCompositeParticles)
    dev_secondary_vertices_2;
    DEVICE_INPUT(dev_max_combo_offsets_t, unsigned) dev_max_combo_offsets;
    DEVICE_OUTPUT(dev_sv_1_filter_decision_t, bool) dev_sv_1_filter_decision;
    DEVICE_OUTPUT(dev_sv_2_filter_decision_t, bool) dev_sv_2_filter_decision;
    DEVICE_OUTPUT(dev_combo_offset_t, unsigned) dev_combo_offset;
    DEVICE_OUTPUT(dev_child1_idx_t, unsigned) dev_child1_idx;
    DEVICE_OUTPUT(dev_child2_idx_t, unsigned) dev_child2_idx;
    HOST_OUTPUT(host_total_combo_t, unsigned) host_total_combo;

    // Set all properties to filter svs
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Max child vertex chi2", float) maxVertexChi2;
    PROPERTY(minMassV1_t, "minMassV1", "Minimum mass of first vertex", float) minMassV1;
    PROPERTY(maxMassV1_t, "maxMassV1", "Maximum mass of first vertex", float) maxMassV1;
    PROPERTY(minPtV1_t, "minPtV1", "Minimum pT of first vertex", float) minPtV1;
    PROPERTY(minCosDiraV1_t, "minCosDiraV1", "Minimum DIRA of first vertex", float) minCosDiraV1;
    PROPERTY(minEtaV1_t, "minEtaV1", "Minimum eta of first vertex", float) minEtaV1;
    PROPERTY(maxEtaV1_t, "maxEtaV1", "Maximum eta of first vertex", float) maxEtaV1;
    PROPERTY(minTrackPtV1_t, "minTrackPtV1", "Minimum track pT of first vertex", float) minTrackPtV1;
    PROPERTY(minTrackPV1_t, "minTrackPV1", "Minimum track p of first vertex", float) minTrackPV1;
    PROPERTY(minTrackIPChi2V1_t, "minTrackIPChi2V1", "Minimum track IP chi2 of first vertex", float) minTrackIPChi2V1;
    PROPERTY(minTrackIPV1_t, "minTrackIPV1", "Minimum track IP of first vertex", float) minTrackIPV1;
    PROPERTY(minMassV2_t, "minMassV2", "Minimum mass of second vertex", float) minMassV2;
    PROPERTY(maxMassV2_t, "maxMassV2", "Maximum mass of second vertex", float) maxMassV2;
    PROPERTY(minPtV2_t, "minPtV2", "Minimum pT of second vertex", float) minPtV2;
    PROPERTY(minCosDiraV2_t, "minCosDiraV2", "Minimum DIRA of second vertex", float) minCosDiraV2;
    PROPERTY(minEtaV2_t, "minEtaV2", "Minimum eta of second vertex", float) minEtaV2;
    PROPERTY(maxEtaV2_t, "maxEtaV2", "Maximum eta of second vertex", float) maxEtaV2;
    PROPERTY(minTrackPtV2_t, "minTrackPtV2", "Minimum track pT of second vertex", float) minTrackPtV2;
    PROPERTY(minTrackPV2_t, "minTrackPV2", "Minimum track p of second vertex", float) minTrackPV2;
    PROPERTY(minTrackIPChi2V2_t, "minTrackIPChi2V2", "Minimum track IP chi2 of second vertex", float) minTrackIPChi2V2;
    PROPERTY(minTrackIPV2_t, "minTrackIPV2", "Minimum track IP of second vertex", float) minTrackIPV2;
    PROPERTY(block_dim_filter_t, "block_dim_filter", "block dimensions for filter step", DeviceDimensions)
    block_dim_filter;
  };

  __global__ void filter_two_svs(Parameters);

  struct filter_two_svs_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 30.f};
    // Selection cuts for first vertex
    Property<minMassV1_t> m_minMassV1 {this, 0.f};
    Property<maxMassV1_t> m_maxMassV1 {this, 20000.f};
    Property<minPtV1_t> m_minPtV1 {this, 200.f * Gaudi::Units::MeV};
    // Momenta of SVs from displaced decays won't point back to a PV, so don't
    // make a DIRA cut here by default.
    Property<minCosDiraV1_t> m_minCosDiraV1 {this, 0.0f};
    Property<minEtaV1_t> m_minEtaV1 {this, 2.f};
    Property<maxEtaV1_t> m_maxEtaV1 {this, 5.f};
    Property<minTrackPtV1_t> m_minTrackPtV1 {this, 200.f * Gaudi::Units::MeV};
    Property<minTrackPV1_t> m_minTrackPV1 {this, 1000.f * Gaudi::Units::MeV};
    Property<minTrackIPChi2V1_t> m_minTrackIPChi2V1 {this, 4.f};
    Property<minTrackIPV1_t> m_minTrackIPV1 {this, 0.2f * Gaudi::Units::mm};
    // Selection cuts for second vertex
    Property<minMassV2_t> m_minMassV2 {this, 0.f};
    Property<maxMassV2_t> m_maxMassV2 {this, 20000.f};
    Property<minPtV2_t> m_minPtV2 {this, 200.f * Gaudi::Units::MeV};
    Property<minCosDiraV2_t> m_minCosDiraV2 {this, 0.0f};
    Property<minEtaV2_t> m_minEtaV2 {this, 2.f};
    Property<maxEtaV2_t> m_maxEtaV2 {this, 5.f};
    Property<minTrackPtV2_t> m_minTrackPtV2 {this, 200.f * Gaudi::Units::MeV};
    Property<minTrackPV2_t> m_minTrackPV2 {this, 2000.f * Gaudi::Units::MeV};
    Property<minTrackIPChi2V2_t> m_minTrackIPChi2V2 {this, 4.f};
    Property<minTrackIPV2_t> m_minTrackIPV2 {this, 0.06f * Gaudi::Units::mm};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{128, 1, 1}}};
  };
} // namespace FilterTwoSvs
