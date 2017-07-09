import os
import osproc
import random
import strutils

const
  vlc = "/Applications/VLC.app/Contents/MacOS/VLC"
  playlist = ".playlist.m3u"
  excluded = [".DS_Store", "xplay", playlist]

proc write(playlist : string, files : seq[string]) = 
  var file = open(playlist, mode=fmWrite)
  for line in files:
    file.writeLine(line)
  file.close()

if paramCount() > 0:
  randomize()
  let dir = paramStr(1)
  var files: seq[string]
  files = @[]

  for i in walkDir(dir):
    if i.kind == pcFile and not excluded.contains(i.path.splitFile().name):
      files.add(i.path)
  files.shuffle()

  playlist.write(files)

  discard 
    startProcess(
      command = vlc, 
      args = ["--intf=macosx", playlist]
    ).waitForExit()

  playlist.removeFile()
else:
  echo "Directory not specified"
  echo "Usage: xplay <directory>"
