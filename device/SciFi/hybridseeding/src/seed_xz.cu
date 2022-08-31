/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "seed_xz.cuh"
#include "BinarySearch.cuh"
#include "hybrid_seeding_helpers.cuh"
#include "hybrid_seeding_case.cuh"
#include "memory_optim.cuh"

/**
 * @brief Seeding in SciFi 1st stage with x_z layers
 * @detail first implementation of seeding starting with x_z layers to fit under HLT1 timing budget.
 */

namespace {
  // For a given pair of hits, one in the first layer, the other in the second layer, calculate interesting paramaters.
  __device__ seed_xz::TwoHitCombination
  makeTwoHitCombination(const hybrid_seeding::Case& currentCase, const float firstHit, const float lastHit)
  {
    seed_xz::TwoHitCombination hitComb;
    hitComb.tx = (lastHit - firstHit) * currentCase.invZlZf;  //-LoH: average slope
    hitComb.xRef = firstHit - currentCase.dz[0] * hitComb.tx; //-LoH: position at z=zRef
    hitComb.xProj = firstHit - hitComb.tx * currentCase.t1_z; //-LoH: extrapolated position at z=0. Used only for 1/p
                                                              // calculation. Could be changed for 1 fewer terms
    float q = copysignf(1.f, -hitComb.xProj);
    hitComb.xProj *= -q; // now absolute value
    // SPEEDUP: is the quadratic term really needed considering our momentum?
    // SPEEDUP: use x0 rather than invP (frees a register)
    hitComb.invP = hitComb.xProj * (currentCase.invPTerms_1 + currentCase.invPTerms_2 * hitComb.xProj);
    hitComb.xProj = hitComb.xRef + currentCase.dz[2] * hitComb.tx; // xProj is now the projected x on T2x1

    // FIXME: This tuning should be improved
    hitComb.maxPara = hitComb.xProj - q * (currentCase.threeHit0 + hitComb.invP * currentCase.threeHit1);
    hitComb.minPara = hitComb.xProj - q * (-2.f * currentCase.threeHit0 + hitComb.invP * (currentCase.threeHit1));
    if (q > 0.f) {
      float temp = hitComb.minPara;
      hitComb.minPara = hitComb.maxPara;
      hitComb.maxPara = temp;
    }
    return hitComb;
  }

  __device__ int findRemainingHit(const float tolRem, float& predPos, int nHits, float* hits)
  {
    auto minIdx = seeding::searchBin(predPos, hits, nHits);
    predPos -= hits[minIdx];
    if (std::fabs(predPos) > tolRem) return SciFi::Constants::INVALID_IDX;
    return minIdx;
  }

  __device__ SciFi::Seeding::TrackXZ make_trackXZ(
    SciFi::ConstHits& scifi_hits,
    unsigned int* zone_offset,
    const seed_xz::multiHitCombination& multiHitComb,
    float chi2ndof)
  {
    int n_hits = 0;
    SciFi::Seeding::TrackXZ track;
    track.chi2 = chi2ndof;

    for (int iLayer = 0; iLayer < 6; iLayer++) {
      track.idx[iLayer] = multiHitComb.idx[iLayer];
      if (multiHitComb.idx[iLayer] == SciFi::Constants::INVALID_IDX) continue;
      auto hit_idx = zone_offset[iLayer] + multiHitComb.idx[iLayer];
      track.ids[n_hits] = scifi_hits.id(hit_idx);
      track.hits[n_hits++] = hit_idx;
    }
    track.number_of_hits = n_hits;
    track.ax = multiHitComb.ax;
    track.bx = multiHitComb.bx;
    track.cx = multiHitComb.cx;

    return track;
  }

