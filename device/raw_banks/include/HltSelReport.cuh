/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include "BackendCommon.h"
#include "RawBanksDefinitions.cuh"

union IntFloat {
  uint32_t mInt;
  float mFloat;
};

struct HltSelRepRBEnums {

  enum SubBankIDs {
    kHitsID = 0,
    kObjTypID = 1,
    kSubstrID = 2,
    kExtraInfoID = 3,
    kStdInfoID = 4,
    kMaxBankID = 7,
    kUnknownID = 8
  };

  enum IntegrityCodes {
    kBankIsOK = 0,
    kEmptyBank = 1,
    kDuplicateBankIDs = 2,
    kPtrOutOfSequence = 3,
    kPtrOutOfRange = 4,
    kZeroAllocatedSize = 5,
    kNoBank = 6,
    kUnknownError = 100
  };
  
};

struct HltSelRepRBHits {

  uint32_t* m_location;
  uint32_t m_length;

  __device__ __host__ HltSelRepRBHits() {}
  
  __device__ __host__ HltSelRepRBHits(unsigned nSeq, unsigned nHits, uint32_t* base_pointer)
  {
    unsigned len = nSeq / 2 + 1 + nHits;
    m_location = base_pointer;
    m_location[0] = 0u;
    m_location[0] += nSeq;
    m_location[0] |= ((nSeq / 2 + 1) << 16);
    m_length = len;
  }

  __device__ unsigned numberOfSeq() const
  {
    return (unsigned)(m_location[0] & 0xFFFFu);
  }

  __device__ unsigned hitsLocation() const
  {
    return (numberOfSeq() / 2 + 1);
  }
  
  __device__ unsigned seqEnd(unsigned iSeq) const
  {
    if ((numberOfSeq() == 0) && (iSeq == 0)) return hitsLocation();
    unsigned iWord = (iSeq + 1) / 2;
    unsigned iPart = (iSeq + 1) % 2;
    unsigned bits = iPart * 16;
    unsigned mask = 0xFFFFu << bits;
    return (unsigned)((m_location[iWord] & mask) >> bits);
  }

  __device__ unsigned seqBegin(unsigned iSeq) const
  {
    if ((numberOfSeq() == 0) && (iSeq == 0)) return hitsLocation();
    if (iSeq) return seqEnd(iSeq - 1);
    return hitsLocation();
  }

  __device__ unsigned seqSize(unsigned iSeq) const
  {
    return (seqEnd(iSeq) - seqBegin(iSeq));
  }

  __device__ unsigned size() const
  {
    if (numberOfSeq()) return seqEnd(numberOfSeq() - 1);
    return seqEnd(0);
  }

  __device__ static unsigned sizeFromPtr(const uint32_t* ptr)
  {
    if ((unsigned)(ptr[0] & 0xFFFFu)) {
      unsigned iSeq = (unsigned)(ptr[0] & 0xFFFFu) - 1;
      unsigned iWord = (iSeq + 1) / 2;
      unsigned iPart = (iSeq + 1) % 2;
      unsigned bits = iPart * 16;
      unsigned mask = 0xFFFFu << bits;
      return (unsigned)((ptr[iWord] & mask) >> bits);
    }
    else {
      return (unsigned)(ptr[0] & 0xFFFFu) / 2 + 1;
    }
  }
  
  // Add the a hit sequence to the bank. Just adds the total number of
  // hits in order to calculate the sequence end point. Hits have to
  // be copied manually on the GPU.
  __device__ unsigned addSeq(unsigned nHits)
  {
    for (unsigned iSeq = 0; iSeq < numberOfSeq(); ++iSeq) {
      if (seqSize(iSeq) == 0) {
        unsigned iWord = (iSeq + 1) / 2;
        unsigned iPart = (iSeq + 1) % 2;
        unsigned bits = iPart * 16;
        unsigned mask = 0xFFFFu << bits;
        unsigned begin = seqBegin(iSeq);
        unsigned end = begin + nHits;
        m_location[iWord] = (m_location[iWord] & ~mask) | (end << bits);
        ++iSeq;
        if (iSeq < numberOfSeq()) {
          iWord = (iSeq + 1) / 2;
          iPart = (iSeq + 1) % 2;
          bits = iPart * 16;
          mask = 0xFFFFu << bits;
          m_location[iWord] = (m_location[iWord] & ~mask) | (end << bits);
        }
        return begin;
      }
    }
    return hitsLocation();
  }
  
};

struct HltSelRepRBStdInfo {

  uint32_t* m_location;

  // Object count iterator.
  uint32_t m_iterator;

  // Info count iterator.
  uint32_t m_iteratorInfo;

