#include "SequenceVisitor.cuh"
#include "UTDecodeRawBanksInOrder.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(ut_decode_raw_banks_in_order_t)

template<>
void SequenceVisitor::visit<ut_decode_raw_banks_in_order_t>(
  ut_decode_raw_banks_in_order_t& state,
  const ut_decode_raw_banks_in_order_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0], UT::Constants::n_layers), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_ut_raw_input>(),
    arguments.offset<dev_ut_raw_input_offsets>(),
    arguments.offset<dev_event_list>(),
    constants.dev_ut_boards.data(),
    constants.dev_ut_geometry.data(),
    constants.dev_ut_region_offsets.data(),
    constants.dev_unique_x_sector_layer_offsets.data(),
    arguments.offset<dev_ut_hit_offsets>(),
    arguments.offset<dev_ut_hits>(),
    arguments.offset<dev_ut_hit_permutations>());

  state.invoke();
}
