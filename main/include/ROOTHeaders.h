#pragma once

// #if defined(WITH_ROOT)
// #warning "WITH_ROOT defined"
// #else
// #warning "WITH_ROOT not defined"
// #endif

// #if defined(ROOT_CXX17)
// #warning "ROOT_CXX17 defined"
// #else
// #warning "ROOT_CXX17 not defined"
// #endif

#if defined(WITH_ROOT) && (!defined(ROOT_CXX17) || (defined(ROOT_CXX17) && __cplusplus > 201402L))
#include <TDirectory.h>
#include <TFile.h>
#include <TTree.h>
#include <TH1.h>
#include <TH2.h>
#include <TClass.h>
#include <TBufferFile.h>
#include <TArrayI.h>

#endif
