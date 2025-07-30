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
#include "CPUID.h"

namespace cpu_id {
  static std::unique_ptr<CpuID> cpu_id_instance;

#if !defined(__APPLE__) && defined(__x86_64__)
  CpuID::CpuID(const unsigned level) : m_level(level)
  {
    __get_cpuid(m_level, &m_registers[0], &m_registers[1], &m_registers[2], &m_registers[3]);
  }
#else
  CpuID::CpuID(const unsigned) {}
#endif

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