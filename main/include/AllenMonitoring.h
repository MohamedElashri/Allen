/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include <iostream>
#include <mutex>

#include <Algorithm.cuh>

#ifndef ALLEN_STANDALONE
#include "ServiceLocator.h"
#endif

namespace Allen::Monitoring {
  struct AccumulatorBase;

  template<typename T>
  struct Counter;

  template<typename T>
  struct AveragingCounter;

  struct AccumulatorInfosAndPointers {
    std::size_t offset {0};
    std::size_t size {0};
    std::size_t element_size {0};
    std::vector<AccumulatorBase*> owners;
  };

  struct CountersHistogram {

    CountersHistogram() : m_title("CountersHistogram"), m_bins(2, 0.0f) {}

    friend void reset(CountersHistogram& c)
    {
      std::fill(c.m_bins.begin(), c.m_bins.end(), 0.0f);
      c.m_totNEntries = 0.0;
    }

    friend void to_json(nlohmann::json& j, CountersHistogram const& h)
    {
      j = {{"type", "histogram:WeightedHistogram:d"},
           {"title", h.m_title},
           {"dimension", 1},
           {"empty", h.m_totNEntries == 0},
           {"nEntries", h.m_totNEntries},
           {"axis",
            {{{"nBins", h.m_bins.size() - 2},
              {"minValue", h.m_minValue},
              {"maxValue", h.m_maxValue},
              {"title", ""},
              {"labels", h.m_labels}}}},
           {"bins", h.m_bins}};
    }

    void registerHistogram()
    {

      // Handle warning if no counters are used in the sequence
      if (m_labels.size() == 0) {
        m_labels.push_back("empty_bin");
        m_maxValue++;
        m_bins.push_back(0.f);
      }

// Register CountersHistogram for Gaudi
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(
        "CountersHistogram", "CountersValues", "histogram:WeightedHistogram:d", *this);
#endif
    }

    void addCounter(std::string label)
    {
      m_labels.push_back(label);
      m_maxValue++;
      m_bins.push_back(0.f);
    }

    void addAvCounter(const std::string& label)
    {
      m_labels.insert(m_labels.end(), {label + "_sum", label + "_n_entries"});
      m_maxValue += 2;
      m_bins.insert(m_bins.end(), 2, 0.f);
    }

    void updateBin(int bin_index, float value) { m_bins[bin_index + 1] = value; }

    void resetHistogram()
    {
      m_bins = std::vector<float>(2, 0.f);
      m_labels = std::vector<std::string>();
      m_minValue = 0;
      m_maxValue = 0;
    }

    std::string m_title;
    std::vector<float> m_bins;
    int m_minValue = 0;
    int m_maxValue = 0;
    std::vector<std::string> m_labels;
    unsigned m_totNEntries = 0;
  };

  struct AccumulatorManager {
    static AccumulatorManager* get()
    {
      static AccumulatorManager instance;
      return &instance;
    }

    void registerAccumulator(AccumulatorBase* acc);
    void registerCounter(Counter<unsigned>* c) { m_counters.push_back(c); }
    void registerAveragingCounter(AveragingCounter<unsigned>* c) { m_av_counters.push_back(c); }
    void initAccumulators(unsigned number_of_streams);
    void mergeAndReset(bool singlethreaded = false);
    char* bufferForStream(unsigned stream_id) const { return m_dev_buffer_ptr[m_stream_current_buffer[stream_id]]; }
    void synchronizeStream(unsigned stream_id)
    {
      m_stream_done[stream_id] = false;
      m_stream_current_buffer[stream_id] = m_current_buffer;
    }
    void streamDone(unsigned stream_id) { m_stream_done[stream_id] = true; }
    std::mutex& getMutex() { return m_mutex; }

  private:
    std::mutex m_mutex; // used only for allen in gaudi (generated wrappers)

    char* m_dev_buffer_ptr[2] {nullptr, nullptr}; // double buffering
    char* m_host_buffer_ptr {nullptr};
    std::size_t m_buffer_size {0};

    unsigned m_current_buffer {0};
    std::vector<unsigned> m_stream_current_buffer;
    std::vector<bool> m_stream_done;

    CountersHistogram m_counters_histogram;

    std::vector<AccumulatorBase*> m_registered_accumulators;
    std::vector<Counter<unsigned>*> m_counters;
    std::vector<AveragingCounter<unsigned>*> m_av_counters;
    std::map<std::string, AccumulatorInfosAndPointers> m_accumulators;
  };

