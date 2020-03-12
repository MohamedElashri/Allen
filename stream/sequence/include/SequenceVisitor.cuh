#pragma once

#include "CheckerInvoker.h"
#include "Logger.h"
#include "RuntimeOptions.h"
#include "Constants.cuh"
#include "HostBuffers.cuh"
#include "Constants.cuh"

template<typename T>
struct SequenceVisitor {
  /**
   * @brief Invokes the specific checker for the algorithm T.
   */
  static void check(HostBuffers&, const Constants&, const CheckerInvoker&, MCEvents const&) {}
};
