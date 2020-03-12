#ifndef ZEROMQ_IZEROMQSVC_H
#define ZEROMQ_IZEROMQSVC_H 1

// Include files
// from STL
#include <type_traits>
#include <string>
#include <vector>
#include <sstream>
#include <ios>

// boost
#ifdef __CLING__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wexpansion-to-defined"
#endif
#include <boost/serialization/array.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/map.hpp>
#include <boost/serialization/unordered_map.hpp>
#include <boost/serialization/unordered_set.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/binary_iarchive.hpp>
#include <boost/archive/binary_oarchive.hpp>
#ifdef __CLING__
#pragma GCC diagnostic pop
#endif
#include <boost/iostreams/device/array.hpp>
#include <boost/iostreams/device/back_inserter.hpp>
#include <boost/iostreams/stream_buffer.hpp>
#include <boost/numeric/conversion/cast.hpp>

// from Gaudi
#ifndef STANDALONE
#include "GaudiKernel/INamedInterface.h"
#include "GaudiKernel/StringKey.h"
#include "GaudiUtils/Aida2ROOT.h"

// AIDA
#include <AIDA/IHistogram.h>
#endif

// ROOT
#if defined(WITH_ROOT)
#include <TH1.h>
#include <TClass.h>
#include <TBufferFile.h>
#endif

// ZeroMQ
#include <zmq/zmq.hpp>

#include "Utility.h"
#include "SerializeTuple.h"
#include "CustomSink.h"
#include "functions.h"

namespace Detail {

#if defined(WITH_ROOT)
  template<class T>
  struct ROOTHisto {
    constexpr static bool value = std::is_base_of<TH1, T>::value;
  };

  template<class T>
  struct ROOTObject {
    constexpr static bool value = std::is_base_of<TObject, T>::value;
  };
#else
  template<class T>
  using ROOTHisto = std::false_type;

  template<class T>
  using ROOTObject = std::false_type;
#endif

#ifndef STANDALONE
  template<class T>
  struct AIDAHisto {
    constexpr static bool value = std::is_base_of<AIDA::IHistogram, T>::value;
  };
#endif

} // namespace Detail

namespace ZMQ {

  struct TimeOutException : std::exception {
    TimeOutException() = default;
    TimeOutException(const TimeOutException&) = default;
    ~TimeOutException() = default;
    TimeOutException& operator=(const TimeOutException&) = default;
  };

  struct MoreException : std::exception {
    MoreException() = default;
    MoreException(const MoreException&) = default;
    ~MoreException() = default;
    MoreException& operator=(const MoreException&) = default;
  };

} // namespace ZMQ

template<int PERIOD = 0>
struct ZmqLingeringSocketPtrDeleter {
  void operator()(zmq::socket_t* socket)
  {
    auto period = PERIOD;
    if (socket) socket->setsockopt(ZMQ_LINGER, &period, sizeof(period));
    delete socket;
  }
};

template<int PERIOD = 0>
using ZmqLingeringSocketPtr = std::unique_ptr<zmq::socket_t, ZmqLingeringSocketPtrDeleter<PERIOD>>;

/** @class IZeroMQSvc IZeroMQSvc.h ZeroMQ/IZeroMQSvc.h
 *
 *
 *  @author
 *  @date   2015-06-22
 */
#ifndef STANDALONE
class GAUDI_API IZeroMQSvc : public extend_interfaces<INamedInterface> {
public:
  // Return the interface ID
  DeclareInterfaceID(IZeroMQSvc, 2, 0);
#else
class IZeroMQSvc {
public:
  virtual ~IZeroMQSvc() = default;
#endif

  enum Encoding { Text = 0, Binary };

#ifndef STANDALONE
  IZeroMQSvc() = default;
  virtual Encoding encoding() const = 0;
  virtual zmq::context_t& context() const = 0;
  virtual zmq::socket_t socket(int type) const = 0;
#else
  Encoding encoding() const { return m_enc; };
  void setEncoding(const Encoding& e) { m_enc = e; };
  zmq::context_t& context() const
  {
    if (!m_context) {
      m_context = new zmq::context_t {1};
    }
    return *m_context;
  }
  virtual zmq::socket_t socket(int type) const
  {
    auto socket = zmq::socket_t {context(), type};
    int period = 0;
    socket.setsockopt(zmq::LINGER, &period, sizeof(period));
    return socket;
  }
#endif

  // decode message with ZMQ, POD version
  template<
    class T,
    typename std::enable_if<!std::is_pointer<T>::value && Detail::is_trivial<T>::value, T>::type* = nullptr>
  T decode(const zmq::message_t& msg) const
  {
    T object;
    memcpy(&object, msg.data(), msg.size());
    return object;
  }

