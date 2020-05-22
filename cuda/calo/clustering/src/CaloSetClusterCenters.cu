#include <CaloSetClusterCenters.cuh>

__global__ void calo_set_cluster_centers::calo_set_cluster_centers(
  calo_set_cluster_centers::Parameters parameters,
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
      uint num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - 
                          parameters.dev_ecal_cluster_offsets[event_number];
      // Loop over all clusters in this event.
      for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
        // Find the right cluster center cell ID.
        uint count = i + 1;
        uint c = 1;
        while (count > 0) {
          if (parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + c].clusters[0] == c) {
            count--;
          }
          c++;
        }
        c--; // To counter the last c++;

        parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number] + i] =
          CaloCluster(c, parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + c].adc,
          ecal_geometry.getX(c), ecal_geometry.getY(c));
      }

      // Hcal
      num_clusters = parameters.dev_hcal_cluster_offsets[event_number + 1] - 
                     parameters.dev_hcal_cluster_offsets[event_number];
      // Loop over all clusters in this event.
      for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
        // Find the right cluster center cell ID.
        uint count = i + 1;
        uint c = 1;
        while (count > 0) {
          if (parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + c].clusters[0] == c) {
            count--;
          }
          c++;
        }
        c--; // To counter the last c++;
        
        parameters.dev_hcal_clusters[parameters.dev_hcal_cluster_offsets[event_number] + i] =
          CaloCluster(c, parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + c].adc,
          hcal_geometry.getX(c), hcal_geometry.getY(c));
      }
    }
  }