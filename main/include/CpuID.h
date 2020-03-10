#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <x86intrin.h>
#include <cpuid.h>
#include <cassert>

namespace cpu_id {
  constexpr uint cpu_id_register_size = 4;
  enum class CpuIDRegister : uint { eax = 0, ebx = 1, ecx = 2, edx = 3 };

  struct CpuID {
  private:
    uint m_level = 0;
    std::array<uint32_t, cpu_id_register_size> m_registers;

  public:
    CpuID(const uint level);
    bool supports_feature(const uint bit, const CpuIDRegister reg_index = CpuIDRegister::ecx) const;
  };

  bool supports_feature(const uint bit, const CpuIDRegister reg_index = CpuIDRegister::ecx);

  void reset_cpuid();
} // namespace cpu_id
