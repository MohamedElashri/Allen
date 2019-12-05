#pragma once

#include "CudaCommon.h"

#include <string>
#include <sstream>
#include <map>
#include <list>
#include <set>
#include <regex>
#include <functional>
#include <iostream>

namespace Configuration {

  namespace Detail {
    std::regex const array_expr {"\\[(?:\\s*(\\d+)\\s*,?)+\\]"};
    std::regex const digit_expr {"(\\d+)"};
  } // namespace Detail

  // General template
  template<typename T>
  bool from_string(T& holder, const std::string& value);

  // General template
  template<typename T>
  std::string to_string(T const& holder)
  {
    // very basic implementation based on streaming
    std::stringstream s;
    s << holder;
    return s.str();
  }

  template<>
  std::string to_string<std::array<uint, 3>>(std::array<uint, 3> const& holder);
} // namespace Configuration

/**
 * @brief      Common interface for templated Property and SharedProperty classes
 *
 */
class BaseProperty {
public:
  virtual bool from_string(const std::string& value) = 0;

  virtual std::string to_string() const = 0;

  virtual std::string print() const = 0;

  virtual void sync_value() const = 0;

  virtual ~BaseProperty() {}
};

/**
 * @brief      Functionality common to Algorithm classes and SharedPropertySets
 *
 */
struct BaseAlgorithm {
  virtual void set_properties(const std::map<std::string, std::string>& algo_config) = 0;

  virtual std::map<std::string, std::string> get_properties() = 0;

  virtual bool register_property(const std::string& name, BaseProperty* property) = 0;

  virtual bool property_used(const std::string& name) const = 0;

  virtual BaseProperty const* get_prop(const std::string& prop_name) const = 0;

  virtual ~BaseAlgorithm() {}
};

// Forward declare to use in Algorithm
template<typename V>
class Property;

/**
 * @brief      In addition to functionality in BaseAlgorithm, algorithms may need to access properties shared with other
 * algorithms
 *
 */
class Algorithm : public BaseAlgorithm {
public:
  void set_properties(const std::map<std::string, std::string>& algo_config) override
  {
    for (auto kv : algo_config) {
      auto it = m_properties.find(kv.first);

      if (it == m_properties.end()) {
        std::cout << "could not set " << kv.first << "=" << kv.second << std::endl;
        std::cout << "parameter does not exist" << std::endl;
        throw std::exception {};
      }
      else {
        it->second->from_string(kv.second);
      }
    }
  }

  template<typename T>
  T get_property_value(std::string property_name) const
  {
    T holder;
    auto prop = dynamic_cast<Property<T> const*>(get_prop(property_name));
    if (prop)
      holder = prop->get_value();
    else
      std::cout << "property " << property_name << " not found" << std::endl;
    return holder;
  }

  std::map<std::string, std::string> get_properties() override
  {
    std::map<std::string, std::string> properties;
    for (const auto& kv : m_properties) {
      properties.emplace(kv.first, kv.second->to_string());
    }
    return properties;
  }

  bool register_property(std::string const& name, BaseProperty* property) override
  {
    auto r = m_properties.emplace(name, property);
    if (!std::get<1>(r)) {
      throw std::exception {};
    }
    return std::get<1>(r);
  }

  bool property_used(std::string const&) const override { return true; }

  void set_shared_properties(const std::string& set_name, const std::map<std::string, std::string>& algo_config)
  {
    if (m_shared_sets.find(set_name) != m_shared_sets.end()) {
      m_shared_sets.at(set_name)->set_properties(algo_config);
    }
  }

  std::map<std::string, std::string> get_shared_properties(const std::string& set_name) const
  {
    if (m_shared_sets.find(set_name) != m_shared_sets.end()) {
      return m_shared_sets.at(set_name)->get_properties();
    }
    return std::map<std::string, std::string>();
  }

  std::vector<std::string> get_shared_sets() const
  {
    std::vector<std::string> ret;
    for (auto kv : m_shared_sets) {
      ret.push_back(kv.first);
    }
    return ret;
  }

  bool register_shared_property(std::string const& set_name, std::string const&, BaseAlgorithm* prop_set, BaseProperty*)
  {
    m_shared_sets.emplace(set_name, prop_set);
    return true;
  }

protected:
  BaseProperty const* get_prop(const std::string& prop_name) const override
  {
    if (m_properties.find(prop_name) != m_properties.end()) {
      return m_properties.at(prop_name);
    }
    return 0;
  }

private:
  std::map<std::string, BaseProperty*> m_properties;
  std::map<std::string, BaseAlgorithm*> m_shared_sets;
};

/**
 * @brief      Store, update and readout the value of a configurable algorithm property without constant memory storage
 *
 */
template<typename V>
class CPUProperty : public BaseProperty {
public:
  CPUProperty() = delete;

  CPUProperty(
    BaseAlgorithm* algo,
    const std::string& name,
    V const default_value,
    const std::string& description = "") :
    m_algo {algo},
    m_cached_value {default_value}, m_name {std::move(name)}, m_description {std::move(description)}
  {
    algo->register_property(m_name, this);
  }

  V get_value() const { return m_cached_value; }

  virtual bool from_string(const std::string& value) override
  {
    if (!Configuration::from_string<V>(m_cached_value, value)) return false;
    return true;
  }

  std::string to_string() const override { return Configuration::to_string(m_cached_value); }

  std::string print() const override
  {
    // very basic implementation based on streaming
    std::stringstream s;
    s << m_name << " " << to_string() << " " << m_description;
    return s.str();
  }

  virtual void sync_value() const override {}

protected:
  virtual void update() {}

  void set_value(V value) { m_cached_value = value; }

private:
  BaseAlgorithm* m_algo = nullptr;
  V m_cached_value;
  std::string m_name;
  std::string m_description;
};

