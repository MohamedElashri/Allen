/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLineWithIndex.cuh"
#include "ROOTService.h"
#include "MassDefinitions.h"
#include "AllenMonitoring.h"

namespace downstream_mva_busca_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_downstream_mva_busca_t, float) dev_downstream_mva_busca;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
    DEVICE_OUTPUT(pt_t, float) pt;
    DEVICE_OUTPUT(mipchi2_t, float) mipchi2;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(mva_threshold_t, "mva_threshold_t", "the mva threshold", float) mva_threshold;

    PROPERTY(enable_trigger_t, "enable_trigger", "enable trigger for event pass", bool) enable_trigger;
    PROPERTY(general_line_t, "general_line", "general line with specific trigger system", bool) general_line;
    PROPERTY(trigger_mass_min_t, "trigger_mass_min", "enable trigger for event pass", float) trigger_mass_min;
    PROPERTY(trigger_mass_max_t, "trigger_mass_max", "enable trigger for event pass", float) trigger_mass_max;

    PROPERTY(trigger_fd_min_t, "trigger_fd_min", "enable trigger for event pass", float) trigger_fd_min;
    PROPERTY(trigger_fd_max_t, "trigger_fd_max", "enable trigger for event pass", float) trigger_fd_max;

    PROPERTY(daughter_momentum_cut_t, "daughter_momentum_cut", "momentum caut for daughter particle", float)
    daughter_momentum_cut;
    PROPERTY(downstream_quality_cut_t, "downstream_quality_cut", "momentum caut for daughter particle", float)
    downstream_quality_cut;

    PROPERTY(mass_ee_cut_t, "mass_ee_cut", "lower ee mass threshold", float) mass_ee_cut;

    PROPERTY(mass_pipi_lower_threshold_t, "mass_pipi_lower_threshold", "lower pipi mass threshold", float)
    mass_pipi_lower_threshold;
    PROPERTY(mass_pipi_higher_threshold_t, "mass_pipi_higher_threshold", "higher pipi mass threshold", float)
    mass_pipi_higher_threshold;

    PROPERTY(mass_ppi_lower_threshold_t, "mass_ppi_lower_threshold", "lower ppi mass threshold", float)
    mass_ppi_lower_threshold;
    PROPERTY(mass_ppi_higher_threshold_t, "mass_ppi_higher_threshold", "higher ppi mass threshold", float)
    mass_ppi_higher_threshold;

    PROPERTY(histogram_busca_mass_min_t, "histogram_ks_mass_min", "histogram_ks_mass_min description", float)
    histogram_busca_mass_min;
    PROPERTY(histogram_busca_mass_max_t, "histogram_ks_mass_max", "histogram_ks_mass_max description", float)
    histogram_busca_mass_max;
    PROPERTY(
      histogram_busca_mass_nbins_t,
      "histogram_ks_mass_nbins",
      "histogram_ks_mass_nbins description",
      unsigned int)
    histogram_busca_mass_nbins;
    PROPERTY(
      histogram_busca_mass_sigma_multiplier_t,
      "histogram_busca_mass_sigma_multiplier",
      "histogram_busca_mass_sigma_multiplier description",
      float)
    histogram_busca_mass_sigma_multiplier;

    PROPERTY(histogram_busca_fd_min_t, "histogram_ks_pt_min", "histogram_ks_pt_min description", float)
    histogram_busca_fd_min;
    PROPERTY(histogram_busca_fd_max_t, "histogram_ks_pt_max", "histogram_ks_pt_max description", float)
    histogram_busca_fd_max;
    PROPERTY(histogram_busca_fd_nbins_t, "histogram_ks_pt_nbins", "histogram_ks_pt_nbins description", unsigned int)
    histogram_busca_fd_nbins;
    PROPERTY(
      histogram_busca_fd_sigma_multiplier_t,
      "histogram_busca_fd_sigma_multiplier",
      "histogram_busca_fd_sigma_multiplier description",
      float)
    histogram_busca_fd_sigma_multiplier;

    PROPERTY(enable_monitoring_t, "enable_monitoring_t", "Enable line tupling", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    PROPERTY(muon_line_t, "muon_line", "Turn on muon BuSca line", bool) muon_line;
    PROPERTY(electron_line_t, "electron_line", "Turn of electron line", bool) electron_line;
    PROPERTY(hadron_line_t, "hadron_line", "Turn of hadron line", bool) hadron_line;
    PROPERTY(disable_R_cut_t, "disable_R_cut", "Turn of hadron line", bool) disable_R_cut;
  };

  struct downstream_mva_busca_line_t : public SelectionAlgorithm,
                                       Parameters,
                                       CompositeParticleLineWithIndex<downstream_mva_busca_line_t, Parameters> {

    struct DeviceAccumulators {
      Allen::Monitoring::HistogramND<unsigned, Allen::Monitoring::LogAxis, Allen::Monitoring::LogAxis>::DeviceType
        busca_scaled;
      Allen::Monitoring::Histogram2D<>::DeviceType busca_armenteros;
      Allen::Monitoring::Histogram2D<>::DeviceType busca_triggered_armenteros;
      DeviceAccumulators(const downstream_mva_busca_line_t& algo, const Allen::Context& ctx) :
        busca_scaled(algo.m_busca_scaled.data(ctx)), busca_armenteros(algo.m_busca_armenteros.data(ctx)),
        busca_triggered_armenteros(algo.m_busca_triggered_armenteros.data(ctx))
      {}
    };

    using monitoring_types = std::tuple<sv_masses_t, pt_t, mipchi2_t>;

    __device__ static bool select(
      const Parameters&,
      const DeviceAccumulators&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static void monitor(
      const Parameters& parameters,
      const DeviceAccumulators& accumulators,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
      unsigned index,
      bool sel);

    template<int line_type>
    __device__ static bool lepton_selection(const Allen::Views::Physics::CompositeParticle composite);

    void init();

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<mva_threshold_t> m_mva_threshold {this, 0.5f};

    Property<enable_trigger_t> m_enable_trigger {this, false};
    Property<trigger_mass_min_t> m_trigger_mass_min_t {this, 0.f};
    Property<trigger_mass_max_t> m_trigger_mass_max_t {this, 0.f};
    Property<trigger_fd_min_t> m_trigger_fd_min_t {this, 0.f};
    Property<trigger_fd_max_t> m_trigger_fd_max_t {this, 0.f};

    Property<daughter_momentum_cut_t> m_daughter_momentum_cut_t {this, 8000.f};
    Property<downstream_quality_cut_t> m_downstream_quality_cut_t {this, 0.3f};
    Property<mass_ee_cut_t> m_mass_ee_cut_t {this, 200.f};
    Property<mass_pipi_lower_threshold_t> m_mass_pipi_lower_threshold_t {this, 460.f};
    Property<mass_pipi_higher_threshold_t> m_mass_pipi_higher_threshold_t {this, 540.f};
    Property<mass_ppi_lower_threshold_t> m_mass_ppi_lower_threshold_t {this, 1110.f};
    Property<mass_ppi_higher_threshold_t> m_mass_ppi_higher_threshold_t {this, 1132.f};

    Property<histogram_busca_mass_min_t> m_histogramMassMin {this, 200.f};
    Property<histogram_busca_mass_max_t> m_histogramMassMax {this, 5000.f};
    Property<histogram_busca_mass_nbins_t> m_histogramMassNBins {this, 80u};
    Property<histogram_busca_mass_sigma_multiplier_t> m_histogramMassSigmaMulti {this, 2.f};

    Property<histogram_busca_fd_min_t> m_histogramFDMin {this, 0.f};
    Property<histogram_busca_fd_max_t> m_histogramFDMax {this, 2500.f};
    Property<histogram_busca_fd_nbins_t> m_histogramFDNBins {this, 20u};
    Property<histogram_busca_fd_sigma_multiplier_t> m_histogramFDSigmaMulti {this, 2.f};

    // Switch to create monitoring tuple
    Property<enable_monitoring_t> m_enable_monitoring {this, true};
    Property<enable_tupling_t> m_enable_tupling {this, true};
    Property<muon_line_t> m_muon_line {this, true};
    Property<electron_line_t> m_electron_line {this, false};
    Property<hadron_line_t> m_hadron_line {this, false};
    Property<disable_R_cut_t> m_disable_R_cut {this, false};
    Property<general_line_t> m_general_line {this, true};

    Allen::Monitoring::HistogramND<unsigned, Allen::Monitoring::LogAxis, Allen::Monitoring::LogAxis> m_busca_scaled {
      this,
      "busca_scaled",
      "busca_scaled",
      {property<histogram_busca_mass_nbins_t>(),
       property<histogram_busca_mass_min_t>(),
       property<histogram_busca_mass_max_t>(),
       1.f / property<histogram_busca_mass_min_t>(),
       1.f * log2f(1 + 0.02f * property<histogram_busca_mass_sigma_multiplier_t>()),
       0.f},
      {property<histogram_busca_fd_nbins_t>(),
       property<histogram_busca_fd_min_t>(),
       property<histogram_busca_fd_max_t>(),
       1.f / (-4000.f),
       1.f / log2f(1 - 0.02f * property<histogram_busca_mass_sigma_multiplier_t>()),
       1.f}};

    Allen::Monitoring::Histogram2D<> m_busca_armenteros {this,
                                                         "armenteros_busca",
                                                         "armenteros",
                                                         {100u, -1.f, 1.f},
                                                         {100u, 0.f, 4000.f}};

    Allen::Monitoring::Histogram2D<> m_busca_triggered_armenteros {this,
                                                                   "armenteros_triggered_busca",
                                                                   "armenteros triggered",
                                                                   {100u, -1.f, 1.f},
                                                                   {100u, 0.f, 4000.f}};
  };
} // namespace downstream_mva_busca_line
