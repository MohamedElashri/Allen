/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdouble-promotion"
#if __clang_major__ >= 10
#pragma clang diagnostic ignored "-Wdeprecated-copy"
#endif
#elif defined(__CUDACC__)
#pragma push
#pragma diag_suppress = 3141
#elif __GNUC__ >= 8

// Note: UMESIMD is not maintained since 2017 and therefore AVX512F is not supported
//       on GCC-8 onwards. The current only way to express "do not include
//       AVX512F-related UMESIMD include files" is by undefining __AVX512F__.
#if defined(__AVX512F__)
#undef __AVX512F__
#define ADD_BACK_AVX512F
#endif

#pragma GCC diagnostic ignored "-Wdouble-promotion"
#if __GNUC__ >= 9
#pragma GCC diagnostic ignored "-Wdeprecated-copy"
#endif
#endif

#include "umesimd/UMESimd.h"

#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__CUDACC__)
#pragma pop
#elif __GNUC__ >= 8
#pragma GCC diagnostic pop
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
      using t = UME::SIMD::SIMDVecMask<1>;
    };

#if defined(TARGET_DEVICE_CPU)

#if defined(__AVX512F__)
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
      using t = UME::SIMD::SIMDVecMask<16>;
    };

    template<typename T>
    using Vector512 = typename Vector_t<T, vector_backend::b512>::t;
#else
    template<typename T>
    using Vector512 = typename Vector_t<T, vector_backend::scalar>::t;
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
      using t = UME::SIMD::SIMDVecMask<8>;
    };

    template<typename T>
    using Vector256 = typename Vector_t<T, vector_backend::b256>::t;
#else
    template<typename T>
    using Vector256 = typename Vector_t<T, vector_backend::scalar>::t;
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
      using t = UME::SIMD::SIMDVecMask<4>;
    };

    template<typename T>
    using Vector128 = typename Vector_t<T, vector_backend::b128>::t;
#else
    template<typename T>
    using Vector128 = typename Vector_t<T, vector_backend::scalar>::t;
#endif

#else
    template<typename T>
    using Vector512 = typename Vector_t<T, vector_backend::scalar>::t;

    template<typename T>
    using Vector256 = typename Vector_t<T, vector_backend::scalar>::t;

    template<typename T>
    using Vector128 = typename Vector_t<T, vector_backend::scalar>::t;
#endif

    // Choose default vector width at compile time
    // based on:
    // * Architecture capability
    // * Target (only consider CPU for vectors of length greater than 1)
#ifdef TARGET_DEVICE_CPU
#ifdef CPU_STATIC_VECTOR_WIDTH
    template<typename T>
    using Vector = typename Vector_t<T, CPU_STATIC_VECTOR_WIDTH>::t;
#elif defined(__AVX512F__) || defined(__AVX512__)
    template<typename T>
    using Vector = Vector512<T>;
#elif defined(__AVX__)
    template<typename T>
    using Vector = Vector256<T>;
#elif defined(__SSE__) || defined(__aarch64__) || defined(__ALTIVEC__)
    template<typename T>
    using Vector = Vector128<T>;
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
    constexpr size_t vector_length()
    {
      return Vector<T>::length();
    }

    // Length of specific vector lengths
    template<typename T = float>
    constexpr size_t vector128_length()
    {
      return Vector128<T>::length();
    }

    template<typename T = float>
    constexpr size_t vector256_length()
    {
      return Vector256<T>::length();
    }

    template<typename T = float>
    constexpr size_t vector512_length()
    {
      return Vector512<T>::length();
    }

    // Prints a vector
    template<typename VEC_T>
    void print_vector(VEC_T const& x, const std::string& name = "")
    {
      if (name != "") {
        std::cout << name << ": ";
      }
      std::cout << "[";
      for (unsigned int i = 0; i < VEC_T::length(); i++) {
        typename UME::SIMD::SIMDTraits<VEC_T>::SCALAR_T x_i = x[i];
        std::cout << x_i;
        if (i != VEC_T::length() - 1) {
          std::cout << ", ";
        }
      }
      std::cout << "]\n";
    }
  } // namespace device
} // namespace Allen

template<typename T, unsigned I>
__device__ inline UME::SIMD::SIMDVec_f<T, I> signselect(
  const UME::SIMD::SIMDVec_f<T, I>& x,
  const UME::SIMD::SIMDVec_f<T, I>& a,
  const UME::SIMD::SIMDVec_f<T, I>& b)
{
  return a.blend(x.cmple(0.f), b);
}

template<unsigned I>
__device__ inline UME::SIMD::SIMDVec_f<float, I> fabsf(const UME::SIMD::SIMDVec_f<float, I>& v)
{
  return v.abs();
}

template<unsigned I>
__device__ inline UME::SIMD::SIMDVec_f<double, I> abs(const UME::SIMD::SIMDVec_f<double, I>& v)
{
  return v.abs();
}

template<typename T, unsigned I>
__device__ inline UME::SIMD::SIMDVec_f<T, I> copysignf(
  const UME::SIMD::SIMDVec_f<T, I>& a,
  const UME::SIMD::SIMDVec_f<T, I>& b)
{
  return a.copysign(b);
}

__device__ inline float signselect(const float& s, const float& a, const float& b) { return (s > 0) ? a : b; }

// Note: See AVX512 compatibility issues of UMESIMD above
#if defined(ADD_BACK_AVX512F)
#define __AVX512F__
#endif
