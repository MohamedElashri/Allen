#include <CaloSetClusterCenters.cuh>

__device__ void event_set_centers(CaloDigit const* digits, CaloCluster* clusters,
                                  unsigned num_clusters, CaloGeometry const& geometry)
{
    // Loop over all clusters in this event.
    for (unsigned i = threadIdx.x; i < num_clusters; i += blockDim.x) {
      // Find the right cluster center cell ID.
      unsigned count = i + 1;
      unsigned c = 1;
      while (count > 0) {
        if (digits[c].clusters[0] == c) {
          count--;
        }
        c++;
      }
      c--; // To counter the last c++;

      clusters[i] = CaloCluster(c, digits[c].adc, geometry.getX(c), geometry.getY(c));
    }
}

__device__ void set_centers(unsigned const event_number, CaloDigit const* digits, CaloCluster* clusters, const unsigned* cluster_offsets,
                            CaloGeometry const& geometry)
{
  unsigned num_clusters = cluster_offsets[event_number + 1] - cluster_offsets[event_number];
  event_set_centers(&digits[event_number * geometry.max_cellid],
                    &clusters[cluster_offsets[event_number]],
                    num_clusters, geometry);
}

__global__ void calo_set_cluster_centers::calo_set_cluster_centers(
  calo_set_cluster_centers::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, ECAL_MAX_CELLID);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, HCAL_MAX_CELLID);

  for (auto event_number = blockIdx.x * blockDim.x; event_number < number_of_events;
    event_number += blockDim.x * gridDim.x) {

    // Ecal
    set_centers(event_number, parameters.dev_ecal_digits, parameters.dev_ecal_clusters,
                parameters.dev_ecal_cluster_offsets, ecal_geometry);

    // Hcal
    set_centers(event_number, parameters.dev_hcal_digits, parameters.dev_hcal_clusters,
                parameters.dev_hcal_cluster_offsets, hcal_geometry);
  }
}

void calo_set_cluster_centers::calo_set_cluster_centers_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_clusters_t>(arguments, first<host_ecal_number_of_clusters_t>(arguments));
  set_size<dev_hcal_clusters_t>(arguments, first<host_hcal_number_of_clusters_t>(arguments));
}

void calo_set_cluster_centers::calo_set_cluster_centers_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  // Set cluster centers.
  global_function(calo_set_cluster_centers)(
    first<host_number_of_selected_events_t>(arguments), dim3(property<block_dim_x_t>().get()), cuda_stream)(
    arguments,
    constants.dev_ecal_geometry,
    constants.dev_hcal_geometry);
}
