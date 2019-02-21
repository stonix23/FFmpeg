
SET cpuISA=-1

IF NOT "%1"=="" (
	SET cpuISA=%1
)


ffmpeg.exe -s:v 1920x1080 -vcodec v210 -hide_banner -stream_loop 200 -i OddaView_1920x1080.v210  -cpuflags %cpuISA% -f null -y NUL

ffmpeg.exe -s:v 1920x1080 -vcodec v210 -hide_banner -stream_loop 200 -i OddaView_1920x1080.v210  -cpuflags %cpuISA% -f null -y NUL

ffmpeg.exe -s:v 1920x1080 -vcodec v210 -hide_banner -stream_loop 200 -i OddaView_1920x1080.v210  -cpuflags %cpuISA% -f null -y NUL

