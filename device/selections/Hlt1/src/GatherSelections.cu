#include "GatherSelections.cuh"

// Helper traits to traverse dev_input_selections_t
template<typename Arguments, typename Tuple>
struct TupleTraits {
  constexpr static unsigned i = 0;

  constexpr static unsigned get_size(Arguments&) { return 0; }

  template<typename AssignType>
  static void populate_offsets(const Arguments& arguments)
  {
    data<AssignType>(arguments)[i] = 0;
  }

  template<typename OffsetsType, typename AssignType, typename Stream>
  static void populate_selections(const Arguments&, Stream&)
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
  static void populate_offsets(const Arguments& arguments)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_offsets<AssignType>(arguments);
    data<AssignType>(arguments)[i] = data<AssignType>(arguments)[i - 1] + size<T>(arguments);
  }

  template<typename OffsetsType, typename AssignType, typename Stream>
  static void populate_selections(const Arguments& arguments, Stream& stream)
  {
    TupleTraits<Arguments, std::tuple<R...>>::template populate_selections<OffsetsType, AssignType>(arguments, stream);
    copy<AssignType, T>(arguments, size<T>(arguments), stream, data<OffsetsType>(arguments)[i - 1], 0);
  }
};

void gather_selections::gather_selections_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_selections_offsets_t>(arguments, std::tuple_size<dev_input_selections_t::type>::value + 1);
  set_size<dev_selections_offsets_t>(arguments, std::tuple_size<dev_input_selections_t::type>::value + 1);
  set_size<dev_selections_t>(
    arguments, TupleTraits<ArgumentReferences<Parameters>, dev_input_selections_t::type>::get_size(arguments));

  // printf("Sizes: %lu, %u\n",
  //   std::tuple_size<dev_input_selections_t::type>::value + 1,
  //   TupleTraits<ArgumentReferences<Parameters>, dev_input_selections_t::type>::get_size(arguments));
}

void gather_selections::gather_selections_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  // Calculate offsets in host_selections_offsets_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<dev_input_selections_t::type>::t>::template populate_offsets<
    host_selections_offsets_t>(arguments);

  // Copy host_selections_offsets_t onto dev_selections_offsets_t
  copy<dev_selections_offsets_t, host_selections_offsets_t>(arguments, stream);

  // Populate dev_selections_t
  TupleTraits<ArgumentReferences<Parameters>, TupleReverse<dev_input_selections_t::type>::t>::
    template populate_selections<host_selections_offsets_t, dev_selections_t>(arguments, stream);
}
