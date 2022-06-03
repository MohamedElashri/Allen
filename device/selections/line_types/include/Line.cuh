/*****************************************************************************\
 * (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
 \*****************************************************************************/
#pragma once

#include <string>
#include <ArgumentOps.cuh>
#include <DeterministicScaler.cuh>
#include "Event/ODIN.h"
#include "ODINBank.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include <tuple>
#ifdef WITH_ROOT
#include <ROOTHeaders.h>
#include "ROOTService.h"
#endif

// Helper macro to explicitly instantiate lines
#define INSTANTIATE_LINE(DERIVED, PARAMETERS)                                                                  \
  template void Line<DERIVED, PARAMETERS>::operator()(                                                         \
      const ArgumentReferences<PARAMETERS>&,                                                                     \
      const RuntimeOptions&,                                                                                     \
      const Constants&,                                                                                          \
      HostBuffers&,                                                                                              \
      const Allen::Context&) const;                                                                              \
template __device__ void process_line<DERIVED, PARAMETERS>(                                                  \
    char*,                                                                                                     \
    bool*,                                                                                                     \
    unsigned*,                                                                                                 \
    Allen::IMultiEventContainer**,                                                                             \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned,                                                                                                  \
    unsigned);                                                                                                 \
template void line_output_monitor<DERIVED, PARAMETERS>(char*, const RuntimeOptions&, const Allen::Context&); \
INSTANTIATE_ALGORITHM(DERIVED)

// Type-erased line function type
using line_fn_t = void (*)(
    char*,
    bool*,
    unsigned*,
    Allen::IMultiEventContainer**,
    unsigned,
    unsigned,
    unsigned,
    unsigned,
    unsigned,
    unsigned);

template<typename Derived, typename Parameters>
using type_erased_tuple_t =
std::tuple<Parameters, size_t, unsigned, unsigned, ArgumentReferences<Parameters>, const Derived*>;

template<typename Derived, typename Parameters>
struct Line {
  private:
    uint32_t m_pre_scaler_hash;
    uint32_t m_post_scaler_hash;

    template <typename TupleType, typename FuncT, std::size_t... seq_t> 
      void for_each_internal( FuncT& f , std::integer_sequence<std::size_t, seq_t...> /*seq*/ ) const {
        ( f.template operator() < typename std::tuple_element<seq_t, TupleType>::type >(), ... );
      }
    template <typename FuncT, typename TupleType> 
      void for_each( FuncT& f ) const { 
        std::make_index_sequence< std::tuple_size< TupleType >::value > sequence;
        for_each_internal<TupleType>(f, sequence); 
      }

    // under C++20  - these can be converted to lambda functions - for now have to do 
    // lambdas the old fashioned way
    struct set_size_functor {
      set_size_functor( ArgumentReferences<Parameters>& arguments, std::size_t size ) : arguments(arguments), size(size) {}
      ArgumentReferences<Parameters>& arguments;
      std::size_t size; 
      template <typename f> void operator()(){ set_size<f>(arguments, size); }
    };

    struct initialize_functor {
      initialize_functor( const ArgumentReferences<Parameters>& arguments, const Allen::Context& context ) : 
        arguments(arguments), context(context) {}
      const ArgumentReferences<Parameters>& arguments;
      const Allen::Context& context; 
      template <typename f> void operator()(){ initialize<f>(arguments, -1, context); }
    };

  public:
    void init()
    {
      auto derived_instance = static_cast<const Derived*>(this);
      const std::string pre_scaler_hash_string =
        derived_instance->template property<typename Parameters::pre_scaler_hash_string_t>();
      const std::string post_scaler_hash_string =
        derived_instance->template property<typename Parameters::post_scaler_hash_string_t>();

      if (pre_scaler_hash_string.empty() || post_scaler_hash_string.empty()) {
        throw HashNotPopulatedException(derived_instance->name());
      }

      m_pre_scaler_hash = mixString(pre_scaler_hash_string.size(), pre_scaler_hash_string);
      m_post_scaler_hash = mixString(post_scaler_hash_string.size(), post_scaler_hash_string);
    }

