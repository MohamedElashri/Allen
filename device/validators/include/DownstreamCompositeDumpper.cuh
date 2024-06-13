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

#include "SciFiEventModel.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "CheckerTracks.cuh"
#include "CheckerInvoker.h"
#include "CompositeDumper.h"
#include "DumppingObjects.cuh"

namespace downstream_composite_dumper {
  struct Parameters {

    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // MC
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;

    // Extra info
    DEVICE_INPUT(dev_downstream_mva_ks_t, float) dev_downstream_mva_ks;
    DEVICE_INPUT(dev_downstream_mva_l0_t, float) dev_downstream_mva_l0;
    DEVICE_INPUT(dev_downstream_mva_detached_ks_t, float) dev_downstream_mva_detached_ks;
    DEVICE_INPUT(dev_downstream_mva_detached_l0_t, float) dev_downstream_mva_detached_l0;

    // vertexing output
    HOST_INPUT(host_number_of_vertices_t, unsigned) host_number_of_vertices;
    DEVICE_INPUT(dev_offset_vertices_t, unsigned) dev_offset_vertices;
    DEVICE_INPUT(dev_multi_event_composites_view_t, Allen::Views::Physics::MultiEventCompositeParticles)
    dev_multi_event_composites_view;

    // Output
    DEVICE_OUTPUT(dev_checker_composites_t, Checker::Composite) dev_checker_composites;
    DEVICE_OUTPUT(dev_dumpping_objects_t, Allen::DumppingObjects::DownstreamComposite) dev_dumpping_objects;

    // Property
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  // __global__ Checker::Track create_track_from_seed(const SciFi::Seeding::Track seed);
  __global__ void downstream_composite_dumper(Parameters parameters, const float*);

  struct downstream_composite_dumper_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<root_output_filename_t> m_root_output_filename {this, "CompositeDumpper.root"};
  };
} // namespace downstream_composite_dumper
