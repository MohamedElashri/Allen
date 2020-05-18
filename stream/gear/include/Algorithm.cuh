#pragma once

#include "CudaCommon.h"
#include "Logger.h"
#include "BaseTypes.cuh"
#include "HostFunction.cuh"
#include "GlobalFunction.cuh"

namespace Allen {
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
    template<typename T>
    using Property = Allen::Property<T>;

    void set_properties(const std::map<std::string, std::string>& algo_config) override
    {
      for (auto kv : algo_config) {
        auto it = m_properties.find(kv.first);

        if (it == m_properties.end()) {
          error_cout << "could not set " << kv.first << "=" << kv.second << "\n";
          error_cout << "parameter does not exist"
                     << "\n";
          throw std::exception {};
        }
        else {
          it->second->from_string(kv.second);
        }
      }
    }

    // Gets the value of property with type T
    template<typename T>
    T property() const
    {
      auto prop = dynamic_cast<Allen::Property<T> const*>(get_prop(T::name));
      if (prop)
        return prop->get_value();
      else
        warning_cout << "property " << T::name << " not found\n";
      return T{};
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
        throw std::exception {};
      }
      return std::get<1>(r);
    }

    // Setter and getter of name of the algorithm
    void set_name(const std::string& name) { m_name = name; }

    std::string name() const { return m_name; }

  protected:
    BaseProperty const* get_prop(const std::string& prop_name) const override
    {
      if (m_properties.find(prop_name) != m_properties.end()) {
        return m_properties.at(prop_name);
      }
      return 0;
    }

    template<typename R, typename... T>
    HostFunction<const Allen::Algorithm*, R, T...> host_function(R(f)(T...)) const
    {
      return HostFunction<const Allen::Algorithm*, R, T...> {dynamic_cast<const Allen::Algorithm*>(this), f};
    }

    template<typename R, typename... T>
    GlobalFunction<const Allen::Algorithm*, R, T...> global_function(R(f)(T...)) const
    {
      return GlobalFunction<const Allen::Algorithm*, R, T...> {dynamic_cast<const Allen::Algorithm*>(this), f};
    }

  private:
    std::map<std::string, BaseProperty*> m_properties;
    std::string m_name = "";
  };
} // namespace Allen
