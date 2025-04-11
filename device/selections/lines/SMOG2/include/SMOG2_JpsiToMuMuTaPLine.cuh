/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "AllenMonitoring.h"

namespace SMOG2jpsitomumu_tap_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    DEVICE_INPUT(dev_muonidnn_t, float) dev_muonidnn;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;

    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(pvz_t, float) pvz;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(maxchi2corr_t, float) maxchi2corr;
    DEVICE_OUTPUT(min_muon_nn_t, float) min_muon_nn;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
  };

  struct SMOG2jpsitomumu_tap_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CompositeParticleLine<SMOG2jpsitomumu_tap_line_t, Parameters> {
    struct DeviceProperties {
      float JpsiMinMass;
      float JpsiMaxMass;
      float JpsiMinZ;
      float JpsiMaxZ;
      float mutagMinP;
      float mutagMinPt;
      float mutagMaxChi2Corr;
      float muprobeMinP;
      float muprobeMinPt;
      float JpsiMinPt;
      float JpsiMaxVChi2;
      float JpsiMaxDoca;
      bool posTag;
      float maxTrackChi2Ndf;
      float minMuonNN;
      bool useNN;

      Allen::Monitoring::Histogram<>::DeviceType histogram_SMOG2jpsitomumu_tap_mass;

      DeviceProperties(const SMOG2jpsitomumu_tap_line_t& algo, const Allen::Context& ctx) :
        JpsiMinMass(algo.m_JpsiMinMass), JpsiMaxMass(algo.m_JpsiMaxMass), JpsiMinZ(algo.m_JpsiMinZ),
        JpsiMaxZ(algo.m_JpsiMaxZ), mutagMinP(algo.m_mutagMinP), mutagMinPt(algo.m_mutagMinPt),
        mutagMaxChi2Corr(algo.m_mutagMaxChi2Corr), muprobeMinP(algo.m_muprobeMinP), muprobeMinPt(algo.m_muprobeMinPt),
        JpsiMinPt(algo.m_JpsiMinPt), JpsiMaxVChi2(algo.m_JpsiMaxVChi2), JpsiMaxDoca(algo.m_JpsiMaxDoca),
        posTag(algo.m_posTag), maxTrackChi2Ndf(algo.m_maxTrackChi2Ndf), minMuonNN(algo.m_minMuonNN),
        useNN(algo.m_useNN), histogram_SMOG2jpsitomumu_tap_mass(algo.m_histogram_SMOG2jpsitomumu_tap_mass.data(ctx))
      {}
    };

    __device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> static get_input(
      const Parameters& parameters,
      const unsigned event_number,
      const unsigned i);

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    // monitoring
    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      const DeviceProperties& properties,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<mass_t, svz_t, pvz_t, pt_t, maxchi2corr_t, min_muon_nn_t>;

  private:
    Allen::Property<float> m_JpsiMinMass {this,
                                          "JpsiMinMass",
                                          2850.f * Gaudi::Units::MeV,
                                          "Min invariant mass for JPsi candidate"};
    Allen::Property<float> m_JpsiMaxMass {this,
                                          "JpsiMaxMass",
                                          3350.f * Gaudi::Units::MeV,
                                          "Min invariant mass for JPsi candidate"};
    Allen::Property<float> m_JpsiMinZ {this,
                                       "JpsiMinZ",
                                       -551.f * Gaudi::Units::mm,
                                       "minimum vertex z dimuon coordinate"};
    Allen::Property<float> m_JpsiMaxZ {this,
                                       "JpsiMaxZ",
                                       -331.f * Gaudi::Units::mm,
                                       "maximum vertex z dimuon coordinate"};
    Allen::Property<float> m_mutagMinP {this, "mutagMinP", 3000.f * Gaudi::Units::MeV, "Min momentum for tag muon"};
    Allen::Property<float> m_mutagMinPt {this, "mutagMinPt", 600.f * Gaudi::Units::MeV, "Min Pt for tag muon"};
    Allen::Property<float> m_mutagMaxChi2Corr {this, "mutagMaxChi2Corr", 1.8, "maximum muon tag correlated chi2"};
    Allen::Property<float> m_muprobeMinP {this,
                                          "muprobeMinP",
                                          3000.f * Gaudi::Units::MeV,
                                          "Min momentum for probe muon"};
    Allen::Property<float> m_muprobeMinPt {this, "muprobeMinPt", 150.f * Gaudi::Units::MeV, "Min Pt for probe muon"};
    Allen::Property<float> m_JpsiMinPt {this, "JpsiMinPt", 0.f * Gaudi::Units::MeV, "Min Pt for the Jpsi candidate"};
    Allen::Property<bool> m_posTag {this, "posTag", true, "Tags positive charged tracks with isMuon"};
    Allen::Property<float> m_JpsiMaxVChi2 {this, "JpsiMaxVChi2", 16.f, "Max chi2 for the J/psi candidate vertex"};
    Allen::Property<float> m_JpsiMaxDoca {this,
                                          "JpsiMaxDoca",
                                          0.5f * Gaudi::Units::mm,
                                          "Max DOCA for the J/psi candidate combination"};
    Allen::Property<float> m_maxTrackChi2Ndf {this, "maxTrackChi2Ndf", 5.f, "max track fit Chi2ndf"};
    Allen::Property<float> m_minMuonNN {this, "minMuonNN", 0.1, "min NN evaluation"};
    Allen::Property<float> m_useNN {this, "useNN", true, "useNN"};

    Allen::Monitoring::Histogram<> m_histogram_SMOG2jpsitomumu_tap_mass {this,
                                                                         "histogram_SMOG2jpsitomumu_tap_mass",
                                                                         "m(jpsi)",
                                                                         {60u, 2950.f, 3250.f}};
  };
} // namespace SMOG2jpsitomumu_tap_line
