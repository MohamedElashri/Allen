#pragma once

#include "CudaCommon.h"

#ifdef KALMAN_DOUBLE_PRECISION
using KalmanFloat = double;
#else
using KalmanFloat = float;
#endif

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // Template declaration
  template<bool _sym, int _size>
  struct SquareMatrix;

  //----------------------------------------------------------------------
  // Non-symmetric, square matrix.
  template<int _size>
  struct SquareMatrix<false, _size> {
    int size;
    KalmanFloat vals[_size * _size];
    __host__ __device__ SquareMatrix()
    {
      size = _size;
      for (int i = 0; i < _size * _size; i++)
        vals[i] = 0.;
    }
    __host__ __device__ SquareMatrix(const KalmanFloat init_vals[_size * _size])
    {
      size = _size;
      for (int i = 0; i < _size * _size; i++)
        vals[i] = init_vals[i];
    }
    __host__ __device__ void SetElements(const KalmanFloat init_vals[_size * _size])
    {
      for (int i = 0; i < size * size; i++)
        vals[i] = init_vals[i];
    }
    __host__ __device__ KalmanFloat& operator()(int i, int j) { return vals[i * _size + j]; }
    __host__ __device__ const KalmanFloat& operator()(int i, int j) const { return vals[i * _size + j]; }
    __host__ __device__ KalmanFloat& operator[](int i) { return vals[i]; }
    __host__ __device__ const KalmanFloat& operator[](int i) const { return vals[i]; }
    __host__ __device__ SquareMatrix<false, _size> T()
    {
      SquareMatrix<false, _size> ret;
      for (int i = 0; i < _size; i++)
        for (int j = 0; j < _size; j++)
          ret(i, j) = vals[j * _size + i];
      return ret;
    }
    __host__ __device__ SquareMatrix<false, _size> T() const
    {
      SquareMatrix<false, _size> ret;
      for (int i = 0; i < _size; i++)
        for (int j = 0; j < _size; j++)
          ret(i, j) = vals[j * _size + i];
      return ret;
    }
  };

  //----------------------------------------------------------------------
  // Symmetric matrix.
  template<int _size>
  struct SquareMatrix<true, _size> {
    KalmanFloat vals[((_size * (_size + 1)) >> 1)];
    __host__ __device__ SquareMatrix()
    {
      for (int i = 0; i < ((_size * (_size + 1)) >> 1); i++)
        vals[i] = 0;
    }
    __host__ __device__ SquareMatrix(KalmanFloat init_vals[((_size * (_size + 1)) >> 1)])
    {
      for (int i = 0; i < ((_size * (_size + 1)) >> 1); i++)
        vals[i] = init_vals[i];
    }
    __host__ __device__ void SetElements(KalmanFloat init_vals[((_size * (_size + 1)) >> 1)])
    {
      for (int i = 0; i < ((_size * (_size + 1)) >> 1); i++)
        vals[i] = init_vals[i];
    }
    __host__ __device__ KalmanFloat& operator()(int i, int j)
    {
      if (i > j) {
        int tmp = i;
        i = j;
        j = tmp;
      }
      int idx = i;
      while (j > 0) {
        idx += j;
        j -= 1;
      }
      return vals[idx];
    }
    __host__ __device__ const KalmanFloat& operator()(int i, int j) const
    {
      if (i > j) {
        int tmp = i;
        i = j;
        j = tmp;
      }
      int idx = i;
      while (j > 0) {
        idx += j;
        j -= 1;
      }
      return vals[idx];
    }
    __host__ __device__ KalmanFloat& operator[](int i) { return vals[i]; }
    __host__ __device__ const KalmanFloat& operator[](int i) const { return vals[i]; }
  };

  //----------------------------------------------------------------------
  // Vector.
  template<int _size>
  struct Vector {
    KalmanFloat vals[_size];

    __host__ __device__ Vector();
    __host__ __device__ Vector(KalmanFloat init_vals[_size]);
    __host__ __device__ KalmanFloat& operator()(int i) { return vals[i]; }
    __host__ __device__ const KalmanFloat& operator()(int i) const { return vals[i]; }
    __host__ __device__ KalmanFloat& operator[](int i) { return vals[i]; }
    __host__ __device__ const KalmanFloat& operator[](int i) const { return vals[i]; }
  };

  template<int _size>
  __host__ __device__ Vector<_size>::Vector()
  {
    for (int i = 0; i < _size; i++)
      vals[i] = 0;
  }

  template<int _size>
  __host__ __device__ Vector<_size>::Vector(KalmanFloat init_vals[_size])
  {
    for (int i = 0; i < _size; i++)
      vals[i] = init_vals[i];
  }

  //----------------------------------------------------------------------
  // Invert a square matrix
  template<bool _sym, int _size>
  __host__ __device__ SquareMatrix<_sym, _size> inverse(const SquareMatrix<_sym, _size>& A)
  {
    SquareMatrix<_sym, _size> Ainv;
    SquareMatrix<false, _size> ut;
    SquareMatrix<false, _size> lt;

    // Decompose
    for (int i = 0; i < _size; i++) {
      // Upper triangular
      for (int k = i; k < _size; k++) {
        KalmanFloat sum = 0;
        for (int j = 0; j < i; j++)
          sum += lt(i, j) * ut(j, k);
        ut(i, k) = A(i, k) - sum;
      }
      // Lower triangular
      for (int k = i; k < _size; k++) {
        if (i == k)
          lt(i, i) = 1;
        else {
          KalmanFloat sum = 0;
          for (int j = 0; j < i; j++)
            sum += lt(k, j) * ut(j, i);
          lt(k, i) = (A(k, i) - sum) / ut(i, i);
        }
      }
    }

    // Invert triangular matrices.
    SquareMatrix<false, _size> utinv;
    SquareMatrix<false, _size> ltinv;
    // Set diagonals.
    for (int i = 0; i < _size; i++) {
      utinv(i, i) = 1.f / ut(i, i);
      ltinv(i, i) = 1.f / lt(i, i);
    }
    // Off-diagonal.
    for (int i = 0; i < _size; i++) {
      // Upper.
      for (int off = 1; off < _size - i; off++) {
        int j = i + off;
        KalmanFloat utval = 0;
        KalmanFloat ltval = 0;
        for (int k = i; k <= j; k++) {
          utval -= utinv(i, k) * ut(k, j);
          ltval -= ltinv(k, i) * lt(j, k);
        }
        utval /= ut(j, j);
        ltval /= lt(j, j);
        utinv(i, j) = utval;
        ltinv(j, i) = ltval;
      }
    }

    // Make the inverse.
    multiplySquareBySquare(utinv, ltinv, Ainv);
    return Ainv;
  }

  //----------------------------------------------------------------------
  // Multiply two square matrices. C=AxB.
  template<bool _symA, bool _symB, bool _symC, int _size>
  __device__ __host__ void multiplySquareBySquare(
    const SquareMatrix<_symA, _size>& A,
    const SquareMatrix<_symB, _size>& B,
    SquareMatrix<_symC, _size>& C)
  {
    for (int i = 0; i < _size; i++) {
      for (int j = 0; j < _size; j++) {
        KalmanFloat sum = 0;
        for (int k = 0; k < _size; k++)
          sum += A(i, k) * B(k, j);
        C(i, j) = sum;
      }
    }
  }

  //----------------------------------------------------------------------
  // Operator * Multiply two square matrices. C=A*B.
  template<bool _symA, bool _symB, int _size>
  __host__ __device__ SquareMatrix<false, _size> operator*(
    const SquareMatrix<_symA, _size>& A,
    const SquareMatrix<_symB, _size>& B)
  {
    SquareMatrix<false, _size> C;
    for (int i = 0; i < _size; i++) {
      for (int j = 0; j < _size; j++) {
        KalmanFloat sum = 0;
        for (int k = 0; k < _size; k++)
          sum += A(i, k) * B(k, j);
        C(i, j) = sum;
      }
    }
    return C;
  }

  //----------------------------------------------------------------------
  // Operator + Add two square matrices. C=A+B.
  template<bool _symA, bool _symB, int _size>
  __host__ __device__ SquareMatrix<false, _size> operator+(
    const SquareMatrix<_symA, _size>& A,
    const SquareMatrix<_symB, _size>& B)
  {
    SquareMatrix<false, _size> C;
    for (int i = 0; i < _size; i++) {
      for (int j = 0; j < _size; j++) {
        C(i, j) = A(i, j) + B(i, j);
      }
    }
    return C;
  }

  template<int _size>
  __host__ __device__ SquareMatrix<true, _size> operator+(
    const SquareMatrix<true, _size>& A,
    const SquareMatrix<true, _size>& B)
  {
    KalmanFloat res_vals[((_size * (_size + 1)) >> 1)];
    for (int i = 0; i < (((_size * (_size + 1)) >> 1)); i++) {
      res_vals[i] = A.vals[i] + B.vals[i];
    }
    return SquareMatrix<true, _size>(res_vals);
  }

  //----------------------------------------------------------------------
  // Operator - Subtract a square matrix from another. C=A-B.
  template<bool _symA, bool _symB, int _size>
  __host__ __device__ SquareMatrix<false, _size> operator-(
    const SquareMatrix<_symA, _size>& A,
    const SquareMatrix<_symB, _size>& B)
  {
    SquareMatrix<false, _size> C;
    for (int i = 0; i < _size; i++) {
      for (int j = 0; j < _size; j++) {
        C(i, j) = A(i, j) - B(i, j);
      }
    }
    return C;
  }

  template<int _size>
  __host__ __device__ SquareMatrix<true, _size> operator-(
    const SquareMatrix<true, _size>& A,
    const SquareMatrix<true, _size>& B)
  {
    KalmanFloat res_vals[((_size * (_size + 1)) >> 1)];
    for (int i = 0; i < (((_size * (_size + 1)) >> 1)); i++) {
      res_vals[i] = A.vals[i] - B.vals[i];
    }
    return SquareMatrix<true, _size>(res_vals);
  }

  //----------------------------------------------------------------------
  // Operator + Add two vectors. C=A+B.
  template<int _size>
  __host__ __device__ Vector<_size> operator+(const Vector<_size>& A, const Vector<_size>& B)
  {
    Vector<_size> C;
    for (int i = 0; i < _size; i++) {
      C(i) = A(i) + B(i);
    }
    return C;
  }

  //----------------------------------------------------------------------
  // Operator - Subtract a vector from another. C=A-B.
  template<int _size>
  __host__ __device__ Vector<_size> operator-(const Vector<_size>& A, const Vector<_size>& B)
  {
    Vector<_size> C;
    for (int i = 0; i < _size; i++) {
      C(i) = A(i) - B(i);
    }
    return C;
  }

  //----------------------------------------------------------------------
  // Operator * Multiply square matrix by vector. C=A*B.
  template<bool _symA, int _size>
  __host__ __device__ Vector<_size> operator*(const SquareMatrix<_symA, _size>& A, const Vector<_size>& B)
  {
    Vector<_size> C;
    for (int i = 0; i < _size; i++) {
      KalmanFloat sum = 0;
      for (int j = 0; j < _size; j++)
        sum += A(i, j) * B(j);
      C(i) = sum;
    }
    return C;
  }

  //----------------------------------------------------------------------
  // Operator for scalar multiplication of vectors.
  template<int _size>
  __host__ __device__ Vector<_size> operator*(const KalmanFloat& a, const Vector<_size> v)
  {
    Vector<_size> u;
    for (int i = 0; i < _size; i++)
      u(i) = v(i) * a;
    return u;
  }

  //----------------------------------------------------------------------
  // Operator for scalar multiplication of square matrices.
  template<bool _sym, int _size>
  __host__ __device__ SquareMatrix<_sym, _size> operator*(const KalmanFloat& a, const SquareMatrix<_sym, _size> M)
  {
    SquareMatrix<_sym, _size> aM;
    for (int i = 0; i < _size; i++)
      for (int j = 0; j < _size; j++)
        aM(i, j) = M(i, j) * a;
    return aM;
  }

  //----------------------------------------------------------------------
  // Operator for scalar division of vectors.
  template<int _size>
  __host__ __device__ Vector<_size> operator/(const Vector<_size> v, const KalmanFloat& a)
  {
    Vector<_size> u;
    for (int i = 0; i < _size; i++)
      u(i) = v(i) / a;
    return u;
  }

  //----------------------------------------------------------------------
  // Operator for scalar multiplication of square matrices.
  template<bool _sym, int _size>
  __host__ __device__ SquareMatrix<_sym, _size> operator/(const SquareMatrix<_sym, _size> M, const KalmanFloat& a)
  {
    SquareMatrix<_sym, _size> Moa;
    for (int i = 0; i < _size; i++)
      for (int j = 0; j < _size; j++)
        Moa(i, j) = M(i, j) / a;
    return Moa;
  }

  template<int _size>
  __host__ __device__ SquareMatrix<true, _size> AssignSymmetric(const SquareMatrix<false, _size>& A)
  {
    SquareMatrix<true, _size> B;
    for (int i = 0; i < _size; i++) {
      for (int j = i; j < _size; j++) {
        B(i, j) = A(i, j);
      }
    }
    return B;
  }

  typedef Vector<5> Vector5;
  typedef SquareMatrix<true, 5> SymMatrix5x5;
  typedef SquareMatrix<false, 5> Matrix5x5;

  __device__ __host__ inline void tensorProduct(const Vector<5>& u, const Vector<5>& v, SquareMatrix<true, 5>& A);

  __device__ __host__ inline void multiply_S5x5_2x1(const SquareMatrix<true, 5>& A, const Vector<2>& B, Vector<5>& V);

  __device__ __host__ inline void
  multiply_S5x5_S2x2(const SquareMatrix<true, 5>& A, const SquareMatrix<true, 2>& B, Vector<10>& V);

  __device__ __host__ inline void
  similarity_1x2_S5x5_2x1(const Vector<2>& A, const SquareMatrix<true, 5>& B, KalmanFloat& r);

  __device__ __host__ inline void
  similarity_5x2_2x2(const Vector<10>& K, const SquareMatrix<true, 2>& C, SquareMatrix<true, 5>& KCKt);

  __device__ __host__ inline KalmanFloat similarity_2x1_2x2(const Vector<2>& a, const SquareMatrix<true, 2>& C);

  __device__ __host__ inline SquareMatrix<true, 5> similarity_5_5(
    const SquareMatrix<false, 5>& F,
    const SquareMatrix<true, 5>& C);

  __device__ __host__ inline SquareMatrix<true, 5> similarity_5_5_alt(
    const SquareMatrix<false, 5>& F,
    const SquareMatrix<true, 5>& C);

  __device__ __host__ inline void WeightedAverage(
    const Vector<5>& x1,
    const SquareMatrix<true, 5>& C1,
    const Vector<5>& x2,
    const SquareMatrix<true, 5>& C2,
    Vector<5>& x,
    SquareMatrix<true, 5>& C);
  
  __device__ __host__ inline Vector<5> operator*(const Vector<10>& M, const Vector<2>& a);

} // namespace ParKalmanFilter