  // SPEEDUP: in reality, there are only 4 possible LHS matrices, so we could precalculate them, most of the detMi and
  // detM
  __device__ float fitXZ(const hybrid_seeding::Case& currentCase, seed_xz::multiHitCombination& hitComb)
  {
    const unsigned int layers[6] = {currentCase.iFirst,
                                    currentCase.iLast,
                                    currentCase.iMiddle,
                                    currentCase.iRem[0],
                                    currentCase.iRem[1],
                                    currentCase.iRem[2]};

    float rhs[3] = {0.f};
    float lhs[6];
    for (auto i = 0; i < 6; i++)
      lhs[i] = currentCase.startingFitMatrix[i];
    for (auto i = 3; i < 6; i++) {
      if (hitComb.idx[layers[i]] == SciFi::Constants::INVALID_IDX) {
        continue;
      }
      lhs[0]++;
      lhs[1] += currentCase.dz[i];
      lhs[2] += currentCase.dz2[i];
      lhs[3] += currentCase.dz[i] * currentCase.dz[i];
      lhs[4] += currentCase.dz2[i] * currentCase.dz[i];
      lhs[5] += currentCase.dz2[i] * currentCase.dz2[i];
      rhs[0] -= hitComb.delta_x[i];
      rhs[1] -= hitComb.delta_x[i] * currentCase.dz[i];
      rhs[2] -= hitComb.delta_x[i] * currentCase.dz2[i];
    }
    // Fit x
    // SPEEDUP: if we have enough registers, we could cache these
    // There are only 4 possible detM, which is why there is no detM != 0 test
    // SPEEDUP: if we have enough registers, we could at least calculate only once some common terms
    // e.g
    // float term_3544 = lhs[3] * lhs[5] - lhs[4] * lhs[4] (used 2 times)
    // float term_2415 = lhs[4] * lhs[2] - lhs[5] * lhs[1] (used 3 times)
    // float term_1423 = lhs[1] * lhs[4] - lhs[2] * lhs[3] (used 3 times)
    // float term_1204 = lhs[1] * lhs[2] - lhs[0] * lhs[4] (used 2 times)
    float detM = lhs[0] * (lhs[3] * lhs[5] - lhs[4] * lhs[4]) + lhs[1] * (lhs[4] * lhs[2] - lhs[5] * lhs[1]) +
                 lhs[2] * (lhs[1] * lhs[4] - lhs[2] * lhs[3]);
    float detM0 = rhs[0] * (lhs[3] * lhs[5] - lhs[4] * lhs[4]) + rhs[1] * (lhs[4] * lhs[2] - lhs[5] * lhs[1]) +
                  rhs[2] * (lhs[1] * lhs[4] - lhs[2] * lhs[3]);
    float detM1 = rhs[0] * (lhs[2] * lhs[4] - lhs[1] * lhs[5]) + rhs[1] * (lhs[0] * lhs[5] - lhs[2] * lhs[2]) +
                  rhs[2] * (lhs[1] * lhs[2] - lhs[0] * lhs[4]);
    float detM2 = rhs[0] * (lhs[1] * lhs[4] - lhs[2] * lhs[3]) + rhs[1] * (lhs[1] * lhs[2] - lhs[0] * lhs[4]) +
                  rhs[2] * (lhs[0] * lhs[3] - lhs[1] * lhs[1]);
    hitComb.ax += detM0 / detM;
    hitComb.bx += detM1 / detM;
    hitComb.cx += detM2 / detM;
    // TODO: Refit?
    float score = 0.f;
    for (unsigned i = 0; i < 3; i++) { // SPEEDUP: the division by detM is probably useless
      float err = (detM0 + detM1 * currentCase.dz[i] + detM2 * currentCase.dz2[i]) / detM;
      score += err * err;
    }
    for (unsigned i = 3; i < 6; i++) { // SPEEDUP: the division by detM is probably useless
      if (hitComb.idx[layers[i]] == SciFi::Constants::INVALID_IDX) continue;
      float err = hitComb.delta_x[i] + (detM0 + detM1 * currentCase.dz[i] + detM2 * currentCase.dz2[i]) / detM;
      score += err * err;
    }
    // Make track
    // FIXME: Hack to make clone selection systematically prefer tracks with more hits
    if (lhs[0] == 5) score *= 10.f;
    score += currentCase.scoreOffset; // if 2 tracks using the same hits have the same chi2, privilagiate the first case
    return score;
  }

