/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "Argument.cuh"
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
  namespace Configuration {
    template<typename T>
    struct ConvertorToString {
      static std::string convert(const T& holder)
      {
        if constexpr (std::is_same_v<T, BankTypes>) {
          return bank_name(holder);
        }
        else {
          std::stringstream s;
          s << holder;
          return s.str();
        }
      }
    };

    template<typename T, std::size_t N>
    struct ConvertorToString<std::array<T, N>> {
      static std::string convert(const std::array<T, N>& holder)
      {
        std::stringstream s;
        s << "[";
        for (size_t i = 0; i < N; ++i) {
          s << holder[i];
          if (i != N - 1) {
            s << ", ";
          }
        }
        s << "]";
        return s.str();
      }
    };

    template<typename T, typename U>
    struct ConvertorToString<std::map<T, U>> {
      static std::string convert(const std::map<T, U>& holder)
      {
        std::stringstream s;
        s << "{";
        unsigned i = 0;
        for (const auto& elem : holder) {
          s << holder.first << ": " << holder.second;
          if (i != holder.size() - 1) {
            s << ", ";
          }
          ++i;
        }
        s << "}";
        return s.str();
      }
    };
  } // namespace Configuration

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
      return Configuration::ConvertorToString<typename V::t>::convert(m_cached_value.get());
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
