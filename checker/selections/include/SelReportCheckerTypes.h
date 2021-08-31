/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <vector>
#include <utility>
#include <cassert>
#include <cstdint>
#include <string>
#include <iostream>
#include <Common.h>

struct SelReport {

  // Struct for accessing information stored in SelReports. Used only
  // for reading. Simplified version of HltSelRepRawBank:
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRawBank.h

  enum SubBankIDs {
    kHitsID = 0,
    kObjTypID = 1,
    kSubstrID = 2,
    kExtraInfoID = 3,
    kStdInfoID = 4,
    kMaxBankID = 7,
    kUnknownID = 8
  };

  enum Header { kAllocatedSize = 0, kSubBankIDs = 1, kSubBankLocations = 2, kHeaderSize = 10 };

  const unsigned* m_location;

  SelReport() {};
  SelReport(const unsigned* bankBody) { m_location = bankBody; }

  // Get the number of sub banks in the raw bank.
  unsigned numberOfSubBanks() const { return (unsigned) (m_location[kSubBankIDs] & 0x7L); }

  // Check if a subbank exists given the bank ID.
  bool subBankExists(unsigned idSubBank) const
  {
    for (unsigned iBank = 0; iBank != numberOfSubBanks(); ++iBank) {
      if (subBankID(iBank) == idSubBank) return true;
    }
    return false;
  }

  // Get the index of a raw bank given the bank ID.
  unsigned indexSubBank(unsigned idSubBank) const
  {
    for (unsigned iBank = 0; iBank != numberOfSubBanks(); ++iBank) {
      if (subBankID(iBank) == idSubBank) return iBank;
    }
    return (unsigned) (kUnknownID);
  }

  // Get the sub bank ID of a given bank.
  unsigned subBankID(unsigned iBank) const
  {
    unsigned bits = (iBank + 1) * 3;
    unsigned mask = 0x7L << bits;
    return (unsigned) ((m_location[kSubBankIDs] & mask) >> bits);
  }

  // Relative location of the sub-bank in the bank body in number of words.
  unsigned subBankBegin(unsigned iBank) const
  {
    if (iBank) {
      return m_location[kSubBankLocations + iBank - 1];
    }
    else {
      return (unsigned) kHeaderSize;
    }
  }

  // Relative location of the sub-bank end.
  unsigned subBankEnd(unsigned iBank) const { return m_location[kSubBankLocations + iBank]; }

  // Get the beginning of the bank using the bank ID.
  unsigned subBankBeginFromID(unsigned idSubBank) const { return subBankBegin(indexSubBank(idSubBank)); }

  // Get the end of the bank using the bank ID.
  unsigned subBankEndFromID(unsigned idSubBank) const { return subBankEnd(indexSubBank(idSubBank)); }

  // Get the sub bank size from the bank index.
  unsigned subBankSize(unsigned iBank) const { return subBankEnd(iBank) - subBankBegin(iBank); }

  // Get the sub bank size using the bank ID.
  unsigned subBankSizeFromID(unsigned idSubBank) const { return subBankSize(indexSubBank(idSubBank)); }

  // Get the allocated bank size.
  unsigned size() const { return m_location[kAllocatedSize]; }

  // Get a pointer to a subbank from the index.
  const unsigned* subBankPointer(unsigned iBank) const
  {
    unsigned bankBegin = subBankBegin(iBank);
    return m_location + bankBegin;
  }

  // Get a pointer to a subbank from the index.
  const unsigned* subBankPointerFromID(unsigned idSubBank) const { return subBankPointer(indexSubBank(idSubBank)); }
};

struct RBHits {

  // Struct for accessing information in the hist sub-bank.
  // Simplified version HltSelRepRBHits:
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRBHits.h

  const unsigned* m_location;

  RBHits() {};
  RBHits(const unsigned* bankBody) { m_location = bankBody; }

  // Get the number of sequences stored in the bank.
  unsigned numberOfSeq() const { return (unsigned) (m_location[0] & 0xFFFFL); }

  // Get the start location for the hit sequences.
  unsigned hitsLocation() const { return (numberOfSeq() / 2 + 1); }

  // Get the location of the end of a hit sequence.
  unsigned seqEnd(unsigned iSeq) const
  {
    if (numberOfSeq() == 0) return hitsLocation();
    unsigned iWord = (iSeq + 1) / 2;
    unsigned iPart = (iSeq + 1) % 2;
    unsigned bits = iPart * 16;
    unsigned mask = 0xFFFFL << bits;
    return (unsigned) ((m_location[iWord] & mask) >> bits);
  }

  // Get the location of the beginning of a hit sequence.
  unsigned seqBegin(unsigned iSeq) const
  {
    if (iSeq == 0) return hitsLocation();
    if (iSeq) return seqEnd(iSeq - 1);
    return hitsLocation();
  }

  // Get the size of a sequence.
  unsigned seqSize(unsigned iSeq) const { return seqEnd(iSeq) - seqBegin(iSeq); }

  // Get the size of the sub bank.
  unsigned size() const
  {
    if (numberOfSeq()) return seqEnd(numberOfSeq() - 1);
    return seqEnd(0);
  }

