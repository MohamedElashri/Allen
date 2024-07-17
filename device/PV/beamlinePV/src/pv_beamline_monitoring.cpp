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
#include <iostream>
#include <Common.h>
#include <Logger.h>
#include <BeamlinePVConstants.cuh>

#include <ROOTHeaders.h>

void pv_beamline_monitor(unsigned n_events, float* zhisto)
{
  // Check the output
  TFile output {"testt.root", "RECREATE"};
  TTree outtree {"PV", "PV"};
  unsigned i_event = 0;

  outtree.Branch("event", &i_event);
  float z_histo;
  float z_bin;
  outtree.Branch("z_histo", &z_histo);
  outtree.Branch("z_bin", &z_bin);
  int mindex;
  outtree.Branch("index", &mindex);
  for (i_event = 0; i_event < n_events; i_event++) {
    info_cout << "number event " << i_event << std::endl;
    for (int i = 0; i < BeamlinePVConstants::Common::Nbins; i++) {
      int index = BeamlinePVConstants::Common::Nbins * i_event + i;
      mindex = i;

      z_histo = zhisto[index];
      z_bin = BeamlinePVConstants::Common::zmin + i * BeamlinePVConstants::Common::dz;
      if (z_histo > 5) {
        info_cout << "zhisto: " << i << " " << z_bin << " " << z_histo << std::endl << std::endl;
        outtree.Fill();
      }
    }
  }
  outtree.Write();
  output.Close();
}
