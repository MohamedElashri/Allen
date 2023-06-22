/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "GatherSelections.cuh"
#include "SelectionsEventModel.cuh"
#include "DeterministicScaler.cuh"
#include <algorithm>
#include "ExternLines.cuh"
#include <string>
#include <sstream>
#include <vector>
#include <iterator>

INSTANTIATE_ALGORITHM(gather_selections::gather_selections_t)

template<typename Out>
void split(const std::string& s, char delim, Out result)
{
  std::istringstream iss(s);
  std::string item;
  while (std::getline(iss, item, delim)) {
    *result++ = item;
  }
}

std::vector<std::string> split(const std::string& s, char delim)
{
  std::vector<std::string> elems;
  split(s, delim, std::back_inserter(elems));
  return elems;
}

namespace gather_selections {
  __global__ void
  run_lines(gather_selections::Parameters params, const unsigned number_of_events, const unsigned number_of_lines)
  {
    // Process each event with a different block
    // ODIN data
    LHCb::ODIN odin {params.dev_odin_data[blockIdx.x]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    for (unsigned i = threadIdx.y; i < number_of_lines; i += blockDim.y) {
      invoke_line_functions(
        params.dev_fn_indices[i],
        params.dev_fn_parameter_pointers[i],
        params.dev_selections + params.dev_selections_lines_offsets[i],
        params.dev_selections_offsets + i * number_of_events,
        params.dev_particle_containers + i,
        run_no,
        evt_hi,
        evt_lo,
        gps_hi,
        gps_lo,
        params.dev_selections_lines_offsets[i],
        number_of_events);
    }

    if (blockIdx.x == 0 && threadIdx.x == 0 && threadIdx.y == 0) {
      params.dev_selections_offsets[number_of_lines * number_of_events] =
        params.dev_selections_lines_offsets[number_of_lines];
    }
  }

  __global__ void postscaler(
    gather_selections::Parameters params,
    const unsigned number_of_lines,
    bool* dev_decisions_per_event_line,
    bool* dev_postscaled_decisions_per_event_line,
    unsigned* dev_histo_line_passes,
    unsigned* dev_histo_line_rates)
  {
    const auto number_of_events = gridDim.x;
    const auto event_number = blockIdx.x;

    __shared__ int event_decision;

    if (threadIdx.x == 0) {
      // Initialize event decision
      event_decision = false;
    }

    __syncthreads();

    Selections::Selections sels {params.dev_selections, params.dev_selections_offsets, number_of_events};

    LHCb::ODIN odin {params.dev_odin_data[event_number]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    for (unsigned i = threadIdx.x; i < number_of_lines; i += blockDim.x) {
      auto span = sels.get_span(i, event_number);

      for (unsigned j = 0; j < span.size(); ++j) {
        if (span[j]) {
          dev_decisions_per_event_line[event_number * number_of_lines + i] = true;
          dev_histo_line_passes[i]++;
          break;
        }
      }

      deterministic_post_scaler(
        params.dev_post_scale_hashes[i],
        params.dev_post_scale_factors[i],
        span.size(),
        span.data(),
        run_no,
        evt_hi,
        evt_lo,
        gps_hi,
        gps_lo);

      for (unsigned j = 0; j < span.size(); ++j) {
        if (span[j]) {
          dev_postscaled_decisions_per_event_line[event_number * number_of_lines + i] = true;
          dev_histo_line_rates[i]++;
          event_decision = true;
          break;
        }
      }
    }

    __syncthreads();

    if (threadIdx.x == 0 && event_decision) {
      const auto index = atomicAdd(params.dev_event_list_output_size.data(), 1);
      params.dev_event_list_output[index] = mask_t {event_number};
    }
  }
} // namespace gather_selections

void gather_selections::gather_selections_t::init()
{
  const auto names_of_active_line_algorithms = split(property<names_of_active_line_algorithms_t>().get(), ',');
  for (const auto& name : names_of_active_line_algorithms) {
    const auto it = std::find(std::begin(line_strings), std::end(line_strings), name);
    m_indices_active_line_algorithms.push_back(it - std::begin(line_strings));
  }
#ifndef ALLEN_STANDALONE
  const auto line_names = std::string(property<names_of_active_lines_t>());
  std::istringstream is(line_names);
  std::string line_name;
  std::vector<std::string> line_labels;
  while (std::getline(is, line_name, ',')) {
    const std::string pass_counter_name {line_name + "Pass"};
    const std::string rate_counter_name {line_name + "Rate"};
    m_pass_counters.push_back(std::make_unique<Gaudi::Accumulators::Counter<>>(this, pass_counter_name));
    m_rate_counters.push_back(std::make_unique<Gaudi::Accumulators::Counter<>>(this, rate_counter_name));
    line_labels.push_back(line_name);
  }
  float n_lines = line_labels.size();

  histogram_line_passes = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "line_passes", "line passes", {unsigned(n_lines), 0, n_lines, {}, line_labels}}, {}};
  histogram_line_rates = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "line_rates", "line rates", {unsigned(n_lines), 0, n_lines, {}, line_labels}}, {}};
