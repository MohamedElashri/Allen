 #include "../include/FilterSvs.cuh"

 INSTANTIATE_ALGORITHM(FilterSvs::filter_svs_t)

void FilterSvs::filter_svs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_two_track_sv_track_pointers_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void FilterSvs::filter_svs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
  {

    global_function(filter_svs)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_filter_t>(), context)(
      arguments);
  }

  __global__ void FilterSvs::filter_svs(FilterSvs::Parameters parameters)
  {

    const unsigned event_number = parameters.dev_event_list[blockIdx.x];
    const unsigned number_of_events = parameters.dev_number_of_events[0];

    const auto composite_particles = parameters.dev_secondary_vertices->container(event_number);
    const unsigned n_svs = composite_particles.size();

    // unsigned* event_sv_number = parameters.dev_sv_atomics + event_number;
    // unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
    // unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;


   }
