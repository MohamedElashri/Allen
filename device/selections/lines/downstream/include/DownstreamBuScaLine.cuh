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
  };

  struct downstream_mva_busca_line_t : public SelectionAlgorithm,
                                       Parameters,
                                       CompositeParticleLineWithIndex<downstream_mva_busca_line_t, Parameters> {

    struct DeviceProperties {
      float mva_threshold;
      bool enable_trigger;
      float trigger_mass_min;
      float trigger_mass_max;
      float trigger_fd_min;
      float trigger_fd_max;
      float daughter_momentum_cut;
      float downstream_quality_cut;
      float mass_ee_cut;
      float mass_pipi_lower_threshold;
      float mass_pipi_higher_threshold;
      float mass_ppi_lower_threshold;
      float mass_ppi_higher_threshold;
      bool muon_line;
      bool electron_line;
      bool hadron_line;
      bool disable_R_cut;
      bool general_line;

      Allen::Monitoring::HistogramND<unsigned, Allen::Monitoring::LogAxis, Allen::Monitoring::LogAxis>::DeviceType
        busca_scaled;
      Allen::Monitoring::Histogram2D<>::DeviceType busca_armenteros;
      Allen::Monitoring::Histogram2D<>::DeviceType busca_triggered_armenteros;
      DeviceProperties(const downstream_mva_busca_line_t& algo, const Allen::Context& ctx) :
        mva_threshold(algo.m_mva_threshold), enable_trigger(algo.m_enable_trigger.value()),
        trigger_mass_min(algo.m_trigger_mass_min), trigger_mass_max(algo.m_trigger_mass_max),
        trigger_fd_min(algo.m_trigger_fd_min), trigger_fd_max(algo.m_trigger_fd_max),
        daughter_momentum_cut(algo.m_daughter_momentum_cut), downstream_quality_cut(algo.m_downstream_quality_cut),
        mass_ee_cut(algo.m_mass_ee_cut), mass_pipi_lower_threshold(algo.m_mass_pipi_lower_threshold),
        mass_pipi_higher_threshold(algo.m_mass_pipi_higher_threshold),
        mass_ppi_lower_threshold(algo.m_mass_ppi_lower_threshold),
        mass_ppi_higher_threshold(algo.m_mass_ppi_higher_threshold), muon_line(algo.m_muon_line.value()),
        electron_line(algo.m_electron_line.value()), hadron_line(algo.m_hadron_line.value()),
        disable_R_cut(algo.m_disable_R_cut.value()), general_line(algo.m_general_line.value()),
        busca_scaled(algo.m_busca_scaled.data(ctx)), busca_armenteros(algo.m_busca_armenteros.data(ctx)),
        busca_triggered_armenteros(algo.m_busca_triggered_armenteros.data(ctx))
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>);

    __device__ static void monitor(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned>,
      unsigned,
      bool);

    template<int line_type>
    __device__ static bool lepton_selection(const Allen::Views::Physics::CompositeParticle);

    void init();

  private:
    Allen::Property<float> m_mva_threshold {this, "mva_threshold_t", 0.5f, "the mva threshold"};

    Allen::Property<bool> m_enable_trigger {this, "enable_trigger", false, "enable trigger for event pass"};
    Allen::Property<float> m_trigger_mass_min {this, "trigger_mass_min", 0.f, "enable trigger for event pass"};
    Allen::Property<float> m_trigger_mass_max {this, "trigger_mass_max", 0.f, "enable trigger for event pass"};
    Allen::Property<float> m_trigger_fd_min {this, "trigger_fd_min", 0.f, "enable trigger for event pass"};
    Allen::Property<float> m_trigger_fd_max {this, "trigger_fd_max", 0.f, "enable trigger for event pass"};

    Allen::Property<float> m_daughter_momentum_cut {this,
                                                    "daughter_momentum_cut",
                                                    8000.f,
                                                    "momentum caut for daughter particle"};
    Allen::Property<float> m_downstream_quality_cut {this,
                                                     "downstream_quality_cut",
                                                     0.3f,
                                                     "momentum caut for daughter particle"};
    Allen::Property<float> m_mass_ee_cut {this, "mass_ee_cut", 200.f, "lower ee mass threshold"};
    Allen::Property<float> m_mass_pipi_lower_threshold {this,
                                                        "mass_pipi_lower_threshold",
                                                        460.f,
                                                        "lower pipi mass threshold"};
    Allen::Property<float> m_mass_pipi_higher_threshold {this,
                                                         "mass_pipi_higher_threshold",
                                                         540.f,
                                                         "higher pipi mass threshold"};
    Allen::Property<float> m_mass_ppi_lower_threshold {this,
                                                       "mass_ppi_lower_threshold",
                                                       1110.f,
                                                       "lower ppi mass threshold"};
    Allen::Property<float> m_mass_ppi_higher_threshold {this,
                                                        "mass_ppi_higher_threshold",
                                                        1132.f,
                                                        "higher ppi mass threshold"};

    Allen::Property<bool> m_muon_line {this, "muon_line", true, "Turn on muon BuSca line"};
    Allen::Property<bool> m_electron_line {this, "electron_line", false, "Turn of electron line"};
    Allen::Property<bool> m_hadron_line {this, "hadron_line", false, "Turn of hadron line"};
    Allen::Property<bool> m_disable_R_cut {this, "disable_R_cut", false, "Turn of hadron line"};
    Allen::Property<bool> m_general_line {this, "general_line", true, "general line with specific trigger system"};

    Allen::Property<float> m_histogramMassMin {this,
                                               "histogram_ks_mass_min",
                                               200.f,
                                               "histogram_ks_mass_min description"};
    Allen::Property<float> m_histogramMassMax {this,
                                               "histogram_ks_mass_max",
                                               5000.f,
                                               "histogram_ks_mass_max description"};
    Allen::Property<unsigned> m_histogramMassNBins {this,
                                                    "histogram_ks_mass_nbins",
                                                    80u,
                                                    "histogram_ks_mass_nbins description"};
    Allen::Property<float> m_histogramMassSigmaMulti {this,
                                                      "histogram_busca_mass_sigma_multiplier",
                                                      2.f,
                                                      "histogram_busca_mass_sigma_multiplier description"};
    Allen::Property<float> m_histogramFDMin {this, "histogram_ks_pt_min", 0.f, "histogram_ks_pt_min description"};
    Allen::Property<float> m_histogramFDMax {this, "histogram_ks_pt_max", 2500.f, "histogram_ks_pt_max description"};
    Allen::Property<unsigned> m_histogramFDNBins {this,
                                                  "histogram_ks_pt_nbins",
                                                  20u,
                                                  "histogram_ks_pt_nbins description"};
    Allen::Property<float> m_histogramFDSigmaMulti {this,
                                                    "histogram_busca_fd_sigma_multiplier",
                                                    2.f,
                                                    "histogram_busca_fd_sigma_multiplier description"};

    Allen::Monitoring::HistogramND<unsigned, Allen::Monitoring::LogAxis, Allen::Monitoring::LogAxis> m_busca_scaled {
      this,
      "busca_scaled",
      "busca_scaled",
      {m_histogramMassNBins,
       m_histogramMassMin,
       m_histogramMassMax,
       1.f / m_histogramMassMin,
       1.f * log2f(1 + 0.02f * m_histogramMassSigmaMulti),
       0.f},
      {m_histogramFDNBins,
       m_histogramFDMin,
       m_histogramFDMax,
       1.f / (-4000.f),
       1.f / log2f(1 - 0.02f * m_histogramFDSigmaMulti),
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
