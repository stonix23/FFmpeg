
SET cpuISA=0

IF NOT "%1"=="" (
	SET cpuISA=%1
)


ffmpeg.exe -s:v 1920x1080 -vcodec v210 -i OddaView_1920x1080.v210  -cpuflags %cpuISA% -f rawvideo -v 24 -y out.yuv

FC /B OddaView_1920x1080_ref.yuv out.yuv

ffmpeg.exe -s:v 1280x720 -vcodec v210 -i OddaView_1280x720.v210  -cpuflags %cpuISA% -f rawvideo -v 24 -y out.yuv

FC /B OddaView_1280x720_ref.yuv out.yuv


ffmpeg.exe -s:v 352x288 -vcodec v210 -i OddaView_352x288.v210  -cpuflags %cpuISA% -f rawvideo -v 24 -y out.yuv

FC /B OddaView_352x288_ref.yuv out.yuv

del out.yuv