namespace ParKalmanFilter {

  //----------------------------------------------------------------------
  // Miscellaneous operators
  __host__ __device__ Vector<5> operator*(const Vector<10>& M, const Vector<2>& a)
  {
    Vector<5> b;
    for (int i = 0; i < 5; i++)
      b(i) = M(i) * a(0) + M(i + 5) * a(1);
    return b;
  }

  //----------------------------------------------------------------------
  // Symmetric tensor product of any two 5-element vectors.
  __device__ __host__ void tensorProduct(const Vector<5>& u, const Vector<5>& v, SquareMatrix<true, 5>& A)
  {
    // double* a = A.vals;
    A(0, 0) = u(0) * v(0);
    A(1, 0) = u(1) * v(0);
    A(1, 1) = u(1) * v(1);
    A(2, 0) = u(2) * v(0);
    A(2, 1) = u(2) * v(1);
    A(2, 2) = u(2) * v(2);
    A(3, 0) = u(3) * v(0);
    A(3, 1) = u(3) * v(1);
    A(3, 2) = u(3) * v(2);
    A(3, 3) = u(3) * v(3);
    A(4, 0) = u(4) * v(0);
    A(4, 1) = u(4) * v(1);
    A(4, 2) = u(4) * v(2);
    A(4, 3) = u(4) * v(3);
    A(4, 4) = u(4) * v(4);
  }

