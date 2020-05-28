#include <CaloFindLocalMaxima.cuh>

__device__ void local_maxima(CaloDigit* digits, unsigned* num_clusters, const CaloGeometry& geometry)
{
  // Loop over all CellIDs.
  for (uint i = threadIdx.x; i < geometry.max_cellid; i += blockDim.x) {
    uint16_t adc = digits[i].adc;
    if (adc == 0) {
      continue;
    }
    uint16_t* neighbors = &(geometry.neighbors[i * MAX_NEIGH]);
    bool is_max = true;
    for (uint n = 0; n < MAX_NEIGH; n++) {
      is_max = is_max && (adc > digits[neighbors[n]].adc);
    }
    if (is_max) {
      digits[i].clustered_at_iteration = 0;
      digits[i].clusters[0] = i;
      atomicAdd(num_clusters, 1);
    }
  }
}

__global__ void calo_find_local_maxima::calo_find_local_maxima(
  calo_find_local_maxima::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  const auto number_of_events = gridDim.x;
  const auto event_number = blockIdx.x;

  // Get proper geometry.
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry, ECAL_MAX_CELLID);
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry, HCAL_MAX_CELLID);

  // ECal
  local_maxima(
    parameters.dev_ecal_digits + (event_number * ecal_geometry.max_cellid),
    parameters.dev_ecal_num_clusters + event_number,
    ecal_geometry);

  // HCal
  local_maxima(
    parameters.dev_hcal_digits + (event_number * hcal_geometry.max_cellid),
    parameters.dev_hcal_num_clusters + event_number,
    hcal_geometry);
}

void calo_find_local_maxima::calo_find_local_maxima_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_num_clusters_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  set_size<dev_hcal_num_clusters_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

void calo_find_local_maxima::calo_find_local_maxima_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  initialize<dev_ecal_num_clusters_t>(arguments, 0, cuda_stream);
  initialize<dev_hcal_num_clusters_t>(arguments, 0, cuda_stream);

  // Find local maxima.
  global_function(calo_find_local_maxima)(
    first<host_number_of_selected_events_t>(arguments), property<block_dim_x_t>().get(), cuda_stream)(
    arguments,
    constants.dev_ecal_geometry,
    constants.dev_hcal_geometry);
}
