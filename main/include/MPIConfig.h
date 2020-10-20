/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <mpi.h>
#include <limits.h>

// Determine size of size_t for MPI type
#if SIZE_MAX == UCHAR_MAX
#define MPI_SIZE_T MPI_UNSIGNED_CHAR
#elif SIZE_MAX == USHRT_MAX
#define MPI_SIZE_T MPI_UNSIGNED_SHORT
#elif SIZE_MAX == UINT_MAX
#define MPI_SIZE_T MPI_UNSIGNED
#elif SIZE_MAX == ULONG_MAX
#define MPI_SIZE_T MPI_UNSIGNED_LONG
#elif SIZE_MAX == ULLONG_MAX
#define MPI_SIZE_T MPI_UNSIGNED_LONG_LONG
#else
#error "size_t size could not be determined."
#endif

namespace MPI {
  // MPI ranks of sender and receiver
  constexpr int receiver = 0;

  // Required MPI communication size (number of ranks)
  constexpr int comm_size = 3;

  // Chunk size of MDF events
  // Note: With MEPs, this in principle may not be needed
  // ie. 1 MiB
  constexpr int mdf_chunk_size = 1024 * 1024;

  // Rank of current process
  extern int rank;

  namespace message {
    // Message tags
    constexpr int test = 1;
    constexpr int packing_factor = 2;
    constexpr int number_of_meps = 3;
    constexpr int max_file_size = 4;
    constexpr int event_size = 5;
    constexpr int window_size = 6;

    // Event sends will start with tag start, and cycle every modulo
    // ie:
    // const auto tag = event_send_tag_start + (i % event_send_tag_modulo);
    constexpr int event_send_tag_start = 100;
    // constexpr int event_send_tag_modulo = 1024;
  } // namespace message

  std::string rank_str();
} // namespace MPI
