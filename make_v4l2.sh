if [ -e /dev/video2 ]; then
    echo "/dev/video2 already exists. quitting..."
    exit 1
fi

sudo modprobe v4l2loopback \
    devices=1 \
    exclusive_caps=1 \
    video_nr=2 \
    card_label="virtual"

if [ $? -eq 0 ]; then
    echo "modprobe v4l2loopback success"
else
    echo "modprobe v4l2loopback fialed"
fi

