#pragma once

static constexpr unsigned int minNumTracksPerVertex = 5;
static constexpr float zmin = -300.f;        // unit: mm Min z position of vertex seed
static constexpr float zmax = 300.f;         // unit: mm Max z position of vertex seed
static constexpr int Nbins = 2400;           // nubmer of bins in the histogram. Make sure that Nbins = (zmax-zmin)/dz
static constexpr float dz = 0.25f;           // unit: mm Z histogram bin size
static constexpr float maxTrackZ0Err = 1.5f; // unit: mm "Maximum z0-error for adding track to histo"
static constexpr float minDensity = 1.0f;    // unit: 1./mm "Minimal density at cluster peak  (inverse resolution)"
static constexpr float minDipDensity =
  2.0f; // unit: 1./mm,"Minimal depth of a dip to split cluster (inverse resolution)"
static constexpr float minTracksInSeed = 2.5f; // "MinTrackIntegralInSeed"
static constexpr float maxVertexRho = 0.3f;    // unit:: mm "Maximum distance of vertex to beam line"
static constexpr float maxVertexRho2 = 0.09f;
static constexpr unsigned int maxFitIter = 7; // "Maximum number of iterations for vertex fit"
static constexpr float maxDeltaChi2 = 9.f;    //"Maximum chi2 contribution of track to vertex fit"
static constexpr float minWeight = 0.3f;      //"minimum value of adaptive weight of track in multi fit"
static constexpr int order_polynomial = 2;    // order of the polynomial used to approximate Gaussian
static constexpr float maxChi2 = 9.f;        // Maximum chi2 for track to be used in fit
static constexpr float maxWeight = 0.3f;     //Maximum weight for track to be used in fit
static constexpr float chi2Cut = 25.f;       // chi2 cut in multi-fitter
static constexpr float maxDeltaZConverged = 0.0005f; //convergence criterion for fit

static constexpr float minChi2Dist = 16.f ;  //minimum chi2 distance of two recosntructed PVs for them to be considere unique

// Get the beamline. this only accounts for position, not
// rotation. that's something to improve!

// set this to (0,0) for now
// TODO: use real beamline position. (0,0) is only correct for MC
static constexpr float2 beamline {0.f, 0.f};
