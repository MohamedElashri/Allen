/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace SMOG2_kstopipi_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
    DEVICE_OUTPUT(svz_t, float) svz;
    DEVICE_OUTPUT(dev_histogram_smogks_mass_t, unsigned) dev_histogram_smogks_mass;
    DEVICE_OUTPUT(dev_histogram_smogks_svz_t, unsigned) dev_histogram_smogks_svz;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minIPChi2_t, "minIPChi2", "Minimum IPCHI2", float) minIPChi2;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "Maximum vertex Chi2", float) maxVertexChi2;
    PROPERTY(maxIP_t, "maxIP", "Maximum IP", float) maxIP;
    PROPERTY(minMass_t, "minMass", "Minimum invariant mass", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Maximum invariat mass", float) maxMass;
    PROPERTY(minPVZ_t, "minPVZ", "minimum PV z coordinate", float) minPVZ;
    PROPERTY(maxPVZ_t, "maxPVZ", "maximum PV z coordinate", float) maxPVZ;
    PROPERTY(CombCharge_t, "CombCharge", "Charge of the combination", int) CombCharge;

    PROPERTY(histogram_smogks_mass_min_t, "histogram_smogks_mass_min", "minimum for smogks mass histogram", float)
    histogram_smogks_mass_min;
    PROPERTY(histogram_smogks_mass_max_t, "histogram_smogks_mass_max", "maximum for smogks mass histogram", float)
    histogram_smogks_mass_max;
    PROPERTY(
      histogram_smogks_mass_nbins_t,
      "histogram_smogks_mass_nbins",
      "nbins for smogks mass histogram",
      unsigned int)
    histogram_smogks_mass_nbins;
    PROPERTY(histogram_smogks_svz_min_t, "histogram_smogks_svz_min", "minimum for smogks svz histogram", float)
    histogram_smogks_svz_min;
    PROPERTY(histogram_smogks_svz_max_t, "histogram_smogks_svz_max", "maximum for smogks svz histogram", float)
    histogram_smogks_svz_max;
    PROPERTY(
      histogram_smogks_svz_nbins_t,
      "histogram_smogks_svz_nbins",
      "mbins for smogks mass histogram",
      unsigned int)
    histogram_smogks_svz_nbins;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
  };

  struct SMOG2_kstopipi_line_t : public SelectionAlgorithm,
                                 Parameters,
                                 TwoTrackLine<SMOG2_kstopipi_line_t, Parameters> {

    using monitoring_types = std::tuple<sv_masses_t, svz_t>;

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
    Property<minIPChi2_t> m_minIPChi2 {this, 100.f};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 10.0f};
    Property<maxIP_t> m_maxIP {this, 0.3f * Gaudi::Units::mm};
    Property<minMass_t> m_minMass {this, 400.f * Gaudi::Units::MeV};
    Property<maxMass_t> m_maxMass {this, 600.f * Gaudi::Units::MeV};
    Property<minPVZ_t> m_minPVZ {this, -541.f * Gaudi::Units::mm};
    Property<maxPVZ_t> m_maxPVZ {this, -341.f * Gaudi::Units::mm};
    Property<CombCharge_t> m_CombCharge {this, 0};

    Property<histogram_smogks_mass_min_t> m_histogramsmogksMassMin {this, 400.f};
    Property<histogram_smogks_mass_max_t> m_histogramsmogksMassMax {this, 600.f};
    Property<histogram_smogks_mass_nbins_t> m_histogramsmogksMassNBins {this, 100u};
    Property<histogram_smogks_svz_min_t> m_histogramsmogkssvzMin {this, -541.f};
    Property<histogram_smogks_svz_max_t> m_histogramsmogkssvzMax {this, 2700.f};
    Property<histogram_smogks_svz_nbins_t> m_histogramsmogkssvzNBins {this, 100u};
    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_smogks_mass;
    gaudi_monitoring::Lockable_Histogram<>* histogram_smogks_svz;
#endif
  };
} // namespace SMOG2_kstopipi_line
