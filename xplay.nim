import os
import osproc
import random
import strutils

const
    playlist = ".playlist.m3u"
    exclude = @[".DS_Store", "xplay", playlist]

type
    ScanDir = ref object of RootObj
        dir : string

    FilterList = ref object of ScanDir
        exclude : seq[string]
        origin : ScanDir

    ShuffleList = ref object of ScanDir
        origin : ScanDir

    PlFromList = ref object of RootObj
        filename : string
        files : seq[string]

    Play = ref object of RootObj
        filename : string
        command : string
        args : seq[string]

    PlTemp = ref object of Play
        origin : Play

method get(sd : ScanDir) : seq[string] {.base.} =
    echo "Scan dir: " , sd.dir
    if not existsDir(sd.dir):
        raise newException(OSError, "Directory " & sd.dir & " not exists")
    var files : seq[string] = @[]
    for i in walkDir(expandFilename(sd.dir)):
        if i.kind == pcFile:
          files.add(i.path)
    return files

method get(fl : FilterList) : seq[string] =
    var files : seq[string] = @[]
    for i in fl.origin.get():
        if not fl.exclude.contains(i.splitFile().name):
            files.add(i)
    if files.len == 0:
        raise newException(OSError, "No files in directory " & fl.origin.dir)
    echo "Total files: ", files.len
    return files

method get(sl : ShuffleList) : seq[string] =
    randomize()
    var files : seq[string] = sl.origin.get()
    echo "Shuffling dir content"
    files.shuffle()
    return files

proc toFile(pl : PlFromList) : string =
    echo "Writing dir content to ", pl.filename
    var file = open(pl.filename, mode=fmWrite)
    for line in pl.files:
      file.writeLine("file://" & line)
    file.close()
    return pl.filename

method start(pl : Play) {.base.} =
    echo "Starting ", pl.command
    discard
        startProcess(command=pl.command, args=pl.args).waitForExit()

proc plVlc(filename : string) : Play =
    new result
    result.command = "/Applications/VLC.app/Contents/MacOS/VLC"
    result.filename = filename
    result.args = @[
        "--intf=macosx",
        "--video-on-top",
        "--no-auto-preparse",
        filename
    ]

method start(pl : PlTemp) =
    pl.origin.start()
    echo "Remove ", pl.origin.filename
    pl.origin.filename.removeFile()

if isMainModule:
    if paramCount() == 0:
        echo "Directory not specified"
        echo "Usage: xplay <directory>"
    else:
        let dir = paramStr(1)
        try:
            PlTemp(
                origin:
                    plVlc(
                        filename=
                            PlFromList(
                                filename:
                                    playlist,
                                files:
                                    ShuffleList(
                                        origin:
                                            FilterList(
                                                exclude:
                                                    exclude,
                                                origin:
                                                    ScanDir(dir : dir)
                                            )
                                    ).get()
                            ).toFile()
                    )
            ).start()
        except:
            echo getCurrentExceptionMsg(), ". Exit"