  // Get the pointer to the beginning of a sequence.
  const unsigned* sequenceBegin(unsigned iSeq) const
  {
    unsigned iBegin = seqBegin(iSeq);
    return &(m_location[iBegin]);
  }

  // Get the pointer to the end of a sequence.
  const unsigned* sequenceEnd(unsigned iSeq) const
  {
    unsigned iEnd = seqEnd(iSeq);
    return &(m_location[iEnd]);
  }

  // Return a vector of hits.
  std::vector<unsigned> sequence(unsigned iSeq) const
  {
    std::vector<unsigned> hitSeq;
    const unsigned* i = sequenceBegin(iSeq);
    const unsigned* iEnd = sequenceEnd(iSeq);
    hitSeq.reserve(iEnd - i);
    for (; i != iEnd; i++)
      hitSeq.emplace_back(*i);
    return hitSeq;
  }

  // Print out a summary of the bank.
  void fillStream(std::ostream& s)
  {
    s << " RBHits : { "
      << " nSeq " << numberOfSeq() << " size " << size() << std::endl;
    for (unsigned iSeq = 0; iSeq != numberOfSeq(); ++iSeq) {
      s << " seq : " << iSeq << " size " << seqSize(iSeq);
      for (unsigned iHit = seqBegin(iSeq); iHit != seqEnd(iSeq); ++iHit) {
        s << " " << m_location[iHit];
      }
      s << std::endl;
    }
    s << " }" << std::endl;
  }
};

struct RBObjTyp {

  // Struct for accessing information stored in the ObjTyp sub bank.
  // Simplified version HltSelRepRBObjTyp:
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRBObjTyp.h

  const unsigned* m_location;

  RBObjTyp() {};
  RBObjTyp(const unsigned* bankBody) { m_location = bankBody; }

  // Get the number of object types stored.
  unsigned numberOfObjTyp() const { return (unsigned) (m_location[0] & 0xFFFFL); }

  // Get the number of objects stored.
  unsigned numberOfObj() const
  {
    if (numberOfObjTyp()) {
      return (unsigned) (m_location[numberOfObjTyp()] & 0xFFFFL);
    }
    return 0;
  }

  // Get the CLID of the ith object type.
  unsigned getCLID(unsigned iObj) const
  {
    if (iObj >= numberOfObjTyp()) return 0;
    return (m_location[1 + iObj] & 0xFFFF0000L) >> 16;
  }

  // Get the object count of the ith object type.
  unsigned getObjCount(unsigned iObj) const
  {
    if (iObj >= numberOfObjTyp()) return 0;
    unsigned iOld = 0;
    if (iObj > 0) iOld = (m_location[iObj] & 0xFFFFL);
    return (m_location[1 + iObj] & 0xFFFFL) - iOld;
  }

  // Print out a summary of the bank.
  void fillStream(std::ostream& s)
  {
    s << " RBObjTyp : { "
      << " nObjTyp " << numberOfObjTyp() << " nObj " << numberOfObj() << std::endl;
    unsigned iold = 0;
    for (unsigned iObjTyp = 0; iObjTyp != numberOfObjTyp(); ++iObjTyp) {
      unsigned iWord = 1 + iObjTyp;
      unsigned nObj = (m_location[iWord] & 0xFFFFL);
      unsigned clid = ((m_location[iWord] & (0xFFFFL << 16)) >> 16);
      s << " " << iObjTyp << " type " << clid << " #-of-objs " << nObj - iold << " cumulative " << nObj;
      iold = nObj;
      s << std::endl;
    }
    s << " }" << std::endl;
  }
};

struct RBSubstr {

  // Struct for holding substructure information.
  // Simplified version HltSelRepRBSubstr:
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRBSubstr.h

  typedef std::vector<unsigned short> Substrv;
  typedef std::pair<unsigned int, Substrv> Substr;

  enum InitialPositionOfIterator { kInitialPosition = 2 };

  const unsigned* m_location;
  unsigned m_iterator;
  unsigned m_objiterator;

  RBSubstr() {};
  RBSubstr(const unsigned* bankBody)
  {
    m_location = bankBody;
    m_iterator = kInitialPosition;
    m_objiterator = 0;
  }

  // Reset the iterator to the initial position.
  void rewind()
  {
    m_iterator = kInitialPosition;
    m_objiterator = 0;
  }

  // Get the size of the bank.
  unsigned allocatedSize() { return (unsigned) ((m_location[0] & 0xFFFF0000L) >> 16); }

  // Number of saved objects.
  unsigned numberOfObj() { return (unsigned) (m_location[0] & 0xFFFFL); }

  // Determine if the substructure points to hits.
  unsigned hitSubstr(unsigned short inpt) { return (unsigned) (inpt & 0x1L); }

  // Get the substructure length.
  unsigned lenSubstr(unsigned short inpt) { return (unsigned) ((inpt & 0xFFFF) >> 1); }

