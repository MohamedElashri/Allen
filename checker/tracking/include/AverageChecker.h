/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#pragma once

#include <CheckerInvoker.h>

class AverageChecker : public Checker::BaseChecker {
public:
  struct AverageAccumulator {
  private:
    float m_count = 0.f;
    float m_mean = 0.f;
    float m_M2 = 0.f;
    float m_min = std::numeric_limits<float>::infinity();
    float m_max = -std::numeric_limits<float>::infinity();

  public:
    __host__ void operator+=(float new_value)
    {
      m_count += 1.f;
      const float delta = new_value - m_mean;
      m_mean += delta / m_count;
      const float delta2 = new_value - m_mean;
      m_M2 += delta * delta2;
      m_min = fminf(new_value, m_min);
      m_max = fmaxf(new_value, m_max);
    }

    __host__ float mean() const { return m_mean; }

    __host__ float std() const { return m_M2 / (m_count - 1.f); }

    __host__ float min() const { return m_min; }
    __host__ float max() const { return m_max; }
  };

  using FillFunc_t = std::function<void(std::map<std::string, AverageAccumulator>& m_counters)>;

  AverageChecker(CheckerInvoker const* invoker, std::string const& root_file, std::string const& name);

  virtual ~AverageChecker() = default;

  void accumulate(FillFunc_t const&);

  void report(size_t n_events) const override;

protected:
  std::map<std::string, AverageAccumulator> m_counters;
  std::string m_name;
  bool m_first_time = false;
  std::mutex m_mutex;
};
