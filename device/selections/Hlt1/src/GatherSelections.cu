/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "GatherSelections.cuh"
#include "SelectionsEventModel.cuh"
#include "DeterministicScaler.cuh"
#include "Event/ODIN.h"
#include <algorithm>

// Helper traits to traverse dev_input_selections_t
template<typename Arguments, typename Tuple>
struct TupleTraits {
  constexpr static unsigned i = 0;

  constexpr static unsigned get_size(Arguments&) { return 0; }

  template<typename AssignType>
  static void populate_event_offsets(const Arguments& arguments)
  {
    data<AssignType>(arguments)[i] = 0;
  }

  template<typename OffsetsType, typename AssignType, typename Stream>
  static void populate_selections(const Arguments&, Stream&)
  {}

  template<typename AssignType, typename NumberOfEvents, typename Stream>
  static void populate_selection_offsets(const Arguments&, Stream&)
  {}

  template<typename AssignType, typename Stream>
  static void populate_scalars(const Arguments&, Stream&)
  {}
};

template<typename Arguments, typename T, typename... R>
struct TupleTraits<Arguments, std::tuple<T, R...>> {
  constexpr static unsigned i = TupleTraits<Arguments, std::tuple<R...>>::i + 1;

  constexpr static unsigned get_size(Arguments& arguments)
  {
    return TupleTraits<Arguments, std::tuple<R...>>::get_size(arguments) + size<T>(arguments);
  }

  template<typename AssignType>
  static void populate_event_offsets(const Arguments& arguments)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_event_offsets<AssignType>(arguments);
    data<AssignType>(arguments)[i] = data<AssignType>(arguments)[i - 1] + size<T>(arguments);
  }

  template<typename OffsetsType, typename AssignType, typename Stream>
  static void populate_selections(const Arguments& arguments, Stream& stream)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_selections<OffsetsType, AssignType>(arguments, stream);
    copy<AssignType, T>(arguments, size<T>(arguments), stream, data<OffsetsType>(arguments)[i - 1], 0);
  }

  template<typename AssignType, typename NumberOfEvents, typename Stream>
  static void populate_selection_offsets(const Arguments& arguments, Stream& stream)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_selection_offsets<AssignType, NumberOfEvents, Stream>(
      arguments, stream);
    copy<AssignType, T>(arguments, size<T>(arguments), stream, first<NumberOfEvents>(arguments) * (i - 1), 0);

    // There should be as many elements as number of events
    assert(first<NumberOfEvents>(arguments) == size<T>(arguments));
  }

  template<typename AssignType, typename Stream>
  static void populate_scalars(const Arguments& arguments, Stream& stream)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_scalars<AssignType>(arguments, stream);
    copy<AssignType, T>(arguments, size<T>(arguments), stream, i - 1, 0);
  }
};

namespace gather_selections {
  __global__ void postscaler(
    bool* dev_selections,
    const unsigned* dev_selections_offsets,
    const char* dev_odin_raw_input,
    const unsigned* dev_odin_raw_input_offsets,
    const float* scale_factors,
    const uint32_t* scale_hashes,
    const uint32_t* dev_mep_layout,
    const unsigned number_of_lines)
  {
    const auto number_of_events = gridDim.x;
    const auto event_number = blockIdx.x;

    Selections::Selections sels {dev_selections, dev_selections_offsets, number_of_events};

    const unsigned int* odin = *dev_mep_layout ?
      odin_data_mep_t::data(dev_odin_raw_input, dev_odin_raw_input_offsets, event_number) :
      odin_data_t::data(dev_odin_raw_input, dev_odin_raw_input_offsets, event_number);

    const uint32_t run_no = odin[LHCb::ODIN::Data::RunNumber];
    const uint32_t evt_hi = odin[LHCb::ODIN::Data::L0EventIDHi];
    const uint32_t evt_lo = odin[LHCb::ODIN::Data::L0EventIDLo];
    const uint32_t gps_hi = odin[LHCb::ODIN::Data::GPSTimeHi];
    const uint32_t gps_lo = odin[LHCb::ODIN::Data::GPSTimeLo];

    for (unsigned i = threadIdx.x; i < number_of_lines; i += blockDim.x) {
      auto span = sels.get_span(i, event_number);
      deterministic_post_scaler(
        scale_hashes[i],
        scale_factors[i],
        span.size(),
        span.data(),
        run_no,
        evt_hi,
        evt_lo,
        gps_hi,
        gps_lo);
    }
  }
} // namespace gather_selections

void gather_selections::gather_selections_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_number_of_active_lines_t>(arguments, 1);
  set_size<dev_number_of_active_lines_t>(arguments, 1);
  set_size<host_names_of_active_lines_t>(arguments, std::string(property<names_of_active_lines_t>().get()).size());
  set_size<host_selections_lines_offsets_t>(arguments, std::tuple_size<dev_input_selections_t::type>::value + 1);
  set_size<host_selections_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * std::tuple_size<dev_input_selections_t::type>::value + 1);
  set_size<dev_selections_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * std::tuple_size<dev_input_selections_t::type>::value + 1);
  set_size<dev_selections_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, dev_input_selections_t::type>::get_size(arguments));
  set_size<host_post_scale_factors_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, host_input_post_scale_factors_t::type>::get_size(arguments));
  set_size<host_post_scale_hashes_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, host_input_post_scale_hashes_t::type>::get_size(arguments));
  set_size<dev_post_scale_factors_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, host_input_post_scale_factors_t::type>::get_size(arguments));
  set_size<dev_post_scale_hashes_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, host_input_post_scale_hashes_t::type>::get_size(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "Sizes of gather_selections datatypes: " << size<host_selections_offsets_t>(arguments) << ", "
              << size<host_selections_lines_offsets_t>(arguments) << ", " << size<dev_selections_offsets_t>(arguments)
              << ", " << size<dev_selections_t>(arguments) << "\n";
  }
}