  // decode ZMQ message, general version using boost serialize
  template<
    class T,
    typename std::enable_if<
      !(std::is_pointer<T>::value || Detail::ROOTObject<T>::value || Detail::is_trivial<T>::value ||
        std::is_same<T, std::string>::value),
      T>::type* = nullptr>
  T decode(const zmq::message_t& msg) const
  {
    using Device = boost::iostreams::basic_array_source<char>;
    using Stream = boost::iostreams::stream_buffer<Device>;
    Device device {static_cast<const char*>(msg.data()), msg.size()};
    Stream stream {device};
    if (encoding() == Text) {
      std::istream istream {&stream};
      return deserialize<boost::archive::text_iarchive, T>(istream);
    }
    else {
      return deserialize<boost::archive::binary_iarchive, T>(stream);
    }
  }

  // decode ZMQ message, string version
  template<class T, typename std::enable_if<std::is_same<T, std::string>::value, T>::type* = nullptr>
  std::string decode(const zmq::message_t& msg) const
  {
    std::string r(msg.size() + 1, char {});
    r.assign(static_cast<const char*>(msg.data()), msg.size());
    return r;
  }

#if defined(WITH_ROOT)
  // decode ZMQ message, ROOT version
  template<
    class T,
    typename std::enable_if<Detail::ROOTObject<T>::value && !Detail::ROOTHisto<T>::value, T>::type* = nullptr>
  std::unique_ptr<T> decode(const zmq::message_t& msg) const
  {
    return decodeROOT<T>(msg);
  }

  // decode ZMQ message, ROOT histogram and profile version
  template<class T, typename std::enable_if<Detail::ROOTHisto<T>::value, T>::type* = nullptr>
  std::unique_ptr<T> decode(const zmq::message_t& msg) const
  {
    auto histo = decodeROOT<T>(msg);
    if (histo.get()) {
      histo->SetDirectory(nullptr);
      histo->ResetBit(kMustCleanup);
    }
    return histo;
  }
#endif

  // receiving AIDA histograms and and profiles is not possible, because the classes that
  // would allow either serialization of the Gaudi implemenation of AIDA histograms, or
  // their creation from a ROOT histograms (which they are underneath, in the end), are
  // private.

  // receive message with ZMQ, general version
  // FIXME: what to do with flags=0.... more is a pointer, that might prevent conversion
  template<
    class T,
    typename std::enable_if<
      !(Detail::ROOTObject<T>::value
#ifndef STANDALONE
        || Detail::AIDAHisto<T>::value
#endif
        || std::is_same<zmq::message_t, T>::value),
      T>::type* = nullptr>
  T receive(zmq::socket_t& socket, bool* more = nullptr) const
  {
    // receive message
    zmq::message_t msg;
    while (true) {
      try {
        auto nbytes = socket.recv(msg);
        if (!nbytes) {
          throw ZMQ::TimeOutException {};
        }
        if (more) *more = msg.more();
        break;
      } catch (const zmq::error_t& error) {
        if (error.num() == EINTR) {
          msg.rebuild();
        }
        else {
          throw;
        }
      }
    }

    // decode message
    return decode<T>(msg);
  }

  // receive message with ZMQ
  template<class T, typename std::enable_if<std::is_same<zmq::message_t, T>::value, T>::type* = nullptr>
  T receive(zmq::socket_t& socket, bool* more = nullptr) const
  {
    // receive message
    zmq::message_t msg;
    while (true) {
      try {
        auto nbytes = socket.recv(msg);
        if (!nbytes) {
          throw ZMQ::TimeOutException {};
        }
        if (more) *more = msg.more();
        break;
      } catch (const zmq::error_t& error) {
        if (error.num() == EINTR) {
          msg.rebuild();
        }
        else {
          throw;
        }
      }
    }

    return msg;
  }

  // receive message with ZMQ, ROOT version
  template<class T, typename std::enable_if<Detail::ROOTObject<T>::value, T>::type* = nullptr>
  std::unique_ptr<T> receive(zmq::socket_t& socket, bool* more = nullptr) const
  {
    // receive message
    zmq::message_t msg;
    while (true) {
      try {
        auto nbytes = socket.recv(msg);
        if (!nbytes) {
          throw ZMQ::TimeOutException {};
        }
        if (more) *more = msg.more();
        break;
      } catch (const zmq::error_t& error) {
        if (error.num() == EINTR) {
          msg.rebuild();
        }
        else {
          throw;
        }
      }
    }

    // decode message
    return decode<T>(msg);
  }

  // encode message to ZMQ
  template<
    class T,
    typename std::enable_if<!std::is_pointer<T>::value && Detail::is_trivial<T>::value, T>::type* = nullptr>
  zmq::message_t encode(const T& item, std::function<size_t(const T& t)> sizeFun = ZMQ::defaultSizeOf<T>) const
  {
    size_t s = sizeFun(item);
    zmq::message_t msg {s};
    memcpy((void*) msg.data(), &item, s);
    return msg;
  }