// forward declare to use in Property
template<typename V>
class DerivedProperty;

/**
 * @brief      Store, update and readout the value of a single configurable algorithm property
 *
 */
template<typename V>
class Property : public BaseProperty {
public:
  Property() = delete;

  Property(
    BaseAlgorithm* algo,
    const std::string& name,
    V& value,
    V const default_value,
    const std::string& description = "") :
    m_algo {algo},
    m_value {value}, m_cached_value {default_value}, m_name {std::move(name)}, m_description {std::move(description)}
  {
    algo->register_property(m_name, this);
    // don't sync if this is an unused shared property
    if (algo->property_used(m_name)) sync_value();
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
    V holder;
    cudaCheck(cudaMemcpyFromSymbol(&holder, m_value.get(), sizeof(V)));
    return Configuration::to_string(holder);
  }

  std::string print() const override
  {
    // very basic implementation based on streaming
    std::stringstream s;
    s << m_name << " " << to_string() << " " << m_description;
    return s.str();
  }

  void register_derived_property(DerivedProperty<V>* p) { m_derived.push_back(p); }

  virtual void sync_value() const override { cudaCheck(cudaMemcpyToSymbol(m_value.get(), &m_cached_value, sizeof(V))); }

protected:
  virtual void update()
  {
    for (auto i : m_derived) {
      i->update();
    }
  }

  void set_value(V value)
  {
    m_cached_value = value;
    sync_value();
  }

private:
  BaseAlgorithm* m_algo = nullptr;
  std::reference_wrapper<V> m_value;
  V m_cached_value;
  std::string m_name;
  std::string m_description;
  std::vector<DerivedProperty<V>*> m_derived;
};

/**
 * @brief      A property that is defined as a function of other properties belonging to the same algorithm
 *
 */
template<typename V>
class DerivedProperty : public Property<V> {
public:
  DerivedProperty() = delete;

  DerivedProperty(
    BaseAlgorithm* algo,
    std::string name,
    V& value,
    V (*func)(std::vector<Property<V>*>),
    std::vector<Property<V>*> dependencies,
    std::string description = "") :
    Property<V>(algo, name, value, V(), description),
    m_func(func), m_deps(dependencies)
  {
    register_with_dependencies();
  }

  bool from_string(const std::string&) override
  {
    std::cout << "derived properties may not be set directly" << std::endl;
    return false;
  }

  void update() override
  {
    this->set_value(m_func(m_deps));

    // now update any downstream properties
    Property<V>::update();
  }

private:
  void register_with_dependencies()
  {
    for (auto d : m_deps) {
      d->register_derived_property(this);
    }
    update();
  }

  V (*m_func)(std::vector<Property<V>*>);
  std::vector<Property<V>*> m_deps;
};

namespace Configuration {
  namespace Relations {
    template<typename V>
    V inverse(std::vector<Property<V>*> pars);
  }
} // namespace Configuration

/**
 * @brief      Store a collection of related properties that are not tied to a single algorithm
 *
 */
struct SharedPropertySet : public BaseAlgorithm {
  SharedPropertySet() = default;

  void set_properties(const std::map<std::string, std::string>& algo_config) override
  {
    for (auto kv : algo_config) {
      if (!m_used.count(kv.first)) continue;
      auto it = m_properties.find(kv.first);
      if (it == m_properties.end()) {
        std::cout << "could not set " << kv.first << "=" << kv.second << std::endl;
        std::cout << "parameter does not exist" << std::endl;
        throw std::exception {};
      }
      else {
        it->second->from_string(kv.second);
      }
    }
  }

  std::map<std::string, std::string> get_properties() override
  {
    std::map<std::string, std::string> properties;
    for (auto const kv : m_properties) {
      if (!m_used.count(kv.first)) continue;
      properties.emplace(kv.first, kv.second->to_string());
    }
    return properties;
  }

  bool register_property(const std::string& name, BaseProperty* property) override
  {
    auto r = m_properties.emplace(name, property);
    if (!std::get<1>(r)) {
      throw std::exception {};
    }
    return std::get<1>(r);
  }

  bool property_used(const std::string& name) const override { return (m_used.count(name) > 0); }

  BaseProperty const* get_and_register_prop(const std::string& prop_name)
  {
    auto prop = get_prop(prop_name);
    if (prop) m_used.insert(prop_name);
    return prop;
  }

protected:
  BaseProperty const* get_prop(const std::string& prop_name) const override
  {
    if (m_properties.find(prop_name) != m_properties.end()) {
      return m_properties.at(prop_name);
    }
    return 0;
  }

private:
  std::map<std::string, BaseProperty*> m_properties;
  std::set<std::string> m_used;
};

// function to access singleton instances of all SharedPropertySets
namespace Configuration {
  SharedPropertySet* getSharedPropertySet(const std::string& name);
}

/**
 * @brief      Register a property from a shared set with an algorithm that uses it
 *
 */
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

  void sync_value() const override
  {
    if (m_prop) m_prop->sync_value();
  }

private:
  void init(const std::string& set_name, const std::string& prop_name)
  {
    m_set = Configuration::getSharedPropertySet(set_name);
    if (!m_set) {
      std::cout << "Unknown shared property set " << set_name << std::endl;
    }
    m_prop = dynamic_cast<Property<V> const*>(m_set->get_and_register_prop(prop_name));
    if (m_prop) {
      sync_value();
    }
    else {
      std::cout << "Unknown shared property " << prop_name << std::endl;
    }
  }

  BaseAlgorithm* m_algo = nullptr;
  SharedPropertySet* m_set = nullptr;
  Property<V> const* m_prop = nullptr;
};