  template<bool limitTriplets>
  __device__ void makeTriplets(
    unsigned* triplets,
    unsigned& nTriplets,
    const hybrid_seeding::Case& currentCase,
    seeding::HitCache& hits,
    const unsigned int* layers)
  {

    unsigned maxTripletPerFirstHit = seeding::Triplet::maxTriplets / hits.size[layers[0]];
    _unused(maxTripletPerFirstHit);

    for (unsigned int firstHitIdx = threadIdx.x; firstHitIdx < hits.size[layers[0]]; firstHitIdx += blockDim.x) {
      float xFirst = hits.hit(layers[0], firstHitIdx);
      float maxXl = xFirst * currentCase.twoHitScale + currentCase.tol2Hit;
      float minXl = maxXl - 2.f * currentCase.tol2Hit;

      unsigned nCandidates = 0;
      _unused(nCandidates);
      // SPEEDUP: cache last layer first hit
      auto startSecond =
        hybrid_seeding::binary_search_leftmost_unrolled(hits.layer(layers[1]), hits.size[layers[1]], minXl);
      for (auto secondHitIdx = startSecond; secondHitIdx < hits.size[layers[1]]; secondHitIdx++) {
        float xLast = hits.hit(layers[1], secondHitIdx);
        if (xLast > maxXl) break;
        auto twoHitComb = makeTwoHitCombination(currentCase, xFirst, xLast); // New parameters
        // Look for parabola hits and update bounds
        // BENCHMARK EFFICIENCY: make a second loop in T2x2
        auto startThird = hybrid_seeding::binary_search_leftmost_unrolled(
          hits.layer(layers[2]), hits.size[layers[2]], twoHitComb.minPara);
        for (auto thirdHitIdx = startThird; thirdHitIdx < hits.size[layers[2]]; thirdHitIdx++) {
          auto xMiddle = hits.hit(layers[2], thirdHitIdx);
          // FIXME: adding 1.f to tolerances increases efficiencies by 1.2%
          if (xMiddle > twoHitComb.maxPara) break;

          if constexpr (limitTriplets) {
            if (nCandidates >= maxTripletPerFirstHit) break;
            nCandidates++;
          }

          auto idx = atomicAdd(&nTriplets, 1);
          if (idx >= seeding::Triplet::maxTriplets) break;
          triplets[idx] = seeding::Triplet(firstHitIdx, secondHitIdx, thirdHitIdx).indices;
        } // third hit
      }   // second hit
    }     // first hit
  }
} // namespace

INSTANTIATE_ALGORITHM(seed_xz::seed_xz_t);

void seed_xz::seed_xz_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_hits_working_mem_t>(arguments, first<host_scifi_hit_count_t>(arguments));
  set_size<dev_count_hits_working_mem_t>(arguments, 1);
  set_size<dev_triplets_t>(arguments, first<host_number_of_events_t>(arguments) * seeding::Triplet::maxTriplets);
  // Real output
  set_size<host_seeding_tracksXZ_t>(
    arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::Nmax_seed_xz);
  set_size<host_seeding_number_of_tracksXZ_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_seeding_tracksXZ_t>(
    arguments, first<host_number_of_events_t>(arguments) * SciFi::Constants::Nmax_seed_xz);
  set_size<dev_seeding_number_of_tracksXZ_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_seeding_number_of_tracksXZ_part0_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_seeding_number_of_tracksXZ_part1_t>(arguments, first<host_number_of_events_t>(arguments));
}

void seed_xz::seed_xz_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_seeding_number_of_tracksXZ_t>(arguments, 0, context);
  Allen::memset_async<dev_count_hits_working_mem_t>(arguments, 0, context);

  global_function(seed_xz)(dim3(size<dev_event_list_t>(arguments)), dim3(128), context)(arguments);
}

