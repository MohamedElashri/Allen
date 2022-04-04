/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "BaseTypes.cuh"
#include "BankTypes.h"
#include "Logger.h"
#include "Common.h"
#include <string>
#include <sstream>
#include <map>
#include <list>
#include <set>
#include <regex>
#include <functional>
#include <iostream>

namespace Allen {
  /**
   * @brief      Store and readout the value of a single configurable algorithm property
   *
   */
  template<typename V>
  class Property : public BaseProperty {
  public:
    Property() = delete;

    Property(BaseAlgorithm* algo, const typename V::t& default_value) :
      m_algo {algo}, m_cached_value {V(default_value)}, m_name {V::name}, m_description {V::description}
    {
      algo->register_property(m_name, this);
    }

    const V* get_value_address() const { return &m_cached_value; }

    V get_value() const { return m_cached_value; }

    void from_json(const nlohmann::json& value) override { set_value(value); }

    nlohmann::json to_json() const override { return m_cached_value.get(); }

    std::string to_string() const override
    {
      nlohmann::json j = m_cached_value.get();
      return j.dump();
    }

    std::string print() const override
    {
      // very basic implementation based on streaming
      std::stringstream s;
      s << m_name << " " << to_string() << " " << m_description;
      return s.str();
    }

    void set_value(typename V::t value) { m_cached_value = V {value}; }

  private:
    BaseAlgorithm* m_algo = nullptr;
    V m_cached_value;
    std::string m_name;
    std::string m_description;
  };
} // namespace Allen
