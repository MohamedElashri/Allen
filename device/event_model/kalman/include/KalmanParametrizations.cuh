/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "ParKalmanDefinitions.cuh"
#include "KalmanParametrizationsCoef.cuh"
#include "ParKalmanMath.cuh"

#include <fstream>
#include <sstream>

namespace ParKalmanFilter {
  //----------------------------------------------------------------------
  // Structure for storing parameters and performing extrapolations.
  struct KalmanParametrizations {

    // Parameters.
    StandardCoefs C[nBinXMax][nBinYMax];

    float ZINI, ZFIN;
    float PMIN;
    float BENDX, BENDX_X2, BENDX_Y2, BENDY_XY;
    float Txmax, Tymax, XFmax, Xmax, Ymax;
    float Dtxy;
    float step;

// Parameters for Pierre's UT-T extrapolation.
#define QUADRATICINTERPOLATION 1
    int Nbinx, Nbiny;
    int XGridOption, YGridOption;
    int DEGX1, DEGX2, DEGY1, DEGY2;

    // Keep track of polarity and whether or not parameters have been loaded.
    bool paramsLoaded = false;

    __device__ __host__ inline float UTTExtrEndZ() const;

    __device__ __host__ inline float UTTExtrBeginZ() const;

    // Pierre's extrapolation.
    __host__ inline void read_params_UTT(std::string file);

    //----------------------------------------------------------------------
    // Template function for reading parameters. // no longer needed
    template<int nPars, int nSets>
    __host__ void read_params(std::string file, float (&params)[nSets][nPars])
    {

      // Set all parameters to 0.
      for (int i = 0; i < nSets; i++)
        for (int j = 0; j < nPars; j++)
          params[i][j] = 0.;

      // Setup infile stream.
      std::string line;
      std::ifstream myFile(file);

      // Read parameters.
      bool foundSet = false;
      if (myFile.is_open()) {
        int iSet = 0;
        while (getline(myFile, line)) {
          // determine which parameterset the respective line of paramters belongs to
          foundSet = false;
          for (int s = 0; s < nSets; s++) {
            std::stringstream ss;
            ss << "_" << s << "_";
            std::string str = ss.str();
            if (line.find(str) != std::string::npos) {
              iSet = s;
              foundSet = true;
            }
          }
          if (!foundSet) continue;
          // set the values
          std::istringstream iss(line);
          std::string sub;
          iss >> sub;
          int p = 0;
          while (iss >> sub && p < nPars) {
            params[iSet][p] = std::atof(sub.c_str());
            p++;
          }
        }
        myFile.close();
      }
      else {
        throw StrException("Failed to set the KalmanParametrizations parameters from file " + file);
      }
    }

    //----------------------------------------------------------------------
    // Set parameters.
    __host__ void SetParameters(std::string param_file_location)
    {
      // Get polarity.
      if (paramsLoaded) return;
      std::string ParamFileLocation;
      ParamFileLocation = param_file_location + "/ParametrizedKalmanFit/25v0/";
      read_params_UTT(ParamFileLocation + "/params_UTT_v0.tab");
      paramsLoaded = true;
    }
  }; // End KalmanParametrizations

  // We need to load both parametrisation at this point, based on the condition only the right polarity will be used.

} // namespace ParKalmanFilter

namespace ParKalmanFilter {

  ////////////////////////////////////////////////////////////////////////
  // Read parameters.
  ////////////////////////////////////////////////////////////////////////

  //----------------------------------------------------------------------
  //  read parameters from file - here for the extrapolation UT -> T
  __host__ void KalmanParametrizations::read_params_UTT(std::string file)
  {
    std::string line;
    std::ifstream myfile(file);
    if (!myfile.is_open()) throw StrException("Failed to open parameter file.");
    myfile >> ZINI >> ZFIN >> PMIN >> BENDX >> BENDX_X2 >> BENDX_Y2 >> BENDY_XY >> Txmax >> Tymax >> XFmax >> Dtxy;
    myfile >> Nbinx >> Nbiny >> XGridOption >> YGridOption >> DEGX1 >> DEGX2 >> DEGY1 >> DEGY2;
    for (int ix = 0; ix < Nbinx; ix++)
      for (int iy = 0; iy < Nbiny; iy++)
        C[ix][iy].Read(myfile);
    Xmax = ZINI * Txmax;
    Ymax = ZINI * Tymax;
  }

  __device__ __host__ float KalmanParametrizations::UTTExtrEndZ() const { return ZFIN; }

  __device__ __host__ float KalmanParametrizations::UTTExtrBeginZ() const { return ZINI; }

} // namespace ParKalmanFilter
