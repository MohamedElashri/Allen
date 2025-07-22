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
    DEVICE_OUTPUT(dev_combo_offsets_t, unsigned) dev_combo_offsets;
    HOST_OUTPUT(host_number_of_combos_t, unsigned) host_number_of_combos;
    DEVICE_OUTPUT(dev_child1_idx_t, unsigned) dev_child1_idx;
    DEVICE_OUTPUT(dev_child2_idx_t, unsigned) dev_child2_idx;
  };

  __global__ void filter_svs(
    Parameters,
    const float maxVertexChi2,
    const float minTrackP,
    const float minChildEta,
    const float maxChildEta,
    const float minCosDira,
    const float minTrackPt,
    const float minComboPt,
    const float minTrackIPChi2,
    const float minTrackPtLowIP,
    const float minTrackLowIP,
    const float minComboPtHighIP,
    const float minTrackHighIP);

  struct filter_svs_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 30.f, "Max child vertex chi2"};
    Allen::Property<float> m_minComboPt {this, "minComboPt", 500.f * Allen::Units::MeV, "Minimum combo pT"};
    Allen::Property<float> m_minComboPtHighIP {this,
                                               "minComboPtHighIP",
                                               200.f * Allen::Units::MeV,
                                               "Minimum combo pT high IP"};
    // Momenta of SVs from displaced decays won't point back to a PV, so don't
    // make a DIRA cut here by default.
    Allen::Property<float> m_minCosDira {this, "minChildCosDira", 0.0f, "Minimum child DIRA"};
    Allen::Property<float> m_minChildEta {this, "minChildEta", 2.f, "Minimum child eta"};
    Allen::Property<float> m_maxChildEta {this, "maxChildEta", 5.f, "Maximum child eta"};
    Allen::Property<float> m_minTrackPt {this, "minTrackPt", 200.f * Allen::Units::MeV, "Minimum track pT"};
    Allen::Property<float> m_minTrackPtLowIP {this,
                                              "minTrackPtLowIP",
                                              500.f * Allen::Units::MeV,
                                              "Minimum track pT Low IP"};
    Allen::Property<float> m_minTrackP {this, "minTrackP", 1000.f * Allen::Units::MeV, "Minimum track p"};
    Allen::Property<float> m_minTrackIPChi2 {this, "minTrackIPChi2", 4.f, "Minimum track IP chi2"};
    Allen::Property<float> m_minTrackHighIP {this, "minTrackHighIP", 0.2f * Allen::Units::mm, "Minimum track high IP"};
    Allen::Property<float> m_minTrackLowIP {this, "minTrackLowIP", 0.06f * Allen::Units::mm, "Minimum track low IP"};
    Allen::Property<dim3> m_block_dim_filter {this,
                                              "block_dim_filter",
                                              {128, 1, 1},
                                              "block dimensions for filter step"};
  };
} // namespace FilterSvs
