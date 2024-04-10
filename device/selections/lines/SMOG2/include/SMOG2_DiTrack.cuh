/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
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

namespace SMOG2_ditrack_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxTrackChi2Ndf_t, "minTrackChi2Ndf", "max track fit Chi2ndf", float) maxTrackChi2Ndf;
    PROPERTY(minTrackP_t, "minTrackP", "minimum final-state particles momentum", float) minTrackP;
    PROPERTY(minTrackPt_t, "minTrackPt", "minimum final-state particles transverse momentum", float) minTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "max SV Chi2", float) maxVertexChi2;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(minZ_t, "minZ", "minimum accepted SV z", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "maximum accepted SV z", float) maxZ;
    PROPERTY(combCharge_t, "combCharge", "Charge of the combination", int) combCharge;
    PROPERTY(m1_t, "m1", "first final-state particle mass", float) m1;
    PROPERTY(m2_t, "m2", "second final-state particle mass", float) m2;
    PROPERTY(minMdipion_t, "minMdipion", "Minimum mass assuming dipion hypothesis in MeV", float) minMdipion;
    PROPERTY(mMother_t, "mMother", "resonance mass", float) mMother;
    PROPERTY(massWindow_t, "massWindow", "maximum mass difference wrt mM", float) massWindow;
    PROPERTY(minTrackIPCHI2_t, "minTrackIPCHI2", "Min IPCHI2 for the final-state parts", float) minTrackIPCHI2;
    PROPERTY(maxTrackIPCHI2_t, "maxTrackIPCHI2", "Max IPCHI2 for the final-state parts", float) maxTrackIPCHI2;
    PROPERTY(minEta_t, "minEta", "minimum pseudoirapidity for composite particle", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "maximum pseudoirapidity for composite particle", float) maxEta;
    PROPERTY(minFDCHI2_t, "minFDCHI2", "Min flight distance CHI2 for the final-state part", float) minFDCHI2;
    PROPERTY(maxFDCHI2_t, "maxFDCHI2", "Max flight distance CHI2 for the final-state part", float) maxFDCHI2;
    PROPERTY(
      minEitherTrackPt_t,
      "minEitherTrackPt",
      "minimum transverse momentum for at least one final-state particle",
      float)
    minEitherTrackPt;
    PROPERTY(maxGhostProb_t, "maxGhostProb", "Maximum ghost probability of the tracks", float) maxGhostProb;

    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(track1pt_t, float) track1pt;
    DEVICE_OUTPUT(track2pt_t, float) track2pt;
    DEVICE_OUTPUT(minipchi2_t, float) minipchi2;
    DEVICE_OUTPUT(ip_t, float) ip;

    DEVICE_OUTPUT(dev_histogram_smogks_mass_t, unsigned) dev_histogram_smogks_mass;
    DEVICE_OUTPUT(dev_histogram_smogks_svz_t, unsigned) dev_histogram_smogks_svz;

    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
  };
  struct SMOG2_ditrack_line_t : public SelectionAlgorithm,
                                Parameters,
                                CompositeParticleLine<SMOG2_ditrack_line_t, Parameters> {
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<sv_masses_t, svz_t, track1pt_t, track2pt_t, minipchi2_t, ip_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<minEta_t> m_minEta {this, 2.0f};
    Property<maxEta_t> m_maxEta {this, 6.0f};
    Property<maxTrackChi2Ndf_t> m_maxTrackChi2Ndf {this, 4.f};
    Property<minTrackP_t> m_minTrackP {this, 3000.f * Gaudi::Units::MeV};
    Property<minTrackPt_t> m_minTrackPt {this, 400.f * Gaudi::Units::MeV};
    Property<minEitherTrackPt_t> m_minEitherTrackPt {this, 800.f * Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 20.f};
    Property<minZ_t> m_minZ {this, -551.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -331.f * Gaudi::Units::mm};
    Property<maxDoca_t> m_maxDoca {this, 0.2f * Gaudi::Units::mm};
    Property<combCharge_t> m_combCharge {this, 0};
    Property<minTrackIPCHI2_t> m_minTrackIPCHI2 {this, 5.f};
    Property<maxTrackIPCHI2_t> m_maxTrackIPCHI2 {this, 999999.f};
    Property<m1_t> m_m1 {this, -1.f * Gaudi::Units::MeV};
    Property<m2_t> m_m2 {this, -1.f * Gaudi::Units::MeV};
    Property<minMdipion_t> m_minMdipion {this, -1.f * Gaudi::Units::MeV};
    Property<mMother_t> m_mMother {this, -1.f * Gaudi::Units::MeV};
    Property<massWindow_t> m_massWindow {this, -1.f * Gaudi::Units::MeV};
    Property<enable_tupling_t> m_enable_tupling {this, false};
    Property<minFDCHI2_t> m_minFDCHI2 {this, -10.f};
    Property<maxFDCHI2_t> m_maxFDCHI2 {this, 999999.f};
    Property<maxGhostProb_t> m_maxGhostProb {this, 0.5};
  };
} // namespace SMOG2_ditrack_line
