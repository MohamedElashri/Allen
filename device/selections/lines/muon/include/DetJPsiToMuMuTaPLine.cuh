/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"

#include "AllenMonitoring.h"

namespace det_jpsitomumu_tap_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // tupling
    DEVICE_OUTPUT(decision_t, bool) decision;
    DEVICE_OUTPUT(jpsi_mass_t, float) jpsi_mass;
    DEVICE_OUTPUT(jpsi_dira_t, float) jpsi_dira;
    DEVICE_OUTPUT(jpsi_doca_t, float) jpsi_doca;
    DEVICE_OUTPUT(jpsi_vchi2_t, float) jpsi_vchi2;
    DEVICE_OUTPUT(jpsi_minipchi2_t, float) jpsi_minipchi2;
    DEVICE_OUTPUT(jpsi_eta_t, float) jpsi_eta;
    DEVICE_OUTPUT(jpsi_vz_t, float) jpsi_vz;
    DEVICE_OUTPUT(jpsi_minpt_t, float) jpsi_minpt;
    DEVICE_OUTPUT(jpsi_vdz_t, float) jpsi_vdz;
    DEVICE_OUTPUT(jpsi_fd_t, float) jpsi_fd;
    DEVICE_OUTPUT(jpsi_p_t, float) jpsi_p;
    DEVICE_OUTPUT(jpsi_pz_t, float) jpsi_pz;
    DEVICE_OUTPUT(jpsi_pt_t, float) jpsi_pt;
    DEVICE_OUTPUT(jpsi_fdchi2_t, float) jpsi_fdchi2;

    DEVICE_OUTPUT(mutag_charge_t, int) mutag_charge;
    DEVICE_OUTPUT(muprobe_charge_t, int) muprobe_charge;
    DEVICE_OUTPUT(mutag_p_t, float) mutag_p;
    DEVICE_OUTPUT(muprobe_p_t, float) muprobe_p;
    DEVICE_OUTPUT(mutag_ipchi2_t, float) mutag_ipchi2;
    DEVICE_OUTPUT(muprobe_ipchi2_t, float) muprobe_ipchi2;
    DEVICE_OUTPUT(mutag_ismuon_t, int) mutag_ismuon;
    DEVICE_OUTPUT(muprobe_ismuon_t, int) muprobe_ismuon;
    DEVICE_OUTPUT(mutag_pt_t, float) mutag_pt;
    DEVICE_OUTPUT(muprobe_pt_t, float) muprobe_pt;
    DEVICE_OUTPUT(mutag_px_t, float) mutag_px;
    DEVICE_OUTPUT(muprobe_px_t, float) muprobe_px;
    DEVICE_OUTPUT(mutag_py_t, float) mutag_py;
    DEVICE_OUTPUT(muprobe_py_t, float) muprobe_py;
    DEVICE_OUTPUT(mutag_pz_t, float) mutag_pz;
    DEVICE_OUTPUT(muprobe_pz_t, float) muprobe_pz;
    DEVICE_OUTPUT(mutag_chi2ndof_t, float) mutag_chi2ndof;
    DEVICE_OUTPUT(muprobe_chi2ndof_t, float) muprobe_chi2ndof;
    DEVICE_OUTPUT(mutag_eta_t, float) mutag_eta;
    DEVICE_OUTPUT(muprobe_eta_t, float) muprobe_eta;
  };

  struct det_jpsitomumu_tap_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     CompositeParticleLine<det_jpsitomumu_tap_line_t, Parameters> {
    struct DeviceProperties {
      float JpsiMinPt;
      float JpsiMaxVChi2;
      float JpsiMinMass;
      float JpsiMaxMass;
      float JpsiMinZ;
      float JpsiMaxDoca;
      float JpsiMinCosDira;
      float JpsiMinFDChi2;
      float mutagMinP;
      float mutagMinPt;
      float mutagMinIPChi2;
      float muprobeMinIPChi2;
      float muprobeMinP;
      bool posTag;
      Allen::Monitoring::Histogram<>::DeviceType histogram_det_jpsitomumu_tap_mass;
      DeviceProperties(const det_jpsitomumu_tap_line_t& algo, const Allen::Context& ctx) :
        JpsiMinPt(algo.m_JpsiMinPt), JpsiMaxVChi2(algo.m_JpsiMaxVChi2), JpsiMinMass(algo.m_JpsiMinMass),
        JpsiMaxMass(algo.m_JpsiMaxMass), JpsiMinZ(algo.m_JpsiMinZ), JpsiMaxDoca(algo.m_JpsiMaxDoca),
        JpsiMinCosDira(algo.m_JpsiMinCosDira), JpsiMinFDChi2(algo.m_JpsiMinFDChi2), mutagMinP(algo.m_mutagMinP),
        mutagMinPt(algo.m_mutagMinPt), mutagMinIPChi2(algo.m_mutagMinIPChi2), muprobeMinIPChi2(algo.m_muprobeMinIPChi2),
        muprobeMinP(algo.m_muprobeMinP), posTag(algo.m_posTag),
        histogram_det_jpsitomumu_tap_mass(algo.m_histogram_det_jpsitomumu_tap_mass.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceProperties&, std::tuple<const Allen::Views::Physics::CompositeParticle>);
    // monitoring
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);
    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<
      decision_t,
      jpsi_mass_t,
      jpsi_dira_t,
      jpsi_doca_t,
      jpsi_vchi2_t,
      jpsi_minipchi2_t,
      jpsi_eta_t,
      jpsi_vz_t,
      jpsi_minpt_t,
      jpsi_vdz_t,
      jpsi_fd_t,
      jpsi_p_t,
      jpsi_pz_t,
      jpsi_pt_t,
      jpsi_fdchi2_t,
      mutag_charge_t,
      muprobe_charge_t,
      mutag_p_t,
      muprobe_p_t,
      mutag_ipchi2_t,
      muprobe_ipchi2_t,
      mutag_ismuon_t,
      muprobe_ismuon_t,
      mutag_pt_t,
      muprobe_pt_t,
      mutag_px_t,
      muprobe_px_t,
      mutag_py_t,
      muprobe_py_t,
      mutag_pz_t,
      muprobe_pz_t,
      mutag_chi2ndof_t,
      muprobe_chi2ndof_t,
      mutag_eta_t,
      muprobe_eta_t>;

  private:
    Allen::Property<float> m_JpsiMinPt {this, "JpsiMinPt", 1000.f * Allen::Units::MeV, "JpsiMinPt description"};
    Allen::Property<float> m_JpsiMaxVChi2 {this, "JpsiMaxVChi2", 15.f, "JpsiMaxVChi2 description"};
    Allen::Property<float> m_JpsiMinMass {this, "JpsiMinMass", 2950.f * Allen::Units::MeV, "JpsiMinMass description"};
    Allen::Property<float> m_JpsiMaxMass {this, "JpsiMaxMass", 3250.f * Allen::Units::MeV, "JpsiMaxMass description"};
    Allen::Property<float> m_JpsiMinZ {this,
                                       "JpsiMinZ",
                                       -330.f * Allen::Units::mm,
                                       "minimum vertex z dimuon coordinate"};
    Allen::Property<float> m_JpsiMaxDoca {this, "JpsiMaxDoca", 1.f * Allen::Units::mm, "JpsiMaxDoca description"};
    Allen::Property<float> m_JpsiMinCosDira {this, "JpsiMinCosDira", 0.99f, "JpsiMinCosDira description"};
    Allen::Property<float> m_JpsiMinFDChi2 {this, "JpsiMinFDChi2", 50.f, "JpsiMinFDChi2 description"};
    Allen::Property<float> m_mutagMinP {this, "mutagMinP", 3000.f * Allen::Units::MeV, "mutagMinP description"};
    Allen::Property<float> m_mutagMinPt {this, "mutagMinPt", 1200.f * Allen::Units::MeV, "mutagMinPt description"};
    Allen::Property<float> m_mutagMinIPChi2 {this, "mutagMinIPChi2", 9.f, "mutagMinIPChi2 description"};
    Allen::Property<float> m_muprobeMinIPChi2 {this, "muprobeMinIPChi2", 9.f, "muprobeMinIPChi2 description"};
    Allen::Property<float> m_muprobeMinP {this, "muprobeMinP", 3000.f * Allen::Units::MeV, "muprobeMinP description"};
    Allen::Property<bool> m_posTag {this, "posTag", true, "Tags positive charged tracks with isMuon"};

    Allen::Monitoring::Histogram<> m_histogram_det_jpsitomumu_tap_mass {this,
                                                                        "histogram_det_jpsitomumu_tap_mass",
                                                                        "m(jpsi)",
                                                                        {60u, 2950.f, 3250.f}};
  };
} // namespace det_jpsitomumu_tap_line
