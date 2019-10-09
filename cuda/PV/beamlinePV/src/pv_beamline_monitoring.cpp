#include <iostream>
#include <Common.h>
#include <Logger.h>
#include <BeamlinePVConstants.cuh>

#include <ROOTHeaders.h>

void pv_beamline_monitor(uint n_events, float* zhisto)
{
  // Check the output
  TFile output {"testt.root", "RECREATE"};
  TTree outtree {"PV", "PV"};
  uint i_event = 0;

  outtree.Branch("event", &i_event);
  float z_histo;
  float z_bin;
  outtree.Branch("z_histo", &z_histo);
  outtree.Branch("z_bin", &z_bin);
  int mindex;
  outtree.Branch("index", &mindex);
  for (i_event = 0; i_event < n_events; i_event++) {
    info_cout << "number event " << i_event << std::endl;
    for (int i = 0; i < Nbins; i++) {
      int index = Nbins * i_event + i;
      mindex = i;

      z_histo = zhisto[index];
      z_bin = zmin + i * dz;
      if (z_histo > 5) {
        info_cout << "zhisto: " << i << " " << z_bin << " " << z_histo << std::endl << std::endl;
        outtree.Fill();
      }
    }
  }
  outtree.Write();
  output.Close();
}