  struct AccumulatorBase {
    AccumulatorBase(const Allen::Algorithm* owner, std::string name) : m_owner(owner), m_name(name)
    {
      AccumulatorManager::get()->registerAccumulator(this);
    }
    virtual ~AccumulatorBase();
    std::string component() const { return m_owner->name(); }
    std::string name() const { return m_name; }
    std::string uniqueName() const { return m_owner->name() + ":" + m_name; }
    virtual std::size_t size() const { return 0; }
    virtual std::size_t elementSize() const { return 0; }
    virtual void registerAccumulator() {}
    virtual void fillAccumulator(void*) {}

    void setBufferInfos(const AccumulatorInfosAndPointers* infos) { m_buffer_infos = infos; }
    char* currentDevicePtr(unsigned stream_id) const
    {
      return AccumulatorManager::get()->bufferForStream(stream_id) + m_buffer_infos->offset;
    }

  private:
    const Allen::Algorithm* m_owner;
    std::string m_name;
    const AccumulatorInfosAndPointers* m_buffer_infos {nullptr};
  };

  // Counters:

  template<typename T = unsigned>
  struct DeviceCounter {
    __host__ __device__ DeviceCounter(T* data) : m_data(data) {}
    __device__ T* data() const { return m_data; }

#if defined(TARGET_DEVICE_CUDA) && defined(DEVICE_COMPILER)
    __device__ void increment() const
    {
      unsigned mask = __activemask();
      unsigned peers = mask;
      unsigned count = __popc(peers);
      int rank = __popc(peers & __lanemask_lt());
      bool is_leader = rank == 0;
      if (is_leader) {
        atomicAdd(&m_data[0], count);
      }
    }
#else
    __device__ void increment() const { __atomic_add_fetch(&m_data[0], 1, __ATOMIC_RELAXED); }
#endif

  private:
    T* m_data;
  };

  template<typename T = unsigned>
  struct Counter : AccumulatorBase {
    using type = T;
    using DeviceType = DeviceCounter<T>;

    Counter(const Allen::Algorithm* owner, std::string name) : AccumulatorBase(owner, name)
    {
      if constexpr (std::is_same<T, unsigned>::value) AccumulatorManager::get()->registerCounter(this);
    }
    std::size_t size() const override { return 1; }
    std::size_t elementSize() const override { return sizeof(T); }
    DeviceType data(const Allen::Context& ctx) const { return reinterpret_cast<T*>(currentDevicePtr(ctx.stream_id)); }

    friend void reset(Counter& c) { c.m_entries = 0.0; }
    friend void to_json(nlohmann::json& j, Counter const& c)
    {
      j = {{"type", "counter:Counter:d"}, {"empty", c.m_entries == 0}, {"nEntries", c.m_entries}};
    }
    void registerAccumulator() override
    {
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(component(), name(), "counter:Counter:d", *this);
#endif
    }
    void fillAccumulator(void* ptr) override { m_entries += reinterpret_cast<T*>(ptr)[0]; }
    double m_entries = 0.0;
  };

  template<typename T = unsigned>
  struct DeviceAveragingCounter {
    __host__ __device__ DeviceAveragingCounter(T* data) : m_data(data) {}
    __device__ T* data() const { return m_data; }

#if defined(TARGET_DEVICE_CUDA) && defined(DEVICE_COMPILER)
    __device__ void add(T value) const
    {
      unsigned mask = __activemask();
      unsigned peers = mask;
      unsigned count = __popc(peers);
      int rank = __popc(peers & __lanemask_lt());
      bool is_leader = rank == 0;
      peers &= __lanemask_gt();
      while (__any_sync(mask, peers)) {
        int next = __ffs(peers);
        T tmp = __shfl_sync(mask, value, next - 1);
        if (next) value += tmp;
        peers &= __ballot_sync(mask, !(rank & 1));
        rank >>= 1;
      }
      if (is_leader) {
        atomicAdd(&m_data[0], value);
        atomicAdd(&m_data[1], count);
      }
    }
#else
    __device__ void add(T value) const
    {
      __atomic_add_fetch(&m_data[0], value, __ATOMIC_RELAXED);
      __atomic_add_fetch(&m_data[1], 1, __ATOMIC_RELAXED);
    }
#endif

  private:
    T* m_data;
  };

  template<typename T = unsigned>
  struct AveragingCounter : AccumulatorBase {
    using type = T;
    using DeviceType = DeviceAveragingCounter<T>;

    AveragingCounter(const Allen::Algorithm* owner, std::string name) : AccumulatorBase(owner, name)
    {
      if constexpr (std::is_same<T, unsigned>::value) AccumulatorManager::get()->registerAveragingCounter(this);
    }
    std::size_t size() const override { return 2; }
    std::size_t elementSize() const override { return sizeof(T); }
    DeviceType data(const Allen::Context& ctx) const { return reinterpret_cast<T*>(currentDevicePtr(ctx.stream_id)); }

