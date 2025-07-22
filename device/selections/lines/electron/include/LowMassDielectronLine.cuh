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
#include "ParKalmanFilter.cuh"
#include "ROOTService.h"
#include <ROOTHeaders.h>

#include "AllenMonitoring.h"

namespace lowmass_dielectron_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    DEVICE_INPUT(dev_electronid_evaluation_t, float) dev_electronid_evaluation;
    // Outputs
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;
    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    // Outputs for ROOT tupling
    DEVICE_OUTPUT(dev_die_masses_raw_t, float) dev_die_masses_raw;
    DEVICE_OUTPUT(dev_die_masses_bremcorr_t, float) dev_die_masses_bremcorr;
    DEVICE_OUTPUT(dev_die_pts_raw_t, float) dev_die_pts_raw;
    DEVICE_OUTPUT(dev_die_pts_bremcorr_t, float) dev_die_pts_bremcorr;
    DEVICE_OUTPUT(dev_e_minpts_raw_t, float) dev_e_minpts_raw;
    DEVICE_OUTPUT(dev_e_minpt_bremcorr_t, float) dev_e_minpt_bremcorr;
    DEVICE_OUTPUT(dev_die_minipchi2_t, float) dev_die_minipchi2;
    DEVICE_OUTPUT(dev_die_ip_t, float) dev_die_ip;
    DEVICE_OUTPUT(dev_electron_nn_t, float) dev_electron_nn;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

  struct lowmass_dielectron_line_t : public SelectionAlgorithm,
                                     Parameters,
                                     CompositeParticleLine<lowmass_dielectron_line_t, Parameters> {
    struct DeviceProperties {
      bool selectPrompt;
      float minMass;
      float maxMass;
      bool ss_on;
      float minZ;
      float trackIPChi2Threshold;
      float maxDOCA;
      float minPTprompt;
      float minPTdisplaced;
      float maxVtxChi2;
      float minDielectronPT;
      bool useNN;
      float nnCut;
      Allen::Monitoring::LogHistogram<>::DeviceType histogram_dielectron_masses;
      Allen::Monitoring::LogHistogram<>::DeviceType histogram_dielectron_masses_brem;
      DeviceProperties(const lowmass_dielectron_line_t& algo, const Allen::Context& ctx) :
        selectPrompt(algo.m_selectPrompt), minMass(algo.m_minMass), maxMass(algo.m_maxMass), ss_on(algo.m_ss_on),
        minZ(algo.m_minZ), trackIPChi2Threshold(algo.m_trackIPChi2Threshold), maxDOCA(algo.m_maxDOCA),
        minPTprompt(algo.m_minPTprompt), minPTdisplaced(algo.m_minPTdisplaced), maxVtxChi2(algo.m_maxVtxChi2),
        minDielectronPT(algo.m_minDielectronPT), useNN(algo.m_useNN), nnCut(algo.m_nnCut),
        histogram_dielectron_masses(algo.m_histogram_dielectron_masses.data(ctx)),
        histogram_dielectron_masses_brem(algo.m_histogram_dielectron_masses_brem.data(ctx))
      {}
    };

    __device__ static bool select(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned>);

    __device__ static std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned>
    get_input(const Parameters&, const unsigned, const unsigned);

    using monitoring_types = std::tuple<
      dev_die_masses_raw_t,
      dev_die_masses_bremcorr_t,
      dev_die_pts_raw_t,
      dev_die_pts_bremcorr_t,
      dev_e_minpts_raw_t,
      dev_e_minpt_bremcorr_t,
      dev_die_minipchi2_t,
      dev_die_ip_t,
      dev_electron_nn_t,
      evtNo_t,
      runNo_t>;

    __device__ static bool fill_tuples(
      const Parameters&,
      const DeviceProperties&,
      std::tuple<const Allen::Views::Physics::CompositeParticle, unsigned>,
      unsigned,
      bool);

  private:
    Allen::Property<bool> m_selectPrompt {this,
                                          "selectPrompt",
                                          true,
                                          "Use ipchi2 threshold as upper (prompt) or lower (displaced) bound"};
    Allen::Property<float> m_minMass {this, "MinMass", 5.f, "Min vertex mass"};
    Allen::Property<float> m_maxMass {this, "MaxMass", 300.f, "Max vertex mass"};
    Allen::Property<bool> m_ss_on {this, "ss_on", false, "Flag when same-sign candidates should be selected"};
    Allen::Property<float> m_minZ {this, "MinZ", -330.f * Allen::Units::mm, "Min z dielectron coordinate"};
    Allen::Property<float> m_trackIPChi2Threshold {
      this,
      "TrackIPChi2Threshold",
      2.0f,
      "Track IP Chi2 threshold"}; // threshold to split 'prompt' and 'displaced' candidates
    Allen::Property<float> m_maxDOCA {this, "MaxDOCA", 0.082f, "Max DOCA"};
    Allen::Property<float> m_minPTprompt {this, "MinPTprompt", 0.f, "Min PTprompt"};
    Allen::Property<float> m_minPTdisplaced {this, "MinPTdisplaced", 0.f, "Min PTdisplaced"};
    Allen::Property<float> m_maxVtxChi2 {this, "MaxVtxChi2", 7.4f, "Max vertex chi2"};
    Allen::Property<float> m_minDielectronPT {this, "MinDielectronPT", 1000.f, "Min dielectron PT"};
    Allen::Property<bool> m_useNN {this, "UseNN", false, "Use NN flag"};
    Allen::Property<float> m_nnCut {this, "NNCut", 0.7, "NN cut value"};

    Allen::Monitoring::LogHistogram<> m_histogram_dielectron_masses {
      this,
      "dielectron_mass_counts",
      "dielectron masses",
      {200u, 0.f, 1500.f, 0.22842211f, 14.59935056f, 1.f}};
    Allen::Monitoring::LogHistogram<> m_histogram_dielectron_masses_brem {
      this,
      "dielectron_mass_counts_brem",
      "dielectron masses with brem",
      {200u, 0.f, 1500.f, 0.22842211f, 14.59935056f, 1.f}};
  };
} // namespace lowmass_dielectron_line