#endif
}

void gather_selections::gather_selections_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Sum all the sizes from input selections
  const auto host_fn_parameters_agg = input_aggregate<host_fn_parameters_agg_t>(arguments);
  const auto total_size_host_fn_parameters_agg = [&host_fn_parameters_agg]() {
    size_t total_size = 0;
    for (size_t i = 0; i < host_fn_parameters_agg.size_of_aggregate(); ++i) {
      total_size += host_fn_parameters_agg.size(i);
    }
    return total_size;
  }();

  const auto host_decisions_sizes = input_aggregate<host_decisions_sizes_t>(arguments);
  const auto total_size_host_decisions_sizes = [&host_decisions_sizes]() {
    unsigned sum = 0;
    for (unsigned i = 0; i < host_decisions_sizes.size_of_aggregate(); ++i) {
      sum += (host_decisions_sizes.size(i) > 0) ? host_decisions_sizes.first(i) : 0;
    }
    return sum;
  }();

  const auto size_of_aggregates = input_aggregate<host_decisions_sizes_t>(arguments).size_of_aggregate();

  assert(input_aggregate<host_input_post_scale_factors_t>(arguments).size_of_aggregate() == size_of_aggregates);
  assert(input_aggregate<host_input_post_scale_hashes_t>(arguments).size_of_aggregate() == size_of_aggregates);
  assert(m_indices_active_line_algorithms.size() == size_of_aggregates);

  set_size<host_number_of_active_lines_t>(arguments, 1);
  set_size<dev_number_of_active_lines_t>(arguments, 1);
  set_size<host_names_of_active_lines_t>(arguments, std::string(property<names_of_active_lines_t>().get()).size() + 1);
  set_size<host_selections_lines_offsets_t>(arguments, size_of_aggregates + 1);
  set_size<dev_selections_lines_offsets_t>(arguments, size_of_aggregates + 1);
  set_size<host_selections_offsets_t>(arguments, first<host_number_of_events_t>(arguments) * size_of_aggregates + 1);
  set_size<dev_selections_offsets_t>(arguments, first<host_number_of_events_t>(arguments) * size_of_aggregates + 1);
  set_size<dev_selections_t>(arguments, total_size_host_decisions_sizes);
  set_size<host_post_scale_factors_t>(arguments, size_of_aggregates);
  set_size<host_post_scale_hashes_t>(arguments, size_of_aggregates);
  set_size<dev_post_scale_factors_t>(arguments, size_of_aggregates);
  set_size<dev_post_scale_hashes_t>(arguments, size_of_aggregates);
  set_size<dev_particle_containers_t>(arguments, size_of_aggregates);
  set_size<host_fn_parameters_t>(arguments, total_size_host_fn_parameters_agg);
  set_size<dev_fn_parameters_t>(arguments, total_size_host_fn_parameters_agg);
  set_size<host_fn_parameter_pointers_t>(arguments, size_of_aggregates);
  set_size<dev_fn_parameter_pointers_t>(arguments, size_of_aggregates);
  set_size<host_fn_indices_t>(arguments, size_of_aggregates);
  set_size<dev_fn_indices_t>(arguments, size_of_aggregates);
  set_size<host_event_list_output_size_t>(arguments, 1);
  set_size<dev_event_list_output_size_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, first<host_number_of_events_t>(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "Sizes of gather_selections datatypes: " << size<host_selections_offsets_t>(arguments) << ", "
              << size<host_selections_lines_offsets_t>(arguments) << ", " << size<dev_selections_offsets_t>(arguments)
              << ", " << size<dev_selections_t>(arguments) << "\n";
  }
}

