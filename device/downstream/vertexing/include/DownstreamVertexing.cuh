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
#include "NeuralNetwork.cuh"

// Local
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"

namespace downstream_vertexing {
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // Size of downstream tracks
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    // Downstream tracks
    DEVICE_INPUT(dev_multi_event_downstream_track_particles_view_t, Allen::Views::Physics::MultiEventBasicParticles)
    dev_multi_event_downstream_track_particles_view;
    // Output
    DEVICE_OUTPUT(dev_downstream_secondary_vertices_t, VertexFit::MiniVertex) dev_downstream_secondary_vertices;
    DEVICE_OUTPUT(dev_offsets_downstream_secondary_vertices_t, unsigned) dev_offsets_downstream_secondary_vertices;
    HOST_OUTPUT(host_number_of_downstream_secondary_vertices_t, unsigned) host_number_of_downstream_secondary_vertices;
    // Property
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    // Cuts
    PROPERTY(track_min_pt_both_t, "track_min_pt_both", "Minimum track pT required for both tracks.", float)
    track_min_pt_both;
    PROPERTY(track_min_pt_either_t, "track_min_pt_either", "Minimum track pT required for at least one track.", float)
    track_min_pt_either;
    PROPERTY(track_min_ip_both_t, "track_min_ip_both", "Minimum track IP required for both tracks.", float)
    track_min_ip_both;
    PROPERTY(track_min_ip_either_t, "track_min_ip_either", "Minimum track IP required for at least one track.", float)
    track_min_ip_either;
    PROPERTY(sum_pt_min_t, "sum_pt_min", "Minimum sum of track pT.", float) sum_pt_min;
    PROPERTY(doca_max_t, "doca_max", "Maximum DOCA between tracks.", float) doca_max;
    PROPERTY(min_vtx_z_t, "min_vtx_z", "Minimum z position of the vertex.", float) min_vtx_z;
    PROPERTY(max_vtx_z_t, "max_vtx_z", "Maximum z position of the vertex.", float) max_vtx_z;
    PROPERTY(min_quality_t, "min_quality", "Minimum MVA quality score.", float) min_quality;
    PROPERTY(dihadron_t, "dihadron", "Filter leptons", bool) dihadron;
  };

  __global__ void
  downstream_vertexing(Parameters, const float*, const Allen::NeuralNetwork::Model::DownstreaCompositeQuality*);

  struct downstream_vertexing_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{16, 4, 1}}};
    // Cuts
    Property<track_min_pt_both_t> m_minpt_both {this, 136.1f * Gaudi::Units::MeV};
    Property<track_min_pt_either_t> m_minpt_either {this, 277.1f * Gaudi::Units::MeV};
    Property<track_min_ip_both_t> m_minip_both {this, 64.7f * Gaudi::Units::mm};
    Property<track_min_ip_either_t> m_minip_either {this, 64.7f * Gaudi::Units::mm};
    Property<sum_pt_min_t> m_minsumpt {this, 471.8f * Gaudi::Units::MeV};
    Property<doca_max_t> m_maxdoca {this, 19.1f * Gaudi::Units::mm};
    Property<min_vtx_z_t> m_min_vtx_z {this, 54.5f * Gaudi::Units::mm};
    Property<max_vtx_z_t> m_max_vtx_z {this, 2484.6f * Gaudi::Units::mm};
    Property<min_quality_t> m_min_quality {this, 0.1};
    Property<dihadron_t> m_dihadron {this, true};
  };
} // namespace downstream_vertexing