#pragma once

namespace Allen {
  /**
   * @brief Holds the current local properties.
   */  
  template<unsigned long I>
  class local_t {
    constexpr static unsigned id();
    constexpr static unsigned size();
  };

  /**
   * @brief Holds the current global properties.
   */
  template<unsigned long I>
  class global_t {
    constexpr static unsigned id();
    constexpr static unsigned size();
  };
} // namespace Allen
