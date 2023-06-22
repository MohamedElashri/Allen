/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#ifndef ALLEN_STANDALONE

#include "Gaudi/Accumulators/Histogram.h"
#include <mutex>
#include <gsl/gsl>
#include "BackendCommon.h"
#include "ArgumentOps.cuh"

template<int I = 1, typename T = float>
using gaudi_histo_t = Gaudi::Accumulators::Histogram<I, Gaudi::Accumulators::atomicity::none, T>;

namespace gaudi_monitoring {
  template<int I = 1, typename T = float>
  struct Lockable_Histogram {
    gaudi_histo_t<I, T> m_h;
    std::mutex mtx;

    template<class Operation>
    auto call(Operation o) -> decltype(o(m_h))
    {
      std::lock_guard l(mtx);
      return o(m_h);
    }
  };

  template<int I = 1, typename T = float>
  Lockable_Histogram(gaudi_histo_t<I, T>)->Lockable_Histogram<I, T>;

  namespace details {
    template<typename Args, typename T>
    auto get_host_buffer(const Args& args, const Allen::Context& context, const T& buffer)
    {
      auto& dev_buffer_span = std::get<0>(buffer);
      auto host_buffer = Allen::ArgumentOperations::make_host_buffer<unsigned>(args, dev_buffer_span.size());
      Allen::copy_async(host_buffer.get(), dev_buffer_span, context, Allen::memcpyDeviceToHost);
      return host_buffer;
    }

    template<typename Args, std::size_t... Is, typename T>
    std::array<Allen::buffer<Allen::Store::Scope::Host, unsigned>, sizeof...(Is)>
    get_host_buffers(const Args& args, const Allen::Context& context, const T& buffers, std::index_sequence<Is...>)
    {
      if constexpr (std::is_same_v<std::tuple_element_t<1, T>, gaudi_monitoring::Lockable_Histogram<>*>) {
        return std::array<Allen::buffer<Allen::Store::Scope::Host, unsigned>, 1> {
          get_host_buffer(args, context, buffers)};
      }
      else {
        return {get_host_buffer(args, context, std::get<Is>(buffers))...};
      }
    }

    template<typename T>
    void fill_gaudi_counter(gsl::span<const unsigned> data, T counter)
    {
      assert(data.size() == 1);
      counter += data[0];
    }

    template<typename T, typename U, typename V>
    void fill_gaudi_histogram(gsl::span<const unsigned> data, T histo, U min, V max)
    {
      unsigned n_bins = data.size();
      float bin_size = float(max - min) / float(n_bins);
      float half_bin_size = bin_size / 2.f;
      histo->call([=](auto& locked_histo) {
        for (unsigned bin = 0; bin < n_bins; bin++) {
          if (data[bin] != 0) {
            float value = min + bin * bin_size +
                          half_bin_size; // use middle of bin for increment to not rely on floating point calculation
            locked_histo[value] += data[bin];
          }
        }
      });
    }

    template<typename T, typename U>
    void fill_dispatcher(const T& host_buffer, const U& buffer)
    {
      if constexpr (std::is_same_v<std::tuple_element_t<1, U>, gaudi_monitoring::Lockable_Histogram<>*>) {
        fill_gaudi_histogram(host_buffer, std::get<1>(buffer), std::get<2>(buffer), std::get<3>(buffer));
      }
      else {
        fill_gaudi_counter(host_buffer, std::get<1>(buffer));
      }
    }

    template<typename Ts, typename Us, std::size_t... Is>
    void fill_helper(const Ts& host_buffers, const Us& buffers, std::index_sequence<Is...>)
    {
      if constexpr (std::is_same_v<std::tuple_element_t<1, Us>, gaudi_monitoring::Lockable_Histogram<>*>) {
        fill_dispatcher(host_buffers[0].get(), buffers);
      }
      else {
        (fill_dispatcher(host_buffers[Is].get(), std::get<Is>(buffers)), ...);
      }
    }
  } // namespace details

  template<typename Args, typename T>
  void fill(const Args& args, const Allen::Context& context, T buffers)
  {
    const unsigned size = [&]() {
      unsigned size = std::tuple_size_v<T>;
      if constexpr (std::is_same_v<std::tuple_element_t<1, T>, gaudi_monitoring::Lockable_Histogram<>*>) {
        size = 1;
      }
      return size;
    }();
    constexpr auto index_sequence = std::make_index_sequence<size>();
    auto host_buffers = details::get_host_buffers(args, context, buffers, index_sequence);
    Allen::synchronize(context);
    details::fill_helper(std::move(host_buffers), buffers, index_sequence);
  }
} // namespace gaudi_monitoring
#endif
