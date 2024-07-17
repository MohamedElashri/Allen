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
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);

    PROPERTY(JpsiMinPt_t, "JpsiMinPt", "JpsiMinPt description", float) JpsiMinPt;
    PROPERTY(JpsiMaxVChi2_t, "JpsiMaxVChi2", "JpsiMaxVChi2 description", float) JpsiMaxVChi2;
    PROPERTY(JpsiMinMass_t, "JpsiMinMass", "JpsiMinMass description", float) JpsiMinMass;
    PROPERTY(JpsiMaxMass_t, "JpsiMaxMass", "JpsiMaxMass description", float) JpsiMaxMass;
    PROPERTY(JpsiMinZ_t, "JpsiMinZ", "minimum vertex z dimuon coordinate", float) JpsiMinZ;
    PROPERTY(JpsiMaxDoca_t, "JpsiMaxDoca", "JpsiMaxDoca description", float) JpsiMaxDoca;
    PROPERTY(JpsiMinCosDira_t, "JpsiMinCosDira", "JpsiMinCosDira description", float) JpsiMinCosDira;
    PROPERTY(JpsiMinFDChi2_t, "JpsiMinFDChi2", "JpsiMinFDChi2 description", float) JpsiMinFDChi2;

    PROPERTY(mutagMinP_t, "mutagMinP", "mutagMinP description", float) mutagMinP;
    PROPERTY(mutagMinPt_t, "mutagMinPt", "mutagMinPt description", float) mutagMinPt;
    PROPERTY(mutagMinIPChi2_t, "mutagMinIPChi2", "mutagMinIPChi2 description", float) mutagMinIPChi2;
    PROPERTY(muprobeMinIPChi2_t, "muprobeMinIPChi2", "muprobeMinIPChi2 description", float) muprobeMinIPChi2;
    PROPERTY(muprobeMinP_t, "muprobeMinP", "muprobeMinP description", float) muprobeMinP;

    PROPERTY(posTag_t, "posTag", "Tags positive charged tracks with isMuon", bool) posTag;
    // tupling
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

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
    // monitoring
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct det_jpsitomumu_tap_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     CompositeParticleLine<det_jpsitomumu_tap_line_t, Parameters> {
    struct DeviceAccumulators {
      Allen::Monitoring::Histogram<>::DeviceType histogram_det_jpsitomumu_tap_mass;
      DeviceAccumulators(const det_jpsitomumu_tap_line_t& algo, const Allen::Context& ctx) :
        histogram_det_jpsitomumu_tap_mass(algo.m_histogram_det_jpsitomumu_tap_mass.data(ctx))
      {}
    };

    __device__ static bool
    select(const Parameters&, const DeviceAccumulators&, std::tuple<const Allen::Views::Physics::CompositeParticle>);
    // monitoring
    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);
    __device__ static void fill_tuples(
      const Parameters& parameters,
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
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};

    Property<JpsiMinPt_t> m_JpsiMinPt {this, 1000.f * Gaudi::Units::MeV};
    Property<JpsiMaxVChi2_t> m_JpsiMaxVChi2 {this, 15.f};
    Property<JpsiMinMass_t> m_JpsiMinMass {this, 2950.f * Gaudi::Units::MeV};
    Property<JpsiMaxMass_t> m_JpsiMaxMass {this, 3250.f * Gaudi::Units::MeV};
    Property<JpsiMinZ_t> m_JpsiMinZ {this, -341.f * Gaudi::Units::mm};
    Property<JpsiMaxDoca_t> m_JpsiMaxDoca {this, 1.f * Gaudi::Units::mm};
    Property<JpsiMinCosDira_t> m_JpsiMinCosDira {this, 0.99f};
    Property<JpsiMinFDChi2_t> m_JpsiMinFDChi2 {this, 50.f};

    Property<mutagMinP_t> m_mutagMinP {this, 3000.f * Gaudi::Units::MeV};
    Property<mutagMinPt_t> m_mutagMinPt {this, 1200.f * Gaudi::Units::MeV};
    Property<mutagMinIPChi2_t> m_mutagMinIPChi2 {this, 9.f};
    Property<muprobeMinIPChi2_t> m_muprobeMinIPChi2 {this, 9.f};
    Property<muprobeMinP_t> m_muprobeMinP {this, 3000.f * Gaudi::Units::MeV};

    Property<posTag_t> m_posTag {this, true};

    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

    Allen::Monitoring::Histogram<> m_histogram_det_jpsitomumu_tap_mass {this,
                                                                        "histogram_det_jpsitomumu_tap_mass",
                                                                        "m(jpsi)",
                                                                        {60u, 2950.f, 3250.f}};
  };
} // namespace det_jpsitomumu_tap_line
