#include "CudaCommon.h"

template<typename T>
struct LineHandler {

  bool (*m_line)(const T& candidate);

  __device__ LineHandler(bool (*line)(const T& candidate));

  __device__ void operator()(const T* candidates, const int n_candidates, bool* results);
};

template<typename T>
__device__ LineHandler<T>::LineHandler(bool (*line)(const T& candidate))
{
  m_line = line;
}

template<typename T>
__device__ void LineHandler<T>::operator()(const T* candidates, const int n_candidates, bool* results)
{
  for (int i_cand = threadIdx.x; i_cand < n_candidates; i_cand += blockDim.x) {
    results[i_cand] = m_line(candidates[i_cand]);
  }
}
