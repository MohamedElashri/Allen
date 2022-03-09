/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <map>
#include <string>
#include "nlohmann/json.hpp"

namespace Allen {
  /**
   * @brief      Common interface for templated Property and SharedProperty
   * classes
   *
   */
  class BaseProperty {
  public:
    virtual void from_json(const nlohmann::json& value) = 0;

    virtual nlohmann::json to_json() const = 0;

    virtual std::string to_string() const = 0;

    virtual std::string print() const = 0;

    virtual ~BaseProperty() {}
  };

  /**
   * @brief      Functionality common to Algorithm classes and SharedPropertySets
   *
   */
  struct BaseAlgorithm {
    virtual void set_properties(const std::map<std::string, nlohmann::json>& algo_config) = 0;

    virtual std::map<std::string, nlohmann::json> get_properties() const = 0;

    virtual bool register_property(const std::string& name, BaseProperty* property) = 0;

    virtual BaseProperty const* get_prop(const std::string& prop_name) const = 0;

    virtual ~BaseAlgorithm() {}
  };
} // namespace Allen
