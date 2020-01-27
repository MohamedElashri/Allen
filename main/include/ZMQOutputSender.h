#pragma once

#include <read_mdf.hpp>
#include <raw_helpers.hpp>

#include <ZeroMQSvc.h>
#include <OutputHandler.h>

class ZMQOutputSender final : public OutputHandler {
public:
  ZMQOutputSender(
    IInputProvider const* input_provider,
    std::string receiver_connection,
    size_t events_per_slice,
    ZeroMQSvc* zmqSvc,
    bool checksum = true);

  ~ZMQOutputSender();

  zmq::socket_t* client_socket() override;

  void handle() override;

protected:

  std::tuple<size_t, gsl::span<char>> buffer(size_t buffer_size) override;

  virtual bool write_buffer(size_t) override;

private:

  // ZeroMQSvc pointer for convenience.
  ZeroMQSvc* m_zmq = nullptr;

  // ID string
  std::string m_id;

  // are we connected to a receiver
  bool m_connected = false;

  // data socket
  std::optional<zmq::socket_t> m_socket;

  // request socket
  std::optional<zmq::socket_t> m_request;

  // do checksum on write
  bool const m_checksum = false;

  // Buffer message
  zmq::message_t m_buffer;
};
