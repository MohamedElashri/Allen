/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "Logger.h"
#include "BaseTypes.cuh"
#include "TargetFunction.cuh"
#include "Argument.cuh"
#include "Contract.h"

#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include <any>

namespace Allen {
  // Type-erased algorithm
  struct TypeErasedAlgorithm {
    std::any instance;
    std::function<std::string(const std::any&)> name = nullptr;
    std::function<std::any(std::any, std::vector<std::vector<std::reference_wrapper<ArgumentData>>>)>
      create_arg_ref_manager = nullptr;
    std::function<void(const std::any&, std::any&, const RuntimeOptions&, const Constants&, const HostBuffers&)>
      set_arguments_size = nullptr;
    std::function<
      void(const std::any&, std::any&, const RuntimeOptions&, const Constants&, HostBuffers&, const Allen::Context&)>
      invoke = nullptr;
    std::function<void(std::any&)> init = nullptr;
    std::function<void(std::any&, const std::map<std::string, std::string>&)> set_properties = nullptr;

    TypeErasedAlgorithm() = default;
    TypeErasedAlgorithm(const TypeErasedAlgorithm&) = default;
  };

  // Tool to instantiate algorithms
  template<typename T>
  TypeErasedAlgorithm instantiate_algorithm_impl(T*, const std::string&);

  template<typename T>
  TypeErasedAlgorithm instantiate_algorithm(const std::string& name)
  {
    T* t = nullptr;
    return instantiate_algorithm_impl(t, name);
  }

  // Forward declare to use in Algorithm
  template<typename V>
  class Property;

  /**
   * @brief      In addition to functionality in BaseAlgorithm, algorithms may need to access properties shared with
   * other algorithms
   *
   */
  class Algorithm : public BaseAlgorithm {
  public:
    // Define empty contract container by default
    using contracts = std::tuple<>;

    template<typename T>
    using Property = Allen::Property<T>;

    void init() {}

    void set_properties(const std::map<std::string, std::string>& algo_config) override
    {
      for (auto kv : algo_config) {
        auto it = m_properties.find(kv.first);

        if (it == m_properties.end()) {
          error_cout << "could not set " << kv.first << "=" << kv.second << "\n";
          const std::string error_message = "property " + kv.first + " does not exist";
          throw std::runtime_error {error_message};
        }
        else {
          std::cout << kv.second << "\n";
          auto asdf = it->second;
          if (asdf == nullptr) {
            std::cout << "Pointer is nullptr\n";
          }
          else {
            it->second->from_string(kv.second);
          }
        }
      }
    }

    template<typename T, typename R>
    void set_property_value(const R& value)
    {
      auto prop = const_cast<Allen::Property<T>*>(dynamic_cast<Allen::Property<T> const*>(get_prop(T::name)));
      prop->set_value(value);
    }

    // Gets the value of property with type T
    template<typename T>
    T property() const
    {
      const auto base_prop = get_prop(T::name);
      const auto prop = dynamic_cast<const Property<T>*>(base_prop);
      if (!prop) {
        const std::string error_message =
          "property " + std::string(T::name) + " not defined, perhaps member definition is missing";
        throw std::runtime_error {error_message};
      }
      return prop->get_value();
    }

    std::map<std::string, std::string> get_properties() const override
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
        const std::string error_message = "could not register property " + name;
        throw std::runtime_error {error_message};
      }
      return std::get<1>(r);
    }

    // Setter and getter of name of the algorithm
    void set_name(const std::string& name) { m_name = name; }

    std::string name() const { return m_name; }

    template<typename Fn>
    auto host_function(const Fn& fn) const
    {
      return HostFunction<Fn> {m_properties, fn};
    }

    template<typename Fn>
    auto global_function(const Fn& fn) const
    {
      return GlobalFunction<Fn> {m_properties, fn};
    }

    PROPERTY(verbosity_t, "verbosity", "verbosity of algorithm", int);

  protected:
    BaseProperty const* get_prop(const std::string& prop_name) const override
    {
      if (m_properties.find(prop_name) != m_properties.end()) {
        return m_properties.at(prop_name);
      }
      return nullptr;
    }

  private:
    std::map<std::string, BaseProperty*> m_properties;
    std::string m_name = "";
    Property<verbosity_t> m_verbosity = {this, 3};
  };
} // namespace Allen
