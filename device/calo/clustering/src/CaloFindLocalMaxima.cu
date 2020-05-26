#include <CaloFindLocalMaxima.cuh>


__global__ void calo_find_local_maxima::calo_find_local_maxima(
  calo_find_local_maxima::Parameters parameters,
  const uint number_of_events,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
  {
    // Get proper geometry.
    auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
    auto hcal_geometry = CaloGeometry(raw_hcal_geometry);

    for (auto event_number = blockIdx.x * blockDim.x; event_number < number_of_events;
      event_number += blockDim.x * gridDim.x) {

      // Ecal
      // Loop over all CellIDs.
      for (uint i = threadIdx.x; i < ECAL_MAX_CELLID; i += blockDim.x) {
        uint16_t adc = parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + i].adc;
        if (adc == 0) {
          continue;
        }
        uint16_t* neighbors = &(ecal_geometry.neighbors[i * MAX_NEIGH]);
        bool is_max = true;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          is_max = is_max && (adc > parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + neighbors[n]].adc);
        }
        if (is_max) {
          parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + i].clustered_at_iteration = 0;
          parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + i].clusters[0] = i;
          atomicAdd(parameters.dev_ecal_num_clusters + event_number, 1);
        }
      }

      // Hcal
      // Loop over all CellIDs.
      for (uint i = threadIdx.x; i < HCAL_MAX_CELLID; i += blockDim.x) {
        uint16_t adc = parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + i].adc;
        if (adc == 0) {
          continue;
        }
        uint16_t* neighbors = &(hcal_geometry.neighbors[i * MAX_NEIGH]);
        bool is_max = true;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          is_max = is_max && adc > parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + neighbors[n]].adc;
        }
        if (is_max) {
          parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + i].clustered_at_iteration = 0;
          parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + i].clusters[0] = i;
          atomicAdd(parameters.dev_hcal_num_clusters + event_number, 1);
        }
      }
    }
  }