  //----------------------------------------------------------------------
  // Multiplication function from the original ParKalman code.
  __device__ __host__ void multiply_S5x5_2x1(const SquareMatrix<true, 5>& A, const Vector<2>& B, Vector<5>& V)
  {
    /*
    const double* a = A.vals;
    const double* b = B.vals;
    double* v = V.vals;
    v[0]=a[0] *b[0]+a[1] *b[1];
    v[1]=a[1] *b[0]+a[2] *b[1];
    v[2]=a[3] *b[0]+a[4] *b[1];
    v[3]=a[6] *b[0]+a[7] *b[1];
    v[4]=a[10]*b[0]+a[11]*b[1];
    */

    V(0) = A(0, 0) * B(0) + A(0, 1) * B(1);
    V(1) = A(1, 0) * B(0) + A(1, 1) * B(1);
    V(2) = A(2, 0) * B(0) + A(2, 1) * B(1);
    V(3) = A(3, 0) * B(0) + A(3, 1) * B(1);
    V(4) = A(4, 0) * B(0) + A(4, 1) * B(1);
  }

  //----------------------------------------------------------------------
  // Multiplication function from the original ParKalman code.
  __device__ __host__ void
  multiply_S5x5_S2x2(const SquareMatrix<true, 5>& A, const SquareMatrix<true, 2>& B, Vector<10>& V)
  {
    const KalmanFloat* a = A.vals;
    const KalmanFloat* b = B.vals;
    KalmanFloat* v = V.vals;
    v[0] = a[0] * b[0] + a[1] * b[1];
    v[5] = a[0] * b[1] + a[1] * b[2];

    v[1] = a[1] * b[0] + a[2] * b[1];
    v[6] = a[1] * b[1] + a[2] * b[2];

    v[2] = a[3] * b[0] + a[4] * b[1];
    v[7] = a[3] * b[1] + a[4] * b[2];

    v[3] = a[6] * b[0] + a[7] * b[1];
    v[8] = a[6] * b[1] + a[7] * b[2];

    v[4] = a[10] * b[0] + a[11] * b[1];
    v[9] = a[10] * b[1] + a[11] * b[2];
  }

