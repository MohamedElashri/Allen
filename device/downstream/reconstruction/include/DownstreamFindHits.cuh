/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"

// Event Model
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamCache.cuh"

/**
 * @brief This is definition file for downstream_find_hits algorithm
 * implemented in downstream_find_hits.cu
 */
namespace downstream_find_hits {

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Matching input
    DEVICE_INPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used;

    // Scifi input
    DEVICE_INPUT(dev_offsets_seeding_t, unsigned) dev_offsets_seeding;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_seeding_qop_t, float) dev_seeding_qop;
    DEVICE_INPUT(dev_seeding_chi2Y_t, float) dev_seeding_chi2Y;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;

    // Hit caching memory - cache UT hits in global memory in case of it doesn't fit the shared memory
    DEVICE_OUTPUT(dev_hit_caching_memory_t, char) dev_hit_caching_memory;
    DEVICE_OUTPUT(dev_hit_caching_counter_t, unsigned) dev_hit_caching_counter;

    // Output table
    DEVICE_OUTPUT(dev_output_table_t, char) dev_output_table;
    DEVICE_OUTPUT(dev_num_row_output_table_t, unsigned) dev_num_row_output_table;

    // Output SciFi
    DEVICE_OUTPUT(dev_selected_scifi_t, unsigned) dev_selected_scifi;
    DEVICE_OUTPUT(dev_num_selected_scifi_t, unsigned) dev_num_selected_scifi;
    DEVICE_OUTPUT(dev_selected_scifi_offsets_t, unsigned) dev_selected_scifi_offsets;
    DEVICE_OUTPUT(dev_selected_scifi_qop_t, float) dev_selected_scifi_qop;     // for ghost killer
    DEVICE_OUTPUT(dev_selected_scifi_chi2Y_t, float) dev_selected_scifi_chi2Y; // for ghost killer

    // Block size
    PROPERTY(num_threads_scifi_t, "num_threads_scifi", "number of threads for SciFi", DeviceDimensions)
    num_threads_scifi;
    PROPERTY(num_threads_row_t, "num_threads_row", "number of threads for Row", DeviceDimensions) num_threads_row;
  };

  __global__ void downstream_create_output_table(Parameters, const unsigned*, const float*, const float*, const float*);

  __global__ void downstream_fill_output_table(Parameters, const unsigned*, const float*, const float*, const float*);

  struct downstream_find_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<num_threads_scifi_t> m_num_threads_scifi {this, {{128, 1, 1}}};
    Property<num_threads_row_t> m_num_threads_row {this, {{256, 1, 1}}};
  };

} // namespace downstream_find_hits
