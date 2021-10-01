/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "ProgramOptions.h"
#include "RoutingBitsWriter.cuh"
#include "HltDecReport.cuh"
#include "SelectionsEventModel.cuh"
#include <bits/stdc++.h>

void routingbits_writer::routingbits_writer_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_routingbits_t>(
    arguments, (  2*first<host_number_of_events_t>(arguments))); // I don't understand why I need the factor x 2
  set_size<host_routingbits_t>(
    arguments, (  2*first<host_number_of_events_t>(arguments))); // I don't understand why I need the factor x 2
}

void routingbits_writer::routingbits_writer_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  initialize<host_routingbits_t>(arguments, 0, context);

  global_function(routingbits_writer)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_routingbits_conf);
   

  Allen::copy<host_routingbits_t, dev_routingbits_t>(arguments, context);
  safe_assign_to_host_buffer<dev_routingbits_t>(host_buffers.host_routingbits, arguments, context);
}


__global__ void routingbits_writer::routingbits_writer(
  routingbits_writer::Parameters parameters,
  const RoutingBitsConfiguration::RoutingBits* dev_routingbits_conf )
{
  const auto number_of_events = gridDim.x;

  const RoutingBitsConfiguration::AssociatedLines* associated_lines = parameters.host_routingbits_associatedlines;
  for (unsigned event_index = blockIdx.x * blockDim.x + threadIdx.x; event_index < number_of_events; event_index += blockDim.x * gridDim.x) {

       uint32_t* event_routingbits = parameters.dev_routingbits + event_index;
       const uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_index;

       uint32_t bits = 0;

       for (unsigned bit_index = 0; bit_index < sizeof(dev_routingbits_conf->bits)/sizeof(dev_routingbits_conf->bits[0]); bit_index ++) {

         const auto bit = dev_routingbits_conf->bits[bit_index];
         int result = 0;
         
         auto associated_lines_forbit = associated_lines[bit-32];
         const auto n_associated_lines = associated_lines_forbit.n_lines;
         
         for (unsigned line_index = 0; line_index < n_associated_lines; line_index ++) {
           auto line_number = associated_lines_forbit.line_numbers[line_index];
           // Iterate all elements and get a decision for the current {event, line}
           HltDecReport dec_report;
           dec_report.setDecReport(event_dec_reports[2 + line_number]);
           auto decision = dec_report.getDecision();
           if (!dec_report.getDecision()) continue;
           result = 1; 
         }
         int word = bit/32;
         if ( result ) bits |= ( 0x01UL << ( bit - 32 * word ) );   
         event_routingbits[event_index] = bits;
       }    
       //printf("In routingbits_writer: Event: %d , Routing bits:   %d\n", event_index, event_routingbits[event_index]);
  }
}