  //----------------------------------------------------------------------
  // Similarity function from the original ParKalman code.
  __device__ __host__ void similarity_1x2_S5x5_2x1(const Vector<2>& A, const SquareMatrix<true, 5>& B, KalmanFloat& r)
  {
    // r = A(0)*(A(0)*B(0,0) + A(1)*B(0,1)) + A(1)*(A(0)*B(0,1) + A(1)*B(1,1));
    r = A(0) * A(0) * B(0, 0) + 2 * A(0) * A(1) * B(0, 1) + A(1) * A(1) * B(1, 1);
  }

  __device__ __host__ void
  similarity_5x2_2x2(const Vector<10>& K, const SquareMatrix<true, 2>& C, SquareMatrix<true, 5>& KCKt)
  {
    // SquareMatrix<false,5> temp;
    for (int i = 0; i < 5; i++) {
      // for(int j=0; j<5; j++){
      for (int j = i; j < 5; j++) {
        KCKt(i, j) = K(j) * (K(i) * C(0, 0) + K(i + 5) * C(1, 0)) + K(j + 5) * (K(i) * C(0, 1) + K(i + 5) * C(1, 1));
      }
    }
  }

  __device__ __host__ KalmanFloat similarity_2x1_2x2(const Vector<2>& a, const SquareMatrix<true, 2>& C)
  {
    // return a(0)*(a(0)*C(0,0)+a(1)*C(1,0)) + a(1)*(a(0)*C(0,1)+a(1)*C(1,1));
    return a(0) * a(0) * C(0, 0) + 2 * a(1) * a(0) * C(1, 0) + a(1) * a(1) * C(1, 1);
  }

