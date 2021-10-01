/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostRoutingBitsConfiguration.h"
#include "ProgramOptions.h"

void host_routingbits_configuration::host_routingbits_configuration_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // The total sum holder just holds a single unsigned integer.
  set_size<host_routingbits_associatedlines_t>(arguments, 32*sizeof(RoutingBitsConfiguration::AssociatedLines));
  set_size<dev_routingbits_associatedlines_t>(arguments, 32*sizeof(RoutingBitsConfiguration::AssociatedLines));
}

void host_routingbits_configuration::host_routingbits_configuration_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
#if defined(TARGET_DEVICE_CPU)
  // Copy directly data to the output buffer
  //Allen::copy<dev_output_buffer_t, dev_input_buffer_t>(arguments, context);
  host_routingbits_conf_impl(
    first<host_number_of_active_lines_t>(arguments),
    data<host_names_of_active_lines_t>(arguments),
    data<host_routingbits_associatedlines_t>(arguments),
    constants.host_routingbits_conf);

  //for (unsigned i = 0 ; i < 32; i++) { std::cout << i << "    " << data<host_routingbits_associatedlines_t>(arguments)[i].n_lines << std::endl;}
  // Ensure host_routingbits_associatedlines and dev_routingbits_associatedlines contain the same
  //Allen::copy<host_routingbits_associatedlines_t, dev_routingbits_associatedlines_t>(arguments, context);
  //for (unsigned i = 0 ; i < 32; i++) { std::cout << i << "    " << data<host_routingbits_associatedlines_t>(arguments)[i].n_lines << std::endl;}
#else
  // Copy data over to the host
  //Allen::copy<host_output_buffer_t, dev_input_buffer_t>(arguments, context);

  // Perform the prefix sum in the host
  host_routingbits_conf_impl(
    first<host_number_of_active_lines_t>(arguments),
    data<host_names_of_active_lines_t>(arguments),
    data<host_routingbits_associatedlines_t>(arguments),
    constants.host_routingbits_conf);
  // Copy routing bit info to the device
  Allen::copy_async<dev_routingbits_associatedlines_t, host_routingbits_associatedlines_t>(arguments, context);
#endif
}

void host_routingbits_configuration::host_routingbits_conf_impl(
  unsigned number_of_active_lines,
  char* names_of_active_lines,
  RoutingBitsConfiguration::AssociatedLines* routingbits_associatedlines,
  const RoutingBitsConfiguration::RoutingBits* dev_routingbits_conf)
{
  auto line_names = split_string(static_cast<char const*>(names_of_active_lines), ",");

  for (unsigned bit_index = 0; bit_index < sizeof(dev_routingbits_conf->bits)/sizeof(dev_routingbits_conf->bits[0]); bit_index ++) {

      const auto expr = dev_routingbits_conf->expressions[bit_index];
      const auto bit = dev_routingbits_conf->bits[bit_index];
      unsigned cnt_lines = 0;

      RoutingBitsConfiguration::AssociatedLines associated_lines;
      associated_lines.routing_bit = bit;
       

      for (unsigned line_index = 0; line_index < number_of_active_lines; line_index ++) {
          auto line_name = line_names[line_index];

          if( expr.find(line_name)==std::string::npos) continue; // only works with OR logic so far. TODO: implement AND logic / * logic

          associated_lines.line_numbers[cnt_lines] = line_index;
          cnt_lines++;
      }
      associated_lines.n_lines = cnt_lines;  
      routingbits_associatedlines[bit-32] = associated_lines;
  } 
}
