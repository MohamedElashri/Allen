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

#include <array>
#include <cstdint>
#include <memory>
#include <cassert>

#ifdef __x86_64__
#include <x86intrin.h>

#ifdef __APPLE__
#include <CPUID.h>
#else
#include <cpuid.h>
#endif

#endif

namespace cpu_id {
  constexpr unsigned cpu_id_register_size = 4;
  enum class CpuIDRegister : unsigned { eax = 0, ebx = 1, ecx = 2, edx = 3 };

  struct CpuID {
  private:
#if !defined(__APPLE__) && defined(__x86_64__)
    unsigned m_level = 0;
#endif
    std::array<uint32_t, cpu_id_register_size> m_registers {0, 0, 0, 0};

  public:
    CpuID(const unsigned level);
    bool supports_feature(const unsigned bit, const CpuIDRegister reg_index = CpuIDRegister::ecx) const;
  };

  bool supports_feature(const unsigned bit, const CpuIDRegister reg_index = CpuIDRegister::ecx);
} // namespace cpu_id
