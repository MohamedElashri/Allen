/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "CompositeParticleLine.cuh"

#ifndef ALLEN_STANDALONE
#include "GaudiMonitoring.h"
#include <Gaudi/Accumulators.h>
#endif

namespace displaced_di_muon_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_chi2muon_t, float) dev_chi2muon;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minDispTrackPt_t, "minDispTrackPt", "minDispTrackPt description", float) minDispTrackPt;
    PROPERTY(maxVertexChi2_t, "maxVertexChi2", "maxVertexChi2 description", float) maxVertexChi2;
    PROPERTY(dispMinIPChi2_t, "dispMinIPChi2", "dispMinIPChi2 description", float) dispMinIPChi2;
    PROPERTY(dispMinEta_t, "dispMinEta", "dispMinEta description", float) dispMinEta;
    PROPERTY(dispMaxEta_t, "dispMaxEta", "dispMaxEta description", float) dispMaxEta;
    PROPERTY(minZ_t, "minZ", "minimum vertex z dimuon coordinate", float) minZ;
    PROPERTY(maxChi2Muon_t, "maxChi2Muon", "minimum Chi2Muon evaluation", float) maxChi2Muon;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable line monitoring", bool) enable_monitoring;

    DEVICE_OUTPUT(dev_histogram_mass_t, unsigned) dev_histogram_mass;
    PROPERTY(histogram_mass_min_t, "histogram_mass_min", "histogram_mass_min description", float)
    histogram_mass_min;
    PROPERTY(histogram_mass_max_t, "histogram_mass_max", "histogram_mass_max description", float)
    histogram_mass_max;
    PROPERTY(histogram_mass_nbins_t, "histogram_mass_nbins", "histogram_mass_nbins description", unsigned int)
    histogram_mass_nbins;
  };

  struct displaced_di_muon_line_t : public SelectionAlgorithm,
                                    Parameters,
                                    CompositeParticleLine<displaced_di_muon_line_t, Parameters> {
    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);
    __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle, float>);
    void init();
    static void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context);
    __device__ static void monitor(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::CompositeParticle, float> input,
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
    // Dimuon track pt.
    Property<minDispTrackPt_t> m_minDispTrackPt {this, 500.f / Gaudi::Units::MeV};
    Property<maxVertexChi2_t> m_maxVertexChi2 {this, 6.f};
    // Displaced dimuon selections.
    Property<dispMinIPChi2_t> m_dispMinIPChi2 {this, 6.f};
    Property<dispMinEta_t> m_dispMinEta {this, 2.f};
    Property<dispMaxEta_t> m_dispMaxEta {this, 5.f};
    Property<minZ_t> m_minZ {this, -341.f * Gaudi::Units::mm};
    Property<maxChi2Muon_t> m_minChi2Muon {this, 1.8};

    Property<histogram_mass_min_t> m_histogramMassMin {this, 215.f};
    Property<histogram_mass_max_t> m_histogramMassMax {this, 7000.f};
    Property<histogram_mass_nbins_t> m_histogramMassNBins {this, 295u};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};

#ifndef ALLEN_STANDALONE
    gaudi_monitoring::Lockable_Histogram<>* histogram_displaced_dimuon_mass;
#endif
  };
} // namespace displaced_di_muon_line
