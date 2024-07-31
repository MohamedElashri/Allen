/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
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
#include "CaloClusterLine.cuh"
#include "BackendCommon.h"
#include "JetDefinitions.cuh"
#include "ParticleTypes.cuh"

namespace cone_jet_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_jets_t, unsigned) host_number_of_jets;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventNeutralBasicParticles)
    dev_particle_container;

    HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
    HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char)
    host_fn_parameters;

    // For monitoring tuples.
    DEVICE_OUTPUT(jet_pt_t, float) jet_pt;
    DEVICE_OUTPUT(jet_eta_t, float) jet_eta;
    DEVICE_OUTPUT(jet_phi_t, float) jet_phi;
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_jet_pt_t, "min_jet_pt", "Minimum jet pT", float) min_jet_pt;
    PROPERTY(max_jet_pt_t, "max_jet_pt", "Maximum jet pT", float) max_jet_pt;
    PROPERTY(enable_tupling_t, "enable_tupling", "Enable line tupling", bool) enable_tupling;
  };

  struct cone_jet_line_t : public SelectionAlgorithm, Parameters, CaloClusterLine<cone_jet_line_t, Parameters> {

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle> input);

    __device__ static void fill_tuples(
      const Parameters& parameters,
      std::tuple<const Allen::Views::Physics::NeutralBasicParticle> input,
      unsigned index,
      bool sel);

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return arguments.template first<typename Parameters::host_number_of_jets_t>();
    }

    using monitoring_types = std::tuple<jet_pt_t, jet_eta_t, jet_phi_t, evtNo_t, runNo_t>;

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<min_jet_pt_t> m_min_jet_pt {this, 15.f * Gaudi::Units::GeV};
    Property<max_jet_pt_t> m_max_jet_pt {this, 1000.f * Gaudi::Units::GeV};
    Property<enable_tupling_t> m_enable_tupling {this, false};
  };

} // namespace cone_jet_line