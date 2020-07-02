#include "CpuID.h"

namespace cpu_id {
  static std::unique_ptr<CpuID> cpu_id_instance;

  CpuID::CpuID(const unsigned level) : m_level(level)
  {
#if !defined(__APPLE__)
    __get_cpuid(m_level, &m_registers[0], &m_registers[1], &m_registers[2], &m_registers[3]);
#endif
  }

  bool CpuID::supports_feature(const unsigned bit, const CpuIDRegister reg_index) const
  {
    assert(static_cast<unsigned>(reg_index) < cpu_id_register_size);
    return static_cast<bool>((m_registers[static_cast<unsigned>(reg_index)] >> bit) & 0x01);
  }

  bool supports_feature(const unsigned bit, const CpuIDRegister reg_index)
  {
    if (!cpu_id::cpu_id_instance) {
      cpu_id::cpu_id_instance.reset(new CpuID {0x80000001});
    }
    return cpu_id_instance->supports_feature(bit, reg_index);
  }
} // namespace cpu_id