    friend void reset(AveragingCounter& c)
    {
      c.m_sum = 0.0;
      c.m_entries = 0.0;
    }
    friend void to_json(nlohmann::json& j, AveragingCounter const& c)
    {
      j = {{"type", "counter:AveragingCounter:d"},
           {"empty", c.m_entries == 0},
           {"nEntries", c.m_entries},
           {"sum", c.m_sum},
           {"mean", c.m_sum / c.m_entries}};
    }
    void registerAccumulator() override
    {
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(component(), name(), "counter:AveragingCounter:d", *this);
#endif
    }
    void fillAccumulator(void* ptr) override
    {
      m_sum += reinterpret_cast<T*>(ptr)[0];
      m_entries += reinterpret_cast<T*>(ptr)[1];
    }
    double m_sum = 0.0;
    double m_entries = 0.0;
  };

  // Histograms:

  template<typename T>
  struct DeviceAxis {
    using InputType = T;
    DeviceAxis() = default;
    DeviceAxis(unsigned nBins, InputType minValue, InputType maxValue) :
      minValue(minValue), maxValue(maxValue), ratio(static_cast<float>(nBins) / (maxValue - minValue))
    {}
    __device__ unsigned index(InputType value) const { return static_cast<unsigned>((value - minValue) * ratio); }
    __device__ bool inAcceptance(InputType value) const { return value >= minValue && value < maxValue; }

  private:
    T minValue, maxValue;
    float ratio;
  };

  template<typename T>
  struct Axis {
    using DeviceType = DeviceAxis<T>;
    using InputType = T;

    Axis(unsigned nBins, T minValue, T maxValue, std::string title = {}, std::vector<std::string> labels = {}) :
      nBins(nBins), minValue(minValue), maxValue(maxValue), title(title), labels(labels)
    {}

    DeviceType deviceAxis() const { return {nBins, minValue, maxValue}; }

    friend void to_json(nlohmann::json& j, const Axis& axis)
    {
      j = nlohmann::json {
        {"nBins", axis.nBins}, {"minValue", axis.minValue}, {"maxValue", axis.maxValue}, {"title", axis.title}};
      if (!axis.labels.empty()) {
        j["labels"] = axis.labels;
      }
    }

    unsigned int nBins;              // number of bins for this Axis
    T minValue, maxValue;            // min and max values on this axis
    std::string title;               // title of this axis
    std::vector<std::string> labels; // labels for the bins
  };

  namespace {
    __device__ __host__ constexpr float logscale(float x, float a, float b, float c) { return log2f(a * x + c) * b; }
  } // namespace

  struct DeviceLogAxis {
    using InputType = float;
    DeviceLogAxis() = default;
    DeviceLogAxis(unsigned nBins, float _minValue, float _maxValue, float a, float b, float c) : a(a), b(b), c(c)
    {
      minValue = logscale(_minValue, a, b, c);
      maxValue = logscale(_maxValue, a, b, c);
      ratio = static_cast<float>(nBins) / (maxValue - minValue);
    }
    __device__ unsigned index(InputType value) const
    {
      value = logscale(value, a, b, c);
      return static_cast<unsigned>((value - minValue) * ratio);
    }
    __device__ bool inAcceptance(InputType value) const
    {
      value = logscale(value, a, b, c);
      return value >= minValue && value < maxValue;
    }

  private:
    float minValue, maxValue;
    float ratio, a, b, c;
  };

  // An axis with a transform of the form y = log2(a * x + c) * b
  // The default parameters makes it equivalent to y = log10(x)
  struct LogAxis {
    using DeviceType = DeviceLogAxis;
    using InputType = float;

    LogAxis(
      unsigned nBins,
      float minValue,
      float maxValue,
      float a = 1.f,
      float b = std::log10(2),
      float c = 0.f,
      std::string title = {}) :
      nBins(nBins),
      minValue(minValue), maxValue(maxValue), a(a), b(b), c(c), title(title)
    {}

    DeviceType deviceAxis() const { return {nBins, minValue, maxValue, a, b, c}; }

