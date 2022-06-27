/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <MuonPopulateTileAndTDC.cuh>


INSTANTIATE_ALGORITHM(muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t)

__device__ void decode_muon_bank_tell1(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  int const batch_index,
  Muon::MuonRawBank<2> const& raw_bank,
  const unsigned* storage_station_region_quarter_offsets,
  unsigned* atomics_muon,
  unsigned* dev_storage_tile_id,
  unsigned* dev_storage_tdc_value)
{
  const auto tell_number = raw_bank.sourceID;
  const uint16_t* p = raw_bank.data;

  p += (*p + 3) & 0xFFFE;
  for (int j = 0; j < batch_index; ++j) {
    p += 1 + *p;
  }

  const auto batch_size = *p;
  for (int j = 1; j < batch_size + 1; ++j) {
    const auto pp = *(p + j);
    const auto add = (pp & 0x0FFF);
    const auto tdc_value = ((pp & 0xF000) >> 12);
    const auto tileId = muon_raw_to_hits->muonGeometry->getADDInTell1(tell_number, add);

    if (tileId != 0) {
      const auto tile = Muon::MuonTileID(tileId);

      const auto x1 =
        getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
      const auto y1 =
        getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
      const auto x2 =
        getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
      const auto y2 =
        getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
      const auto layout1 = (x1 > x2 ? Muon::MuonLayout {x1, y1} : Muon::MuonLayout {x2, y2});

      // Store tiles according to their station, region, quarter and layout,
      // to prepare data for easy process in muonaddcoordscrossingmaps.
      const auto storage_srq_layout =
        Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);

      const auto insert_index = atomicAdd(atomics_muon + storage_srq_layout, 1);
      dev_storage_tile_id[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = tileId;
      dev_storage_tdc_value[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = tdc_value;
    }
  }
}



__device__ void decode_muon_bank_tell40(
  Muon::MuonRawToHits const* muon_raw_to_hits,
  int const batch_index,
  Muon::MuonRawBank<3> const& raw_bank,
  const unsigned* storage_station_region_quarter_offsets,
  unsigned* atomics_muon,
  unsigned* dev_storage_tile_id,
  unsigned* dev_storage_tdc_value)
{

  printf( "Entering the New PopulateTileANDTDC  \n" );


   // printf("=======+++==========================================================\n" );
   // for (auto i = 1; i < Muon::Constants::maxTell40Number; i++){
   //   printf("Tell40 number %u \n", i );
   //   for (auto j = 0; j < Muon::Constants::maxTell40PCINumber; j++){
   //     printf("        pci number %u \n", j );
   //     for (auto k = 0; k < Muon::Constants::maxNumberLinks; k++){
   // 	printf( "           link number %u \n", k );
   // 	printf("            QuarterOfLink %u" ,  muon_raw_to_hits -> muonGeometry -> QuarterOfLink(i, j, k) ); 
   // 	printf(", RegionOfLink  %u \n" , muon_raw_to_hits -> muonGeometry -> RegionOfLink(i, j, k) ); 
   // 	for (auto l = 0; l < Muon::Constants::ODEFrameSize; l++){
   // 	  printf("              ODE number %u \n", l );
   // 	  printf("              TileInTell40 map %u \n", muon_raw_to_hits -> muonGeometry -> TileInTell40(i, j, k, l) );	  
   // 	}
   //     }
   //   }    
   // }

   
  const auto tell_pci = raw_bank.sourceID & 0x00FF;
  const auto tell_number  = tell_pci/2 + 1;
  const auto pci_number   = tell_pci % 2;
  const auto tell_station = muon_raw_to_hits -> muonGeometry -> whichStationIsTell40( tell_number - 1 );
  const auto active_links = muon_raw_to_hits -> muonGeometry -> NumberOfActiveLink ( tell_number, pci_number );

  printf("TileandTDC: sourceID = %u, raw_bank.last - raw_bank.data = %ld, tell_station = %u, active_links = %u \n", raw_bank.sourceID,  raw_bank.last - raw_bank.data, tell_station, active_links);

  const gsl::span<const uint8_t> range8 {raw_bank.data, (raw_bank.last - raw_bank.data)/sizeof(uint8_t)};

  for ( unsigned int i =0; i < range8.size(); i++){
    printf("TileANDTDC: range[%u] = %x \n", i, range8[i]);
  }

  auto range_data = range8.subspan( 1 );
  unsigned int link_start_pointer = 0;
  unsigned int map_connected_fibers[24] = {};
  unsigned int synch_evt = ( range8[0] & 0x10 ) >> 4;

  if ( !synch_evt ){
    unsigned int number_of_readout_fibers = muon_raw_to_hits -> muonGeometry -> get_number_of_readout_fibers( range8, active_links, map_connected_fibers);
    printf( "Number of readout fibers is %d \n", number_of_readout_fibers );
    
    unsigned int align_info         = ( range8[0] & 0x20 ) >> 5;
    if ( align_info ) link_start_pointer += 3;

    for ( unsigned int link = 0; link < number_of_readout_fibers; link++ ) {
      unsigned int reroutered_link = map_connected_fibers[link];

      auto regionOfLink  = muon_raw_to_hits -> muonGeometry -> RegionOfLink( tell_number, pci_number, reroutered_link );
      auto quarterOfLink = muon_raw_to_hits -> muonGeometry -> QuarterOfLink( tell_number, pci_number, reroutered_link );
      printf("at link %u, reroutered link %u, tell_number %u, pci_number %u, regionOfLink = %u, quarterOfLink = %u \n", link, reroutered_link, tell_number, pci_number, regionOfLink, quarterOfLink);
            
      uint8_t  curr_byte  = range_data[link_start_pointer];
      unsigned int size_of_link = ( ( curr_byte & 0xF0 ) >> 4 ) + 1;

      printf("link_start_pointer is %u, curr_byte is %u, Size of link is %u\n", link_start_pointer, curr_byte, size_of_link);
      if ( size_of_link > 1 ) {
	auto range_link_HitsMap = range_data.subspan( link_start_pointer, 7 );
	auto range_link_TDC     = range_data.subspan( link_start_pointer + 6, size_of_link - 6 );

	bool         first_hitmap_byte  = false;
	bool         last_hitmap_byte   = true;
	unsigned int count_byte         = 0;
	unsigned int pos_in_link        = 0;
	unsigned int nSynch_hits_number = 0;
	unsigned int TDC_counter        = range_link_TDC.size() * 2 - 1;

	printf("TDC counter is %u \n ", TDC_counter);
	for ( auto r = range_link_HitsMap.rbegin(); r < range_link_HitsMap.rend(); r++ ) {
	  // loop in reverse mode hits map is 47->0
	  count_byte++;
	  if ( count_byte == 7 ) first_hitmap_byte = true;
	  if ( count_byte > 7 ) break; // should never happens
	  uint8_t data_copy = *r;
	  for ( unsigned int bit_pos_1 = 8; bit_pos_1 > 0; --bit_pos_1 ) {
	    unsigned int bit_pos = bit_pos_1 - 1;

	    if ( first_hitmap_byte && bit_pos < 4 ) continue; // better put break
	    if ( last_hitmap_byte && bit_pos > 3 ) continue;  // better put bit_pos_1=4	   
	    if ( data_copy & Muon::Constants::single_bit_position[bit_pos] ) {
	      printf("Pos in link: %u \n ", pos_in_link);
		auto tileId = muon_raw_to_hits -> muonGeometry ->TileInTell40( tell_number, pci_number, reroutered_link, pos_in_link );
		printf("TileandIDC: tileID is %u \n", tileId);

		if (tileId != 0) {
		  const auto tile = Muon::MuonTileID(tileId);

		  unsigned int TDC_value          = 0;		  
		  if ( nSynch_hits_number < TDC_counter ) {
                    switch ( nSynch_hits_number ) {
                    case 0:
                      TDC_value = ( range_link_TDC[0] & 0x0F );
                      break;
                    case 1:
                      TDC_value = ( range_link_TDC[1] & 0xF0 ) >> 4;
                      break;
                    case 2:
                      TDC_value = ( range_link_TDC[1] & 0x0F );
                      break;
                    case 3:
                      TDC_value = ( range_link_TDC[2] & 0xF0 ) >> 4;
                      break;
                    case 4:
                      TDC_value = ( range_link_TDC[2] & 0x0F );
                      break;
                    case 5:
                      TDC_value = ( range_link_TDC[3] & 0xF0 ) >> 4;
                      break;
                    case 6:
                      TDC_value = ( range_link_TDC[3] & 0x0F );
                      break;
                    case 7:
                      TDC_value = ( range_link_TDC[4] & 0xF0 ) >> 4;
                      break;
                    case 8:
                      TDC_value = ( range_link_TDC[4] & 0x0F );
                      break;
                    case 9:
                      TDC_value = ( range_link_TDC[5] & 0xF0 ) >> 4;
                      break;
                    case 10:
                      TDC_value = ( range_link_TDC[5] & 0x0F );
                      break;
                    case 11:
                      TDC_value = ( range_link_TDC[6] & 0xF0 ) >> 4;
                      break;
                    default:
                      TDC_value = 0;
                      break;
                    } 
		  }

		  printf("TDC_value is %u \n", TDC_value);		  
		  nSynch_hits_number++;
		    
		  const auto x1 =
		    getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
		  const auto y1 =
		    getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripXTableNumber, tile.station(), tile.region());
		  const auto x2 =
		    getLayoutX(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
		  const auto y2 =
		    getLayoutY(muon_raw_to_hits->muonTables, Muon::MuonTables::stripYTableNumber, tile.station(), tile.region());
		  const auto layout1 = (x1 > x2 ? Muon::MuonLayout {x1, y1} : Muon::MuonLayout {x2, y2});
		  
		  // Store tiles according to their station, region, quarter and layout,
		  // to prepare data for easy process in muonaddcoordscrossingmaps.		  
		  if ( tell_station * 16 + regionOfLink * 4 + quarterOfLink < 64 ) {		   
		    const auto storage_srq_layout =
		      Muon::Constants::n_layouts * tile.stationRegionQuarter() + (tile.layout() != layout1);
		    const auto insert_index = atomicAdd(atomics_muon + storage_srq_layout, 1);
		    dev_storage_tile_id[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = tileId;
		    dev_storage_tdc_value[storage_station_region_quarter_offsets[storage_srq_layout] + insert_index] = TDC_value;
		  }		  
		} 	
	    }
	    pos_in_link++;
	  }
	  last_hitmap_byte = false;
	}
      }
      link_start_pointer = link_start_pointer + size_of_link;	
    }    
  } 
  printf( "THIS IS THE END OF THE PopulateTILEANDTDC SIZE \n" );
}


template<bool mep_layout>
__global__ void muon_populate_tile_and_tdc_kernel(muon_populate_tile_and_tdc::Parameters parameters, unsigned int muon_bank_version, unsigned int number_of_events)
{

  for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
    const unsigned event_number = parameters.dev_event_list[event_index];
    printf("at index %u, event_number = %u \n", event_index, event_number);

    //const unsigned event_number = parameters.dev_event_list[blockIdx.x];
    const auto storage_station_region_quarter_offsets =
      parameters.dev_storage_station_region_quarter_offsets +
      event_number * 2 * Muon::Constants::n_stations * Muon::Constants::n_regions * Muon::Constants::n_quarters;
    unsigned* atomics_muon = parameters.dev_atomics_muon + event_number * 2 * Muon::Constants::n_stations *
      Muon::Constants::n_regions * Muon::Constants::n_quarters;
    
    if (muon_bank_version == 2){
      const auto raw_event = Muon::RawEvent<mep_layout, 2> {
	parameters.dev_muon_raw, parameters.dev_muon_raw_offsets, parameters.dev_muon_raw_sizes, event_number};
      
      // number_of_raw_banks = 10
      // batches_per_bank = 4
      constexpr uint32_t batches_per_bank_mask = 0x3;
      constexpr uint32_t batches_per_bank_shift = 2;
      for (unsigned i = threadIdx.x; i < raw_event.number_of_raw_banks() * Muon::batches_per_bank; i += blockDim.x) {
	const auto bank_index = i >> batches_per_bank_shift;
	const auto batch_index = i & batches_per_bank_mask;
	const auto raw_bank = raw_event.raw_bank(bank_index);
	
	decode_muon_bank_tell1(parameters.dev_muon_raw_to_hits,
			       batch_index, raw_bank, storage_station_region_quarter_offsets, atomics_muon,
			       parameters.dev_storage_tile_id, parameters.dev_storage_tdc_value);
      }
      
    } else if (muon_bank_version == 3){
      const auto raw_event = Muon::RawEvent<mep_layout, 3> {
	parameters.dev_muon_raw, parameters.dev_muon_raw_offsets, parameters.dev_muon_raw_sizes, event_number};
      
      // number_of_raw_banks = 10
      // batches_per_bank = 4
      constexpr uint32_t batches_per_bank_mask = 0x3;
      constexpr uint32_t batches_per_bank_shift = 2;
      //for (unsigned i = threadIdx.x; i < raw_event.number_of_raw_banks() * Muon::batches_per_bank; i += blockDim.x) {
      for (unsigned i = 0; i < raw_event.number_of_raw_banks(); i += blockDim.x) {

	//const auto bank_index = i >> batches_per_bank_shift;
	//const auto batch_index = i & batches_per_bank_mask;
	//const auto raw_bank = raw_event.raw_bank(bank_index);
	
	const int bank_index = i;
	const int batch_index = 0;
	const auto raw_bank = raw_event.raw_bank(i);    	

	//TODO: remove invalid banks (e.g. 26624 in standalone mode) 
	decode_muon_bank_tell40(parameters.dev_muon_raw_to_hits,
				batch_index, raw_bank, storage_station_region_quarter_offsets, atomics_muon,
				parameters.dev_storage_tile_id, parameters.dev_storage_tdc_value);
      }      
    } else{
      throw StrException("MuonPopulateTileAndTDC : unrecognized muon raw bank version \n"); }
  }
}

void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_storage_tile_id_t>(arguments, first<host_muon_total_number_of_tiles_t>(arguments));
  set_size<dev_storage_tdc_value_t>(arguments, first<host_muon_total_number_of_tiles_t>(arguments));
  set_size<dev_atomics_muon_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * 2 * Muon::Constants::n_stations * Muon::Constants::n_regions *
      Muon::Constants::n_quarters);
}

void muon_populate_tile_and_tdc::muon_populate_tile_and_tdc_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_atomics_muon_t>(arguments, 0, context);
  Allen::memset_async<dev_storage_tile_id_t>(arguments, 0, context);
  Allen::memset_async<dev_storage_tdc_value_t>(arguments, 0, context);
  const unsigned int muon_bank_version = first<host_raw_bank_version_t>(arguments);
  
  global_function(
    runtime_options.mep_layout ? muon_populate_tile_and_tdc_kernel<true> : muon_populate_tile_and_tdc_kernel<false>)(
														     1, //size<dev_event_list_t>(arguments),
    // FIXME:
														     1, //10 * Muon::batches_per_bank,
														     context)(arguments, muon_bank_version, 
															      size<dev_event_list_t>(arguments));
  print<dev_storage_tile_id_t>(arguments);
  print<dev_storage_tdc_value_t>(arguments);

}
