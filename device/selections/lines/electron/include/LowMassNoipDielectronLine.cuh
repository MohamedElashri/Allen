/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "TwoTrackLine.cuh"
#include "ParKalmanFilter.cuh"
#include "ROOTService.h"
#include <ROOTHeaders.h>

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace lowmass_noip_dielectron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Prompt/secondary vertex evaluator
    DEVICE_INPUT(dev_vertex_passes_prompt_selection_t, float) dev_vertex_passes_prompt_selection;
    DEVICE_INPUT(dev_vertex_passes_displaced_selection_t, float) dev_vertex_passes_displaced_selection;
    // Kalman fitted tracks
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    // ECAL
    DEVICE_INPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    // Outputs
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    // Outputs for ROOT tupling
    DEVICE_OUTPUT(dev_die_masses_raw_t, float) dev_die_masses_raw;
    DEVICE_OUTPUT(dev_die_masses_bremcorr_t, float) dev_die_masses_bremcorr;
    DEVICE_OUTPUT(dev_die_pts_raw_t, float) dev_die_pts_raw;
    DEVICE_OUTPUT(dev_die_pts_bremcorr_t, float) dev_die_pts_bremcorr;
    DEVICE_OUTPUT(dev_e_minpts_raw_t, float) dev_e_minpts_raw;
    DEVICE_OUTPUT(dev_e_minpt_bremcorr_t, float) dev_e_minpt_bremcorr;
    DEVICE_OUTPUT(dev_die_minipchi2_t, float) dev_die_minipchi2;
    DEVICE_OUTPUT(dev_die_ip_t, float) dev_die_ip;
    // outputs for Gaudi histogram
    DEVICE_OUTPUT(dev_masses_histo_t, unsigned) dev_masses_histo;
    DEVICE_OUTPUT(dev_masses_brem_histo_t, unsigned) dev_masses_brem_histo;
    // Properties
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(selectPrompt_t, "selectPrompt", "Use ipchi2 threshold as upper (prompt) or lower (displaced) bound", bool)
    selectPrompt;
    PROPERTY(MinMass_t, "MinMass", "Min vertex mass", float) minMass;
    PROPERTY(MaxMass_t, "MaxMass", "Max vertex mass", float) maxMass;
    PROPERTY(ss_on_t, "ss_on", "Flag when same-sign candidates should be selected", bool) ss_on;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
    PROPERTY(MinZ_t, "MinZ", "Min z dielectron coordinate", float) MinZ;
  };

  struct lowmass_noip_dielectron_line_t : public SelectionAlgorithm,
                                          Parameters,
                                          TwoTrackLine<lowmass_noip_dielectron_line_t, Parameters> {
    __device__ static bool select(
      const Parameters&,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float,
        const bool,
        const bool>);

    __device__ static std::tuple<
      const Allen::Views::Physics::CompositeParticle,
      const bool,
      const bool,
      const float,
      const float,
      const float,
      const bool,
      const bool>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;
    void init_tuples(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const;

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<
        const Allen::Views::Physics::CompositeParticle,
        const bool,
        const bool,
        const float,
        const float,
        const float,
        const bool,
        const bool> input,
      unsigned index,
      bool sel);

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;
    void output_tuples(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions&, const Allen::Context&)
      const;

    void init();

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    // Low-mass no-IP dielectron selections.
    Property<selectPrompt_t> m_selectPrompt {this, true};
    Property<MinMass_t> m_MinMass {this, 5.f};
    Property<MaxMass_t> m_MaxMass {this, 300.f};
    Property<ss_on_t> m_ss_on {this, false};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<enable_tupling_t> m_enable_tupling {this, false};
    Property<MinZ_t> m_MinZ {this, -341.f * Gaudi::Units::mm};

#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_dielectron_masses;
    gaudi_monitoring::Lockable_Histogram<>* histogram_dielectron_masses_brem;
#endif
  };
} // namespace lowmass_noip_dielectron_line
