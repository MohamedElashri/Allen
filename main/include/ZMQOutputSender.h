/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <read_mdf.hpp>
#include <raw_helpers.hpp>

#include <ZeroMQ/IZeroMQSvc.h>
#include <OutputHandler.h>

class ZMQOutputSender final : public OutputHandler {
public:
  ZMQOutputSender(
    IInputProvider const* input_provider,
    std::string receiver_connection,
    size_t const m_output_batch_size,
    size_t const n_lines,
    IZeroMQSvc* zmqSvc,
    bool checksum = true);

  ~ZMQOutputSender();

  zmq::socket_t* client_socket() const override;

  void handle() override;

protected:
  gsl::span<char> buffer(size_t, size_t buffer_size, size_t) override;

  virtual bool write_buffer(size_t) override;

private:
  // ZeroMQSvc pointer for convenience.
  IZeroMQSvc* m_zmq = nullptr;

  // ID string
  std::string m_id;

  // are we connected to a receiver
  bool m_connected = false;

  // data socket
  mutable std::optional<zmq::socket_t> m_socket;

  // request socket
  std::optional<zmq::socket_t> m_request;

  // Buffer message
  zmq::message_t m_buffer;
};