    friend void to_json(nlohmann::json& j, const LogAxis& axis)
    {
      std::vector<double> xbins;
      xbins.reserve(axis.nBins + 1);

      double minValue = static_cast<double>(logscale(axis.minValue, axis.a, axis.b, axis.c));
      double maxValue = static_cast<double>(logscale(axis.maxValue, axis.a, axis.b, axis.c));
      double step = (maxValue - minValue) / static_cast<double>(axis.nBins);
      double a = static_cast<double>(axis.a);
      double b = static_cast<double>(axis.b);
      double c = static_cast<double>(axis.c);

      for (unsigned i = 0; i <= axis.nBins; i++) {
        double y = minValue + i * step;
        xbins.emplace_back((-c + std::exp(y * std::log(2) / b)) / a);
      }
      j = nlohmann::json {{"nBins", axis.nBins},
                          {"minValue", axis.minValue},
                          {"maxValue", axis.maxValue},
                          {"title", axis.title},
                          {"xbins", xbins}};
    }

    unsigned int nBins;       // number of bins for this Axis
    float minValue, maxValue; // min and max values on this axis
    float a, b, c;            // scaling coefficients
    std::string title;        // title of this axis
  };

  namespace details {
    template<class... Args, std::size_t... Is>
    constexpr auto remove_last_helper(std::tuple<Args...> tp, std::index_sequence<Is...>)
    {
      return std::tuple {std::get<Is>(tp)...};
    }

    template<class... Args>
    constexpr auto remove_last(std::tuple<Args...> tp)
    {
      return remove_last_helper(tp, std::make_index_sequence<sizeof...(Args) - 1> {});
    }
  } // namespace details

  template<typename T = unsigned, typename... Types>
  struct DeviceNDHistogram {
    __host__ DeviceNDHistogram(T* data, std::tuple<Types...> axis_h) : m_data(data)
    {
      std::apply(
        [&](auto... axis) {
          unsigned i = 0;
          ((stride[i] = axis.nBins, i++), ...);
          for (unsigned i = 0; (i + 2u) < sizeof...(Types); i++) {
            stride[i + 1] *= stride[i];
          }
        },
        details::remove_last(axis_h));
      m_axis = (std::apply(
        [&](auto... axis) { return std::tuple<decltype(axis.deviceAxis())...> {axis.deviceAxis()...}; }, axis_h));
    }

    template<typename First, typename... InputTypes>
    __device__ unsigned index(First& first, InputTypes&... values) const
    {
      unsigned sum = std::get<0>(m_axis).index(first);
      std::apply(
        [&](auto, auto... axis) {
          unsigned i = 0;
          ((sum += stride.at(i) * axis.index(values), i++), ...);
        },
        m_axis);
      return sum;
    }

    template<typename... InputTypes>
    __device__ bool inAcceptance(InputTypes&... values) const
    {
      return std::apply([&](auto... axis) { return (axis.inAcceptance(values) && ...); }, m_axis);
    }

    __device__ T* data() const { return m_data; }

#if defined(TARGET_DEVICE_CUDA) && defined(DEVICE_COMPILER)
    template<typename... InputTypes>
    __device__ void increment(InputTypes... values) const
    {
      // Based on https://hal.science/hal-03330414/document
      if (inAcceptance(values...)) {
        unsigned index_ = index(values...);
        unsigned active = __activemask();
        unsigned peers = conflict_mask(active, index_);
        unsigned count = __popc(peers);
        unsigned rank = __popc(peers & __lanemask_lt());
        if (rank == 0) atomicAdd(&m_data[index_], count);
      }
    }
#else
    template<typename... InputTypes>
    void increment(InputTypes... values) const
    {
      if (inAcceptance(values...)) {
        unsigned index_ = index(values...);
        __atomic_add_fetch(&m_data[index_], 1, __ATOMIC_RELAXED);
      }
    }
#endif

  private:
    T* m_data;
    std::tuple<typename Types::DeviceType...> m_axis;
    std::array<unsigned, sizeof...(Types) - 1> stride;
  };

  template<typename T = unsigned, typename... Types>
  struct HistogramND : AccumulatorBase {
    using type = T;
    using DeviceType = DeviceNDHistogram<T, Types...>;

    HistogramND(const Allen::Algorithm* owner, std::string name, std::string title, Types... axis) :
      AccumulatorBase(owner, name), m_title(title), m_axis(axis...)
    {}

    std::size_t size() const override
    {
      return std::apply([&](auto... axis) { return (1 * ... * axis.nBins); }, m_axis);
    }

    std::size_t elementSize() const override { return sizeof(T); }

    DeviceType data(const Allen::Context& ctx) const
    {
      T* ptr = reinterpret_cast<T*>(currentDevicePtr(ctx.stream_id));
      return DeviceType(ptr, m_axis);
    }

    auto& x_axis() { return std::get<0>(m_axis); }

    auto& y_axis() { return std::get<1>(m_axis); }

