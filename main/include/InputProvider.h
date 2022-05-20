/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <unordered_set>
#include <map>
#include <vector>
#include <cmath>
#include <mutex>
#include <optional>
#include <any>

#include <gsl/gsl>

#include <Event/ODIN.h>

#include "Logger.h"
#include "BankTypes.h"
#include "Common.h"
#include "AllenUnits.h"

class IInputProvider {
public:
  enum class Layout { Allen, MEP };

  struct BufferStatus {
    bool writable = true;
    int work_counter = 0;
    std::vector<std::tuple<size_t, size_t>> intervals;
    size_t index = 0;
  };

  /// Desctructor
  virtual ~IInputProvider() {};

  /**
   * @brief      Are slices provided in MEP layout or not
   *
   * @return     layout
   */
  virtual Layout layout() const = 0;

  /**
   * @brief      Get the maximum number of events per slice
   *
   * @return     number of events per slice
   */
  virtual size_t events_per_slice() const = 0;

  /**
   * @brief      Get event ids in a given slice
   *
   * @param      slice index
   *
   * @return     event ids
   */
  virtual EventIDs event_ids(
    size_t slice_index,
    std::optional<size_t> first = std::nullopt,
    std::optional<size_t> last = std::nullopt) const = 0;

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
   * @return     tuple of (success, eof, timed_out, slice_index, n_filled)
   */
  virtual std::tuple<bool, bool, bool, size_t, size_t, std::any> get_slice(
    std::optional<unsigned int> timeout = std::nullopt) = 0;

  /**
   * @brief      Get banks and offsets of a given type
   *
   * @param      bank type requested
   *
   * @return     spans spanning bank and offset memory
   */
  virtual BanksAndOffsets banks(BankTypes bank_type, size_t slice_index) const = 0;

  virtual void event_sizes(
    size_t const slice_index,
    gsl::span<unsigned int const> const selected_events,
    std::vector<size_t>& sizes) const = 0;

  virtual void copy_banks(size_t const slice_index, unsigned int const event, gsl::span<char> buffer) const = 0;

  virtual bool release_buffers() = 0;
};

class InputProvider : public IInputProvider {
public:
  InputProvider() = default;

  InputProvider(
    size_t n_slices,
    size_t events_per_slice,
    std::unordered_set<BankTypes> const& types,
    Layout layout,
    std::optional<size_t> n_events)
  {
    init_input(n_slices, events_per_slice, types, layout, n_events);
  }

  /// Descturctor
  virtual ~InputProvider() = default;

  /**
   * @brief      Are slices provided in MEP layout or not
   *
   * @return     layout
   */
  Layout layout() const override { return m_layout; }

  /**
   * @brief      Get the bank types filled by this provider
   *
   * @return     unordered set of bank types
   */
  std::unordered_set<BankTypes> const& types() const { return m_types; }

  /**
   * @brief      Get the number of slices
   *
   * @return     number of slices
   */
  size_t n_slices() const { return m_nslices; }

  /**
   * @brief      Get the maximum number of events per slice
   *
   * @return     number of events per slice
   */
  size_t events_per_slice() const override { return m_events_per_slice; }

  std::optional<size_t> const& n_events() const { return m_nevents; }

  bool release_buffers() override { return true; }

protected:
  void init_input(
    size_t n_slices,
    size_t events_per_slice,
    std::unordered_set<BankTypes> types,
    Layout layout,
    std::optional<size_t> n_events)
  {
    m_nslices = n_slices;
    m_events_per_slice = events_per_slice;
    m_types = types;
    m_layout = layout;
    m_nevents = n_events;
  }

  template<typename MSG>
  void debug_output(const MSG& msg, std::optional<size_t> const thread_id = std::nullopt) const
  {
    if (logger::verbosity() >= logger::debug) {
      std::unique_lock<std::mutex> lock {m_output_mut};
      debug_cout << (thread_id ? std::to_string(*thread_id) + " " : std::string {}) << msg << "\n";
    }
  }

private:
  // MEP layout
  Layout m_layout = Layout::Allen;

  // Number of slices to be provided
  size_t m_nslices = 0;

  // Number of events per slice
  size_t m_events_per_slice = 0;

  // Optional total number of events to be provided
  std::optional<size_t> m_nevents = std::nullopt;

  // BankTypes provided by this provider
  std::unordered_set<BankTypes> m_types;

  // Mutex for ordered debug output
  mutable std::mutex m_output_mut;
};
