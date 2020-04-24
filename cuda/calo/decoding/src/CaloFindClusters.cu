#include <CaloFindClusters.cuh>


__global__ void calo_find_clusters::calo_get_neighbors(
  calo_find_clusters::Parameters parameters,
  const uint number_of_events,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry,
  const uint number_of_ecal_hits,
  const uint number_of_hcal_hits)
{
  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);

  for (auto event_number = blockIdx.x * blockDim.x; event_number < number_of_events;
    event_number += blockDim.x * gridDim.x) {
 
    const auto selected_event_number = parameters.dev_event_list[event_number];

    // Ecal
    for (uint i = parameters.dev_ecal_hits_offsets[event_number * ECAL_BANKS] + threadIdx.x;
         i < parameters.dev_ecal_hits_offsets[(event_number + 1) * ECAL_BANKS]; i += blockDim.x) {
      CaloDigit& cur = parameters.dev_ecal_digits[i];
      uint16_t* neighbors = &(ecal_geometry.neighbors[cur.area() * AREA_SIZE +
        cur.row() * ROW_SIZE + cur.col() * MAX_NEIGH + i]);
      
      for (uint n = 0; n < MAX_NEIGH; n++) {
        if (neighbors[n] != 0) {
          for (uint k = parameters.dev_ecal_hits_offsets[event_number * ECAL_BANKS];
               k < parameters.dev_ecal_hits_offsets[(event_number + 1) * ECAL_BANKS]; k++) {
            if (neighbors[n] == parameters.dev_ecal_digits[k].cellID) {
              cur.neighbors[n] = &(parameters.dev_ecal_digits[k]);
              break;
            }
          }
        }
      }
    }
  }
}


__global__ void calo_find_clusters::calo_find_local_maxima(
    calo_find_clusters::Parameters parameters,
    const uint number_of_events)
  {
  
  
  }


__global__ void calo_find_clusters::calo_find_clusters(
calo_find_clusters::Parameters parameters,
const uint number_of_events)
{


}