    void operator()(
        const ArgumentReferences<Parameters>&,
        const RuntimeOptions&,
        const Constants&,
        HostBuffers&,
        const Allen::Context& context) const;

    /**
     * @brief Default monitor function.
     */
    void init_monitor(const ArgumentReferences<Parameters>& arguments, const Allen::Context& context) const { 
      if constexpr( Allen::has_monitoring_types<Derived>::value ) 
      {
        initialize_functor f(arguments, context);
        for_each<decltype(f), typename Derived::monitoring_types >( f );
      }
    }

    void set_arguments_size(
        ArgumentReferences<Parameters> arguments,
        const RuntimeOptions&,
        const Constants&,
        const HostBuffers&) const
    {
      set_size<typename Parameters::host_decisions_size_t>(arguments, 1);
      set_size<typename Parameters::host_post_scaler_t>(arguments, 1);
      set_size<typename Parameters::host_post_scaler_hash_t>(arguments, 1);

      // Set the size of the type-erased fn parameters
      set_size<typename Parameters::host_fn_parameters_t>(arguments, sizeof(type_erased_tuple_t<Derived, Parameters>));

      if constexpr( Allen::has_monitoring_types<Derived>::value ) 
      {
        set_size_functor ssf( arguments, Derived::get_decisions_size(arguments));
        for_each< set_size_functor, typename Derived::monitoring_types >( ssf ); 
      }
    }

    template<typename T>
      static __device__ void monitor(const Parameters&, T, unsigned, bool)
      {
      }

    template <std::size_t N, typename lv, typename rv> 
      void set_equal( lv& l, const rv& r, std::size_t index ) const 
      {
        std::get<N>(l) = std::get<N>(r)[index];
      }

    template <std::size_t N, typename ValueType> 
      void make_branch( handleROOTSvc& handler, TTree* tree, const ArgumentReferences<Parameters>& arguments, ValueType& values ) 
      const 
      {
        #ifdef WITH_ROOT 
        using TupleType = typename Derived::monitoring_types;  
        handler.branch( tree, name< typename std::tuple_element<N, TupleType>::type >(arguments), std::get<N>(values) );  
        #endif
      }
    template <std::size_t... seq_t> 
    void do_monitoring(const ArgumentReferences<Parameters>& arguments, handleROOTSvc& handler, std::integer_sequence<std::size_t, seq_t...> /*int_seq*/ )
      const
    {
    #ifdef WITH_ROOT
      using TupleType    = typename Derived::monitoring_types;  
      auto host_v   = std::tuple{ make_vector< typename std::tuple_element<seq_t, TupleType>::type >(arguments)  ...  };   
      auto values   = std::tuple{ typename std::tuple_element<seq_t, TupleType>::type::type() ... };
      size_t ev = 0; 
      auto tree = handler.tree("monitor_tree");
      if (tree == nullptr) return;
      ( make_branch<seq_t>( handler, tree, arguments, values ), ... );  
      handler.branch(tree, "ev"     , ev);
      auto i0  = tree->GetEntries();  
      for( unsigned i = 0 ; i != std::get<0>(host_v).size(); ++i )
      {
        if( std::get<0>(host_v)[i] != -1 ) 
        {
          ( set_equal<seq_t>(values, host_v, i),   ... );
          ev = i0 + i;
          tree->Fill();
        }
      }
    #endif
    }

    void output_monitor(const ArgumentReferences<Parameters>& arguments, const RuntimeOptions& runtime_options, const Allen::Context&) const {
      if constexpr( Allen::has_monitoring_types<Derived>::value ) 
      {
#ifdef WITH_ROOT
        std::make_index_sequence< std::tuple_size< typename Derived::monitoring_types >::value > sequence;
        auto derived_instance = static_cast<const Derived*>(this);
        auto handler = runtime_options.root_service->handle(derived_instance->name());
        do_monitoring(arguments, handler, sequence); 
#endif
      } 
    }
};

  template<typename Derived, typename Parameters>
void line_output_monitor(char* input, const RuntimeOptions& runtime_options, const Allen::Context& context)
{
  if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
    const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
    auto derived_instance = std::get<5>(type_casted_input);
    derived_instance->output_monitor(std::get<4>(type_casted_input), runtime_options, context);
  }
}

  template<typename Derived, typename Parameters>
