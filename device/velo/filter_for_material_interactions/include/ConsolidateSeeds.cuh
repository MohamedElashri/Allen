/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "patPV_Definitions.cuh"
#include "VeloConsolidated.cuh"

namespace consolidate_seeds {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_total_number_of_seeds_t, unsigned) host_total_number_of_seeds;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_track_view;
    DEVICE_INPUT(dev_interaction_seeds_t, PatPV::XYZPoint) dev_interaction_seeds;
    DEVICE_INPUT(dev_number_of_seeds_t, unsigned) dev_number_of_seeds;
    DEVICE_INPUT(dev_interaction_seeds_offsets_t, unsigned) dev_interaction_seeds_offsets;

    DEVICE_OUTPUT(dev_consolidated_interaction_seeds_t, PatPV::XYZPoint) dev_consolidated_interaction_seeds;

    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim_x;
  };

  __global__ void consolidate_seeds(Parameters);

  struct consolidate_seeds_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 64};
  };

} // namespace consolidate_seeds
