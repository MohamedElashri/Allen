/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

namespace d2pipi_line {
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

    // Monitoring
    DEVICE_OUTPUT(min_pt_t, float) min_pt; // To be used in bandwidth division
    DEVICE_OUTPUT(min_ip_t, float) min_ip; // To be used in bandwidth division
    DEVICE_OUTPUT(D0_ct_t, float) D0_ct;   // To be used in bandwidth division
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float) minComboPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(maxDOCA_t, "maxDOCA", "maxDOCA description", float) maxDOCA;
    PROPERTY(minEta_t, "minEta", "minEta description", float) minEta;
    PROPERTY(maxEta_t, "maxEta", "maxEta description", float) maxEta;
    PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float) minTrackPt;
    PROPERTY(massWindow_t, "massWindow", "massWindow description", float) massWindow;
    PROPERTY(minTrackIP_t, "minTrackIP", "minTrackIP description", float) minTrackIP;
    PROPERTY(ctIPScale_t, "ctIPScale", "D0 ct should be larger than this time minTrackIP", float) ctIPScale;
    PROPERTY(minZ_t, "minZ", "minimum vertex z coordinate", float) minZ;
    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dibody combinations", bool) OppositeSign;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    DEVICE_OUTPUT(dev_histogram_d02pipi_mass_t, unsigned) dev_histogram_d02pipi_mass;
    PROPERTY(
      histogram_d02pipi_mass_min_t,
      "histogram_d02pipi_mass_min",
      "histogram_d02pipi_mass_min description",
      float)
    histogram_d02pipi_mass_min;
    PROPERTY(
      histogram_d02pipi_mass_max_t,
      "histogram_d02pipi_mass_max",
      "histogram_d02pipi_mass_max description",
      float)
    histogram_d02pipi_mass_max;
    PROPERTY(
      histogram_d02pipi_mass_nbins_t,
      "histogram_d02pipi_mass_nbins",
      "histogram_d02pipi_mass_nbins description",
      unsigned int)
    histogram_d02pipi_mass_nbins;

    DEVICE_OUTPUT(dev_histogram_d02pipi_pt_t, unsigned) dev_histogram_d02pipi_pt;
    PROPERTY(histogram_d02pipi_pt_min_t, "histogram_d02pipi_pt_min", "histogram_d02pipi_pt_min description", float)
    histogram_d02pipi_pt_min;
    PROPERTY(histogram_d02pipi_pt_max_t, "histogram_d02pipi_pt_max", "histogram_d02pipi_pt_max description", float)
    histogram_d02pipi_pt_max;
    PROPERTY(
      histogram_d02pipi_pt_nbins_t,
      "histogram_d02pipi_pt_nbins",
      "histogram_d02pipi_pt_nbins description",
      unsigned int)
    histogram_d02pipi_pt_nbins;
  };

  struct d2pipi_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<d2pipi_line_t, Parameters> {
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

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle> input,
      unsigned index,
      bool sel);

    using monitoring_types = std::tuple<min_pt_t, min_ip_t, D0_ct_t, evtNo_t, runNo_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minComboPt_t> m_minComboPt {this, 2000.0f * Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 20.f};
    Property<maxDOCA_t> m_maxDOCA {this, 0.2f * Gaudi::Units::mm};
    Property<minEta_t> m_minEta {this, 2.0f};
    Property<maxEta_t> m_maxEta {this, 5.0f};
    Property<minTrackPt_t> m_minTrackPt {this, 800.f * Gaudi::Units::MeV};
    Property<massWindow_t> m_massWindow {this, 100.f * Gaudi::Units::MeV};
    Property<minTrackIP_t> m_minTrackIP {this, 0.06f * Gaudi::Units::mm};
    Property<ctIPScale_t> m_ctIPScale {this, 1.f};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<OppositeSign_t> m_opposite_sign {this, true};
    Property<histogram_d02pipi_mass_min_t> m_histogramD0MassMin {this, 1765.f};
    Property<histogram_d02pipi_mass_max_t> m_histogramD0MassMax {this, 1965.f};
    Property<histogram_d02pipi_mass_nbins_t> m_histogramD0MassNBins {this, 100u};
    Property<histogram_d02pipi_pt_min_t> m_histogramD0PtMin {this, 0.f};
    Property<histogram_d02pipi_pt_max_t> m_histogramD0PtMax {this, 1e4};
    Property<histogram_d02pipi_pt_nbins_t> m_histogramD0PtNBins {this, 100u};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};

#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_d02pipi_mass;
    gaudi_monitoring::Lockable_Histogram<>* histogram_d02pipi_pt;
#endif
  };
} // namespace d2pipi_line