void gather_selections::gather_selections_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  [[maybe_unused]] const Constants& constants,
  const Allen::Context& context) const
{
  // Run the selection algorithms
  // * Aggregate parameter fns
  Allen::aggregate::store_contiguous_async<host_fn_parameters_t, host_fn_parameters_agg_t>(arguments, context);
  Allen::copy_async<dev_fn_parameters_t, host_fn_parameters_t>(arguments, context);

  // * Prepare pointers to parameters
  unsigned accumulated_offset_params = 0;
  const auto host_fn_parameters_agg = input_aggregate<host_fn_parameters_agg_t>(arguments);
  for (unsigned i = 0; i < host_fn_parameters_agg.size_of_aggregate(); ++i) {
    if (host_fn_parameters_agg.size(i) == 0) {
      data<host_fn_parameter_pointers_t>(arguments)[i] = nullptr;
    }
    else {
      data<host_fn_parameter_pointers_t>(arguments)[i] =
        data<dev_fn_parameters_t>(arguments) + accumulated_offset_params;
      accumulated_offset_params += host_fn_parameters_agg.size(i);
    }
  }
  Allen::copy_async<dev_fn_parameter_pointers_t, host_fn_parameter_pointers_t>(arguments, context);

  // * Pass the number of lines for posterior algorithms
  const auto host_decisions_sizes = input_aggregate<host_decisions_sizes_t>(arguments);
  data<host_number_of_active_lines_t>(arguments)[0] = host_decisions_sizes.size_of_aggregate();
  Allen::copy_async<dev_number_of_active_lines_t, host_number_of_active_lines_t>(arguments, context);

  // * Calculate prefix sum of host_decisions_sizes_t sizes into host_selections_lines_offsets_t
  auto* container = data<host_selections_lines_offsets_t>(arguments);
  container[0] = 0;
  for (size_t i = 0; i < host_decisions_sizes.size_of_aggregate(); ++i) {
    container[i + 1] = container[i] + (host_decisions_sizes.size(i) ? host_decisions_sizes.first(i) : 0);
  }
  Allen::copy_async<dev_selections_lines_offsets_t, host_selections_lines_offsets_t>(arguments, context);

  // * Prepare dev_fn_indices_t, containing all fn indices
  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    data<host_fn_indices_t>(arguments)[i] = m_indices_active_line_algorithms[i];
  }
  Allen::copy_async<dev_fn_indices_t, host_fn_indices_t>(arguments, context);

  // * Run all selections in one go
  global_function(gather_selections::run_lines)(
    first<host_number_of_events_t>(arguments), dim3(warp_size, 256 / warp_size), context)(
    arguments, first<host_number_of_events_t>(arguments), first<host_number_of_active_lines_t>(arguments));

  // Run monitoring if configured
  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    line_output_monitor_functions[m_indices_active_line_algorithms[i]](
      host_fn_parameters_agg.data(i), runtime_options, context);
  }

  // Save the names of active lines as output
  Allen::memset_async<host_names_of_active_lines_t>(arguments, 0, context);
  const auto line_names = std::string(property<names_of_active_lines_t>());
  line_names.copy(data<host_names_of_active_lines_t>(arguments), line_names.size());

  // Populate host_post_scale_factors_t
  Allen::aggregate::store_contiguous_async<host_post_scale_factors_t, host_input_post_scale_factors_t>(
    arguments, context, true);

  // Populate host_post_scale_hashes_t
  Allen::aggregate::store_contiguous_async<host_post_scale_hashes_t, host_input_post_scale_hashes_t>(
    arguments, context, true);

  // Copy host_post_scale_factors_t to dev_post_scale_factors_t,
  // and host_post_scale_hashes_t to dev_post_scale_hashes_t
  Allen::copy_async<dev_post_scale_factors_t, host_post_scale_factors_t>(arguments, context);
  Allen::copy_async<dev_post_scale_hashes_t, host_post_scale_hashes_t>(arguments, context);

  // Initialize output mask size
  Allen::memset_async<dev_event_list_output_size_t>(arguments, 0, context);

  auto dev_decisions_per_event_line = make_device_buffer<bool>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
  auto dev_postscaled_decisions_per_event_line = make_device_buffer<bool>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
  Allen::memset_async(dev_decisions_per_event_line.data(), 0, dev_decisions_per_event_line.size_bytes(), context);
  Allen::memset_async(
    dev_postscaled_decisions_per_event_line.data(), 0, dev_decisions_per_event_line.size_bytes(), context);

  auto dev_histo_line_passes = make_device_buffer<unsigned>(arguments, first<host_number_of_active_lines_t>(arguments));
  auto dev_histo_line_rates = make_device_buffer<unsigned>(arguments, first<host_number_of_active_lines_t>(arguments));
  Allen::memset_async(dev_histo_line_passes.data(), 0, dev_histo_line_passes.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_histo_line_rates.data(), 0, dev_histo_line_rates.size() * sizeof(unsigned), context);

  // Run the postscaler
  global_function(postscaler)(first<host_number_of_events_t>(arguments), property<block_dim_x_t>().get(), context)(
    arguments,
    first<host_number_of_active_lines_t>(arguments),
    dev_decisions_per_event_line.data(),
    dev_postscaled_decisions_per_event_line.data(),
    dev_histo_line_passes.data(),
    dev_histo_line_rates.data());

