#pragma once

namespace Muon {
  namespace MuonBase {
    typedef unsigned int ContentType;
    //
    static constexpr unsigned int BitsX = 7;
    static constexpr unsigned int BitsY = 4;
    static constexpr unsigned int BitsQuarter = 2;
    static constexpr unsigned int BitsRegion = 2;
    static constexpr unsigned int BitsReadout = 0;
    static constexpr unsigned int BitsLayer = 0;
    static constexpr unsigned int BitsStation = 3;
    static constexpr unsigned int BitsLayoutX = 6;
    static constexpr unsigned int BitsLayoutY = 4;

    //
    static constexpr unsigned int BitsIndex = BitsX + BitsY + BitsRegion + BitsQuarter;
    static constexpr unsigned int BitsKey = BitsIndex + BitsReadout + BitsLayer + BitsStation;
    //
    static constexpr unsigned int ShiftY = 0;
    static constexpr unsigned int ShiftX = ShiftY + BitsY;
    static constexpr unsigned int ShiftQuarter = ShiftX + BitsX;
    static constexpr unsigned int ShiftRegion = ShiftQuarter + BitsQuarter;
    static constexpr unsigned int ShiftReadout = ShiftRegion + BitsRegion;
    static constexpr unsigned int ShiftLayer = ShiftReadout + BitsReadout;
    static constexpr unsigned int ShiftStation = ShiftLayer + BitsLayer;
    static constexpr unsigned int ShiftLayoutX = ShiftStation + BitsStation;
    static constexpr unsigned int ShiftLayoutY = ShiftLayoutX + BitsLayoutX;
    //
    static constexpr unsigned int ShiftIndex = 0;
    static constexpr unsigned int ShiftKey = 0;
    //
    static constexpr ContentType MaskX = ((((ContentType) 1) << BitsX) - 1) << ShiftX;
    static constexpr ContentType MaskY = ((((ContentType) 1) << BitsY) - 1) << ShiftY;
    static constexpr ContentType MaskRegion = ((((ContentType) 1) << BitsRegion) - 1) << ShiftRegion;
    static constexpr ContentType MaskQuarter = ((((ContentType) 1) << BitsQuarter) - 1) << ShiftQuarter;
    static constexpr ContentType MaskLayoutX = ((((ContentType) 1) << BitsLayoutX) - 1) << ShiftLayoutX;
    static constexpr ContentType MaskLayoutY = ((((ContentType) 1) << BitsLayoutY) - 1) << ShiftLayoutY;
    static constexpr ContentType MaskReadout = ((((ContentType) 1) << BitsReadout) - 1) << ShiftReadout;
    static constexpr ContentType MaskLayer = ((((ContentType) 1) << BitsLayer) - 1) << ShiftLayer;
    static constexpr ContentType MaskStation = ((((ContentType) 1) << BitsStation) - 1) << ShiftStation;
    //
    static constexpr ContentType MaskIndex = ((((ContentType) 1) << BitsIndex) - 1) << ShiftIndex;
    static constexpr ContentType MaskKey = ((((ContentType) 1) << BitsKey) - 1) << ShiftKey;

    static constexpr int CENTER = 0;
    static constexpr int UP = 1;
    static constexpr int DOWN = -1;
    static constexpr int RIGHT = 1;
    static constexpr int LEFT = -1;

  } // namespace MuonBase
} // namespace Muon
