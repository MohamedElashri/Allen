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
#include "AllenMonitoring.h"

namespace SMOG2_ditrack_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(sv_masses_m12_t, float) sv_masses_m12;
    DEVICE_OUTPUT(sv_masses_m21_t, float) sv_masses_m21;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(track1pt_t, float) track1pt;
    DEVICE_OUTPUT(track2pt_t, float) track2pt;
    DEVICE_OUTPUT(minipchi2_t, float) minipchi2;
    DEVICE_OUTPUT(ip_t, float) ip;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(pvz_t, float) pvz;
  };
  struct SMOG2_ditrack_line_t : public SelectionAlgorithm,
                                Parameters,
                                CompositeParticleLine<SMOG2_ditrack_line_t, Parameters> {

    struct DeviceProperties {
      float minEta;
      float maxEta;
      float maxTrackChi2Ndf;
      float minTrackP;
      float minTrackPt;
      float minEitherTrackPt;
      float maxVertexChi2;
      float minZ;
      float maxZ;
      float maxDoca;
      int combCharge;
      float minTrackIPCHI2;
      float maxTrackIPCHI2;
      float m1;
      float m2;
      float minMdipion;
      float mMother;
      float massWindow;
      float minFDCHI2;
      float maxFDCHI2;
      float maxGhostProb;

      Allen::Monitoring::Histogram<>::DeviceType histogram_smogditrack_mass;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogditrack_pt;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogditrack_pvz;
      Allen::Monitoring::Histogram<>::DeviceType histogram_smogditrack_svz;

      DeviceProperties(const SMOG2_ditrack_line_t& algo, const Allen::Context& ctx) :
        minEta(algo.m_minEta), maxEta(algo.m_maxEta), maxTrackChi2Ndf(algo.m_maxTrackChi2Ndf),
        minTrackP(algo.m_minTrackP), minTrackPt(algo.m_minTrackPt), minEitherTrackPt(algo.m_minEitherTrackPt),
        maxVertexChi2(algo.m_maxVertexChi2), minZ(algo.m_minZ), maxZ(algo.m_maxZ), maxDoca(algo.m_maxDoca),
        combCharge(algo.m_combCharge), minTrackIPCHI2(algo.m_minTrackIPCHI2), maxTrackIPCHI2(algo.m_maxTrackIPCHI2),
        m1(algo.m_m1), m2(algo.m_m2), minMdipion(algo.m_minMdipion), mMother(algo.m_mMother),
        massWindow(algo.m_massWindow), minFDCHI2(algo.m_minFDCHI2), maxFDCHI2(algo.m_maxFDCHI2),
        maxGhostProb(algo.m_maxGhostProb), histogram_smogditrack_mass(algo.m_histogram_smogditrack_mass.data(ctx)),
        histogram_smogditrack_pt(algo.m_histogram_smogditrack_pt.data(ctx)),
        histogram_smogditrack_pvz(algo.m_histogram_smogditrack_pvz.data(ctx)),
        histogram_smogditrack_svz(algo.m_histogram_smogditrack_svz.data(ctx))
      {}
    };

    using monitoring_types =
      std::tuple<sv_masses_m12_t, sv_masses_m21_t, svz_t, track1pt_t, track2pt_t, minipchi2_t, ip_t, pvz_t, pt_t>;

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    void init();

  private:
    Allen::Property<float> m_minEta {this, "minEta", 2.0f, "minimum pseudoirapidity for composite particle"};
    Allen::Property<float> m_maxEta {this, "maxEta", 6.0f, "maximum pseudoirapidity for composite particle"};
    Allen::Property<float> m_maxTrackChi2Ndf {this, "maxTrackChi2Ndf", 4.f, "max track fit Chi2ndf"};
    Allen::Property<float> m_minTrackP {this,
                                        "minTrackP",
                                        3000.f * Gaudi::Units::MeV,
                                        "minimum final-state particles momentum"};
    Allen::Property<float> m_minTrackPt {this,
                                         "minTrackPt",
                                         400.f * Gaudi::Units::MeV,
                                         "minimum final-state particles transverse momentum"};
    Allen::Property<float> m_minEitherTrackPt {this,
                                               "minEitherTrackPt",
                                               800.f * Gaudi::Units::MeV,
                                               "minimum transverse momentum for at least one final-state particle"};
    Allen::Property<float> m_maxVertexChi2 {this, "maxVertexChi2", 20.f, "max SV Chi2"};
    Allen::Property<float> m_minZ {this, "minZ", -537.5f * Gaudi::Units::mm, "minimum accepted SV z"};
    Allen::Property<float> m_maxZ {this, "maxZ", -337.5f * Gaudi::Units::mm, "maximum accepted SV z"};
    Allen::Property<float> m_maxDoca {this, "maxDoca", 0.2f * Gaudi::Units::mm, "max distance of closest approach"};
    Allen::Property<int> m_combCharge {this, "combCharge", 0, "Charge of the combination"};
    Allen::Property<float> m_minTrackIPCHI2 {this, "minTrackIPCHI2", 5.f, "Min IPCHI2 for the final-state parts"};
    Allen::Property<float> m_maxTrackIPCHI2 {this, "maxTrackIPCHI2", 999999.f, "Max IPCHI2 for the final-state parts"};
    Allen::Property<float> m_m1 {this, "m1", -1.f * Gaudi::Units::MeV, "first final-state particle mass"};
    Allen::Property<float> m_m2 {this, "m2", -1.f * Gaudi::Units::MeV, "second final-state particle mass"};
    Allen::Property<float> m_minMdipion {this,
                                         "minMdipion",
                                         -1.f * Gaudi::Units::MeV,
                                         "Minimum mass assuming dipion hypothesis in MeV"};
    Allen::Property<float> m_mMother {this, "mMother", -1.f * Gaudi::Units::MeV, "resonance mass"};
    Allen::Property<float> m_massWindow {this,
                                         "massWindow",
                                         -1.f * Gaudi::Units::MeV,
                                         "maximum mass difference wrt mM"};
    Allen::Property<float> m_minFDCHI2 {this, "minFDCHI2", -10.f, "Min flight distance CHI2 for the final-state part"};
    Allen::Property<float> m_maxFDCHI2 {this,
                                        "maxFDCHI2",
                                        999999.f,
                                        "Max flight distance CHI2 for the final-state part"};
    Allen::Property<float> m_maxGhostProb {this, "maxGhostProb", 0.5, "Maximum ghost probability of the tracks"};

    Allen::Monitoring::Histogram<> m_histogram_smogditrack_mass {this,
                                                                 "SMOG2_ditrack_mass",
                                                                 "mass [MeV]",
                                                                 {100u, 2700.f, 4000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogditrack_pt {this,
                                                               "SMOG2_ditrack_pt",
                                                               "pT [MeV]",
                                                               {100u, 100.f, 8000.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogditrack_svz {this,
                                                                "smogditrack_svz",
                                                                "SV_z [mm]",
                                                                {100u, -550.f, -300.f}};
    Allen::Monitoring::Histogram<> m_histogram_smogditrack_pvz {this,
                                                                "smogditrack_Pvz",
                                                                "PV_z [mm]",
                                                                {100u, -550.f, -300.f}};
  };
} // namespace SMOG2_ditrack_line
