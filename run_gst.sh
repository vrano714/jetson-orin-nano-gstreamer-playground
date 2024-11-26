SINK="videoconvert ! v4l2sink device=/dev/video2"
RESOLUTION="1080"
WIDTH=960
WIDTH2x=1920
HEIGHT=540
HEIGHT2x=1080
ALIGN="sbs"

DOCROP=false
CROP_L=0
CROP_R=0
CROP_T=0
CROP_B=0
CROP_COMMAND=""

while getopts "s:r:a:c" optKey; do
	case "$optKey" in
		s)
			if [ "${OPTARG}" = "v4l2" ]; then
				SINK="videoconvert ! v4l2sink device=/dev/video2"
			elif [ "${OPTARG}" = "fake" ]; then
				SINK="fakesink"
			elif [ "${OPTARG}" = "file" ]; then # file produced by this gonna be not playable?
				SINK="videoconvert ! queue ! x264enc ! matroskamux ! filesink location=$HOME/hoge.mkv"
			else
				SINK="autovideosink"
			fi
			;;
		r)
			RESOLUTION="${OPTARG}"
			if [ "$RESOLUTION" = "2160" ]; then
				# 2x 2160
				WIDTH=3840
				WIDTH2x=7680
				HEIGHT=2160
				HEIGHT2x=4320
			elif [ "$RESOLUTION" = "1080" ]; then
				# 2x 1080
				WIDTH=1920
				WIDTH2x=3840
				HEIGHT=1080
				HEIGHT2x=2160
			elif [ "$RESOLUTION" = "720" ]; then
				# 2x 720
				WIDTH=1280
				WIDTH2x=2560
				HEIGHT=720
				HEIGHT2x=1440
			elif [ "$RESOLUTION" = "540" ]; then
				# 2x 540
				WIDTH=960
				WIDTH2x=1920
				HEIGHT=540
				HEIGHT2x=1080
			fi
			;;
		a)
			# this should be sbs or tab
			ALIGN="${OPTARG}"
			;;
		c)
			# when used, get 80% image
			DOCROP=true
			;;
	esac
done

if "${DOCROP}"; then
    if [ "$RESOLUTION" = "2160" ]; then
        CROP_L=384
        CROP_R=3456
        CROP_T=216
        CROP_B=1944
        #CROP_L=160
        #CROP_R=3680
        #CROP_T=90
        #CROP_B=2070
    elif [ "$RESOLUTION" = "1080" ]; then
        CROP_L=192
        CROP_R=1728
        CROP_T=108
        CROP_B=972
    elif [ "$RESOLUTION" = "720" ]; then
        CROP_L=128
        CROP_R=1152
        CROP_T=72
        CROP_B=648
    elif [ "$RESOLUTION" = "540" ]; then
        CROP_L=96
        CROP_R=864
        CROP_T=54
        CROP_B=486
    fi
    CROP_COMMAND="! nvvidconv left=$CROP_L right=$CROP_R top=$CROP_T bottom=$CROP_B"
fi

if [ "$ALIGN" = "tab" ]; then
	# this is top-and-bottom
	gst-launch-1.0 nvcompositor name=m \
		sink_0::xpos=0 sink_0::ypos=0 sink_0::width=$WIDTH sink_0::height=$HEIGHT \
		sink_1::xpos=0 sink_1::ypos=$HEIGHT sink_1::width=$WIDTH sink_1::height=$HEIGHT \
		! "video/x-raw(memory:NVMM)", width=$WIDTH2x, height=$HEIGHT2x \
		! nvvidconv left=0 right=$WIDTH top=0 bottom=$HEIGHT2x \
		! "video/x-raw", width=$WIDTH, height=$HEIGHT2x, format=I420 \
		! identity drop-allocation=true \
		! $SINK \
		nvarguscamerasrc sensor-id=0 wbmode=5 \
		! "video/x-raw(memory:NVMM)", width=$WIDTH, height=$HEIGHT, framerate=30/1 \
        $CROP_COMMAND \
		! m.sink_0 \
		nvarguscamerasrc sensor-id=1  wbmode=5 \
		! "video/x-raw(memory:NVMM)", width=$WIDTH, height=$HEIGHT, framerate=30/1 \
        $CROP_COMMAND \
		! m.sink_1
else # ignore any other content than tab and fall back to sbs
	# this is side-by-side
	gst-launch-1.0 nvcompositor name=m \
		sink_0::xpos=0 sink_0::ypos=0 sink_0::width=$WIDTH sink_0::height=$HEIGHT \
		sink_1::xpos=$WIDTH sink_1::ypos=0 sink_1::width=$WIDTH sink_1::height=$HEIGHT \
		! "video/x-raw(memory:NVMM)", width=$WIDTH2x, height=$HEIGHT2x \
		! nvvidconv left=0 right=$WIDTH2x top=0 bottom=$HEIGHT \
		! "video/x-raw", width=$WIDTH2x, height=$HEIGHT, format=I420 \
		! identity drop-allocation=true \
		! $SINK \
		nvarguscamerasrc sensor-id=0 wbmode=5 \
		! "video/x-raw(memory:NVMM)", width=$WIDTH, height=$HEIGHT, framerate=30/1 \
        $CROP_COMMAND \
		! m.sink_0 \
		nvarguscamerasrc sensor-id=1  wbmode=5 \
		! "video/x-raw(memory:NVMM)", width=$WIDTH, height=$HEIGHT, framerate=30/1 \
        $CROP_COMMAND \
		! m.sink_1
fi
