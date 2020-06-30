#pragma once

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdouble-promotion"
#pragma clang diagnostic ignored "-Wdeprecated-copy"
#elif defined(__CUDACC__)
#pragma push
#pragma diag_suppress = 3141
#endif

#include "umesimd/UMESimd.h"

#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__CUDACC__)
#pragma pop
#endif

namespace Allen {
  namespace device {
    namespace vector_backend {
      constexpr static unsigned long scalar = 0;
      constexpr static unsigned long b128 = 1;
      constexpr static unsigned long b256 = 2;
      constexpr static unsigned long b512 = 3;
    } // namespace vector_backend

    template<typename TYPE, unsigned long I>
    struct Vector_t;

    template<>
    struct Vector_t<float, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_f<float, 1>;
    };
    template<>
    struct Vector_t<double, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_f<double, 1>;
    };
    template<>
    struct Vector_t<uint64_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_u<uint64_t, 1>;
    };
    template<>
    struct Vector_t<uint32_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_u<uint32_t, 1>;
    };
    template<>
    struct Vector_t<uint16_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_u<uint16_t, 1>;
    };
    template<>
    struct Vector_t<uint8_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_u<uint8_t, 1>;
    };
    template<>
    struct Vector_t<int64_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_i<int64_t, 1>;
    };
    template<>
    struct Vector_t<int32_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_i<int32_t, 1>;
    };
    template<>
    struct Vector_t<int16_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_i<int16_t, 1>;
    };
    template<>
    struct Vector_t<int8_t, vector_backend::scalar> {
      using t = UME::SIMD::SIMDVec_i<int8_t, 1>;
    };
    template<>
    struct Vector_t<bool, vector_backend::scalar> {
      using t = UME::SIMD::SIMDMask1;
    };

#if defined(TARGET_DEVICE_CPU)

#if defined(__AVX512F__) || defined(__AVX512__)
    template<>
    struct Vector_t<float, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_f<float, 16>;
    };
    template<>
    struct Vector_t<double, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_f<double, 8>;
    };
    template<>
    struct Vector_t<uint64_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_u<uint64_t, 8>;
    };
    template<>
    struct Vector_t<uint32_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_u<uint32_t, 16>;
    };
    template<>
    struct Vector_t<uint16_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_u<uint16_t, 16>;
    };
    template<>
    struct Vector_t<uint8_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_u<uint8_t, 16>;
    };
    template<>
    struct Vector_t<int64_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_i<int64_t, 8>;
    };
    template<>
    struct Vector_t<int32_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_i<int32_t, 16>;
    };
    template<>
    struct Vector_t<int16_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_i<int16_t, 16>;
    };
    template<>
    struct Vector_t<int8_t, vector_backend::b512> {
      using t = UME::SIMD::SIMDVec_i<int8_t, 16>;
    };
    template<>
    struct Vector_t<bool, vector_backend::b512> {
      using t = UME::SIMD::SIMDMask16;
    };
#endif
#if defined(__AVX__)
    template<>
    struct Vector_t<float, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_f<float, 8>;
    };
    template<>
    struct Vector_t<double, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_f<double, 4>;
    };
    template<>
    struct Vector_t<uint64_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_u<uint64_t, 4>;
    };
    template<>
    struct Vector_t<uint32_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_u<uint32_t, 8>;
    };
    template<>
    struct Vector_t<uint16_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_u<uint16_t, 8>;
    };
    template<>
    struct Vector_t<uint8_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_u<uint8_t, 8>;
    };
    template<>
    struct Vector_t<int64_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_i<int64_t, 4>;
    };
    template<>
    struct Vector_t<int32_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_i<int32_t, 8>;
    };
    template<>
    struct Vector_t<int16_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_i<int16_t, 8>;
    };
    template<>
    struct Vector_t<int8_t, vector_backend::b256> {
      using t = UME::SIMD::SIMDVec_i<int8_t, 8>;
    };
    template<>
    struct Vector_t<bool, vector_backend::b256> {
      using t = UME::SIMD::SIMDMask8;
    };
#endif
#if defined(__SSE__) || defined(__ALTIVEC__) || defined(__aarch64__)
    template<>
    struct Vector_t<float, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_f<float, 4>;
    };
    template<>
    struct Vector_t<double, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_f<double, 2>;
    };
    template<>
    struct Vector_t<uint64_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_u<uint64_t, 2>;
    };
    template<>
    struct Vector_t<uint32_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_u<uint32_t, 4>;
    };
    template<>
    struct Vector_t<uint16_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_u<uint16_t, 4>;
    };
    template<>
    struct Vector_t<uint8_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_u<uint8_t, 4>;
    };
    template<>
    struct Vector_t<int64_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_i<int64_t, 2>;
    };
    template<>
    struct Vector_t<int32_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_i<int32_t, 4>;
    };
    template<>
    struct Vector_t<int16_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_i<int16_t, 4>;
    };
    template<>
    struct Vector_t<int8_t, vector_backend::b128> {
      using t = UME::SIMD::SIMDVec_i<int8_t, 4>;
    };
    template<>
    struct Vector_t<bool, vector_backend::b128> {
      using t = UME::SIMD::SIMDMask4;
    };
#endif
#endif

    // Choose default vector width at compile time
    // based on:
    // * Architecture capability
    // * Target (only consider CPU for vectors of length greater than 1)
#ifdef TARGET_DEVICE_CPU
#ifdef STATIC_VECTOR_WIDTH
    template<typename T>
    using Vector = typename Vector_t<STATIC_VECTOR_WIDTH, T>::t;
#elif defined(__AVX512F__) || defined(__AVX512__)
    template<typename T>
    using Vector = typename Vector_t<T, vector_backend::b512>::t;
#elif defined(__AVX__)
    template<typename T>
    using Vector = typename Vector_t<T, vector_backend::b256>::t;
#elif defined(__SSE__) || defined(__aarch64__) || defined(__ALTIVEC__)
    template<typename T>
    using Vector = typename Vector_t<T, vector_backend::b128>::t;
#else
    template<typename T>
    using Vector = typename Vector_t<T, vector_backend::scalar>::t;
#endif
#else
    template<typename T>
    using Vector = typename Vector_t<T, vector_backend::scalar>::t;
#endif

    // Length of currently configured Vector
    template<typename T = float>
    constexpr size_t vector_length() {
      return Vector<T>::length();
    }
  } // namespace device
} // namespace Allen