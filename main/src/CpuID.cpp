#include "CpuID.h"

namespace cpu_id {
  static std::unique_ptr<CpuID> cpu_id_instance;

  CpuID::CpuID(const uint level) : m_level(level)
  {
    __get_cpuid(m_level, &m_registers[0], &m_registers[1], &m_registers[2], &m_registers[3]);
  }

  bool CpuID::supports_feature(const uint bit, const CpuIDRegister reg_index) const
  {
    assert(static_cast<uint>(reg_index) < cpu_id_register_size);
    return static_cast<bool>((m_registers[static_cast<uint>(reg_index)] >> bit) & 0x01);
  }

  bool supports_feature(const uint bit, const CpuIDRegister reg_index)
  {
    return cpu_id_instance->supports_feature(bit, reg_index);
  }

  void reset_cpuid() {
    if (!cpu_id::cpu_id_instance) {
      cpu_id::cpu_id_instance.reset(new CpuID {0x80000001});
    }
  }
} // namespace cpu_id