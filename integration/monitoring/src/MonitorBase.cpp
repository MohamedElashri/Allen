#include "MonitorBase.h"
#include "ROOTHeaders.h"

#include <ctime>

#ifdef WITH_ROOT
void MonitorBase::saveHistograms(std::string file_name, bool append) const
{
  std::string mode = "RECREATE";
  if (append) mode = "UPDATE";
  TFile* file = TFile::Open(file_name.c_str(), mode.c_str());
  if (!file) return;
  auto* dir = static_cast<TDirectory*>(file->Get(m_name.c_str()));
  if (!dir) {
    dir = file->mkdir(m_name.c_str());
    dir = static_cast<TDirectory*>(file->Get(m_name.c_str()));
  }

  for (auto& kv : m_histograms) {
    auto h = kv.second.get();

    dir->cd();
    if (append) {
      auto* hout = static_cast<TH1D*>(dir->Get(h->GetName()));
      if (hout) {
        hout->Add(h);
        hout->Write();
      }
      else {
        h->Write();
      }
    }
    else {
      h->Write();
    }
  }

  file->Close();
#else
void MonitorBase::saveHistograms(std::string, bool) const
{
#endif
}

unsigned MonitorBase::getWallTimeBin()
{
  if (m_offset <= 0) m_offset = time(0);

  return time(0) - m_offset;
}
