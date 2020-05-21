#include <CaloFindClusters.cuh>

__host__ __device__ void add_to_cluster(uint start, uint16_t cellid, uint16_t cluster, uint16_t adc,
    CaloCluster* clusters, CaloGeometry geometry) {
  uint cur = start;
  while (clusters[cur].center_id != cluster) {
    cur++;
  }
  atomicAdd(&(clusters[cur].e), adc);
  atomicAdd(&(clusters[cur].x), adc * (geometry.xy[cellid * XY_SIZE] - clusters[cur].refX));
  atomicAdd(&(clusters[cur].y), adc * (geometry.xy[cellid * XY_SIZE + 1] - clusters[cur].refY));
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
    // Shift iteration count by one to account for local maxima being cluster iteration 0.
    for (int i = 1; i < CLUST_ITERATIONS + 1; i++) {
      // Loop over all Cells and update clusters.
      for (uint c = threadIdx.x; c < ECAL_MAX_CELLID; c += blockDim.x) {
        CaloDigit* digit = &parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + c];
        // If it isn't already clustered.
        if (digit->clustered_at_iteration > i) {
          uint16_t* neighbors = &(ecal_geometry.neighbors[c * MAX_NEIGH]);
          int cur = 0;
          for (uint n = 0; n < MAX_NEIGH; n++) {
            // If it was clustered in a previous iteration
            if (parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + neighbors[n]].clustered_at_iteration < i) {
              uint16_t cluster = parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + neighbors[n]].clusters[0];
              int clust = 1;
              while(cluster != 0 && clust < MAX_CLUST) {
                bool exists = false;
                for (int k = 0; k < cur; k++) {
                  if (digit->clusters[k] == cluster) {
                    exists = true;
                  }
                }
                if (!exists) {
                  digit->clustered_at_iteration = i;
                  digit->clusters[cur] = cluster;
                  cur++;
                  add_to_cluster(parameters.dev_ecal_cluster_offsets[event_number],
                                c, cluster, digit->adc, parameters.dev_ecal_clusters,
                                ecal_geometry);
                }
                cluster = parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + neighbors[n]].clusters[clust];
                clust++;
              }
            }
          }
          // if (cur > 10) {
          //   printf("final cur ECAL: %d\n", cur);
          // }
        }
      }
    }

    // Hcal
    // Shift iteration count by one to account for local maxima being cluster iteration 0.
    for (int i = 1; i < CLUST_ITERATIONS + 1; i++) {
      // Loop over all Cells and update clusters.
      for (uint c = threadIdx.x; c < HCAL_MAX_CELLID; c += blockDim.x) {
        CaloDigit* digit = &parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + c];
        // If it isn't already clustered.
        if (digit->clustered_at_iteration > i) {
          uint16_t* neighbors = &(hcal_geometry.neighbors[c * MAX_NEIGH]);
          int cur = 0;
          for (uint n = 0; n < MAX_NEIGH; n++) {
            // If it was clustered in a previous iteration
            if (parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + neighbors[n]].clustered_at_iteration < i) {
              uint16_t cluster = parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + neighbors[n]].clusters[0];
              int clust = 1;
              while(cluster != 0 && clust < MAX_CLUST) {
                bool exists = false;
                for (int k = 0; k < cur; k++) {
                  if (digit->clusters[k] == cluster) {
                    exists = true;
                  }
                }
                if (!exists) {
                  digit->clustered_at_iteration = i;
                  digit->clusters[cur] = cluster;
                  cur++;
                  add_to_cluster(parameters.dev_hcal_cluster_offsets[event_number],
                    c, cluster, digit->adc, parameters.dev_hcal_clusters,
                    hcal_geometry);
                }
                cluster = parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + neighbors[n]].clusters[clust];
                clust++;
              }
            }
          }
          // if (cur > 10) {
          //   printf("final cur HCAL: %d\n", cur);
          // }
        }
      }
    }

    __syncthreads();

    // Determine the final cluster positions.
    // Ecal
    uint num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - 
                          parameters.dev_ecal_cluster_offsets[event_number];
    for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
      CaloCluster* cluster = &parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number] + i];
      cluster->x = cluster->refX + (cluster->x / cluster->e);
      cluster->y = cluster->refY + (cluster->y / cluster->e);
      // printf("Ecal cluster - Center: %d, x: %f, y: %f, e: %d\n", cluster->center_id, cluster->x, cluster->y, cluster->e);
    }

    // Hcal
    num_clusters = parameters.dev_hcal_cluster_offsets[event_number + 1] - 
                          parameters.dev_hcal_cluster_offsets[event_number];
    for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
      CaloCluster* cluster = &parameters.dev_hcal_clusters[parameters.dev_hcal_cluster_offsets[event_number] + i];
      cluster->x = cluster->refX + (cluster->x / cluster->e);
      cluster->y = cluster->refY + (cluster->y / cluster->e);
      // printf("Hcal cluster - Center: %d, x: %f, y: %f, e: %d\n", cluster->center_id, cluster->x, cluster->y, cluster->e);
    }
  }
}