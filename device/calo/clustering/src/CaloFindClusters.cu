#include <CaloConstants.cuh>
#include <CaloCluster.cuh>
#include <CaloFindClusters.cuh>

__device__ void add_to_cluster(uint16_t cellid, uint16_t cluster, uint16_t adc,
  CaloSeedCluster const* seed_clusters, CaloCluster* clusters, CaloGeometry const& geometry) {
  // Find the cluster to add to.
  uint cur = 0;
  while (clusters[cur].center_id != cluster) {
    cur++;
  }
  // Add energy and position data.
  atomicAdd(&(clusters[cur].e), adc);
  atomicAdd(&(clusters[cur].x), adc * (geometry.getX(cellid) - seed_clusters[cur].x));
  atomicAdd(&(clusters[cur].y), adc * (geometry.getY(cellid) - seed_clusters[cur].y));
}

__device__ void init_clusters(CaloDigit const* digits,
                              CaloSeedCluster const* seed_clusters,
                              CaloDigitClusters* digit_clusters,
                              unsigned const num_clusters, unsigned const max_cellid) {
  for (unsigned c = threadIdx.x; c < num_clusters; c += blockDim.x) {
    auto const cellid = seed_clusters[c].id;
    digit_clusters[cellid].clusters[0] = cellid;
  }

  for (unsigned d = threadIdx.x; d < max_cellid; d += blockDim.x) {
    if (digits[d].adc != 0xffff) {
      digit_clusters[d].clustered_at_iteration = Calo::Constants::unclustered;
    }
  }
}

__device__ void find_clusters(CaloDigit const* digits, CaloSeedCluster const* seed_clusters,
                              CaloDigitClusters* digits_clusters, CaloCluster* clusters,
                              CaloGeometry const& geometry, unsigned const iterations)
{
  // Shift iteration count by one to account for local maxima being cluster iteration 0.
  for (unsigned i = 1; i < iterations + 1; i++) {
    // Loop over all Cells and update clusters.
    for (uint c = threadIdx.x; c < geometry.max_cellid; c += blockDim.x) {
      CaloDigitClusters& digit_clusters = digits_clusters[c];
      // If it isn't already clustered.
      if (digit_clusters.clustered_at_iteration > i) {
        uint16_t* neighbors = &(geometry.neighbors[c * Calo::Constants::max_neighbours]);
        int cur = 0;
        for (uint n = 0; n < Calo::Constants::max_neighbours; n++) {
          // If it was clustered in a previous iteration
          if (digits_clusters[neighbors[n]].clustered_at_iteration < i) {
            uint16_t cluster = digits_clusters[neighbors[n]].clusters[0];
            int clust = 1;
            while(cluster != 0 && clust < Calo::Constants::digit_max_clusters) {
              bool exists = false;
              for (int k = 0; k < cur; k++) {
                if (digit_clusters.clusters[k] == cluster) {
                  exists = true;
                }
              }
              if (!exists) {
                digit_clusters.clustered_at_iteration = i;
                digit_clusters.clusters[cur] = cluster;
                cur++;
                add_to_cluster(c, cluster, digits[c].adc, seed_clusters, clusters, geometry);
              }
              cluster = digits_clusters[neighbors[n]].clusters[clust];
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

void __device__ cluster_position(CaloSeedCluster const* seed_clusters, CaloCluster* clusters,
                                 unsigned const num_clusters) {
  for (uint i = threadIdx.x; i < num_clusters; i += blockDim.x) {
    CaloSeedCluster const& seed_cluster = seed_clusters[i];
    CaloCluster& cluster = clusters[i];
    cluster.x = seed_cluster.x + (cluster.x / cluster.e);
    cluster.y = seed_cluster.x + (cluster.y / cluster.e);
  }
}

__global__ void calo_find_clusters::calo_find_clusters(
  calo_find_clusters::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry,
  const unsigned iterations)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, Calo::Constants::ecal_max_cellid);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, Calo::Constants::hcal_max_cellid);

  unsigned const event_number = blockIdx.x;

  // Initialize digit clusters from seed clusters
  // Ecal
  unsigned const ecal_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const ecal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_offset;
  init_clusters(parameters.dev_ecal_digits + (event_number * ecal_geometry.max_cellid),
                parameters.dev_ecal_seed_clusters + ecal_offset,
                parameters.dev_ecal_digits_clusters + (event_number * ecal_geometry.max_cellid),
                ecal_num_clusters, ecal_geometry.max_cellid);
  // Hcal
  unsigned const hcal_offset = parameters.dev_ecal_cluster_offsets[event_number];
  unsigned const hcal_num_clusters = parameters.dev_ecal_cluster_offsets[event_number + 1] - ecal_offset;
  init_clusters(&parameters.dev_hcal_digits[event_number * hcal_geometry.max_cellid],
                &parameters.dev_hcal_seed_clusters[hcal_offset],
                &parameters.dev_hcal_digits_clusters[event_number * hcal_geometry.max_cellid],
                hcal_num_clusters, hcal_geometry.max_cellid);

  __syncthreads();

  // Find clusters
  // Ecal
  find_clusters(&parameters.dev_ecal_digits[event_number * ecal_geometry.max_cellid],
                &parameters.dev_ecal_seed_clusters[ecal_offset],
                &parameters.dev_ecal_digits_clusters[event_number * ecal_geometry.max_cellid],
                &parameters.dev_ecal_clusters[ecal_offset],
                ecal_geometry, iterations);

  // Hcal
  find_clusters(&parameters.dev_hcal_digits[event_number * hcal_geometry.max_cellid],
                &parameters.dev_hcal_seed_clusters[hcal_offset],
                &parameters.dev_hcal_digits_clusters[event_number * hcal_geometry.max_cellid],
                &parameters.dev_hcal_clusters[hcal_offset],
                hcal_geometry, iterations);

  __syncthreads();

  // Determine the final cluster positions.
  // Ecal
  cluster_position(&parameters.dev_ecal_seed_clusters[ecal_offset],
                   &parameters.dev_ecal_clusters[ecal_offset], ecal_num_clusters);
  // Hcal
  cluster_position(&parameters.dev_hcal_seed_clusters[hcal_offset],
                   &parameters.dev_hcal_clusters[hcal_offset], hcal_num_clusters);
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
    first<host_number_of_selected_events_t>(arguments), property<block_dim_x_t>(), cuda_stream)(
    arguments,
    constants.dev_ecal_geometry,
    constants.dev_hcal_geometry,
    property<iterations_t>().get());
}
