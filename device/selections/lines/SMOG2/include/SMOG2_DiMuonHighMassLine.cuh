/*****************************************************************************\
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace SMOG2_dimuon_highmass_line {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;

    DEVICE_OUTPUT(smogdimuon_masses_t, float) smogdimuon_masses;
    DEVICE_OUTPUT(smogdimuon_svz_t, float) smogdimuon_svz;

    DEVICE_OUTPUT(dev_histogram_smogdimuon_mass_t, unsigned) dev_histogram_smogdimuon_mass;
    DEVICE_OUTPUT(dev_histogram_smogdimuon_svz_t, unsigned) dev_histogram_smogdimuon_svz;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(maxTrackChi2Ndf_t, "minTrackChi2Ndf", "max track fit Chi2ndf", float) maxTrackChi2Ndf;
    PROPERTY(minTrackPt_t, "minTrackPt", "min track transverse momentum", float) minTrackPt;
    PROPERTY(minTrackP_t, "minTrackP", "min track momentum", float) minTrackP;
    PROPERTY(minMass_t, "minMass", "min invariant mass for track combination", float) minMass;
    PROPERTY(maxDoca_t, "maxDoca", "max distance of closest approach", float) maxDoca;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Max vertex chi2", float) maxVertexChi2;
    PROPERTY(minZ_t, "minZ", "minimum vertex z", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "maximum vertex z", float) maxZ;
    PROPERTY(CombCharge_t, "HighMassCombCharge", "Charge of the combination", int) CombCharge;

    PROPERTY(
      histogram_smogdimuon_mass_min_t,
      "histogram_smogdimuon_mass_min",
      "minimum for smogdimuon mass histogram",
      float)
    histogram_smogdimuon_mass_min;
    PROPERTY(
      histogram_smogdimuon_mass_max_t,
      "histogram_smogdimuon_mass_max",
      "maximum for smogdimuon mass histogram",
      float)
    histogram_smogdimuon_mass_max;
    PROPERTY(
      histogram_smogdimuon_mass_nbins_t,
      "histogram_smogdimuon_mass_nbins",
      "Nbins for smogdimuon mass histogram",
      unsigned int)
    histogram_smogdimuon_mass_nbins;

    PROPERTY(
      histogram_smogdimuon_svz_min_t,
      "histogram_smogdimuon_svz_min",
      "minimum for smogdimuon svz histogram",
      float)
    histogram_smogdimuon_svz_min;
    PROPERTY(
      histogram_smogdimuon_svz_max_t,
      "histogram_smogdimuon_svz_max",
      "maximum for smogdimuon svz histogram",
      float)
    histogram_smogdimuon_svz_max;
    PROPERTY(
      histogram_smogdimuon_svz_nbins_t,
      "histogram_smogdimuon_svz_nbins",
      "Nbins for smogdimuon svz histogram",
      unsigned int)
    histogram_smogdimuon_svz_nbins;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct SMOG2_dimuon_highmass_line_t : public SelectionAlgorithm,
                                        Parameters,
                                        TwoTrackLine<SMOG2_dimuon_highmass_line_t, Parameters> {

    using monitoring_types = std::tuple<smogdimuon_masses_t, smogdimuon_svz_t>;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    void init();

    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    __host__ void
    output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<maxTrackChi2Ndf_t> m_maxTrackChi2Ndf {this, 3.f};
    Property<minTrackPt_t> m_minTrackPt {this, 500.f * Gaudi::Units::MeV};
    Property<minTrackP_t> m_minTrackP {this, 3000.f * Gaudi::Units::MeV};
    Property<minMass_t> m_minMass {this, 2700.f * Gaudi::Units::MeV};
    Property<CombCharge_t> m_CombCharge {this, 0};
    Property<maxDoca_t> m_maxDoca {this, 0.5f * Gaudi::Units::mm};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 25.0f};
    Property<minZ_t> m_minZ {this, -551.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -331.f * Gaudi::Units::mm};

    // histogram properties
    Property<histogram_smogdimuon_mass_min_t> m_histogramsmogdimuonMassMin {this, 2700.f};
    Property<histogram_smogdimuon_mass_max_t> m_histogramsmogdimuonMassMax {this, 4000.f};
    Property<histogram_smogdimuon_mass_nbins_t> m_histogramsmogdimuonMassNBins {this, 300u};

    Property<histogram_smogdimuon_svz_min_t> m_histogramsmogdimuonSVzMin {this, -541.f};
    Property<histogram_smogdimuon_svz_max_t> m_histogramsmogdimuonSVzMax {this, -341.f};
    Property<histogram_smogdimuon_svz_nbins_t> m_histogramsmogdimuonSVzNBins {this, 100u};
    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};

#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_smogdimuon_mass;
    gaudi_monitoring::Lockable_Histogram<>* histogram_smogdimuon_svz;
#endif
  };
} // namespace SMOG2_dimuon_highmass_line