  // Location of the first float word inside the bank.
  uint32_t m_floatLoc;

  __device__ __host__ HltSelRepRBStdInfo() {}

  __device__ __host__ HltSelRepRBStdInfo(unsigned nObj, unsigned  nAllInfo, uint32_t* base_pointer)
  {
    m_location = base_pointer;
    unsigned len = 1 + (3 + nObj) / 4 + nAllInfo;
    //m_location[0] = (std::min(len, 0xFFFFu) << 16);
    // Just set this to length and check if it's too large later.
    m_iterator = 0;
    m_iteratorInfo = 0;
    m_location[0] = (len << 16);
    m_floatLoc = 1 + (3 + nObj) / 4;
  }

  __device__ __host__ void rewind()
  {
    m_iterator = 0;
    m_iteratorInfo = 0;
  }

  __device__ __host__ unsigned sizeStored() const
  {
    return (m_location[0] >> 16) & 0xFFFFu;
  }

  __device__ __host__ static unsigned sizeStoredFromPtr(const uint32_t* ptr)
  {
    return (ptr[0] >> 16) & 0xFFFFu;
  }

  __device__ __host__ bool writeStdInfo() const
  {
    return sizeStored() >= Hlt1::maxStdInfoEvent;
  }
  
  __device__ __host__ unsigned numberOfObj() const
  {
    return (unsigned)(m_location[0] & 0xFFFFu);
  }

  __device__ __host__ unsigned sizeInfo(unsigned iObj) const
  {
    unsigned bits = 8 * (iObj % 4);
    return (m_location[1 + (iObj / 4)] >> bits) & 0xFFu;
  }

  __device__ __host__ unsigned size() const
  {
    unsigned nObj = numberOfObj();
    unsigned len = 1 + (3 + nObj) / 4;
    for (unsigned i = 0; i != nObj; ++i) {
      auto bits = 8 * (i % 4);
      len += (m_location[1 + (i / 4)] >> bits) & 0xFFu;
    }
    return len;
  }

  __device__ __host__ static unsigned sizeFromPtr(const uint32_t* ptr)
  {
    unsigned nObj = (unsigned)(ptr[0] & 0xFFFFu);
    unsigned len = 1 + (3 + nObj) / 4;
    for (unsigned i = 0; i != nObj; ++i) {
      auto bits = 8 * (i % 4);
      len += (ptr[1 + (i / 4)] >> bits) & 0xFFu;
    }
    return len;
  }
  
  __device__ __host__ void saveSize()
  {
    unsigned s = size();
    m_location[0] &= 0xFFFFu;
    m_location[0] |= (std::min(s, 0xFFFFu) << 16);
  }
  
  // Prepare to add info for an object with nInfo floats.
  __device__ __host__ void addObj(unsigned nInfo)
  {
    unsigned iObj = numberOfObj();
    unsigned iWord = 1 + (iObj / 4);
    m_location[0] = (m_location[0] & ~0xFFFFu) | (iObj + 1);

    unsigned iPart = iObj % 4;
    unsigned bits = iPart * 8;
    unsigned mask = 0xFFu << bits;
    m_location[iWord] = ((m_location[iWord] & ~mask) | (nInfo << bits));
    
    ++m_iterator;
  }

  // Add a unsigned to the StdInfo.
  __device__ __host__ void addInfo(unsigned info)
  {
    unsigned iWord = m_floatLoc + m_iteratorInfo;
    ++m_iteratorInfo;
    m_location[iWord] = info;
  }

  // Add a float to the StdInfo.
  __device__ __host__ void addInfo(float info)
  {
    IntFloat a;
    a.mFloat = info;
    unsigned iWord = m_floatLoc + m_iteratorInfo;
    ++m_iteratorInfo;
    m_location[iWord] = a.mInt;
  }
  
};

struct HltSelRepRBObjTyp {

  uint32_t* m_location;
  uint32_t m_iterator;
  
  __device__ __host__ HltSelRepRBObjTyp() {}

  __device__ __host__ HltSelRepRBObjTyp(unsigned len, uint32_t* base_pointer)
  {
    m_location = base_pointer;
    m_location[0] = (len << 16);
    m_location[1] = 0;
    m_iterator = 0;
  }

  __device__ __host__ void addObj(unsigned clid, unsigned nObj)
  {
    unsigned iWord = m_iterator;
    m_location[iWord] = (clid << 16);
    m_location[iWord] &= 0xFFFF0000u;
    m_location[iWord] |= nObj;
  }

  __device__ __host__ unsigned numberOfObjTyp() const
  {
    return (unsigned)(m_location[0] & 0xFFFFu);
  }

