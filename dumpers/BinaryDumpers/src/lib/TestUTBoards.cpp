/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>

#include <Dumpers/TestUTBoards.h>

namespace fs = std::filesystem;

using namespace std;

UTBoards::UTBoards( std::vector<char> data ) : m_data{std::move( data )} {
  uint32_t* p      = (uint32_t*)m_data.data();
  number_of_boards = *p;
  p += 1;
  number_of_channels = 6 * number_of_boards;
  stripsPerHybrids   = p;
  p += number_of_boards;
  stations = p;
  p += number_of_channels;
  layers = p;
  p += number_of_channels;
  detRegions = p;
  p += number_of_channels;
  sectors = p;
  p += number_of_channels;
  chanIDs = p;
  p += number_of_channels;
}

std::vector<char> readFile( const string& filename ) {
  fs::path      p{filename};
  std::ifstream file( filename, std::ios::binary );

  // Stop eating new lines in binary mode
  file.unsetf( std::ios::skipws );

  std::vector<char> v;
  v.reserve( fs::file_size( p ) );

  // read the data:
  v.insert( v.begin(), std::istream_iterator<char>( file ), std::istream_iterator<char>() );
  return v;
}

UTBoards readUTBoards( const string& filename ) {
  auto v = readFile( filename );
  return UTBoards{std::move( v )};
}
