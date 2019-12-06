#include <cstdio>

#include "TrackChecker.h"

namespace {
  using Checker::HistoCategory;
  using Checker::TrackEffReport;
} // namespace

namespace Categories {

  const std::vector<TrackEffReport>& Velo {
    {// define which categories to monitor
     TrackEffReport({
       "Electrons long eta25",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     TrackEffReport({
       "Electrons long fromB eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Electrons long fromB eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long fromB eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Electrons long fromB eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long fromD eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Electrons long fromD eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long fromD eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Electrons long fromD eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f && mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Electrons long eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long strange eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Electrons long strange eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons long strange eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Electrons long strange eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Electrons Velo",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron(); },
     }),
     TrackEffReport({
       "Electrons Velo backward",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron() && mcp.eta < 0; },
     }),
     TrackEffReport({
       "Electrons Velo forward",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron() && mcp.eta > 0; },
     }),
     TrackEffReport({
       "Electrons Velo eta25",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     TrackEffReport({
       "Not electron long eta25",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5(); },
     }),
     TrackEffReport({
       "Not electron long fromB eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Not electron long fromB eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long fromB eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Not electron long fromB eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long fromD eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Not electron long fromD eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long fromD eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Not electron long fromD eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f && mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Not electron long eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long strange eta25",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Not electron long strange eta25 p<5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p < 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron long strange eta25 p>3GeV pt>400MeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 400.f;
       },
     }),
     TrackEffReport({
       "Not electron long strange eta25 p>5GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 5e3f;
       },
     }),
     TrackEffReport({
       "Not electron Velo",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron(); },
     }),
     TrackEffReport({
       "Not electron Velo backward",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron() && mcp.eta < 0; },
     }),
     TrackEffReport({
       "Not electron Velo forward",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron() && mcp.eta > 0; },
     }),
     TrackEffReport({
       "Not electron Velo eta25",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron() && mcp.inEta2_5(); },
     })}};

  const std::vector<HistoCategory>& VeloHisto {
    {// define which categories to create histograms for
     HistoCategory({
       "VeloTracks_electrons",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron(); },
     }),
     HistoCategory({
       "VeloTracks_eta25_electrons",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     HistoCategory({
       "LongFromB_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "VeloTracks_notElectrons",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron(); },
     }),
     HistoCategory({
       "VeloTracks_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron() && mcp.inEta2_5(); },
     }),
     HistoCategory({
       "LongFromB_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     })}};

  const std::vector<TrackEffReport>& VeloUT {{
    // define which categories to monitor
    TrackEffReport({
      "Velo",
      [](MCParticles::const_reference& mcp) { return mcp.hasVelo && !mcp.isElectron() && mcp.inEta2_5(); },
    }),
    TrackEffReport({
      "Velo+UT",
      [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.hasUT && !mcp.isElectron() && mcp.inEta2_5(); },
    }),
    TrackEffReport({
      "Velo+UT, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.hasVelo && mcp.hasUT && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Velo, not long",
      [](MCParticles::const_reference& mcp) {
        return mcp.hasVelo && !mcp.isLong && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Velo+UT, not long",
      [](MCParticles::const_reference& mcp) {
        return mcp.hasVelo && mcp.hasUT && !mcp.isLong && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Velo+UT, not long, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.hasVelo && mcp.hasUT && !mcp.isLong && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long",
      [](MCParticles::const_reference& mcp) { return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5(); },
    }),
    TrackEffReport({
      "Long, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long, pt > 20 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.pt > 20e3f && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long strange",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long strange, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.p > 5e3f && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long strange muons",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromStrangeDecay && mcp.isMuon() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long strange muons, p > 3 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromStrangeDecay && mcp.isMuon() && mcp.p > 3e3f && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long electrons",
      [](MCParticles::const_reference& mcp) { return mcp.isLong && mcp.isElectron() && mcp.inEta2_5(); },
    }),
    TrackEffReport({
      "Long from B electrons",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B electrons, p > 5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.p > 5e3f && mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from D electrons, p > 3 GeV, pt > 0.5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from D, p > 3 GeV, pt > 0.5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B electrons, p > 3 GeV, pt > 0.5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B, p > 3 GeV, pt > 0.5 GeV",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5();
      },
    }),
    TrackEffReport({
      "Long from B, p > 3 GeV, pt > 0.5 GeV, eta < 2.5, (phi-pi/2)<0.8",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5() && mcp.eta < 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) < 0.8f;
      },
    }),
    TrackEffReport({
      "Long from B, p > 3 GeV, pt > 0.5 GeV, eta > 2.5, (phi-pi/2)<0.8",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5() && mcp.eta > 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) < 0.8f;
      },
    }),
    TrackEffReport({
      "Long from B, p > 3 GeV, pt > 0.5 GeV, eta < 2.5, (phi-pi/2)>0.8",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5() && mcp.eta < 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) > 0.8f;
      },
    }),
    TrackEffReport({
      "Long from B, p > 3 GeV, pt > 0.5 GeV, eta > 2.5, (phi-pi/2)>0.8",
      [](MCParticles::const_reference& mcp) {
        return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
               mcp.inEta2_5() && mcp.eta > 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) > 0.8f;
      },
    }),
  }};

  const std::vector<HistoCategory>& VeloUTHisto {
    {// define which categories to create histograms for
     HistoCategory({
       "VeloUTTracks_eta25_electrons",
       [](MCParticles::const_reference& mcp) { return mcp.hasVelo && mcp.hasUT && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     HistoCategory({
       "LongFromB_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "VeloUTTracks_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.hasVelo && mcp.hasUT && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromB_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     })}};

  const std::vector<TrackEffReport>& Forward {
    {// define which categories to monitor
     TrackEffReport({
       "Long",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5(); },
     }),
     TrackEffReport({
       "Long, p > 5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long, pt > 20 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.pt > 20e3f && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long strange",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long strange, p > 5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.p > 5e3f && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long strange muons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isMuon() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long strange muons, p > 3 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isMuon() && mcp.p > 3e3f && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B, p > 5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.p > 5e3f && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long electrons",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     TrackEffReport({
       "Long electrons from B",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long electrons from B, p > 5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.p > 5e3f && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from D electrons, p > 3 GeV, pt > 0.3 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.3e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from D electrons, p > 3 GeV, pt > 0.5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from D, p > 3 GeV, pt > 0.3 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.3e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from D, p > 3 GeV, pt > 0.5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B electrons, p > 3 GeV, pt > 0.3 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.3e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B electrons, p > 3 GeV, pt > 0.5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.3 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.3e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.5 GeV",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5();
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.5 GeV, eta < 2.5, (phi-pi/2)<0.8",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5() && mcp.eta < 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) < 0.8f;
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.5 GeV, eta > 2.5, (phi-pi/2)<0.8",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5() && mcp.eta > 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) < 0.8f;
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.5 GeV, eta < 2.5, (phi-pi/2)>0.8",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5() && mcp.eta < 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) > 0.8f;
       },
     }),
     TrackEffReport({
       "Long from B, p > 3 GeV, pt > 0.5 GeV, eta > 2.5, (phi-pi/2)>0.8",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.p > 3e3f && mcp.pt > 0.5e3f &&
                mcp.inEta2_5() && mcp.eta > 2.5f && std::fabs(std::fabs(mcp.phi) - 1.57f) > 0.8f;
       },
     })}};

  const std::vector<HistoCategory>& ForwardHisto {
    {// define which categories to create histograms for
     HistoCategory({
       "Long_eta25_electrons",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && mcp.isElectron() && mcp.inEta2_5(); },
     }),
     HistoCategory({
       "LongFromB_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_muons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && mcp.isMuon() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_p_gt_3_pt_gt_0p5_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.5e3f;
       },
     }),
     HistoCategory({
       "LongFromD_eta25_p_gt_3_pt_gt_0p3_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.3e3f;
       },
     }),
     HistoCategory({
       "LongFromB_eta25_p_gt_3_pt_gt_0p5_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.5e3f;
       },
     }),
     HistoCategory({
       "LongFromB_eta25_p_gt_3_pt_gt_0p3_electrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.3e3f;
       },
     }),
     HistoCategory({
       "Long_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) { return mcp.isLong && !mcp.isElectron() && mcp.inEta2_5(); },
     }),
     HistoCategory({
       "LongFromB_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongFromD_eta25_p_gt_3_pt_gt_0p5_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.5e3f;
       },
     }),
     HistoCategory({
       "LongFromD_eta25_p_gt_3_pt_gt_0p3_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.3e3f;
       },
     }),
     HistoCategory({
       "LongFromB_eta25_p_gt_3_pt_gt_0p5_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.5e3f;
       },
     }),
     HistoCategory({
       "LongFromB_eta25_p_gt_3_pt_gt_0p3_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromBeautyDecay && !mcp.isElectron() && mcp.inEta2_5() && mcp.p > 3e3f &&
                mcp.pt > 0.3e3f;
       },
     }),
     HistoCategory({
       "LongFromD_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromCharmDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     }),
     HistoCategory({
       "LongStrange_eta25_notElectrons",
       [](MCParticles::const_reference& mcp) {
         return mcp.isLong && mcp.fromStrangeDecay && !mcp.isElectron() && mcp.inEta2_5();
       },
     })}};
} // namespace Categories
