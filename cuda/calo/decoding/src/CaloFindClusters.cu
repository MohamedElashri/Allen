#include <CaloFindClusters.cuh>


__global__ void calo_find_clusters::calo_find_local_maxima(
  calo_find_clusters::Parameters parameters,
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
      for (uint i = threadIdx.x; i < MAX_CELLID; i += blockDim.x) {
        uint16_t adc = parameters.dev_ecal_digits[event_number * MAX_CELLID + i].adc;
        if (adc == 0) {
          continue;
        }
        uint16_t* neighbors = &(ecal_geometry.neighbors[CaloDigit::area(i) * AREA_SIZE +
        CaloDigit::row(i) * ROW_SIZE + CaloDigit::col(i) * MAX_NEIGH]);
        bool is_max = true;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          is_max = adc > parameters.dev_ecal_digits[event_number * MAX_CELLID + neighbors[n]].adc;
        }
        if (is_max) {
          parameters.dev_ecal_digits[event_number * MAX_CELLID + i].clusters[0] = i;
        }
      }

      // Hcal
      // Loop over all CellIDs.
      for (uint i = threadIdx.x; i < MAX_CELLID; i += blockDim.x) {
        uint16_t adc = parameters.dev_hcal_digits[event_number * MAX_CELLID + i].adc;
        if (adc == 0) {
          continue;
        }
        uint16_t* neighbors = &(hcal_geometry.neighbors[CaloDigit::area(i) * AREA_SIZE +
        CaloDigit::row(i) * ROW_SIZE + CaloDigit::col(i) * MAX_NEIGH]);
        bool is_max = true;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          is_max = adc > parameters.dev_hcal_digits[event_number * MAX_CELLID + neighbors[n]].adc;
        }
        if (is_max) {
          parameters.dev_hcal_digits[event_number * MAX_CELLID + i].clusters[0] = i;
        }
      }
    }
  }


__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
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
    for (int i = 0; i < CLUST_ITERATIONS; i++) {
      // Loop over all Cells and update clusters.
      for (uint c = threadIdx.x; c < MAX_CELLID; c += blockDim.x) {
        CaloDigit* digit = &parameters.dev_ecal_digits[event_number * MAX_CELLID + c];
        // If it is already clustered.
        if (digit->clusters[0] != 0) {
          continue;
        }
        uint16_t* neighbors = &(ecal_geometry.neighbors[CaloDigit::area(c) * AREA_SIZE +
        CaloDigit::row(c) * ROW_SIZE + CaloDigit::col(c) * MAX_NEIGH]);
        int cur = 0;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          uint16_t cluster = parameters.dev_ecal_digits[event_number * MAX_CELLID + neighbors[n]].clusters[0];
          if(cluster != 0) {
            bool exists = false;
            for (int k = 0; k < cur; k++) {
              if (digit->clusters[k] == cluster) {
                exists = true;
              }
            }
            if (!exists) {
              digit->clusters[cur] = cluster;
              cur++;
            }
          }
        }
      }
    }

    // Hcal
    for (int i = 0; i < CLUST_ITERATIONS; i++) {
      // Loop over all Cells and update clusters.
      for (uint c = threadIdx.x; c < MAX_CELLID; c += blockDim.x) {
        CaloDigit* digit = &parameters.dev_hcal_digits[event_number * MAX_CELLID + c];
        // If it is already clustered.
        if (digit->clusters[0] != 0) {
          continue;
        }
        uint16_t* neighbors = &(hcal_geometry.neighbors[CaloDigit::area(c) * AREA_SIZE +
        CaloDigit::row(c) * ROW_SIZE + CaloDigit::col(c) * MAX_NEIGH]);
        int cur = 0;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          uint16_t cluster = parameters.dev_hcal_digits[event_number * MAX_CELLID + neighbors[n]].clusters[0];
          if(cluster != 0) {
            bool exists = false;
            for (int k = 0; k < cur; k++) {
              if (digit->clusters[k] == cluster) {
                exists = true;
              }
            }
            if (!exists) {
              digit->clusters[cur] = cluster;
              cur++;
            }
          }
        }
      }
    }
  }
}