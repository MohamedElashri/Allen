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

  struct AccumulatorInfosAndPointers {
    std::size_t offset {0};
    std::size_t size {0};
    std::size_t element_size {0};
    std::vector<AccumulatorBase*> owners;
  };

  struct AccumulatorManager {
    static AccumulatorManager* get()
    {
      static AccumulatorManager instance;
      return &instance;
    }

    void registerAccumulator(AccumulatorBase* acc);
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

    std::vector<AccumulatorBase*> m_registered_accumulators;
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

    Counter(const Allen::Algorithm* owner, std::string name) : AccumulatorBase(owner, name) {}
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

    AveragingCounter(const Allen::Algorithm* owner, std::string name) : AccumulatorBase(owner, name) {}
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

  template<typename AxisT = DeviceAxis<float>, typename T = unsigned>
  struct DeviceHistogram {
    using AxisType = AxisT;

    __host__ __device__ DeviceHistogram(T* data, AxisType axis) : m_data(data), m_axis(axis) {}

    __device__ unsigned index(typename AxisType::InputType value) const { return m_axis.index(value); }
    __device__ bool inAcceptance(typename AxisType::InputType value) const { return m_axis.inAcceptance(value); }
    __device__ T& operator[](typename AxisType::InputType value) const { return m_data[index(value)]; }
    __device__ T* data() const { return m_data; }

#if defined(TARGET_DEVICE_CUDA) && defined(DEVICE_COMPILER)
    __device__ void increment(typename AxisType::InputType value) const
    {
      // Based on https://hal.science/hal-03330414/document
      if (m_axis.inAcceptance(value)) {
        unsigned index = m_axis.index(value);
        unsigned active = __activemask();
        unsigned peers = conflict_mask(active, index);
        unsigned count = __popc(peers);
        unsigned rank = __popc(peers & __lanemask_lt());
        if (rank == 0) atomicAdd(&m_data[index], count);
      }
    }
#else
    __device__ void increment(typename AxisType::InputType value) const
    {
      if (m_axis.inAcceptance(value)) {
        unsigned index = m_axis.index(value);
        __atomic_add_fetch(&m_data[index], 1, __ATOMIC_RELAXED);
      }
    }
#endif

  private:
    T* m_data;
    AxisType m_axis;
  };

  template<typename AxisT = Axis<float>, typename T = unsigned>
  struct Histogram : AccumulatorBase {
    using type = T;
    using AxisType = AxisT;
    using DeviceType = DeviceHistogram<typename AxisType::DeviceType, T>;

    Histogram(const Allen::Algorithm* owner, std::string name, std::string title, AxisType axis) :
      AccumulatorBase(owner, name), m_title(title), m_axis {axis}
    {}
    std::size_t size() const override { return m_axis.nBins; }
    std::size_t elementSize() const override { return sizeof(T); }

    DeviceType data(const Allen::Context& ctx) const
    {
      T* ptr = reinterpret_cast<T*>(currentDevicePtr(ctx.stream_id));
      return {ptr, m_axis.deviceAxis()};
    }

    AxisType& axis() { return m_axis; }

    friend void reset(Histogram& c)
    {
      std::fill(c.m_bins.begin(), c.m_bins.end(), 0.0);
      c.m_totNEntries = 0.0;
    }
    friend void to_json(nlohmann::json& j, Histogram const& h)
    {
      j = {{"type", "histogram:Histogram:d"},
           {"title", h.m_title},
           {"dimension", 1},
           {"empty", h.m_totNEntries == 0},
           {"nEntries", h.m_totNEntries},
           {"axis", {h.m_axis}},
           {"bins", h.m_bins}};
    }
    void registerAccumulator() override
    {
      m_bins.resize(m_axis.nBins + 2);
      m_totNEntries = 0.0;
#ifndef ALLEN_STANDALONE
      Gaudi::svcLocator()->monitoringHub().registerEntity(component(), name(), "histogram:Histogram:d", *this);
#endif
    }
    void fillAccumulator(void* ptr) override
    {
      for (unsigned bin = 0; bin < m_axis.nBins; bin++) {
        auto count = reinterpret_cast<T*>(ptr)[bin];
        m_bins[bin + 1] += count;
        m_totNEntries += count;
      }
    }
    std::vector<double> m_bins;
    double m_totNEntries = 0.0;
    std::string m_title;
    AxisType m_axis;
  };

  template<typename AxisT = LogAxis, typename T = unsigned>
  using LogHistogram = Histogram<AxisT, T>;

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