  __device__ __host__ unsigned size() const
  {
    return (numberOfObjTyp() + 1);
  }

  __device__ __host__ static unsigned sizeFromPtr(const uint32_t* ptr)
  {
    return (unsigned)(ptr[0] & 0xFFFFu) + 1;
  }
  
  __device__ __host__ void saveSize()
  {
    unsigned s = size();
    m_location[0] &= 0xFFFFu;
    m_location[0] |= (s << 16);
  }

};

struct HltSelRepRBSubstr {

  enum InitialPositionOfIterator {
    kInitialPosition = 2
  };

  uint32_t* m_location;
  uint32_t m_iterator = kInitialPosition;

  __device__ __host__ HltSelRepRBSubstr() {}

  __device__ __host__ HltSelRepRBSubstr(unsigned len, uint32_t* base_pointer)
  {
    if (len < 1) {
      len = Hlt1::subStrDefaultAllocationSize;
    }
    m_location = base_pointer;
    m_location[0] = len << 16;
    m_iterator = InitialPositionOfIterator::kInitialPosition;
  }

  __device__ __host__ void addSubstr(unsigned nPtrs, unsigned hits)
  {
    // Increment the number of substructures.
    unsigned iSub = m_location[0] & 0xFFFFL;
    m_location[0] = (m_location[0] & ~0xFFFFL) | (iSub + 1);
    // Put the count in.
    unsigned iWord = m_iterator / 2;
    unsigned iPart = m_iterator % 2;
    ++m_iterator;
    unsigned short nW = 0;
    nW = nPtrs << 1;
    if (hits) {
      nW |= 1;
    } else if (!nPtrs) {
      return;
    }
    if (iPart) {
      m_location[iWord] &= 0xFFFFL;
      m_location[iWord] |= (nW << 16);
    } else {
      m_location[iWord] = (0L | nW);
    }
  }

  __device__ __host__ void addPtr(unsigned ptr)
  {
    unsigned iWord = m_iterator / 2;
    unsigned iPart = m_iterator % 2;
    ++m_iterator;
    if (iPart) {
      m_location[iWord] &= 0xFFFFL;
      m_location[iWord] |= (ptr << 16);
    } else {
      m_location[iWord] = (0L | (unsigned short) ptr);
    }
  }

  __device__ __host__ unsigned numberOfObj() const
  {
    return (unsigned)(m_location[0] & 0xFFFFL);
  }
  
  __device__ __host__ unsigned allocatedSize() const
  {
    return (unsigned)((m_location[0] & 0xFFFF0000L) >> 16);
  }

  __device__ __host__ unsigned lenSubstr(unsigned inpt) const
  {
    return (unsigned)((inpt & 0xFFFF) >> 1);
  }
  
  __device__ __host__ unsigned size() const
  {
    unsigned itera = InitialPositionOfIterator::kInitialPosition;
    for (unsigned iSub = 0; iSub != numberOfObj(); ++iSub) {
      unsigned iWord = itera / 2;
      unsigned iPart = itera % 2;
      unsigned short nW;
      if (iPart) {
        nW = (unsigned short)((m_location[iWord] & 0xFFFF0000L) >> 16);
      } else {
        nW = (unsigned short)(m_location[iWord] & 0xFFFFL);
      }
      unsigned nL = lenSubstr(nW);
      itera += nL + 1;
    }
    unsigned iWord = itera / 2;
    unsigned iPart = itera % 2;
    if (iPart) ++iWord;
    return iWord;
  }

  __device__ __host__ static unsigned sizeFromPtr(const uint32_t* ptr)
  {
    unsigned itera = InitialPositionOfIterator::kInitialPosition;
    unsigned nObj = (unsigned)(ptr[0] & 0xFFFFL);
    for (unsigned iSub = 0; iSub != nObj; ++iSub) {
      unsigned iWord = itera / 2;
      unsigned iPart = itera % 2;
      unsigned short nW;
      if (iPart) {
        nW = (unsigned short)((ptr[iWord] & 0xFFFF0000L) >> 16);
      } else {
        nW = (unsigned short)(ptr[iWord] & 0xFFFFL);
      }
      unsigned nL = (unsigned)((nW & 0xFFFF) >> 1);
      itera += nL + 1;
    }
    unsigned iWord = itera / 2;
    unsigned iPart = itera % 2;
    if (iPart) ++iWord;
    return iWord;
  }
  
  __device__ __host__ void saveSize()
  {
    unsigned s = size();
    m_location[0] &= 0xFFFFL;
    m_location[0] |= (s << 16);
  }
  
};

struct HltSelRepRawBank {

