--[[
--  作者:Steven 
--  日期:2017-02-26
--  文件名:file_type.lua
--  版权说明:南京正溯网络科技有限公司.版权所有©copy right.
--  文件定义,主要用于文件格式定义, 网络传输时候的类型选择
--  
--]]


--[[
	media 类型定义,主要包括图片, 声音, 视频流等
	系统默认使用 8字节字符串来表达定义格式以及其编码相关信息
]]
local bit_help = require "common.bit_help"


local MEDIA_TYPE={
	DEFAULT = 0,
	IMAGE = 1,
	AUDIO = 2,
	VIDEO = 3,	-- 单视频信息
	AVIDEO = 4,	-- 视频+音频混合,比如rtmp
}
 
local MEDIA_ENCODE_TYPE={
	-- 音频
	AUDIO_ENCODE_PCM = 0,
	AUDIO_ENCODE_WAV = 1,
	AUDIO_ENCODE_MP3 = 2,
	AUDIO_ENCODE_OGG = 3,
	AUDIO_ENCODE_MPC = 4,
	AUDIO_ENCODE_WMA = 5,
	AUDIO_ENCODE_RA  = 6,
	AUDIO_ENCODE_APE = 7,
	AUDIO_ENCODE_FLAC= 8,
	AUDIO_ENCODE_TAK = 9,
	AUDIO_ENCODE_TTA = 10,
	AUDIO_ENCODE_TAC = 11,
	AUDIO_ENCODE_MIDI = 12,
}

local VIDEO_ENCODE_TYPE={
	-- 音频
	VIDEO_ENCODE_H261 = 0,
	VIDEO_ENCODE_H262 = 1,
	VIDEO_ENCODE_H263 = 2,
	VIDEO_ENCODE_H263P = 3,
	VIDEO_ENCODE_H263pp = 4,
	VIDEO_ENCODE_H264 = 5,
	VIDEO_ENCODE_H265  = 6,
	VIDEO_ENCODE_JPEG = 7,
	VIDEO_ENCODE_MPEG_1_2= 8,
	VIDEO_ENCODE_MPEG_4 = 9,
	VIDEO_ENCODE_TTA = 10,
	VIDEO_ENCODE_TAC = 11, 
}

local FILE_TYPE = {
	FILE_BINARY = 0,	-- 若没有对应的编码 根据编码直接进行映射文件类型
	FILE_TXT = 1,
	FILE_XML = 2,
	FILE_JSON = 3,
	-- AUDIO
	FILE_MIDI = 4,  

}


local _M = {}
return _M
