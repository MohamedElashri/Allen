/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <map>
#include <string>

namespace Allen {
  /**
   * @brief      Common interface for templated Property and SharedProperty
   * classes
   *
   */
  class BaseProperty {
  public:
    virtual bool from_string(const std::string& value) = 0;

    virtual std::string to_string() const = 0;

    virtual std::string print() const = 0;

    virtual ~BaseProperty() {}
  };

  /**
   * @brief      Functionality common to Algorithm classes and SharedPropertySets
   *
   */
  struct BaseAlgorithm {
    virtual void set_properties(const std::map<std::string, std::string>& algo_config) = 0;

    virtual std::map<std::string, std::string> get_properties() const = 0;

    virtual bool register_property(const std::string& name, BaseProperty* property) = 0;

    virtual BaseProperty const* get_prop(const std::string& prop_name) const = 0;

    virtual ~BaseAlgorithm() {}
  };
} // namespace Allen