__global__ void seed_xz::seed_xz(seed_xz::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  // Output tracks (global memory)
  SciFi::Seeding::TrackXZ* reconstructed_tracksXZ_global =
    parameters.dev_seeding_tracksXZ + event_number * SciFi::Constants::Nmax_seed_xz;

  unsigned* triplets = parameters.dev_triplets + event_number * seeding::Triplet::maxTriplets;

  // Shared between parts
  unsigned nReconstructedTracks = 0;
  hybrid_seeding::Case Case0(0, 2, 4, 1, 3, 5, 3000.f, 0);
  hybrid_seeding::Case Case1(1, 3, 5, 0, 2, 4, 3000.f, 0.01f);

  for (unsigned int part = 0; part < SciFi::Constants::n_parts; part++) {
    __shared__ unsigned nTracksPart;
    if (threadIdx.x == 0) nTracksPart = 0;

    // What space do we need to work with ?
    unsigned maxSeeds = SciFi::Constants::Nmax_seed_xz - nReconstructedTracks;

    // Define the hits
    __shared__ float hits_shared[6 * maxNHits];
    seeding::HitCache hits;
    unsigned zone_offset[6];

    // Encoding goes as:
    // 0 2 4 6  8 10 12 14  16 18 20 22
    // 0     1  2        3   4        5
    unsigned int xLayers[6] = {0 + part, 6 + part, 8 + part, 14 + part, 16 + part, 22 + part};

    // Load the hits in shared:
    unsigned totalHits = 0;
    for (int iLayer = 0; iLayer < 6; iLayer++) {
      hits.size[iLayer] = scifi_hit_count.zone_number_of_hits(xLayers[iLayer]);
      totalHits += hits.size[iLayer];
    }
    // If hits don't fit in shared, use global instead
    shared_or_global<float>(
      totalHits,
      6 * maxNHits,
      hits_shared,
      parameters.dev_hits_working_mem,
      parameters.dev_count_hits_working_mem,
      [&](float* ptr) {
        hits.data = ptr;

        hits.start[0] = 0;
        for (int iLayer = 0; iLayer < 6; iLayer++) {
          if (iLayer > 0) hits.start[iLayer] = hits.start[iLayer - 1] + hits.size[iLayer - 1];
          zone_offset[iLayer] = scifi_hit_count.zone_offset(xLayers[iLayer]);
          for (unsigned int iHit = threadIdx.x; iHit < hits.size[iLayer]; iHit += blockDim.x) {
            hits.hit(iLayer, iHit) = scifi_hits.x0(zone_offset[iLayer] + iHit);
          }
        }
        __syncthreads();

        for (auto currentCase : {Case0, Case1}) {
          const unsigned int layers[6] = {currentCase.iFirst,
                                          currentCase.iLast,
                                          currentCase.iMiddle,
                                          currentCase.iRem[0],
                                          currentCase.iRem[1],
                                          currentCase.iRem[2]};

          __shared__ unsigned nTriplets;
          __syncthreads();
          if (threadIdx.x == 0) {
            nTriplets = 0;
          }
          __syncthreads();

          // Main loop
          makeTriplets<false>(triplets, nTriplets, currentCase, hits, layers);
          __syncthreads();

          // if the event is too big, redo the triplets with a limit per first hit
          if (nTriplets > seeding::Triplet::maxTriplets) {
            __syncthreads();
            if (threadIdx.x == 0) nTriplets = 0;
            __syncthreads();

            makeTriplets<true>(triplets, nTriplets, currentCase, hits, layers);
            __syncthreads();
          }

          for (unsigned int tripletIdx = threadIdx.x; tripletIdx < nTriplets; tripletIdx += blockDim.x) {
            seeding::Triplet triplet {triplets[tripletIdx]};
            int firstHitIdx = triplet.idx0();
            int secondHitIdx = triplet.idx1();
            int thirdHitIdx = triplet.idx2();
            float xFirst = hits.hit(layers[0], firstHitIdx);
            float xLast = hits.hit(layers[1], secondHitIdx);
            float xMiddle = hits.hit(layers[2], thirdHitIdx);
            auto twoHitComb = makeTwoHitCombination(currentCase, xFirst, xLast);

            seed_xz::multiHitCombination multiHitComb;
            // -LoH: the curvature is proportional to the error on the 3rd hit projection:
            multiHitComb.cx = (twoHitComb.xProj - xMiddle) * currentCase.delSeedCorr;
            // -LoH: the slope parameter is close to the average slope, up to curvature correction:
            multiHitComb.bx = twoHitComb.tx - multiHitComb.cx * currentCase.txCorr;
            // -LoH: the intersect of the track with z=zRef plane is close to 2hit intersect, up to curvature
            multiHitComb.ax = twoHitComb.xRef - multiHitComb.cx * currentCase.xRefCorr;
            multiHitComb.delta_x[3] =
              multiHitComb.ax + currentCase.dz[3] * multiHitComb.bx + currentCase.dz2[3] * multiHitComb.cx;
            multiHitComb.delta_x[4] =
              multiHitComb.ax + currentCase.dz[4] * multiHitComb.bx + currentCase.dz2[4] * multiHitComb.cx;

            // Find the remainings
            multiHitComb.idx[layers[3]] = findRemainingHit(
              currentCase.tolRem, multiHitComb.delta_x[3], hits.size[layers[3]], hits.layer(layers[3]));
            multiHitComb.idx[layers[4]] = findRemainingHit(
              currentCase.tolRem, multiHitComb.delta_x[4], hits.size[layers[4]], hits.layer(layers[4]));

            // Early stopping: at least 5 hits
            if (
              multiHitComb.idx[layers[3]] == SciFi::Constants::INVALID_IDX &&
              multiHitComb.idx[layers[4]] == SciFi::Constants::INVALID_IDX)
              continue;
            multiHitComb.delta_x[5] =
              multiHitComb.ax + currentCase.dz[5] * multiHitComb.bx + currentCase.dz2[5] * multiHitComb.cx;

            // T3x2 is responsible for most ghosts: +8% ghosts and +7% efficiency considering it.
            multiHitComb.idx[layers[5]] = findRemainingHit(
              currentCase.tolRem, multiHitComb.delta_x[5], hits.size[layers[5]], hits.layer(layers[5]));

            // Early stopping: at least 5 hits
            if (
              multiHitComb.idx[layers[5]] == SciFi::Constants::INVALID_IDX &&
              (multiHitComb.idx[layers[3]] == SciFi::Constants::INVALID_IDX ||
               multiHitComb.idx[layers[4]] == SciFi::Constants::INVALID_IDX))
              continue;

            // Make the multi hit combination and precalculate fit matrix
            multiHitComb.idx[layers[0]] = firstHitIdx;
            multiHitComb.idx[layers[1]] = secondHitIdx;
            multiHitComb.idx[layers[2]] = thirdHitIdx;
            auto score = fitXZ(currentCase, multiHitComb);

            unsigned idx = atomicAdd(&nTracksPart, 1);
            if (idx >= maxSeeds) break;

            reconstructed_tracksXZ_global[nReconstructedTracks + idx] = make_trackXZ(
              scifi_hits, zone_offset, multiHitComb, score); // FIXME: inside the track model, score = chi2ndof
          }                                                  // Closes first layer
          __syncthreads();

          if (threadIdx.x == 0 && nTracksPart > maxSeeds) {
            nTracksPart = 0; // is not deterministic so drop the new tracks
            // TODO: could be improved by only dropping the current case (since it's most likely to happen in case1)
          }
          __syncthreads();

          if (nTracksPart >= maxSeeds) break;
        } // Closes cases

        // Clone removal
        for (int iLayer = 0; iLayer != 6; iLayer++) {
          for (unsigned iHit = threadIdx.x; iHit < hits.size[iLayer]; iHit += blockDim.x) {
            hits.hit(iLayer, iHit) = 100000.f;
          }
        }
        __syncthreads();
        for (unsigned int i = threadIdx.x; i < nTracksPart; i += blockDim.x) {
          auto& track = reconstructed_tracksXZ_global[nReconstructedTracks + i];
          for (int iLayer = 0; iLayer < 6; iLayer++) {
            auto hit = track.idx[iLayer];
            if (hit == SciFi::Constants::INVALID_IDX) continue;
            atomicMin((int*) &hits.hit(iLayer, hit), __float_as_int(track.chi2 * 1000.f + track.cx));
          }
        }
        __shared__ int nFilteredTracks;
        if (threadIdx.x == 0) nFilteredTracks = 0;
        __syncthreads();

        for (unsigned int i = 0; i < nTracksPart; i += blockDim.x) {
          int nHits = 0;
          SciFi::Seeding::TrackXZ track;
          if (i + threadIdx.x < nTracksPart) {
            track = reconstructed_tracksXZ_global[nReconstructedTracks + i + threadIdx.x];
            for (int iLayer = 0; iLayer < 6; iLayer++) {
              auto hit = track.idx[iLayer];
              if (hit == SciFi::Constants::INVALID_IDX) continue;
              nHits += std::fabs(hits.hit(iLayer, hit) - (track.chi2 * 1000.f + track.cx)) < 0.01f;
            }
          }
          __syncthreads();
          if (nHits > 3) {
            auto idx = atomicAdd(&nFilteredTracks, 1);
            reconstructed_tracksXZ_global[nReconstructedTracks + idx] = track;
          }
          __syncthreads();
        }
        __syncthreads();

        // Finalise
        // Write reconstructed tracks from all cases to device parameters for reconstructed XZ tracks
        if (part == 0) {
          parameters.dev_seeding_number_of_tracksXZ_part0[event_number] = nFilteredTracks;
        }
        else {
          parameters.dev_seeding_number_of_tracksXZ_part1[event_number] = nFilteredTracks;
        }
        nReconstructedTracks += nFilteredTracks;
      });
  } // end loop on parts
  parameters.dev_seeding_number_of_tracksXZ[event_number] = nReconstructedTracks;
}