  // Get the substructure from the current interator position and
  // advance the iterator.
  Substr next()
  {
    unsigned iWord = m_iterator / 2;
    unsigned iPart = m_iterator % 2;
    ++m_iterator;
    unsigned short nW;
    if (iPart) {
      nW = (unsigned short) ((m_location[iWord] & 0xFFFF0000L) >> 16);
    }
    else {
      nW = (unsigned short) (m_location[iWord] & 0xFFFFL);
    }
    unsigned nL = lenSubstr(nW);
    Substrv vect;
    for (unsigned int i = 0; i != nL; i++) {
      iWord = m_iterator / 2;
      iPart = m_iterator % 2;
      ++m_iterator;
      unsigned short n;
      if (iPart) {
        n = (unsigned short) ((m_location[iWord] & 0xFFFF0000L) >> 16);
      }
      else {
        n = (unsigned short) (m_location[iWord] & 0xFFFFL);
      }
      vect.push_back(n);
    }
    ++m_objiterator;
    return Substr(hitSubstr(nW), vect);
  }

  // Print out a summary of the bank content.
  void fillStream(std::ostream& s)
  {
    s << " RBSubstr : { "
      << " nSubstr " << numberOfObj() << " size " << allocatedSize() << std::endl;
    unsigned int itera = ((unsigned) kInitialPosition);

    for (unsigned iSub = 0; iSub != numberOfObj(); ++iSub) {
      unsigned iWord = itera / 2;
      unsigned iPart = itera % 2;
      ++itera;
      unsigned short nW;
      if (iPart) {
        nW = (unsigned short) ((m_location[iWord] & 0xFFFF0000L) >> 16);
      }
      else {
        nW = (unsigned) (m_location[iWord] & 0xFFFFL);
      }
      unsigned nL = lenSubstr(nW);
      s << " subStr : " << iSub << " size " << nL << " hitType " << hitSubstr(nW) << " { ";
      for (unsigned i = 0; i != nL; ++i) {
        unsigned iWord = itera / 2;
        unsigned iPart = itera % 2;
        ++itera;
        unsigned short n;
        if (iPart) {
          n = (unsigned short) ((m_location[iWord] & 0xFFFF0000L) >> 16);
        }
        else {
          n = (unsigned short) (m_location[iWord] & 0xFFFFL);
        }
        s << " " << int(n);
      }
      s << " } " << std::endl;
    }
    s << " }" << std::endl;
  }
};

struct RBStdInfo {

  // Simplified version HltSelRepRBStdInfo:
  // https://gitlab.cern.ch/lhcb/LHCb/-/blob/master/Hlt/HltDAQ/HltDAQ/HltSelRepRBStdInfo.h

  const unsigned* m_location;
  unsigned m_iterator;
  unsigned m_iteratorInfo;
  unsigned m_floatLoc;

  RBStdInfo() {};
  RBStdInfo(const unsigned* bankBody) : m_location(bankBody), m_iterator(0), m_iteratorInfo(0), m_floatLoc(0)
  {
    initialize();
  }

  // Initialize the bank for reading.
  void initialize()
  {
    m_floatLoc = 1 + (3 + numberOfObj()) / 4;
    rewind();
  }

  // Get the length of the info for the object of a certain index.
  unsigned sizeInfo(unsigned iObj)
  {
    auto bits = 8 * (iObj % 4);
    return (m_location[1 + (iObj / 4)] >> bits) & 0xFFu;
  }

  // Reset iterators to initial positions.
  void rewind()
  {
    m_iterator = 0;
    m_iteratorInfo = 0;
  }

  // Get the number of stored objects.
  unsigned numberOfObj() { return (unsigned) (m_location[0] & 0xFFFFu); }

  // Get the total size of the bank.
  unsigned size() { return (m_location[0] >> 16) & 0xFFFFu; }

  // Get the StdInfo from the current iterator position and move to
  // the next position.
  std::vector<float> next()
  {
    std::vector<float> info;
    unsigned nInfo = sizeInfo(m_iterator);
    ++m_iterator;
    for (unsigned i = 0; i != nInfo; i++) {
      unsigned iWord = m_floatLoc + m_iteratorInfo;
      ++m_iteratorInfo;
      info.push_back(*reinterpret_cast<const float*>(&m_location[iWord]));
    }
    return info;
  }

  // Print a summary of the bank content.
  void fillStream(std::ostream& s)
  {
    s << " RBStdInfo : { "
      << " nObj " << numberOfObj() << " size " << size() << std::endl;
    unsigned int iteraInfo = 0;
    for (unsigned int itera = 0; itera != numberOfObj();) {
      unsigned nInfo = sizeInfo(itera);
      ++itera;
      s << " " << itera << " nInfo " << nInfo << " { ";
      for (unsigned i = 0; i != nInfo; i++) {
        unsigned iWord = m_floatLoc + iteraInfo;
        ++iteraInfo;
        union IntFloat {
          unsigned mInt;
          float mFloat;
        };
        IntFloat a;
        a.mInt = m_location[iWord];
        float infFloat = a.mFloat;
        s << infFloat << " ";
      }
      s << " }" << std::endl;
    }
    s << " }" << std::endl;
  }
};
