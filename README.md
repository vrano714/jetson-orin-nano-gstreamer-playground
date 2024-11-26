# Jetson Orin Nano Gstreamer Playground

This is a "playground" repository. Please look the scripts and modify as you like.

I wanted to make a virtual video device on Jetson Orin Nano and to make a single stream from 2 cameras connected to CSI port.

Original aim was to make a high-quality VR camera with Jetson.
However, I think you can create a video with small foreground window on a full-size background window (picture-in-picture).

For the camera module, I tested Raspberry Pi HQ Camera as easy-to-get option with various lens options.

## Prerequisite

- Jetson Orin Nano should have gstreamer (nVidia custom version): I do not know whether it's bundled in the vanilla JetPack.
- CSI port should be configured with `jetson-io`: you may run `sudo /opt/nvidia/jetson-io/jetson-io.py`

### Virtual v4l2 loopback device

```bash
sudo apt update
sudo apt install v4l2loopback-dkms v4l2loopback-utils
sudo reboot
```

## Make virtual v4l2 loopback device

Basically `make_v4l2.sh` should do.

This script will create a virtual v4l2 loopback device at `/dev/video2`.
Note that `video0` and `video1` are used by CSI cameras.

## Run gstreamer to combine 2 camera stream into one

Run `run_gst.sh`. But it has several options to set such as:

- `-s`: sink option
  - `v4l2`: use `v4l2sink` as final destination. This option should be used when you want to use combined video in other applications. (But I only tested Shiguredo sumomo webrtc sender) (default)
  - `fakesink`: use `fakesink`. Discard every frame into hollow.
  - `file`: use `filesink`. Will attempt to make h264 `hoge.mkv` in home dir.
  - any other string: sue `autovideosink`. Show a window of the stream
- `-r`: resolution option
  - `2160`: use `3840x2160` for input stream.
  - `1080`: use `1920x1080` for input stream. (default)
  - `720`: use `1280x720` for input stream.
  - `540`: use `960x540` for input stream.
  - any other string: fallback to default
- `-a`: align option
  - `sbs`: side-by-side (default)
  - `tab`: top-and-bottom
  - any other string: fallback to default
- `-c`: crop option
  - (this option has no additional string to configure)
  - (not tested!)

So, how does the command like?

```bash
./run_gst.sh -s v4l2 -r 2160 -a sbs
```

Running this will make a `7680x2160` video, with `sensor_id=0` at left and `sensor_id=1` at right.

In the gstreamer script, bottom (for sbs, right for tab) side, which is jsut blackout, is cut.
As a result, final video stream should be very wide (or very tall).

---------------------

Author notes

Motivation of publishing these scripts is that someone may benefit in future.
When constructing the pipeline, I suffered because there were little materials to see or to avoid error or to construct better pipeline (especially for jetson specific elements).

(One crucial element was `identity`! I think dropping this will cause error.)
