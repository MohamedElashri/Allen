#pragma once

#include <unordered_set>
#include <map>
#include <vector>
#include <cmath>

#include <BankTypes.h>
#include <Common.h>

struct IInputProvider {

  /**
   * @brief      Get event ids in a given slice
   *
   * @param      slice index
   *
   * @return     event ids
   */
  virtual EventIDs const& event_ids(size_t slice_index) const = 0;

  /**
   * @brief      Indicate a slice is free for filling
   *
   * @param      slice index
   */
  virtual void slice_free(size_t slice_index) = 0;

  /**
   * @brief      Get a slice with n events
   *
   * @param      optional timeout in ms to wait for slice
   *
   * @return     tuple of (eof, timed_out, slice_index, n_filled)
   */
  virtual std::tuple<bool, bool, size_t, size_t> get_slice(std::optional<unsigned int> timeout = std::optional<unsigned int>{}) = 0;

  /**
   * @brief      Get banks and offsets of a given type
   *
   * @param      bank type requested
   *
   * @return     spans spanning bank and offset memory
   */
  virtual BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const = 0;
};

// InputProvider
template<class Derived>
class InputProvider;

template<template<BankTypes...> typename Derived, BankTypes... Banks>
class InputProvider<Derived<Banks...>> : public IInputProvider {
public:
  explicit InputProvider(size_t n_slices, size_t events_per_slice, std::optional<size_t> n_events) :
    m_nslices {n_slices}, m_events_per_slice{events_per_slice},
    m_nevents {n_events}, m_types {banks_set<Banks...>()}
  {}

  virtual ~InputProvider() {};

  std::unordered_set<BankTypes> const& types() const { return m_types; }

  size_t n_slices() const { return m_nslices; }

  size_t events_per_slice() const { return m_events_per_slice < 100 ? 100 : m_events_per_slice; }

  std::optional<size_t> const& n_events() const { return m_nevents; }

  /**
   * @brief      Get event ids in a given slice
   *
   * @param      slice index
   *
   * @return     event ids
   */
  EventIDs const& event_ids(size_t slice_index) const override
  {
    return static_cast<Derived<Banks...> const*>(this)->event_ids(slice_index);
  }

  /**
   * @brief      Get a slice with n events
   *
   * @param      optional timeout in ms to wait for slice
   *
   * @return     tuple of (eof, timed_out, slice_index, n_filled)
   */
  std::tuple<bool, bool, size_t, size_t> get_slice(std::optional<unsigned int> timeout = std::optional<unsigned int>{}) override
  {
    return static_cast<Derived<Banks...>*>(this)->get_slice(timeout);
  }

  /**
   * @brief      Indicate a slice is free for filling
   *
   * @param      slice index
   */
  void slice_free(size_t slice_index) override
  {
    return static_cast<Derived<Banks...>*>(this)->slice_free(slice_index);
  }

  /**
   * @brief      Get banks and offsets of a given type
   *
   * @param      bank type requested
   *
   * @return     spans spanning bank and offset memory
   */
  BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const override
  {
    return static_cast<const Derived<Banks...>*>(this)->banks(bank_type, slice_index);
  }

protected:

  template <typename MSG>
  void debug_output(const MSG& msg, std::optional<size_t> const thread_id = {}) {
    if (logger::ll.verbosityLevel >= logger::verbose) {
      std::unique_lock<std::mutex> lock{m_output_mut};
      verbose_cout << (thread_id ? std::to_string(*thread_id) + " " : std::string{}) << msg << "\n";
    }
  }

private:

  // Number of slices to be provided
  const size_t m_nslices = 0;

  // Number of events per slice
  const size_t m_events_per_slice = 0;

  // Optional total number of events to be provided
  const std::optional<size_t> m_nevents;

  // BankTypes provided by this provider
  const std::unordered_set<BankTypes> m_types;

  // Mutex for ordered debug output
  std::mutex m_output_mut;

};
