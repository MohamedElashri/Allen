from __future__ import print_function
import argparse
import zmq

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('hostname')
arg_parser.add_argument('-p', '--port', dest='port', type=int, default=35000)
arg_parser.add_argument(
    '-c',
    '--command',
    dest='command',
    type=str,
    default='report',
    choices=['report', 'exit'])
args = arg_parser.parse_args()

context = zmq.Context.instance()
request = context.socket(zmq.REQ)

connection = "tcp://%s:%d" % (args.hostname, args.port)
request.connect(connection)

poller = zmq.Poller()
poller.register(request, zmq.POLLIN)

if args.command == "report":
    request.send_string("REPORT")
    result = dict(poller.poll(500))
    if request in result:
        report = request.recv_multipart()
        if len(report) == 1:
            print(report[0])
        else:
            for i in range(0, len(report), 2):
                print(report[i], int(report[i + 1]) / 1024**2, " MB")
    else:
        print("No reply to request for report")
elif args.command == 'exit':
    request.send_string("EXIT")
    result = dict(poller.poll(500))
    if request in result:
        print("Receiver is exiting")
    else:
        print("No reply to exit request")
