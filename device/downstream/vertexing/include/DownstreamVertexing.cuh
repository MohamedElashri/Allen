/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "VertexDefinitions.cuh"

// Event Model
#include "UTDefinitions.cuh"
#include "SingleLayerFCNN.cuh"

// Local
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"

namespace downstream_vertexing {

  using CompositeQualityEvaluator = Allen::MVAModels::SingleLayerFCNN<6, 32>;
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Size of downstream tracks
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    // Downstream tracks
    DEVICE_INPUT(dev_multi_event_downstream_track_particles_view_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_multi_event_downstream_track_particles_view;
    DEVICE_OUTPUT(dev_vertexing_buffer_t, uint8_t) dev_vertexing_buffer;
    // Output
    DEVICE_OUTPUT(dev_downstream_secondary_vertices_t, VertexFit::MiniVertex) dev_downstream_secondary_vertices;
    DEVICE_OUTPUT(dev_offsets_downstream_secondary_vertices_t, unsigned) dev_offsets_downstream_secondary_vertices;
    HOST_OUTPUT(host_number_of_downstream_secondary_vertices_t, unsigned) host_number_of_downstream_secondary_vertices;
  };

  template<bool same_sign_reco>
  __global__ void downstream_vertexing(
    Parameters,
    const float*,
    const CompositeQualityEvaluator::DeviceType*,
    const float track_min_pt_both,
    const float track_min_ip_both,
    const bool dihadron,
    const bool combined_container,
    const float track_min_ip_either,
    const float track_min_pt_either,
    const float sum_pt_min,
    const float doca_max,
    const float min_vtx_z,
    const float max_vtx_z,
    const float min_quality);

  struct downstream_vertexing_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {16, 4, 1}, "block dimensions"};
    // Cuts
    Allen::Property<float> m_minpt_both {this,
                                         "track_min_pt_both",
                                         136.1f * Allen::Units::MeV,
                                         "Minimum track pT required for both tracks."};
    Allen::Property<float> m_minpt_either {this,
                                           "track_min_pt_either",
                                           277.1f * Allen::Units::MeV,
                                           "Minimum track pT required for at least one track."};
    Allen::Property<float> m_minip_both {this,
                                         "track_min_ip_both",
                                         64.7f * Allen::Units::mm,
                                         "Minimum track IP required for both tracks."};
    Allen::Property<float> m_minip_either {this,
                                           "track_min_ip_either",
                                           64.7f * Allen::Units::mm,
                                           "Minimum track IP required for at least one track."};
    Allen::Property<float> m_minsumpt {this, "sum_pt_min", 471.8f * Allen::Units::MeV, "Minimum sum of track pT."};
    Allen::Property<float> m_maxdoca {this, "doca_max", 19.1f * Allen::Units::mm, "Maximum DOCA between tracks."};
    Allen::Property<float> m_min_vtx_z {this,
                                        "min_vtx_z",
                                        54.5f * Allen::Units::mm,
                                        "Minimum z position of the vertex."};
    Allen::Property<float> m_max_vtx_z {this,
                                        "max_vtx_z",
                                        2484.6f * Allen::Units::mm,
                                        "Maximum z position of the vertex."};
    Allen::Property<float> m_min_quality {this, "min_quality", 0.1, "Minimum MVA quality score."};
    Allen::Property<bool> m_dihadron {this, "dihadron", true, "Filter leptons"};
    Allen::Property<bool> m_combined_container {this, "combined_container", false, "Filter leptons"};
    Allen::Property<bool> m_same_sign_reco {this, "same_sign_reco", false, "Filter leptons"};

    CompositeQualityEvaluator composite_quality_nn {"composite_quality_nn",
                                                    "/HLT1Downstream/Hlt1_Downstream_Composite_Quality.json"};
  };
} // namespace downstream_vertexing
