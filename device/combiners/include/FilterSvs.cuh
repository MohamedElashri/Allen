/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "VertexDefinitions.cuh"

#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace FilterSvs {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_INPUT(host_max_combos_t, unsigned) host_max_combos;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_secondary_vertices_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_secondary_vertices;
    DEVICE_INPUT(dev_max_combo_offsets_t, unsigned) dev_max_combo_offsets;
    DEVICE_OUTPUT(dev_sv_filter_decision_t, bool) dev_sv_filter_decision;
    DEVICE_OUTPUT(dev_combo_number_t, unsigned) dev_combo_number;
    DEVICE_OUTPUT(dev_child1_idx_t, unsigned) dev_child1_idx;
    DEVICE_OUTPUT(dev_child2_idx_t, unsigned) dev_child2_idx;

    // Set all properties to filter svs
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Max child vertex chi2", float) maxVertexChi2;
    PROPERTY(minComboPt_t, "minComboPt", "Minimum combo pT", float) minComboPt;
    PROPERTY(minCosDira_t, "minChildCosDira", "Minimum child DIRA", float) minCosDira;
    PROPERTY(minChildEta_t, "minChildEta", "Minimum child eta", float) minChildEta;
    PROPERTY(maxChildEta_t, "maxChildEta", "Maximum child eta", float) maxChildEta;
    PROPERTY(minTrackPt_t, "minTrackPt", "Minimum track pT", float) minTrackPt;
    PROPERTY(minTrackP_t, "minTrackP", "Minimum track p", float) minTrackP;
    PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "Minimum track IP chi2", float) minTrackIPChi2;
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
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 30.f};
    Property<minComboPt_t> m_minComboPt {this, 500.f / Gaudi::Units::MeV};
    // Momenta of SVs from displaced decays won't point back to a PV, so don't
    // make a DIRA cut here by default.
    Property<minCosDira_t> m_minCosDira {this, 0.0f};
    Property<minChildEta_t> m_minChildEta {this, 2.f};
    Property<maxChildEta_t> m_maxChildEta {this, 5.f};
    Property<minTrackPt_t> m_minTrackPt {this, 300.f / Gaudi::Units::MeV};
    Property<minTrackP_t> m_minTrackP {this, 1000.f / Gaudi::Units::MeV};
    Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 4.f};
    Property<block_dim_filter_t> m_block_dim_filter {this, {{128, 1, 1}}};
  };
} // namespace FilterSvs