void gather_selections::gather_selections_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t& event) const
{
  // Save the names of active lines as output
  const auto line_names = std::string(property<names_of_active_lines_t>());
  line_names.copy(data<host_names_of_active_lines_t>(arguments), line_names.size());

  // Pass the number of lines for posterior algorithms
  data<host_number_of_active_lines_t>(arguments)[0] = std::tuple_size<dev_input_selections_t::type>::value;
  copy<dev_number_of_active_lines_t, host_number_of_active_lines_t>(arguments, stream);

  // Calculate prefix sum of dev_input_selections_t sizes into host_selections_lines_offsets_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<dev_input_selections_t::type>::t>::
    template populate_event_offsets<host_selections_lines_offsets_t>(arguments);

  // Populate dev_selections_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<dev_input_selections_t::type>::t>::
    template populate_selections<host_selections_lines_offsets_t, dev_selections_t>(arguments, stream);

  // Copy dev_input_selections_offsets_t onto host_selections_lines_offsets_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<dev_input_selections_offsets_t::type>::t>::
    template populate_selection_offsets<host_selections_offsets_t, host_number_of_events_t>(arguments, stream);

  // Populate host_post_scale_factors_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<host_input_post_scale_factors_t::type>::t>::
    template populate_scalars<host_post_scale_factors_t>(arguments, stream);

  // Populate host_post_scale_hashes_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<host_input_post_scale_hashes_t::type>::t>::
    template populate_scalars<host_post_scale_hashes_t>(arguments, stream);

  // Copy host_post_scale_factors_t to dev_post_scale_factors_t,
  // and host_post_scale_hashes_t to dev_post_scale_hashes_t
  copy<dev_post_scale_factors_t, host_post_scale_factors_t>(arguments, stream);
  copy<dev_post_scale_hashes_t, host_post_scale_hashes_t>(arguments, stream);

  // Synchronize
  cudaEventRecord(event, stream);
  cudaEventSynchronize(event);

  // Add partial sums from host_selections_lines_offsets_t to host_selections_offsets_t
  for (unsigned line_index = 1; line_index < first<host_number_of_active_lines_t>(arguments); ++line_index) {
    const auto line_offset = data<host_selections_lines_offsets_t>(arguments)[line_index];
    for (unsigned i = 0; i < first<host_number_of_events_t>(arguments); ++i) {
      data<host_selections_offsets_t>(arguments)[line_index * first<host_number_of_events_t>(arguments) + i] +=
        line_offset;
    }
  }

  // Add to last element the total sum
  data<host_selections_offsets_t>(
    arguments)[first<host_number_of_active_lines_t>(arguments) * first<host_number_of_events_t>(arguments)] =
    data<host_selections_lines_offsets_t>(arguments)[std::tuple_size<dev_input_selections_t::type>::value];

  // Copy host_selections_offsets_t onto dev_selections_offsets_t
  copy<dev_selections_offsets_t, host_selections_offsets_t>(arguments, stream);

  // Fetch the postscaler function depending on its layout
  // auto postscale_fn = first<dev_mep_layout_t>(arguments) ? global_function(postscaler<odin_data_mep_t>) :
  //                                                           global_function(postscaler<odin_data_t>);
  // Run the postscaler
  global_function(postscaler)(first<host_number_of_events_t>(arguments), property<block_dim_x_t>().get(), stream)(
    data<dev_selections_t>(arguments),
    data<dev_selections_offsets_t>(arguments),
    data<dev_odin_raw_input_t>(arguments),
    data<dev_odin_raw_input_offsets_t>(arguments),
    data<dev_post_scale_factors_t>(arguments),
    data<dev_post_scale_hashes_t>(arguments),
    data<dev_mep_layout_t>(arguments),
    first<host_number_of_active_lines_t>(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    std::vector<uint8_t> host_selections(size<dev_selections_t>(arguments));
    assign_to_host_buffer<dev_selections_t>(host_selections.data(), arguments, stream);
    copy<host_selections_offsets_t, dev_selections_offsets_t>(arguments, stream);

    Selections::ConstSelections sels {
      reinterpret_cast<bool*>(host_selections.data()),
      data<host_selections_offsets_t>(arguments),
      first<host_number_of_events_t>(arguments)};

    std::vector<uint8_t> event_decisions {};
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      bool dec = false;
      for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
        auto decs = sels.get_span(j, i);
        std::cout << "Size of span (event " << i << ", line " << j << "): " << decs.size() << "\n";
        for (auto k = 0u; k < decs.size(); ++k) {
          dec |= decs[k];
        }
      }
      event_decisions.emplace_back(dec);
    }

    const float sum_events = std::accumulate(event_decisions.begin(), event_decisions.end(), 0);
    std::cout << sum_events / event_decisions.size() << std::endl;

    const float sum = std::accumulate(host_selections.begin(), host_selections.end(), 0);
    std::cout << sum / host_selections.size() << std::endl;
  }

  // If running the validation, save relevant information
  if (runtime_options.do_check) {
    host_buffers.host_names_of_lines = std::string(property<names_of_active_lines_t>());
    host_buffers.host_number_of_lines = first<host_number_of_active_lines_t>(arguments);
    safe_assign_to_host_buffer<dev_selections_t>(host_buffers.host_selections, arguments, stream);
    safe_assign_to_host_buffer<dev_selections_offsets_t>(host_buffers.host_selections_offsets, arguments, stream);
  }
}
