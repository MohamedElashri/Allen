/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"

namespace di_muon_mass_alignment_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minHighMassTrackPt_t, "minHighMassTrackPt", "minHighMassTrackPt description", float) minHighMassTrackPt;
    PROPERTY(minHighMassTrackP_t, "minHighMassTrackP", "minHighMassTrackP description", float) minHighMassTrackP;
    PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float) minComboPt;
    PROPERTY(minMass_t, "minMass", "minMass description", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "maxMass description", float) maxMass;
    PROPERTY(maxDoca_t, "maxDoca", "maxDoca description", float) maxDoca;
    PROPERTY(minEta_t, "minEta", "minEta description", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "maxEta description", float) maxEta;
    PROPERTY(minDira_t, "minDira", "minimum value of cos(theta_dira)", float) minDira;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(minIP_t, "minIP", "minIP description", float) minIP;
    PROPERTY(minFdChi2_t, "minFdChi2", "minFdChi2 description", float) minFdChi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
    PROPERTY(maxChi2Muon_t, "maxChi2Muon", "max Chi2Muon evaluation", float) maxChi2Muon;
    PROPERTY(DiMuonCharge_t, "DiMuonCharge", "Charge of the dimuon combination", int) DiMuonCharge;
  };

  struct di_muon_mass_alignment_line_t : public SelectionAlgorithm,
                                         Parameters,
                                         CompositeParticleLine<di_muon_mass_alignment_line_t, Parameters> {
    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const float> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);

    __device__ static bool select(
      const Parameters&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const float>);

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minHighMassTrackPt_t> m_minHighMassTrackPt {this, 500.f / Gaudi::Units::MeV};
    Property<minHighMassTrackP_t> m_minHighMassTrackP {this, 6000.f / Gaudi::Units::MeV};
    Property<minMass_t> m_minMass {this, 2996.f / Gaudi::Units::MeV};
    Property<maxMass_t> m_maxMass {this, 3196.f / Gaudi::Units::MeV};
    Property<maxDoca_t> m_maxDoca {this, 0.2f};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 10.0f};
    Property<minIP_t> m_minIP {this, 0.07f * Gaudi::Units::mm};
    Property<minFdChi2_t> m_minFdChi2 {this, 3.f};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<minEta_t> m_minEta {this, 2.0f};
    Property<maxEta_t> m_maxEta {this, 5.0f};
    Property<minDira_t> m_minDira {this, 0.9995f};
    Property<minComboPt_t> m_minComboPt {this, 2000.0f * Gaudi::Units::MeV};
    Property<maxChi2Muon_t> m_maxChi2Muon {this, 1.8};
    Property<DiMuonCharge_t> m_dimuon_charge {this, 0};
  };
} // namespace di_muon_mass_alignment_line
