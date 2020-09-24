/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <iostream>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <ROOTHeaders.h>

#include "read_mdf.hpp"
#include "root_mdf.hpp"

namespace MDF {
  namespace ROOT {
    Allen::IO open(std::string const& filepath, int flags)
    {
      TFile* f = nullptr;
      TUrl url(filepath.c_str());
      TString opts = "filetype=raw", proto, spec, tmp = url.GetOptions();

      if (tmp.Length() > 0) {
        opts += "&";
        opts += url.GetOptions();
      }
      url.SetOptions(opts);
      proto = url.GetProtocol();
      if (proto == "file" || proto == "http") {
        spec = filepath.c_str();
        spec += "?filetype=raw";
      }
      else {
        spec = url.GetUrl();
      }

      if ((flags & (O_WRONLY | O_CREAT)) != 0) {
        f = TFile::Open(spec, "RECREATE", "", 0);
      }
      else if (flags == O_RDONLY) {
        f = TFile::Open(spec);
      }
      if (f && !f->IsZombie()) {
        return {true,
                [f](char* ptr, size_t size) { return ROOT::read(f, ptr, size); },
                [f](char const* ptr, size_t size) { return ROOT::write(f, ptr, size); },
                [f] { return ROOT::close(f); }};
      }
      else {
        return {};
      }
    }

    bool close(TFile* f)
    {
      if (f) {
        if (!f->IsZombie()) f->Close();
        delete f;
        return true;
      }
      else {
        return false;
      }
    }

    ssize_t read(TFile* f, char* ptr, size_t size)
    {
      Long64_t s = f->GetBytesRead() + size;
      if (s > f->GetSize()) {
        return 0;
      }
      return f->ReadBuffer(ptr, size) == 0 ? size : -1;
    }

    ssize_t write(TFile* f, char const* ptr, size_t size) { return f->WriteBuffer(ptr, size) == 0 ? size : -1; }
  } // namespace ROOT
} // namespace MDF
