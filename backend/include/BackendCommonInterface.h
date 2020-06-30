#pragma once

namespace Allen {
  namespace device {
    /**
     * @brief Holds the current local properties.
     */
    template<unsigned long I>
    struct local_t {
      constexpr static unsigned id();
      constexpr static unsigned size();
    };

    /**
     * @brief Holds the current global properties.
     */
    template<unsigned long I>
    struct global_t {
      constexpr static unsigned id();
      constexpr static unsigned size();
    };
  } // namespace device
} // namespace Allen
