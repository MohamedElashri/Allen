#include <CaloFindClusters.cuh>

__device__ void
add_to_cluster(uint16_t cellid, uint16_t cluster, uint16_t adc, CaloCluster* clusters, CaloGeometry const& geometry)
{
  // Find the cluster to add to.
  uint cur = 0;
  while (clusters[cur].center_id != cluster) {
    cur++;
  }
  // Add energy and position data.
  atomicAdd(&(clusters[cur].e), adc);
  atomicAdd(&(clusters[cur].x), adc * (geometry.getX(cellid) - clusters[cur].refX));
  atomicAdd(&(clusters[cur].y), adc * (geometry.getY(cellid) - clusters[cur].refY));
}

__device__ void fill_clusters(CaloDigit* digits, CaloCluster* clusters, CaloGeometry const& geometry)
{
  // Shift iteration count by one to account for local maxima being cluster iteration 0.
  for (int i = 1; i < CLUST_ITERATIONS + 1; i++) {
    // Loop over all Cells and update clusters.
    for (uint c = threadIdx.x; c < geometry.max_cellid; c += blockDim.x) {
      CaloDigit& digit = digits[c];
      // If it isn't already clustered.
      if (digit.clustered_at_iteration > i) {
        uint16_t* neighbors = &(geometry.neighbors[c * MAX_NEIGH]);
        int cur = 0;
        for (uint n = 0; n < MAX_NEIGH; n++) {
          // If it was clustered in a previous iteration
          if (digits[neighbors[n]].clustered_at_iteration < i) {
            uint16_t cluster = digits[neighbors[n]].clusters[0];
            int clust = 1;
            while (cluster != 0 && clust < MAX_CLUST) {
              bool exists = false;
              for (int k = 0; k < cur; k++) {
                if (digit.clusters[k] == cluster) {
                  exists = true;
                }
              }
              if (!exists) {
                digit.clustered_at_iteration = i;
                digit.clusters[cur] = cluster;
                cur++;
                add_to_cluster(c, cluster, digit.adc, clusters, geometry);
              }
              cluster = digits[neighbors[n]].clusters[clust];
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
}

void __device__ cluster_position(CaloCluster* clusters, const unsigned* offsets, unsigned const event_number)
{
  unsigned const num_clusters = offsets[event_number + 1] - offsets[event_number];
  for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
    CaloCluster* cluster = &clusters[offsets[event_number] + i];
    cluster->x = cluster->refX + (cluster->x / cluster->e);
    cluster->y = cluster->refY + (cluster->y / cluster->e);
  }
}

__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, ECAL_MAX_CELLID);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, HCAL_MAX_CELLID);

  // Ecal
  fill_clusters(
    &parameters.dev_ecal_digits[event_number * ecal_geometry.max_cellid],
    &parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number]],
    ecal_geometry);

  // Hcal
  fill_clusters(
    &parameters.dev_hcal_digits[event_number * hcal_geometry.max_cellid],
    &parameters.dev_hcal_clusters[parameters.dev_hcal_cluster_offsets[event_number]],
    hcal_geometry);

  __syncthreads();

  // Determine the final cluster positions.
  // Ecal
  cluster_position(parameters.dev_ecal_clusters, parameters.dev_ecal_cluster_offsets, event_number);
  // Hcal
  cluster_position(parameters.dev_hcal_clusters, parameters.dev_hcal_cluster_offsets, event_number);
}

__host__ void calo_find_clusters::calo_find_clusters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  // Find clusters.
  global_function(calo_find_clusters)(
    first<host_number_of_selected_events_t>(arguments), property<block_dim_x_t>().get(), cuda_stream)(
    arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
}
