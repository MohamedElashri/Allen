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
} // namespace Configuration

namespace Allen {
  /**
   * @brief      Store, update and readout the value of a single configurable algorithm property
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
      update();
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

    void register_derived_property(DerivedProperty<V>* p) { m_derived.push_back(p); }

  protected:
    virtual void update()
    {
      for (auto i : m_derived) {
        i->update();
      }
    }

    void set_value(V value) { m_cached_value = value; }

  private:
    BaseAlgorithm* m_algo = nullptr;
    V m_cached_value;
    std::string m_name;
    std::string m_description;
    std::vector<DerivedProperty<V>*> m_derived;
  };
  
} // namespace Allen

// function to access singleton instances of all SharedPropertySets
namespace Configuration {
  Allen::SharedPropertySet* getSharedPropertySet(const std::string& name);
}

/**
 * @brief      Register a property from a shared set with an algorithm that uses it
 *
 */
namespace Allen {
  template<typename V>
  class SharedProperty : public BaseProperty {
  public:
    SharedProperty() = delete;
    SharedProperty(Algorithm* algo, const std::string& set_name, const std::string& prop_name) : m_algo(algo)
    {
      init(set_name, prop_name);
      algo->register_shared_property(set_name, prop_name, m_set, this);
    }

    bool from_string(const std::string&) override
    {
      std::cout << "shared properties may not be set directly" << std::endl;
      return false;
    }

    std::string to_string() const override
    {
      if (m_prop) return m_prop->to_string();
      return "";
    }

    std::string print() const override
    {
      if (m_prop) return m_prop->print();
      return "";
    }

  private:
    void init(const std::string& set_name, const std::string& prop_name)
    {
      m_set = Configuration::getSharedPropertySet(set_name);
      if (!m_set) {
        std::cout << "Unknown shared property set " << set_name << std::endl;
      }
      m_prop = dynamic_cast<Property<V> const*>(m_set->get_and_register_prop(prop_name));
      if (!m_prop) {
        std::cout << "Unknown shared property " << prop_name << std::endl;
      }
    }

    BaseAlgorithm* m_algo = nullptr;
    SharedPropertySet* m_set = nullptr;
    Property<V> const* m_prop = nullptr;
  };
} // namespace Allen
