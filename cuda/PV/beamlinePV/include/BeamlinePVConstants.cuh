#pragma once

namespace BeamlinePVConstants {

namespace Common {
static constexpr float zmin = -260.f;        // unit: mm Min z position of vertex seed
static constexpr float zmax = 260.f;         // unit: mm Max z position of vertex seed
static constexpr int Nbins = 2080;           // nubmer of bins in the histogram. Make sure that Nbins = (zmax-zmin)/dz
static constexpr float dz = 0.25f;           // unit: mm Z histogram bin size
static constexpr float maxTrackZ0Err = 1.5f; // unit: mm "Maximum z0-error for adding track to histo"
}


namespace Histo {
static constexpr float maxTrackRho2 =
  0.1f; // unit:: mm^2 "Maximum distance squared of a track to beamline when filling histogram"
static constexpr int order_polynomial = 2;           // order of the polynomial used to approximate Gaussian
}

namespace Peak {
static constexpr float minDensity = 1.0f;    // unit: 1./mm "Minimal density at cluster peak  (inverse resolution)"
static constexpr float minDipDensity =
  2.0f; // unit: 1./mm,"Minimal depth of a dip to split cluster (inverse resolution)"
static constexpr float minTracksInSeed = 2.5f; // "MinTrackIntegralInSeed"
}


namespace MultiFitter {
static constexpr float maxVertexRho2 = 0.01f;  // unit:: mm^2 "Maximum distance squared of vertex to beam line"
static constexpr unsigned int minFitIter = 3;        // "Minimum number of iterations for vertex fit"
static constexpr unsigned int maxFitIter = 7;        // "Maximum number of iterations for vertex fit"
static constexpr float maxChi2 = 25.f;                // Maximum chi2 for track to be used in fit
static constexpr float minWeight = 0.0f;             // Minimum weight for track to be used in fit. Can be tuned, but a too large value worses PV resolution
static constexpr float chi2Cut = 4.f;               // chi2 cut-off in multi-fitter
static constexpr float chi2CutExp = 0.135335283f;    // expf(-chi2Cut * 0.5f) = 0.135335283f
static constexpr float maxDeltaZConverged = 0.0005f; // convergence criterion for fit
}

namespace CleanUp {
static constexpr float minChi2Dist =
  25.f; // minimum chi2 distance of two reconstructed PVs for them to be considered unique
}

}