  enum Header {
    kAllocatedSize = 0,
    kSubBankIDs = 1,
    kSubBankLocations = 2,
    kHeaderSize = 10
  };

  enum DefaultAllocation {
    kDefaultAllocation = 4000
  };

  unsigned* m_location;

  __device__ __host__ HltSelRepRawBank() {};
  __device__ __host__ HltSelRepRawBank(
    unsigned* base_pointer,
    unsigned len = DefaultAllocation::kDefaultAllocation)
  {
    m_location = base_pointer;
    if (len < Header::kHeaderSize) len = DefaultAllocation::kDefaultAllocation;
    m_location[Header::kAllocatedSize] = len;
    // Initialize the header.
    for (unsigned iLoc = 0; iLoc < Header::kHeaderSize; ++iLoc) {
      m_location[iLoc] = 0;
    }
    m_location[Header::kSubBankIDs] = 0;
    m_location[Header::kSubBankLocations + numberOfSubBanks()] = Header::kHeaderSize;
  }
  
  __device__ __host__ unsigned numberOfSubBanks() const
  {
    return (unsigned)(m_location[Header::kSubBankIDs] & 0x7u);
  }

  __device__ __host__ unsigned indexSubBank(unsigned idSubBank) const
  {
    if (!m_location) return (unsigned)(HltSelRepRBEnums::SubBankIDs::kUnknownID);
    for (unsigned iBank = 0; iBank != numberOfSubBanks(); ++iBank) {
      if (subBankID(iBank) == idSubBank) return iBank;
    }
    return (unsigned)(HltSelRepRBEnums::SubBankIDs::kUnknownID);
  }

  __device__ __host__ unsigned subBankID(unsigned iBank) const
  {
    unsigned bits = (iBank + 1) * 3;
    unsigned mask = 0x7u << bits;
    return (unsigned)((m_location[Header::kSubBankIDs] & mask) >> bits);
  }

  __device__ __host__ unsigned subBankBegin(unsigned iBank) const
  {
    if (iBank) {
      return m_location[Header::kSubBankLocations + iBank - 1];
    } else {
      return (unsigned) Header::kHeaderSize;
    }
  }

  __device__ __host__ unsigned subBankEnd(unsigned iBank) const
  {
    return m_location[Header::kSubBankLocations + iBank];
  }

  __device__ __host__ unsigned subBankBeginFromID(unsigned idSubBank) const
  {
    return subBankBegin(indexSubBank(idSubBank));
  }

  __device__ __host__ unsigned subBankEndFromID(unsigned idSubBank) const
  {
    return subBankEnd(indexSubBank(idSubBank));
  }

  __device__ __host__ unsigned subBankSize(unsigned iBank) const
  {
    return (subBankEnd(iBank) - subBankBegin(iBank));
  }

  __device__ __host__ unsigned subBankSizeFromID(unsigned idSubBank)
  {
    return subBankSize(indexSubBank(idSubBank));
  }

  __device__ __host__ unsigned* subBankFromID(unsigned idSubBank) const
  {
    unsigned loc = subBankBeginFromID(idSubBank);
    if (!loc) return 0;
    return &(m_location[loc]);
  }

  __device__ __host__ unsigned allocatedSize() const
  {
    return m_location[Header::kAllocatedSize];
  }

  __device__ __host__ unsigned size() const
  {
    if (numberOfSubBanks()) return subBankEnd(numberOfSubBanks() - 1);
    return Header::kHeaderSize;
  }

  __device__ __host__ void push_back(unsigned idSubBank, const unsigned* pSubBank, unsigned sizeSubBank)
  {
    // Don't worry about reallocating for now.
    // Increment number of banks.
    unsigned iBank = m_location[Header::kSubBankIDs] & 0x7u;
    m_location[Header::kSubBankIDs] =
      (m_location[Header::kSubBankIDs] & ~0x7u) | (iBank + 1);
    // Set the sub-bank's ID.
    unsigned bits = (iBank + 1) * 3;
    unsigned mask = 0x7u << bits;
    m_location[Header::kSubBankIDs] =
      (m_location[Header::kSubBankIDs] & ~mask) | (idSubBank << bits);
    // Get its location.
    unsigned locBank = subBankBegin(iBank);
    // Set its end.
    m_location[Header::kSubBankLocations + iBank] = locBank + sizeSubBank;
    // Copy content. NB: cudaMemcpyDeviceToDevice might have poor
    // performance for these small copies. For now naively copy.
    for (unsigned iWord = 0; iWord < sizeSubBank; ++iWord) {
      m_location[locBank + iWord] = pSubBank[iWord];
    }
  }
  
};