/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"
#include "ROOTService.h"
#include <ROOTHeaders.h>

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace highmass_dielectron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Kalman fitted tracks
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    // ECAL
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    // Outputs
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;

    // Properties
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(OppositeSign_t, "OppositeSign", "Selects opposite sign dimuon combinations", bool) OppositeSign;
    PROPERTY(MinZ_t, "MinZ", "Min z dielectron coordinate", float) MinZ;

    PROPERTY(minMass_t, "minMass", "Min mass of the composite", float) minMass;
    PROPERTY(maxMass_t, "maxMass", "Max mass of the composite", float) maxMass;
    PROPERTY(minTrackP_t, "minTrackP", "Minimal momentum for both daughters ", float) minTrackP;
    PROPERTY(minTrackPt_t, "minTrackPt", "Minimal pT for both daughters", float) minTrackPt;
    PROPERTY(maxTrackEta_t, "maxTrackEta", "Maximal ETA for both daughters", float) maxTrackEta;
    PROPERTY(maxDoca_t, "maxDoca", "maxDoca description", float) maxDoca;

    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;

    // Outputs for ROOT tupling
    DEVICE_OUTPUT(mass_t, float) mass;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    DEVICE_OUTPUT(dev_histogram_Z_mass_t, unsigned) dev_histogram_Z_mass;
    DEVICE_OUTPUT(dev_histogram_upsilon_mass_t, unsigned) dev_histogram_upsilon_mass;

    PROPERTY(histogram_Z_mass_min_t, "histogram_Z_mass_min", "histogram_Z_mass_min description", float)
    histogram_Z_mass_min;
    PROPERTY(histogram_Z_mass_max_t, "histogram_Z_mass_max", "histogram_Z_mass_max description", float)
    histogram_Z_mass_max;
    PROPERTY(histogram_Z_mass_nbins_t, "histogram_Z_mass_nbins", "histogram_Z_mass_nbins description", unsigned int)
    histogram_Z_mass_nbins;

    PROPERTY(histogram_upsilon_mass_min_t, "histogram_upsilon_mass_min", "", float)
    histogram_upsilon_mass_min;
    PROPERTY(histogram_upsilon_mass_max_t, "histogram_upsilon_mass_max", "", float)
    histogram_upsilon_mass_max;
    PROPERTY(histogram_upsilon_mass_nbins_t, "histogram_upsilon_mass_nbins", "", unsigned int)
    histogram_upsilon_mass_nbins;
  };

  struct highmass_dielectron_line_t : public SelectionAlgorithm,
                                      Parameters,
                                      CompositeParticleLine<highmass_dielectron_line_t, Parameters> {
    __device__ static bool select(
      const Parameters&,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float>);

    __device__ static std::tuple<
      const Allen::Views::Physics::CompositeParticle,
      const bool,
      const bool,
      const float,
      const float,
      const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    void init();

    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);

    //__device__ static void
    // monitor(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>, unsigned, bool);

    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float> input,
      unsigned index,
      bool sel);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float> input,
      unsigned index,
      bool sel);

    __host__ void
    output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&) const;
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Low-mass no-IP dielectron selections.
    Property<minTrackP_t> m_minTrackP {this, 14.f * Gaudi::Units::GeV};
    Property<minTrackPt_t> m_minTrackPt {this, 1.5f * Gaudi::Units::GeV};
    Property<maxTrackEta_t> m_maxTrackEta {this, 5.0};

    Property<minMass_t> m_minMass {this, 8.0f * Gaudi::Units::GeV};
    Property<maxMass_t> m_maxMass {this, 140.f * Gaudi::Units::GeV};

    Property<maxDoca_t> m_maxDoca {this, .2f * Gaudi::Units::mm};
    Property<OppositeSign_t> m_only_select_opposite_sign {this, true};

    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};
    Property<MinZ_t> m_MinZ {this, -341.f * Gaudi::Units::mm};

    Property<histogram_Z_mass_min_t> m_histogramZMassMin {this, 60000.f};
    Property<histogram_Z_mass_max_t> m_histogramZMassMax {this, 120000.f};
    Property<histogram_Z_mass_nbins_t> m_histogramZMassNBins {this, 100u};

    Property<histogram_upsilon_mass_min_t> m_histogramUpsilonMassMin {this, 8000.f};
    Property<histogram_upsilon_mass_max_t> m_histogramUpsilonMassMax {this, 11500.f};
    Property<histogram_upsilon_mass_nbins_t> m_histogramUpsilonMassNBins {this, 100u};

#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_dielectron_Z_mass;
    gaudi_monitoring::Lockable_Histogram<>* histogram_dielectron_upsilon_mass;
#endif

    using monitoring_types = std::tuple<mass_t, evtNo_t, runNo_t>;
  };
} // namespace highmass_dielectron_line
