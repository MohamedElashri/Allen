#pragma once

#include <stdint.h>
#include "CudaCommon.h"
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
  __device__ __host__ HltSelRepRBHits(uint nSeq, uint nHits, uint32_t* base_pointer)
  {
    uint len = nSeq / 2 + 1 + nHits;
    m_location = base_pointer;
    m_location[0] = 0u;
    m_location[0] += nSeq;
    m_location[0] |= ((nSeq / 2 + 1) << 16);
    m_length = len;
  }

  __device__ uint numberOfSeq()
  {
    return (uint)(m_location[0] & 0xFFFFu);
  }

  __device__ uint hitsLocation()
  {
    return (numberOfSeq() / 2 + 1);
  }
  
  __device__ uint seqEnd(uint iSeq)
  {
    if ((numberOfSeq() == 0) && (iSeq == 0)) return hitsLocation();
    uint iWord = (iSeq + 1) / 2;
    uint iPart = (iSeq + 1) % 2;
    uint bits = iPart * 16;
    uint mask = 0xFFFFu << bits;
    return (uint)((m_location[iWord] & mask) >> bits);
  }

  __device__ uint seqBegin(uint iSeq)
  {
    if ((numberOfSeq() == 0) && (iSeq == 0)) return hitsLocation();
    if (iSeq) return seqEnd(iSeq - 1);
    return hitsLocation();
  }

  __device__ uint seqSize(uint iSeq) {
    return (seqEnd(iSeq) - seqBegin(iSeq));
  }

  __device__ uint size() {
    if (numberOfSeq()) return seqEnd(numberOfSeq() - 1);
    return seqEnd(0);
  }
  
  // Add the a hit sequence to the bank. Just adds the total number of
  // hits in order to calculate the sequence end point. Hits have to
  // be copied manually on the GPU.
  __device__ uint addSeq(uint nHits)
  {
    for (uint iSeq = 0; iSeq < numberOfSeq(); ++iSeq) {
      if (seqSize(iSeq) == 0) {
        uint iWord = (iSeq + 1) / 2;
        uint iPart = (iSeq + 1) % 2;
        uint bits = iPart * 16;
        uint mask = 0xFFFFu << bits;
        uint begin = seqBegin(iSeq);
        uint end = begin + nHits;
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
  __device__ __host__ HltSelRepRBStdInfo(uint nObj, uint  nAllInfo, uint32_t* base_pointer)
  {
    m_location = base_pointer;
    uint len = 1 + (3 + nObj) / 4 + nAllInfo;
    //m_location[0] = (std::min(len, 0xFFFFu) << 16);
    // Just set this to length and check if it's too large later.
    m_iterator = 0;
    m_iteratorInfo = 0;
    m_location[0] = (len << 16);
    m_floatLoc = 1 + (3 + nObj) / 4;
  }

  __device__ __host__ void rewind() {
    m_iterator = 0;
    m_iteratorInfo = 0;
  }

  __device__ __host__ uint sizeStored() {
    return (m_location[0] >> 16) & 0xFFFFu;
  }

  __device__ __host__ bool writeStdInfo() {
    return sizeStored() >= Hlt1::maxStdInfoEvent;
  }
  
  __device__ __host__ uint numberOfObj() {
    return (uint)(m_location[0] & 0xFFFFu);
  }

  __device__ __host__ uint sizeInfo(uint iObj) {
    uint bits = 8 * (iObj % 4);
    return (m_location[1 + (iObj / 4)] >> bits) & 0xFFu;
  }

  __device__ __host__ uint size() {
    uint nObj = numberOfObj();
    uint len = 1 + (3 + nObj) / 4;
    for (uint i = 0; i != nObj; ++i) {
      auto bits = 8 * (i % 4);
      len += (m_location[1 + (i / 4)] >> bits) & 0xFFu;
    }
    return len;
  }

  __device__ __host__ void saveSize() {
    uint s = size();
    m_location[0] &= 0xFFFFu;
    m_location[0] |= (std::min(s, 0xFFFFu) << 16);
  }
  
  // Prepare to add info for an object with nInfo floats.
  __device__ __host__ void addObj(uint nInfo) {
    uint s = sizeStored();
    uint iObj = numberOfObj();
    uint iWord = 1 + (iObj / 4);
    m_location[0] = (m_location[0] & ~0xFFFFu) | (iObj + 1);

    uint iPart = iObj % 4;
    uint bits = iPart * 8;
    uint mask = 0xFFu << bits;
    m_location[iWord] = ((m_location[iWord] & ~mask) | (nInfo << bits));
    
    ++m_iterator;
  }

  // Add a uint to the StdInfo.
  __device__ __host__ void addInfo(uint info) {
    uint iWord = m_floatLoc + m_iteratorInfo;
    ++m_iteratorInfo;
    m_location[iWord] = info;
  }

  // Add a float to the StdInfo.
  __device__ __host__ void addInfo(float info) {
    IntFloat a;
    a.mFloat = info;
    uint iWord = m_floatLoc + m_iteratorInfo;
    ++m_iteratorInfo;
    m_location[iWord] = a.mInt;
  }
  
};

struct HltSelRepRBObjTyp {

  uint32_t* m_location;
  uint32_t m_iterator;
  
  __device__ __host__ HltSelRepRBObjTyp() {}
  __device__ __host__ HltSelRepRBObjTyp(uint len, uint32_t* base_pointer)
  {
    m_location = base_pointer;
    m_location[0] = (len << 16);
    m_location[1] = 0;
    m_iterator = 0;
  }

  __device__ __host__ void addObj(uint clid, uint nObj)
  {
    uint iWord = m_iterator;
    m_location[iWord] = (clid << 16);
    m_location[iWord] &= 0xFFFF0000u;
    m_location[iWord] |= nObj;
  }

  __device__ __host__ uint numberOfObjTyp()
  {
    return (uint)(m_location[0] & 0xFFFFu);
  }

  __device__ __host__ uint size()
  {
    return (numberOfObjTyp() + 1);
  }
  
  __device__ __host__ void saveSize()
  {
    uint s = size();
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
  __device__ __host__ HltSelRepRBSubstr(uint len, uint32_t* base_pointer)
  {
    if (len < 1) {
      len = Hlt1::subStrDefaultAllocationSize;
    }
    m_location = base_pointer;
    m_location[0] = len << 16;
    m_iterator = InitialPositionOfIterator::kInitialPosition;
  }

  __device__ __host__ void addSubstr(uint nPtrs, uint hits)
  {
    // Increment the number of substructures.
    uint iSub = m_location[0] & 0xFFFFL;
    m_location[0] = (m_location[0] & ~0xFFFFL) | (iSub + 1);
    // Put the count in.
    uint iWord = m_iterator / 2;
    uint iPart = m_iterator % 2;
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

  __device__ __host__ void addPtr(uint ptr)
  {
    uint iWord = m_iterator / 2;
    uint iPart = m_iterator % 2;
    ++m_iterator;
    if (iPart) {
      m_location[iWord] &= 0xFFFFL;
      m_location[iWord] |= (ptr << 16);
    } else {
      m_location[iWord] = (0L | (unsigned short) ptr);
    }
  }

  __device__ __host__ uint numberOfObj()
  {
    return (uint)(m_location[0] & 0xFFFFL);
  }
  
  __device__ __host__ uint allocatedSize()
  {
    return (uint)((m_location[0] & 0xFFFF0000L) >> 16);
  }

  __device__ __host__ uint lenSubstr(uint inpt)
  {
    return (uint)((inpt & 0xFFFF) >> 1);
  }
  
  __device__ __host__ uint size()
  {
    uint s = allocatedSize();
    uint itera = InitialPositionOfIterator::kInitialPosition;
    for (uint iSub = 0; iSub != numberOfObj(); ++iSub) {
      uint iWord = itera / 2;
      uint iPart = itera % 2;
      unsigned short nW;
      if (iPart) {
        nW = (unsigned short)((m_location[iWord] & 0xFFFF0000L) >> 16);
      } else {
        nW = (unsigned short)(m_location[iWord] & 0xFFFFL);
      }
      uint nL = lenSubstr(nW);
      itera += nL + 1;
    }
    uint iWord = itera / 2;
    uint iPart = itera % 2;
    if (iPart) ++iWord;
    return iWord;
  }

  __device__ __host__ void saveSize()
  {
    uint s = size();
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

  uint* m_location;

  __device__ __host__ HltSelRepRawBank() {};
  __device__ __host__ HltSelRepRawBank(
    uint* base_pointer,
    uint len = DefaultAllocation::kDefaultAllocation)
  {
    m_location = base_pointer;
    if (len < Header::kHeaderSize) len = DefaultAllocation::kDefaultAllocation;
    m_location[Header::kAllocatedSize] = len;
    // Initialize the header.
    for (uint iLoc = 0; iLoc < Header::kHeaderSize; ++iLoc) {
      m_location[iLoc] = 0;
    }
    m_location[Header::kSubBankIDs] = 0;
    m_location[Header::kSubBankLocations + numberOfSubBanks()] = Header::kHeaderSize;
  }
  
  __device__ __host__ uint numberOfSubBanks()
  {
    return (uint)(m_location[Header::kSubBankIDs] & 0x7u);
  }

  __device__ __host__ uint indexSubBank(uint idSubBank)
  {
    if (!m_location) return (uint)(HltSelRepRBEnums::SubBankIDs::kUnknownID);
    for (uint iBank = 0; iBank != numberOfSubBanks(); ++iBank) {
      if (subBankID(iBank) == idSubBank) return iBank;
    }
    return (uint)(HltSelRepRBEnums::SubBankIDs::kUnknownID);
  }

  __device__ __host__ uint subBankID(uint iBank)
  {
    uint bits = (iBank + 1) * 3;
    uint mask = 0x7u << bits;
    return (uint)((m_location[Header::kSubBankIDs] & mask) >> bits);
  }

  __device__ __host__ uint subBankBegin(uint iBank)
  {
    if (iBank) {
      return m_location[Header::kSubBankLocations + iBank - 1];
    } else {
      return (uint) Header::kHeaderSize;
    }
  }

  __device__ __host__ uint subBankEnd(uint iBank)
  {
    return m_location[Header::kSubBankLocations + iBank];
  }

  __device__ __host__ uint subBankBeginFromID(uint idSubBank)
  {
    return subBankBegin(indexSubBank(idSubBank));
  }

  __device__ __host__ uint subBankEndFromID(uint idSubBank)
  {
    return subBankEnd(indexSubBank(idSubBank));
  }

  __device__ __host__ uint subBankSize(uint iBank)
  {
    return (subBankEnd(iBank) - subBankBegin(iBank));
  }

  __device__ __host__ uint subBankSizeFromID(uint idSubBank)
  {
    return subBankSize(indexSubBank(idSubBank));
  }

  __device__ __host__ uint* subBankFromID(uint idSubBank)
  {
    uint loc = subBankBeginFromID(idSubBank);
    if (!loc) return 0;
    return &(m_location[loc]);
  }

  __device__ __host__ uint allocatedSize()
  {
    return m_location[Header::kAllocatedSize];
  }

  __device__ __host__ uint size()
  {
    if (numberOfSubBanks()) return subBankEnd(numberOfSubBanks() - 1);
    return Header::kHeaderSize;
  }

  __device__ __host__ void push_back(uint idSubBank, const uint* pSubBank, uint sizeSubBank)
  {
    // Don't worry about reallocating for now.
    // Increment number of banks.
    uint iBank = m_location[Header::kSubBankIDs] & 0x7u;
    m_location[Header::kSubBankIDs] =
      (m_location[Header::kSubBankIDs] & ~0x7u) | (iBank + 1);
    // Set the sub-bank's ID.
    uint bits = (iBank + 1) * 3;
    uint mask = 0x7u << bits;
    m_location[Header::kSubBankIDs] =
      (m_location[Header::kSubBankIDs] & ~mask) | (idSubBank << bits);
    // Get its location.
    uint locBank = subBankBegin(iBank);
    // Set its end.
    m_location[Header::kSubBankLocations + iBank] = locBank + sizeSubBank;
    // Copy content. NB: cudaMemcpyDeviceToDevice might have poor
    // performance for these small copies. For now naively copy.
    for (uint iWord = 0; iWord < sizeSubBank; ++iWord) {
      m_location[locBank + iWord] = pSubBank[iWord];
    }
  }
  
};