__device__ void process_line(
    char* input,
    bool* decisions,
    unsigned* decisions_offsets,
    Allen::IMultiEventContainer** particle_container_ptr,
    unsigned run_no,
    unsigned evt_hi,
    unsigned evt_lo,
    unsigned gps_hi,
    unsigned gps_lo,
    unsigned line_offset)
{
  const auto& type_casted_input = *reinterpret_cast<type_erased_tuple_t<Derived, Parameters>*>(input);
  const auto& parameters = std::get<0>(type_casted_input);
  const auto event_list_size = std::get<1>(type_casted_input);
  const auto number_of_events = std::get<2>(type_casted_input);
  const auto event_number = blockIdx.x;

  // Check if blockIdx.x (event_number) is in dev_event_list
  unsigned mask = 0;
  for (unsigned i = 0; i < (event_list_size + warp_size - 1) / warp_size; ++i) {
    const auto index = i * warp_size + threadIdx.x;
    mask |=
      __ballot_sync(0xFFFFFFFF, index < event_list_size ? event_number == parameters.dev_event_list[index] : false);
  }

  // Do initialization for all events, regardless of mask
  // * Populate offsets in first block
  if (blockIdx.x == 0) {
    for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
      decisions_offsets[i] = line_offset + Derived::offset(parameters, i);
    }
  }

  // * Populate IMultiEventContainer* if relevant
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    if constexpr (Allen::has_dev_particle_container<Derived, device_datatype, input_datatype>::value) {
      const auto ptr = static_cast<const Allen::IMultiEventContainer*>(parameters.dev_particle_container);
      *particle_container_ptr = const_cast<Allen::IMultiEventContainer*>(ptr);
    }
    else {
      *particle_container_ptr = nullptr;
    }
  }

  // * Populate decisions
  const auto pre_scaler_hash = std::get<3>(type_casted_input);
  const bool pre_scaler_result =
    deterministic_scaler(pre_scaler_hash, parameters.pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  const unsigned input_size = Derived::input_size(parameters, event_number);

  for (unsigned i = threadIdx.x; i < input_size; i += blockDim.x) {
    const auto input = Derived::get_input(parameters, event_number, i);
    const bool decision = mask > 0 && pre_scaler_result && Derived::select(parameters, input);
    unsigned index = Derived::offset(parameters, event_number) + i;
    decisions[index] = decision;
    if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
      if (parameters.enable_monitoring) {
        Derived::monitor(parameters, input, event_number, decision);
      }
    }
  }
}

template<typename Derived, typename Parameters>
void Line<Derived, Parameters>::operator()(
    const ArgumentReferences<Parameters>& arguments,
    const RuntimeOptions&,
    const Constants&,
    HostBuffers&,
    [[maybe_unused]] const Allen::Context& context) const
{
  const auto* derived_instance = static_cast<const Derived*>(this);

  // Copy post scaler and hash to an output, such that GatherSelections can later
  // perform the postscaling
  data<typename Parameters::host_post_scaler_t>(arguments)[0] =
    derived_instance->template property<typename Parameters::post_scaler_t>();
  data<typename Parameters::host_post_scaler_hash_t>(arguments)[0] = m_post_scaler_hash;
  data<typename Parameters::host_decisions_size_t>(arguments)[0] = Derived::get_decisions_size(arguments);

  // Delay the execution of the line: Pass the parameters
  auto parameters = std::make_tuple(
      derived_instance->make_parameters(1, 1, 0, arguments),
      size<typename Parameters::dev_event_list_t>(arguments),
      first<typename Parameters::host_number_of_events_t>(arguments),
      m_pre_scaler_hash,
      arguments,
      derived_instance);

  assert(sizeof(type_erased_tuple_t<Derived, Parameters>) == sizeof(parameters));
  std::memcpy(data<typename Parameters::host_fn_parameters_t>(arguments), &parameters, sizeof(parameters));

  if constexpr (Allen::has_enable_monitoring<Parameters>::value) {
    derived_instance->init_monitor(arguments, context);
  }
}


