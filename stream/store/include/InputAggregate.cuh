/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <gsl/gsl>
#include <vector>
#include <cstring>
#include <unordered_map>
#include "BackendCommon.h"
#include "Logger.h"
#include "AllenTypeTraits.h"
#include "ArgumentData.cuh"

namespace Allen::Store {

  /**
   * @brief Aggregate datatype
   */
  template<typename T>
  struct InputAggregate {
  private:
    std::vector<std::reference_wrapper<ArgumentData>> m_argument_data_v;

  public:
    using type = T;

    InputAggregate() = default;

    InputAggregate(const std::vector<std::reference_wrapper<ArgumentData>>& argument_data_v) :
      m_argument_data_v(argument_data_v)
    {}

    template<typename Tuple, std::size_t... Is>
    InputAggregate(Tuple t, std::index_sequence<Is...>) : m_argument_data_v {std::get<Is>(t)...}
    {}

    T* data(const unsigned index) const
    {
      assert(index < m_argument_data_v.size() && "Index is in bounds");
      auto pointer = m_argument_data_v[index].get().pointer();
      return reinterpret_cast<T*>(pointer);
    }

    T first(const unsigned index) const
    {
      assert(index < m_argument_data_v.size() && "Index is in bounds");
      return data(index)[0];
    }

    size_t size(const unsigned index) const
    {
      assert(index < m_argument_data_v.size() && "Index is in bounds");
      return m_argument_data_v[index].get().size();
    }

    gsl::span<T> span(const unsigned index) const { return {data(index), size(index)}; }

    std::string name(const unsigned index) const
    {
      assert(index < m_argument_data_v.size() && "Index is in bounds");
      return m_argument_data_v[index].get().name();
    }

    size_t size_of_aggregate() const { return m_argument_data_v.size(); }
  };

  template<typename T, typename... Ts>
  static auto makeInputAggregate(std::tuple<Ts&...> tp)
  {
    return InputAggregate<T> {tp, std::make_index_sequence<sizeof...(Ts)>()};
  }

// Macro
#define INPUT_AGGREGATE(HOST_DEVICE, ARGUMENT_NAME, ...)                                                           \
  struct ARGUMENT_NAME : public Allen::Store::aggregate_datatype, HOST_DEVICE {                                    \
    using type = Allen::Store::InputAggregate<__VA_ARGS__>;                                                        \
    void parameter(__VA_ARGS__) const;                                                                             \
    ARGUMENT_NAME() = default;                                                                                     \
    ARGUMENT_NAME(const type& input_aggregate) : m_value(input_aggregate) {}                                       \
    template<typename... Ts>                                                                                       \
    ARGUMENT_NAME(std::tuple<Ts&...> value) : m_value(Allen::Store::makeInputAggregate<__VA_ARGS__, Ts...>(value)) \
    {}                                                                                                             \
    const type& value() const { return m_value; }                                                                  \
                                                                                                                   \
  private:                                                                                                         \
    type m_value {};                                                                                               \
  }

#define HOST_INPUT_AGGREGATE(ARGUMENT_NAME, ...) \
  INPUT_AGGREGATE(Allen::Store::host_datatype, ARGUMENT_NAME, __VA_ARGS__)

#define DEVICE_INPUT_AGGREGATE(ARGUMENT_NAME, ...) \
  INPUT_AGGREGATE(Allen::Store::device_datatype, ARGUMENT_NAME, __VA_ARGS__)

} // namespace Allen::Store
