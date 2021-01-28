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

#include <vector>
#include <new>
#include "BackendCommon.h"

namespace Allen {
  /**
   * Minimal allocator for aligned data.
   *
   * Based on
   * https://www.youtube.com/watch?v=dTeKf5Oek2c&feature=youtu.be&t=26m27s
   */
  template<class T>
  class pinned_allocator {
  public:
    typedef T value_type;

    template<typename U>
    struct rebind {
      using other = pinned_allocator<U>;
    };

    pinned_allocator() noexcept {};

    template<class U>
    pinned_allocator(const pinned_allocator<U>&) noexcept
    {}

    bool operator==(const pinned_allocator&) const noexcept { return true; }

    bool operator!=(const pinned_allocator&) const noexcept { return false; }

    T* allocate(const std::size_t n) const
    {
      // The return value of allocate(0) is unspecified.
      // pinned_allocator returns nullptr in order to avoid depending
      // on malloc(0)'s implementation-defined behavior
      // (the implementation can define malloc(0) to return nullptr,
      // in which case the bad_alloc check below would fire).
      // All allocators can return nullptr in this case.
      if (n == 0) {
        return nullptr;
      }

      // All allocators should contain an integer overflow check.
      if (n > static_cast<std::size_t>(-1) / sizeof(T)) {
        throw std::bad_array_new_length();
      }

      void* pv;

      // Mallocator wraps Allen::malloc_host
      Allen::malloc_host(&pv, n * sizeof(T));

      // Allocators should throw std::bad_alloc in the case of memory allocation failure.
      if (pv == nullptr) {
        throw std::bad_alloc();
      }

      return static_cast<T*>(pv);
    }

    void deallocate(T* const p, const std::size_t) const noexcept { Allen::free_host(p); }
  };

  template<typename T>
  using pinned_vector = std::vector<T, pinned_allocator<T>>;
} // namespace Allen
