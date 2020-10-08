/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <cassert>

#ifdef __x86_64__
#include <x86intrin.h>

#ifdef __APPLE__
#include <CpuID.h>
#else
#include <cpuid.h>
#endif

#endif

namespace cpu_id {
  constexpr unsigned cpu_id_register_size = 4;
  enum class CpuIDRegister : unsigned { eax = 0, ebx = 1, ecx = 2, edx = 3 };

  struct CpuID {
  private:
    unsigned m_level = 0;
    std::array<uint32_t, cpu_id_register_size> m_registers;

  public:
    CpuID(const unsigned level);
    bool supports_feature(const unsigned bit, const CpuIDRegister reg_index = CpuIDRegister::ecx) const;
  };

  bool supports_feature(const unsigned bit, const CpuIDRegister reg_index = CpuIDRegister::ecx);
} // namespace cpu_id
