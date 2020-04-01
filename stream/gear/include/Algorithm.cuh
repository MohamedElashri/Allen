#include "CudaCommon.h"
#include "Logger.h"
#include "BaseTypes.cuh"

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
    void set_properties(const std::map<std::string, std::string>& algo_config) override
    {
      for (auto kv : algo_config) {
        auto it = m_properties.find(kv.first);

        if (it == m_properties.end()) {
          error_cout << "could not set " << kv.first << "=" << kv.second << "\n";
          error_cout << "parameter does not exist" << "\n";
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
      T holder;
      auto prop = dynamic_cast<Allen::Property<T> const*>(get_prop(T::name));
      if (prop)
        holder = prop->get_value();
      else
        warning_cout << "property " << T::name << " not found\n";
      return holder;
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

    bool
    register_shared_property(std::string const& set_name, std::string const&, BaseAlgorithm* prop_set, BaseProperty*)
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

}
