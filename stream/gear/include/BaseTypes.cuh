/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <map>
#include <string>
#include <sstream>
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

    virtual ~BaseProperty() {}

    BaseProperty(const std::string& name, const std::string& description, const std::string& data_type) :
      m_name(name), m_description(description), m_data_type(data_type)
    {}

    const std::string& name() const { return m_name; }

    const std::string& description() const { return m_description; }

    const std::string& data_type() const { return m_data_type; }

    std::string print() const
    {
      // very basic implementation based on streaming
      std::stringstream s;
      s << m_name << " " << to_string() << " " << m_description;
      return s.str();
    }

  protected:
    std::string m_name;
    std::string m_description;
    std::string m_data_type;
  };

  /**
   * @brief      Functionality common to Algorithm classes and SharedPropertySets
   *
   */
  struct BaseAlgorithm {
    virtual void set_properties(const std::map<std::string, nlohmann::json>& algo_config) = 0;

    virtual std::map<std::string, nlohmann::json> get_properties() const = 0;

    virtual std::map<std::string, nlohmann::json> get_properties_infos() const = 0;

    virtual bool register_property(const std::string& name, BaseProperty* property) = 0;

    virtual BaseProperty const* get_prop(const std::string& prop_name) const = 0;

    virtual ~BaseAlgorithm() {}
  };
} // namespace Allen
