#pragma once

#include <unordered_set>
#include <map>
#include <cmath>

#include "BankTypes.h"

struct IInputProvider {

  virtual std::tuple<bool, bool, size_t, std::map<BankTypes, size_t>> fill(size_t slice_index, size_t n) = 0;

  virtual BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const = 0;

};

// InputProvider
template <class Derived>
class InputProvider;

template <template <BankTypes...> typename Derived, BankTypes... Banks>
class InputProvider<Derived<Banks...>> : public IInputProvider {
public:

  explicit InputProvider(size_t n_slices, size_t n_events) :
    m_nslices {n_slices}, m_nevents {n_events},
    m_types{banks_set<Banks...>()}
  {}

  const std::unordered_set<BankTypes>& types() const { return m_types; }

  size_t n_slices() const { return m_nslices; }

  size_t n_events() const { return m_nevents; }

  std::tuple<bool, bool, size_t, std::map<BankTypes, size_t>> fill(size_t slice_index, size_t n) override {
    return static_cast<Derived<Banks...>*>(this)->fill(slice_index, n);
  }

  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override {
    return static_cast<const Derived<Banks...>*>(this)->banks(bank_type, slice_index);
  }

private:

  const size_t m_nslices = 0;
  const size_t m_nevents = 0;
  const std::unordered_set<BankTypes> m_types;

};
