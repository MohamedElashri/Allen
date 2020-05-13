#pragma once

#include "CudaCommon.h"
#include "Argument.cuh"
#include "BaseTypes.cuh"
#include "Algorithm.cuh"
#include "Logger.h"
#include <string>
#include <sstream>
#include <map>
#include <list>
#include <set>
#include <regex>
#include <functional>
#include <iostream>

// Functionality for defining names
template<char... Cs>
struct Name {
  constexpr static const char s[sizeof...(Cs) + 1] = {Cs..., '\0'};
};

template<char... Cs>
constexpr char Name<Cs...>::s[sizeof...(Cs) + 1];

namespace Configuration {
  namespace Detail {
    std::regex const array_expr {"\\{(?:\\s*(\\d+)\\s*,?)+\\}"};
    std::regex const digit_expr {"(\\d+)"};
  } // namespace Detail

  // Helper function to deal with a convertor from string
  template<typename T>
  T from_string(const std::string& s);

  // General template
  template<typename T>
  bool from_string(T& holder, const std::string& value)
  {
    try {
      holder = from_string<typename T::t>(value);
    } catch (const std::exception&) {
      warning_cout << "Could not parse JSON string from value \"" << value << "\"\n";
      return false;
    }

    return true;
  }

  // General template
  template<typename T>
  std::string to_string(const T& holder)
  {
    // very basic implementation based on streaming
    std::stringstream s;
    s << holder;
    return s.str();
  }

  template<>
  std::string to_string<DeviceDimensions>(const DeviceDimensions& holder);
  
  template<>
  std::string to_string<BankTypes>(const BankTypes& holder);
} // namespace Configuration

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
      return Configuration::to_string(m_cached_value.get());
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