  __device__ __host__ SquareMatrix<true, 5> similarity_5_5_alt(
    const SquareMatrix<false, 5>& F,
    const SquareMatrix<true, 5>& C)
  {
    SquareMatrix<false, 5> tmp = F * C;
    return AssignSymmetric(tmp * F.T());
  }

  __device__ __host__ SquareMatrix<true, 5> similarity_5_5(
    const SquareMatrix<false, 5>& F,
    const SquareMatrix<true, 5>& C)
  {
    SquareMatrix<true, 5> A;
    KalmanFloat* a = A.vals;
    const KalmanFloat* f = F.vals;
    const KalmanFloat* c = C.vals;
    KalmanFloat _0 = c[0] * f[0] + c[1] * f[1] + c[3] * f[2] + c[6] * f[3] + c[10] * f[4];
    KalmanFloat _1 = c[1] * f[0] + c[2] * f[1] + c[4] * f[2] + c[7] * f[3] + c[11] * f[4];
    KalmanFloat _2 = c[3] * f[0] + c[4] * f[1] + c[5] * f[2] + c[8] * f[3] + c[12] * f[4];
    KalmanFloat _3 = c[6] * f[0] + c[7] * f[1] + c[8] * f[2] + c[9] * f[3] + c[13] * f[4];
    KalmanFloat _4 = c[10] * f[0] + c[11] * f[1] + c[12] * f[2] + c[13] * f[3] + c[14] * f[4];
    a[0] = f[0] * _0 + f[1] * _1 + f[2] * _2 + f[3] * _3 + f[4] * _4;
    a[1] = f[5] * _0 + f[6] * _1 + f[7] * _2 + f[8] * _3 + f[9] * _4;
    a[3] = f[10] * _0 + f[11] * _1 + f[12] * _2 + f[13] * _3 + f[14] * _4;
    a[6] = f[15] * _0 + f[16] * _1 + f[17] * _2 + f[18] * _3 + f[19] * _4;
    a[10] = f[20] * _0 + f[21] * _1 + f[22] * _2 + f[23] * _3 + f[24] * _4;
    _0 = c[0] * f[5] + c[1] * f[6] + c[3] * f[7] + c[6] * f[8] + c[10] * f[9];
    _1 = c[1] * f[5] + c[2] * f[6] + c[4] * f[7] + c[7] * f[8] + c[11] * f[9];
    _2 = c[3] * f[5] + c[4] * f[6] + c[5] * f[7] + c[8] * f[8] + c[12] * f[9];
    _3 = c[6] * f[5] + c[7] * f[6] + c[8] * f[7] + c[9] * f[8] + c[13] * f[9];
    _4 = c[10] * f[5] + c[11] * f[6] + c[12] * f[7] + c[13] * f[8] + c[14] * f[9];
    a[2] = f[5] * _0 + f[6] * _1 + f[7] * _2 + f[8] * _3 + f[9] * _4;
    a[4] = f[10] * _0 + f[11] * _1 + f[12] * _2 + f[13] * _3 + f[14] * _4;
    a[7] = f[15] * _0 + f[16] * _1 + f[17] * _2 + f[18] * _3 + f[19] * _4;
    a[11] = f[20] * _0 + f[21] * _1 + f[22] * _2 + f[23] * _3 + f[24] * _4;
    _0 = c[0] * f[10] + c[1] * f[11] + c[3] * f[12] + c[6] * f[13] + c[10] * f[14];
    _1 = c[1] * f[10] + c[2] * f[11] + c[4] * f[12] + c[7] * f[13] + c[11] * f[14];
    _2 = c[3] * f[10] + c[4] * f[11] + c[5] * f[12] + c[8] * f[13] + c[12] * f[14];
    _3 = c[6] * f[10] + c[7] * f[11] + c[8] * f[12] + c[9] * f[13] + c[13] * f[14];
    _4 = c[10] * f[10] + c[11] * f[11] + c[12] * f[12] + c[13] * f[13] + c[14] * f[14];
    a[5] = f[10] * _0 + f[11] * _1 + f[12] * _2 + f[13] * _3 + f[14] * _4;
    a[8] = f[15] * _0 + f[16] * _1 + f[17] * _2 + f[18] * _3 + f[19] * _4;
    a[12] = f[20] * _0 + f[21] * _1 + f[22] * _2 + f[23] * _3 + f[24] * _4;
    _0 = c[0] * f[15] + c[1] * f[16] + c[3] * f[17] + c[6] * f[18] + c[10] * f[19];
    _1 = c[1] * f[15] + c[2] * f[16] + c[4] * f[17] + c[7] * f[18] + c[11] * f[19];
    _2 = c[3] * f[15] + c[4] * f[16] + c[5] * f[17] + c[8] * f[18] + c[12] * f[19];
    _3 = c[6] * f[15] + c[7] * f[16] + c[8] * f[17] + c[9] * f[18] + c[13] * f[19];
    _4 = c[10] * f[15] + c[11] * f[16] + c[12] * f[17] + c[13] * f[18] + c[14] * f[19];
    a[9] = f[15] * _0 + f[16] * _1 + f[17] * _2 + f[18] * _3 + f[19] * _4;
    a[13] = f[20] * _0 + f[21] * _1 + f[22] * _2 + f[23] * _3 + f[24] * _4;
    _0 = c[0] * f[20] + c[1] * f[21] + c[3] * f[22] + c[6] * f[23] + c[10] * f[24];
    _1 = c[1] * f[20] + c[2] * f[21] + c[4] * f[22] + c[7] * f[23] + c[11] * f[24];
    _2 = c[3] * f[20] + c[4] * f[21] + c[5] * f[22] + c[8] * f[23] + c[12] * f[24];
    _3 = c[6] * f[20] + c[7] * f[21] + c[8] * f[22] + c[9] * f[23] + c[13] * f[24];
    _4 = c[10] * f[20] + c[11] * f[21] + c[12] * f[22] + c[13] * f[23] + c[14] * f[24];
    a[14] = f[20] * _0 + f[21] * _1 + f[22] * _2 + f[23] * _3 + f[24] * _4;
    return A;
  }

  __host__ __device__ void WeightedAverage(
    const Vector<5>& x1,
    const SquareMatrix<true, 5>& C1,
    const Vector<5>& x2,
    const SquareMatrix<true, 5>& C2,
    Vector<5>& x,
    SquareMatrix<true, 5>& C)
  {
    SquareMatrix<true, 5> invR = C1 + C2;
    invR = inverse(invR);
    SquareMatrix<false, 5> K = C1 * invR;
    x = x1 + K * (x2 - x1);
    C = AssignSymmetric(K * C2);
  }

} // namespace ParKalmanFilter
