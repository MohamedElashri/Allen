#include <memory>

#include <IZeroMQSvc.h>

IZeroMQSvc& zmqSvc()
{
  static std::unique_ptr<IZeroMQSvc> svc;
  if (!svc) {
    svc = std::make_unique<IZeroMQSvc>();
  }
  return *svc;
}
