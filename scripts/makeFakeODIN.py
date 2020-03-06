from os import path, listdir, mkdir
from sys import argv, exit, byteorder
from binascii import unhexlify
from random import randint

banksize=56
bankmagic=0xcbcb
banksource=0
bankversion=3
banktype=0x10
bunchcurrent=0xFF
word8byte2=0xC0
word8bytes10=0x0000


if len(argv)<2:
  print("Usage: python3", argv[0], "<base_dir>")
  exit()

basedir = argv[1]

if not path.exists(basedir):
  print("Directory", basedir, "does not exist")
  exit()

odindir = path.join(basedir,"ODIN")
velodir = path.join(basedir,"VP")

if not path.exists(odindir):
  mkdir(odindir)

gpstime = 1640995200000000

files = listdir(velodir)
for filename in files:
  (runno, evtno) = filename.split("/")[-1].split(".")[0].split("_")
  eventtype = 0
  if randint(0,9) == 9:
    eventtype += 0x0004
  if randint(0,9) == 9:
    eventtype += 0x0008
  bunchcurrent = randint(0x00,0xFF)
  word8byte2 = 0x40*randint(0,3)
  output = open(path.join(odindir,filename),"w+b")
  output.write(banksize.to_bytes(2, byteorder))
  output.write(bankmagic.to_bytes(2, byteorder))
  output.write(banksource.to_bytes(2, byteorder))
  output.write(bankversion.to_bytes(1, byteorder))
  output.write(banktype.to_bytes(1, byteorder))
  output.write(int(runno).to_bytes(4, byteorder))
  output.write(int(eventtype).to_bytes(4, byteorder))#Event type(4bytes)
  output.write(int(0).to_bytes(4, byteorder))#Orbit ID(4bytes)
  output.write(int(int(evtno)/0x100000000).to_bytes(4, byteorder))
  output.write(int(int(evtno)%0x100000000).to_bytes(4, byteorder))
  output.write(int(gpstime/0x100000000).to_bytes(4, byteorder))
  output.write(int(gpstime%0x100000000).to_bytes(4, byteorder))
  output.write(int(0).to_bytes(4, byteorder))#Error bits(1), Det status(3)
  output.write(int(word8bytes10).to_bytes(2, byteorder))#reserved/bunch ID (2)
  output.write(int(word8byte2).to_bytes(1, byteorder))#BXtype/F/RoT/Trigger type (1)
  output.write(int(bunchcurrent).to_bytes(1, byteorder))#Bunch current(1)
  output.write(int(0).to_bytes(12, byteorder))#TCK(12)
  output.close()
  gpstime+=1