#ifndef ALLEN_STANDALONE
  // Monitoring
  auto host_histo_line_passes = make_host_buffer<unsigned>(arguments, first<host_number_of_active_lines_t>(arguments));
  auto host_histo_line_rates = make_host_buffer<unsigned>(arguments, first<host_number_of_active_lines_t>(arguments));
  Allen::copy_async(host_histo_line_passes.get(), dev_histo_line_passes.get(), context, Allen::memcpyDeviceToHost);
  Allen::copy_async(host_histo_line_rates.get(), dev_histo_line_rates.get(), context, Allen::memcpyDeviceToHost);
  Allen::synchronize(context);

  for (unsigned i = 0; i < first<host_number_of_active_lines_t>(arguments); i++) {
    m_pass_counters[i]->buffer() += host_histo_line_passes[i];
    m_rate_counters[i]->buffer() += host_histo_line_rates[i];
  }

  gaudi_monitoring::details::fill_gaudi_histogram(
    host_histo_line_passes.get(), histogram_line_passes, 0u, first<host_number_of_active_lines_t>(arguments));
  gaudi_monitoring::details::fill_gaudi_histogram(
    host_histo_line_rates.get(), histogram_line_rates, 0u, first<host_number_of_active_lines_t>(arguments));
#endif

  // Reduce output mask to its proper size
  Allen::copy<host_event_list_output_size_t, dev_event_list_output_size_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_event_list_output_size_t>(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    const auto host_selections = make_host_buffer<dev_selections_t>(arguments, context);
    Allen::copy<host_selections_offsets_t, dev_selections_offsets_t>(arguments, context);

    Selections::ConstSelections sels {reinterpret_cast<const bool*>(host_selections.data()),
                                      data<host_selections_offsets_t>(arguments),
                                      first<host_number_of_events_t>(arguments)};

    std::vector<uint8_t> event_decisions {};
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      bool dec = false;
      for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
        auto decs = sels.get_span(j, i);
        bool span_decision = false;
        for (auto k = 0u; k < decs.size(); ++k) {
          dec |= decs[k];
          span_decision |= decs[k];
        }
        std::cout << "Span (event " << i << ", line " << j << "), size " << decs.size()
                  << ", decision: " << span_decision << "\n";
      }
      event_decisions.emplace_back(dec);
    }

    const float sum_events = std::accumulate(event_decisions.begin(), event_decisions.end(), 0);
    std::cout << sum_events / event_decisions.size() << std::endl;

    const float sum = std::accumulate(host_selections.begin(), host_selections.end(), 0);
    std::cout << sum / host_selections.size() << std::endl;
  }
}
