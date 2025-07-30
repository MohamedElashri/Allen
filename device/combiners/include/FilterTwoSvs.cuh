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
  };

  __global__ void filter_two_svs(
    Parameters,
    const float maxVertexChi2,
    const float minMassV1,
    const float maxMassV1,
    const float minTrackPV1,
    const float minEtaV1,
    const float maxEtaV1,
    const float minCosDiraV1,
    const float minTrackPtV1,
    const float minPtV1,
    const float minTrackIPChi2V1,
    const float minTrackIPV1,
    const float minMassV2,
    const float maxMassV2,
    const float minTrackPV2,
    const float minEtaV2,
    const float maxEtaV2,
    const float minCosDiraV2,
    const float minTrackPtV2,
    const float minPtV2,
    const float minTrackIPChi2V2,
    const float minTrackIPV2);

  struct filter_two_svs_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 30.f, "Max child vertex chi2"};
    // Selection cuts for first vertex
    Allen::Property<float> m_minMassV1 {this, "minMassV1", 0.f, "Minimum mass of first vertex"};
    Allen::Property<float> m_maxMassV1 {this, "maxMassV1", 20000.f, "Maximum mass of first vertex"};
    Allen::Property<float> m_minPtV1 {this, "minPtV1", 200.f * Allen::Units::MeV, "Minimum pT of first vertex"};
    // Momenta of SVs from displaced decays won't point back to a PV, so don't
    // make a DIRA cut here by default.
    Allen::Property<float> m_minCosDiraV1 {this, "minCosDiraV1", 0.0f, "Minimum DIRA of first vertex"};
    Allen::Property<float> m_minEtaV1 {this, "minEtaV1", 2.f, "Minimum eta of first vertex"};
    Allen::Property<float> m_maxEtaV1 {this, "maxEtaV1", 5.f, "Maximum eta of first vertex"};
    Allen::Property<float> m_minTrackPtV1 {this,
                                           "minTrackPtV1",
                                           200.f * Allen::Units::MeV,
                                           "Minimum track pT of first vertex"};
    Allen::Property<float> m_minTrackPV1 {this,
                                          "minTrackPV1",
                                          1000.f * Allen::Units::MeV,
                                          "Minimum track p of first vertex"};
    Allen::Property<float> m_minTrackIPChi2V1 {this, "minTrackIPChi2V1", 4.f, "Minimum track IP chi2 of first vertex"};
    Allen::Property<float> m_minTrackIPV1 {this,
                                           "minTrackIPV1",
                                           0.2f * Allen::Units::mm,
                                           "Minimum track IP of first vertex"};
    // Selection cuts for second vertex
    Allen::Property<float> m_minMassV2 {this, "minMassV2", 0.f, "Minimum mass of second vertex"};
    Allen::Property<float> m_maxMassV2 {this, "maxMassV2", 20000.f, "Maximum mass of second vertex"};
    Allen::Property<float> m_minPtV2 {this, "minPtV2", 200.f * Allen::Units::MeV, "Minimum pT of second vertex"};
    Allen::Property<float> m_minCosDiraV2 {this, "minCosDiraV2", 0.0f, "Minimum DIRA of second vertex"};
    Allen::Property<float> m_minEtaV2 {this, "minEtaV2", 2.f, "Minimum eta of second vertex"};
    Allen::Property<float> m_maxEtaV2 {this, "maxEtaV2", 5.f, "Maximum eta of second vertex"};
    Allen::Property<float> m_minTrackPtV2 {this,
                                           "minTrackPtV2",
                                           200.f * Allen::Units::MeV,
                                           "Minimum track pT of second vertex"};
    Allen::Property<float> m_minTrackPV2 {this,
                                          "minTrackPV2",
                                          2000.f * Allen::Units::MeV,
                                          "Minimum track p of second vertex"};
    Allen::Property<float> m_minTrackIPChi2V2 {this, "minTrackIPChi2V2", 4.f, "Minimum track IP chi2 of second vertex"};
    Allen::Property<float> m_minTrackIPV2 {this,
                                           "minTrackIPV2",
                                           0.06f * Allen::Units::mm,
                                           "Minimum track IP of second vertex"};
    Allen::Property<dim3> m_block_dim_filter {this,
                                              "block_dim_filter",
                                              {128, 1, 1},
                                              "block dimensions for filter step"};
  };
} // namespace FilterTwoSvs
