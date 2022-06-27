/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <string>
#include <unordered_map>
#include <typeindex>
#include <gsl/span>

namespace Allen::Store {
  namespace {
    inline void* magic_cast(std::type_index, std::type_index, void*) { return nullptr; }

    struct VTable {
      void* (*cast_)(std::type_index, void*);
      std::type_index (*type_)();
    };

    template <typename T>
    inline std::type_index type_() { return std::type_index(typeid(T)); }

    template <typename T>
    inline void* cast_(std::type_index type, void* self) { 
        return type==std::type_index(typeid(T)) ? static_cast<T*>(self)
                                                : magic_cast(type,std::type_index(typeid(T)),self);
    }

    template <>
    inline void *cast_<void>(std::type_index,void*) { return nullptr; }

    template <typename T>
    inline constexpr VTable const vtable_for = { &cast_<T>, &type_<T> };
  }

  enum class Scope { Host, Device, Invalid };

  /**
   * @brief Contains the data of an argument, namely its name, data pointer and size.
   *
   */
  struct ArgumentData {
  private:
    const VTable *m_vtable = &vtable_for<void>;
    std::string m_name = "";
    Scope m_scope = Scope::Invalid;
    size_t m_type_size = 0;
    void* m_pointer = nullptr;
    size_t m_size = 0;

  public:
    template<typename T>
    ArgumentData(std::in_place_type_t<T>, const std::string& name, Scope scope) : m_vtable{&vtable_for<T>}, m_name{name}, m_scope{scope},
      m_type_size{sizeof(T)} {}

    std::string name() const { return m_name; }
    Scope scope() const { return m_scope; }
    std::type_index type() const { return m_vtable->type_(); }
    
    template<typename T>
    gsl::span<T> to_span() {
      return gsl::span<T>{static_cast<T*>(m_vtable->cast_(std::type_index(typeid(T)), m_pointer)), m_size};
    }

    template<typename T>
    gsl::span<const T> to_span() const {
      return gsl::span<const T>{static_cast<const T*>(m_vtable->cast_(std::type_index(typeid(T)), m_pointer)), m_size};
    }

    virtual void* pointer() const { return m_pointer; }
    virtual size_t size() const { return m_size; }
    virtual size_t sizebytes() const { return m_size * m_type_size; }
    virtual void set_pointer(void* pointer) { m_pointer = pointer; }
    virtual void set_size(size_t size) { m_size = size; }
    virtual ~ArgumentData() {}
  };

} // namespace Allen::Store
