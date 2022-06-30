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

    template<typename T>
    inline std::type_index type_()
    {
      return std::type_index(typeid(T));
    }

    template<typename T>
    inline void* cast_(std::type_index type, void* self)
    {
      return type == std::type_index(typeid(T)) ? static_cast<T*>(self) :
                                                  magic_cast(type, std::type_index(typeid(T)), self);
    }

    template<>
    inline void* cast_<void>(std::type_index, void*)
    {
      return nullptr;
    }

    template<typename T>
    inline constexpr VTable const vtable_for = {&cast_<T>, &type_<T>};
  } // namespace

  enum class Scope { Host, Device, Invalid };

  /**
   * @brief A base type-erased Allen argument, consistent of a vtable, name, scope and type size.
   *        It carries information about its type.
   */
  struct BaseArgument {
  protected:
    const VTable* m_vtable = &vtable_for<void>;
    std::string m_name = "";
    Scope m_scope = Scope::Invalid;
    size_t m_type_size = 0;

    virtual void* pointer() const = 0;
    virtual size_t size() const = 0;

  public:
    template<typename T>
    BaseArgument(std::in_place_type_t<T>, const std::string& name, Scope scope) :
      m_vtable {&vtable_for<T>}, m_name {name}, m_scope {scope}, m_type_size {sizeof(T)}
    {}

    std::string name() const { return m_name; }
    Scope scope() const { return m_scope; }
    std::type_index type() const { return m_vtable->type_(); }
    size_t sizebytes() const { return size() * m_type_size; }

    template<typename T>
    operator gsl::span<T>()
    {
      return gsl::span<T> {static_cast<T*>(m_vtable->cast_(std::type_index(typeid(T)), pointer())), size()};
    }

    template<typename T>
    operator gsl::span<const T>() const
    {
      return gsl::span<const T> {static_cast<const T*>(m_vtable->cast_(std::type_index(typeid(T)), pointer())), size()};
    }

    virtual ~BaseArgument() {}
    virtual void set_pointer(void* pointer) = 0;
    virtual void set_size(size_t size) = 0;
  };

  /**
   * @brief An AllenArgument, which extends BaseArgument with pointer and size.
   */
  struct AllenArgument : public BaseArgument {
  private:
    void* m_pointer = nullptr;
    size_t m_size = 0;

  protected:
    void* pointer() const override final { return m_pointer; }
    size_t size() const override final { return m_size; }

  public:
    template<typename T>
    AllenArgument(std::in_place_type_t<T>, const std::string& name, Scope scope) :
      Store::BaseArgument {std::in_place_type<T>, name, scope}
    {}

    void set_pointer(void* pointer) override final { m_pointer = pointer; }
    void set_size(size_t size) override final { m_size = size; }
  };
} // namespace Allen::Store
