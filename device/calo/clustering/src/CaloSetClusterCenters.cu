#include <CaloSetClusterCenters.cuh>

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

  // Ecal
  uint num_clusters =
    parameters.dev_ecal_cluster_offsets[event_number + 1] - parameters.dev_ecal_cluster_offsets[event_number];
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

    parameters.dev_ecal_clusters[parameters.dev_ecal_cluster_offsets[event_number] + i] = CaloCluster(
      c,
      parameters.dev_ecal_digits[event_number * ECAL_MAX_CELLID + c].adc,
      ecal_geometry.getX(c),
      ecal_geometry.getY(c));
  }

  // Hcal
  num_clusters =
    parameters.dev_hcal_cluster_offsets[event_number + 1] - parameters.dev_hcal_cluster_offsets[event_number];
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

    parameters.dev_hcal_clusters[parameters.dev_hcal_cluster_offsets[event_number] + i] = CaloCluster(
      c,
      parameters.dev_hcal_digits[event_number * HCAL_MAX_CELLID + c].adc,
      hcal_geometry.getX(c),
      hcal_geometry.getY(c));
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