  // encode message to ZMQ after serialization with boost::serialize
  template<
    class T,
    typename std::enable_if<
      !(std::is_pointer<T>::value || Detail::ROOTObject<T>::value || Detail::is_trivial<T>::value ||
        std::is_same<T, std::string>::value),
      T>::type* = nullptr>
  zmq::message_t encode(const T& item) const
  {
    using Device = CustomSink<char>;
    using Stream = boost::iostreams::stream_buffer<Device>;
    Stream stream {Device {}};
    if (encoding() == Text) {
      std::ostream ostream {&stream};
      serialize<boost::archive::text_oarchive>(item, ostream);
    }
    else {
      serialize<boost::archive::binary_oarchive>(item, stream);
    }
    auto size = stream->size();
    zmq::message_t msg {stream->release(), size, deleteBuffer<Device::byte>};
    return msg;
  }

  zmq::message_t encode(const char* item) const
  {
    std::function<size_t(const char& t)> fun = ZMQ::stringLength;
    return encode(*item, fun);
  }

  zmq::message_t encode(const std::string& item) const { return encode(item.c_str()); }

#if defined(WITH_ROOT)
  zmq::message_t encode(const TObject& item) const
  {
    auto deleteBuffer = [](void* data, void * /* hint */) -> void { delete[](char*) data; };

    TBufferFile buffer(TBuffer::kWrite);
    buffer.WriteObject(&item);

    // Create message and detach buffer
    zmq::message_t message(buffer.Buffer(), buffer.Length(), deleteBuffer);
    buffer.DetachBuffer();

    return message;
  }
#endif

#ifndef STANDALONE
  zmq::message_t encode(const AIDA::IHistogram& item) const
  {
    return encode(*Gaudi::Utils::Aida2ROOT::aida2root(&item));
  }
#endif

  // Send message with ZMQ
  template<class T, typename std::enable_if<!std::is_same<T, zmq::message_t>::value, T>::type* = nullptr>
  std::optional<size_t> send(zmq::socket_t& socket, const T& item, zmq::send_flags flags = zmq::send_flags::none) const
  {

    while (true) {
      try {
        return socket.send(encode(item), flags);
      } catch (const zmq::error_t& error) {
        if (error.num() != EINTR) {
          throw;
        }
      }
    }
  }

  std::optional<size_t> send(zmq::socket_t& socket, const char* item, zmq::send_flags flags = zmq::send_flags::none)
    const
  {

    while (true) {
      try {
        return socket.send(encode(item), flags);
      } catch (const zmq::error_t& error) {
        if (error.num() != EINTR) {
          throw;
        }
      }
    }
  }

  std::optional<size_t> send(zmq::socket_t& socket, zmq::message_t& msg, zmq::send_flags flags = zmq::send_flags::none)
    const
  {

    while (true) {
      try {
        return socket.send(msg, flags);
      } catch (const zmq::error_t& error) {
        if (error.num() != EINTR) {
          throw;
        }
      }
    }
  }

  std::optional<size_t> send(zmq::socket_t& socket, zmq::message_t&& msg, zmq::send_flags flags = zmq::send_flags::none)
    const
  {
    while (true) {
      try {
        return socket.send(std::move(msg), flags);
      } catch (const zmq::error_t& error) {
        if (error.num() != EINTR) {
          throw;
        }
      }
    }
  }

  int poll(zmq_pollitem_t* items, int nitems, long timeout = -1) const
  {
    while (true) {
      try {
        return zmq::poll(items, nitems, timeout);
      } catch (const zmq::error_t& error) {
        if (error.num() != EINTR) {
          throw;
        }
      }
    }
  }

private:
#ifdef STANDALONE
  Encoding m_enc = Text;
  mutable zmq::context_t* m_context = nullptr;
#endif

  template<class A, class S, class T>
  void serialize(const T& t, S& stream) const
  {
    A archive {stream};
    archive << t;
  }

  template<class A, class T, class S>
  T deserialize(S& stream) const
  {
    T t;
    try {
      A archive {stream};
      archive >> t;
    } catch (const boost::archive::archive_exception&) {
    }
    return t;
  }

#if defined(WITH_ROOT)
  // Receive ROOT serialized object of type T with ZMQ
  template<class T>
  std::unique_ptr<T> decodeROOT(const zmq::message_t& msg) const
  {
    // ROOT uses char buffers, ZeroMQ uses size_t
    auto factor = sizeof(size_t) / sizeof(char);

    // Create a buffer and insert the message; buffer must not adopt memory.
    TBufferFile buffer(TBuffer::kRead);
    buffer.SetBuffer(const_cast<void*>(msg.data()), factor * msg.size(), kFALSE);

    std::unique_ptr<T> r {};
    // Grab the object from the buffer. ROOT never does anything with the TClass pointer argument
    // given to ReadObject, because it will return a TObject* regardless...
    auto tmp = static_cast<T*>(buffer.ReadObjectAny(T::Class()));
    if (tmp) {
      r.reset(tmp);
    }
    return r;
  }
#endif
};

#endif // ZEROMQ_IZEROMQSVC_H
