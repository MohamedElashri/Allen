/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <algorithm>
#include <cstdio>
#include <BackendCommon.h>
#include <Datatype.cuh>
#include <Argument.cuh>
#include <BankTypes.h>
#include <AllenTypeTraits.h>
#include <GaudiKernel/StatusCode.h>
#include <GaudiKernel/ParsersFactory.h>
#include <GaudiKernel/StdArrayAsProperty.h>

namespace Allen {
  // Shortcut for type used in input / outputs of Allen - Gaudi wrappers
  template<typename T>
  using parameter_vector = std::vector<bool_as_char_t<T>>;

  /**
   * @brief A wrapper for Allen properties, which provides the syntax employed by Allen.
   */
  template<typename T>
  struct AllenPropertyWrapper {
    T m_value;
    T get() { return m_value; }
  };

  /**
  * @brief A TES wrapper. Allen TES objects are stored as std::vectors (of non-boolean types),
            and TES wrappers provide the Allen syntax on top of these.
  */
  template<typename VECTOR>
  struct TESWrapperArgument : public Store::BaseArgument {
  private:
    VECTOR& m_data;

  protected:
    void* pointer() const override final
    {
      return const_cast<void*>(reinterpret_cast<forward_type_t<VECTOR, void>*>(m_data.data()));
    }

    size_t size() const override final { return m_data.size(); }

  public:
    TESWrapperArgument(VECTOR& data, const std::string& name) :
      Store::BaseArgument {std::in_place_type<typename VECTOR::value_type>, name, Store::Scope::Host}, m_data(data)
    {}

    // set_pointer should never used, since vectors are allocated directly with set_size
    void set_pointer(void*) override final { throw; }

    // set_size resizes the vector of data, when it is an output datatype (not const)
    // If it is invoked on a const vector, it throws
    void set_size([[maybe_unused]] size_t size) override final
    {
      if constexpr (!std::is_const_v<VECTOR>) {
        m_data.resize(size);
      }
      else {
        // Note: static_assert wouldn't work here due to override
        throw;
      }
    }
  };

  // Shortcuts for input / output wrappers
  template<typename T>
  using TESWrapperInput = TESWrapperArgument<const parameter_vector<T>>;

  template<typename T>
  using TESWrapperOutput = TESWrapperArgument<parameter_vector<T>>;
} // namespace Allen

// Parsers are in namespace LHCb for ADL to work.
inline StatusCode parse(BankTypes& result, const std::string& in)
{
  // This takes care of quoting
  std::string input;
  using Gaudi::Parsers::parse;
  auto sc = parse(input, in);
  if (!sc) return sc;

  result = bank_type(input);
  return StatusCode::SUCCESS;
}

inline std::ostream& toStream(const BankTypes& bt, std::ostream& s)
{
  auto bn = bank_name(bt);
  return s << "'" << bn << "'";
}
