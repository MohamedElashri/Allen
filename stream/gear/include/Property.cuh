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
    namespace Detail {
      std::regex const array_expr {"\\[(?:\\s*(\\d+)\\s*,?)+\\]"};
      std::regex const digit_expr {"(\\d+)"};
    } // namespace Detail

    template<typename T>
    struct ConvertorFromString {
      static auto convert(const std::string& s)
      {
        if constexpr (std::is_same_v<T, std::string>) {
          return s;
        }
        else if constexpr (std::is_same_v<T, float> || std::is_same_v<T, double>) {
          return atof(s.c_str());
        }
        else if constexpr (std::is_same_v<T, int8_t> || std::is_same_v<T, int16_t> || std::is_same_v<T, int32_t>) {
          return strtol(s.c_str(), 0, 0);
        }
        else if constexpr (std::is_same_v<T, int64_t>) {
          return strtoll(s.c_str(), 0, 0);
        }
        else if constexpr (std::is_same_v<T, uint8_t> || std::is_same_v<T, uint16_t> || std::is_same_v<T, uint32_t>) {
          return strtoul(s.c_str(), 0, 0);
        }
        else if constexpr (std::is_same_v<T, uint64_t>) {
          return strtoull(s.c_str(), 0, 0);
        }
        if constexpr (std::is_same_v<T, bool>) {
          return atoi(s.c_str());
        }
        if constexpr (std::is_same_v<T, char>) {
          return s.at(0);
        }
        else if constexpr (std::is_same_v<T, BankTypes>) {
          auto bt = bank_type(s);
          if (bt == BankTypes::Unknown) {
            throw StrException {"Failed to parse " + s + " into a BankType."};
          }
          return bt;
        }
        else {
          throw StrException {"ConvertorFromString instantiated with unsupported type."};
        }
      }
    };

    template<typename T, std::size_t N>
    struct ConvertorFromString<std::array<T, N>> {
      static std::array<T, N> convert(const std::string& s)
      {
        std::array<T, N> output;
        std::smatch matches;
        auto r = std::regex_match(s, matches, Detail::array_expr);
        if (!r) {
          throw std::exception {};
        }
        auto digits_begin = std::sregex_iterator(s.begin(), s.end(), Detail::digit_expr);
        auto digits_end = std::sregex_iterator();
        if (std::distance(digits_begin, digits_end) != N) {
          throw StrException {"Failed to parse from string, array size mismatch."};
        }
        int idx = 0;
        for (auto i = digits_begin; i != digits_end; ++i) {
          output[idx++] = ConvertorFromString<T>::convert(i->str());
        }
        return output;
      }
    };

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
      static std::string convert(const std::array<T, N> holder)
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

    // General template
    template<typename T>
    bool from_string(T& holder, const std::string& value)
    {
      try {
        holder = ConvertorFromString<typename T::t>::convert(value);
      } catch (const std::exception&) {
        warning_cout << "Could not parse JSON string from value \"" << value << "\"\n";
        return false;
      }

      return true;
    }
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

    virtual bool from_string(const std::string& value) override
    {
      V holder;
      if (!Configuration::from_string<V>(holder, value)) return false;
      set_value(holder);
      return true;
    }

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

  protected:
    void set_value(V value) { m_cached_value = value; }

  private:
    BaseAlgorithm* m_algo = nullptr;
    V m_cached_value;
    std::string m_name;
    std::string m_description;
  };

} // namespace Allen