    auto& z_axis() { return std::get<2>(m_axis); }

    friend void reset(HistogramND& c)
    {
      std::fill(c.m_bins.begin(), c.m_bins.end(), 0.0);
      c.m_totNEntries = 0.0;
    }

    friend void to_json(nlohmann::json& j, HistogramND const& h)
    {
      j = {{"type", "histogram:Histogram:d"},
           {"title", h.m_title},
           {"dimension", h.m_allen_stride.size()},
           {"empty", h.m_totNEntries == 0},
           {"nEntries", h.m_totNEntries},
           {"axis", h.axisArray()},
           {"bins", h.m_bins}};
    }

    void registerAccumulator() override
    {
      std::apply(
        [&](auto... axis) {
          unsigned i = 0;
          ((m_allen_stride[i] = axis.nBins, i++), ...);
        },
        m_axis);
      for (unsigned i = 1; i < sizeof...(Types); i++) {
        m_allen_stride[i] *= m_allen_stride[i - 1];
      }

      std::apply(
        [&](auto... axis) {
          unsigned i = 0;
          ((m_gaudi_stride[i] = (axis.nBins + 2), i++), ...);
        },
        m_axis);
      for (unsigned i = 1; i < sizeof...(Types); i++) {
        m_gaudi_stride[i] *= m_gaudi_stride[i - 1];
      }

      m_bins.resize(m_gaudi_stride[sizeof...(Types) - 1]);
      m_totNEntries = 0.0;
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(component(), name(), "histogram:Histogram:d", *this);
#endif
    }

    void fillAccumulator(void* ptr) override
    {
      for (unsigned bin = 0; bin < m_allen_stride[sizeof...(Types) - 1]; bin++) {
        auto count = reinterpret_cast<T*>(ptr)[bin];
        unsigned global_bin = convert_allen_bin_to_gaudi_bin(bin);
        m_bins[global_bin] += count;
        m_totNEntries += count;
      }
    }

    std::string m_title;
    double m_totNEntries = 0.0;
    std::vector<double> m_bins;
    std::tuple<Types...> m_axis;
    std::array<std::size_t, sizeof...(Types)> m_allen_stride;
    std::array<std::size_t, sizeof...(Types)> m_gaudi_stride;

  private:
    unsigned convert_allen_bin_to_gaudi_bin(unsigned allen_bin) const
    {
      std::array<unsigned, sizeof...(Types)> bins;
      calc_dim_bin(sizeof...(Types) - 1, allen_bin, bins);
      unsigned bin_index = bins[0] + 1;
      for (unsigned i = 1; i < bins.size(); i++) {
        bin_index += (bins[i] + 1) * m_gaudi_stride[i - 1];
      }
      return bin_index;
    }

    void calc_dim_bin(unsigned dim, unsigned allen_bin, std::array<unsigned, sizeof...(Types)>& bins) const
    {
      if (dim != 0) {
        unsigned highest_bin = allen_bin / m_allen_stride[dim - 1];
        calc_dim_bin(dim - 1, allen_bin % m_allen_stride[dim - 1], bins);
        bins[dim] = highest_bin;
      }
      else {
        bins[dim] = allen_bin;
      }
    }

    constexpr auto axisArray() const
    {
      auto axis_arrays = (std::apply([&](auto... axis) { return std::array {axis...}; }, m_axis));

      return axis_arrays;
    }
  };

  template<typename AxisT = Axis<float>, typename T = unsigned>
  using Histogram = HistogramND<T, AxisT>;

  template<typename AxisT = Axis<float>, typename AxisT2 = Axis<float>, typename T = unsigned>
  using Histogram2D = HistogramND<T, AxisT, AxisT2>;

  template<typename AxisT = LogAxis, typename T = unsigned>
  using LogHistogram = HistogramND<T, AxisT>;

  template<typename HistogramType>
  struct HistogramBinAsCounter {
    HistogramBinAsCounter(
      [[maybe_unused]] const Allen::Algorithm* owner,
      [[maybe_unused]] std::string name,
      const HistogramType* histo,
      unsigned bin) :
      m_histo(histo),
      m_bin(bin)
    {
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(owner->name(), name, "counter:Counter:d", *this);
#endif
    }
    friend void to_json(nlohmann::json& j, HistogramBinAsCounter const& c)
    {
      j = {{"type", "counter:Counter:d"},
           {"empty", c.m_histo->m_bins[c.m_bin + 1] == 0},
           {"nEntries", c.m_histo->m_bins[c.m_bin + 1]}};
    }
    const HistogramType* m_histo;
    unsigned m_bin;
  };
} // namespace Allen::Monitoring
