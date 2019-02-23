;******************************************************************************
;* V210 SIMD unpack
;* Copyright (c) 2011 Loren Merritt <lorenm@u.washington.edu>
;* Copyright (c) 2011 Kieran Kunhya <kieran@kunhya.com>
;*
;* This file is part of FFmpeg.
;*
;* FFmpeg is free software; you can redistribute it and/or
;* modify it under the terms of the GNU Lesser General Public
;* License as published by the Free Software Foundation; either
;* version 2.1 of the License, or (at your option) any later version.
;*
;* FFmpeg is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;* Lesser General Public License for more details.
;*
;* You should have received a copy of the GNU Lesser General Public
;* License along with FFmpeg; if not, write to the Free Software
;* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
;******************************************************************************

%include "libavutil/x86/x86util.asm"

SECTION_RODATA

v210_mult: dw 64,4,64,4,64,4,64,4,64,4,64,4,64,4,64,4
v210_mask: times 8 dd 0x3ff

; for SSSE3 version only
v210_luma_shuf: db 8,9,0,1,2,3,12,13,4,5,6,7,-1,-1,-1,-1
v210_chroma_shuf: db 0,1,8,9,6,7,-1,-1,2,3,4,5,12,13,-1,-1

; for AVX2 version only
v210_luma_shuf1: db 0,1,-1,-1,-1,-1,8,9,-1,-1,-1,-1,-1,-1,-1,-1,0,1,-1,-1,-1,-1,8,9,-1,-1,-1,-1,-1,-1,-1,-1
v210_luma_shuf2: db -1,-1,4,5,6,7,-1,-1,12,13,14,15,-1,-1,-1,-1,-1,-1,4,5,6,7,-1,-1,12,13,14,15,-1,-1,-1,-1
v210_luma_permute: dd 0,1,2,4,5,6,7,7
v210_chroma_shuf1: db 0,1,-1,-1,10,11,-1,-1,2,3,8,9,-1,-1,-1,-1,0,1,-1,-1,10,11,-1,-1,2,3,8,9,-1,-1,-1,-1
v210_chroma_shuf2: db -1,-1,4,5,-1,-1,-1,-1,-1,-1,-1,-1,12,13,-1,-1,-1,-1,4,5,-1,-1,-1,-1,-1,-1,-1,-1,12,13,-1,-1
v210_chroma_permute: dd 0,1,4,5,2,3,6,7
v210_chroma_shuf3: db 0,1,2,3,4,5,8,9,10,11,12,13,-1,-1,-1,-1,0,1,2,3,4,5,8,9,10,11,12,13,-1,-1,-1,-1


SECTION .text

%macro v210_planar_unpack 1

; v210_planar_unpack(const uint32_t *src, uint16_t *y, uint16_t *u, uint16_t *v, int width)
cglobal v210_planar_unpack_%1, 5, 5, 7
    movsxdifnidn r4, r4d
    lea    r1, [r1+2*r4]
    add    r2, r4
    add    r3, r4
    neg    r4

    mova   m3, [v210_mult]
    mova   m4, [v210_mask]
    mova   m5, [v210_luma_shuf]
    mova   m6, [v210_chroma_shuf]
.loop:
%ifidn %1, unaligned
    movu   m0, [r0]
%else
    mova   m0, [r0]
%endif

    pmullw m1, m0, m3
    psrld  m0, 10
    psrlw  m1, 6  ; u0 v0 y1 y2 v1 u2 y4 y5
    pand   m0, m4 ; y0 __ u1 __ y3 __ v2 __

    shufps m2, m1, m0, 0x8d ; y1 y2 y4 y5 y0 __ y3 __
    pshufb m2, m5 ; y0 y1 y2 y3 y4 y5 __ __
    movu   [r1+2*r4], m2

    shufps m1, m0, 0xd8 ; u0 v0 v1 u2 u1 __ v2 __
    pshufb m1, m6 ; u0 u1 u2 __ v0 v1 v2 __
    movq   [r2+r4], m1
    movhps [r3+r4], m1

    add r0, mmsize
    add r4, 6
    jl  .loop

    REP_RET
%endmacro

INIT_XMM ssse3
v210_planar_unpack unaligned

%if HAVE_AVX_EXTERNAL
INIT_XMM avx
v210_planar_unpack unaligned
%endif

INIT_XMM ssse3
v210_planar_unpack aligned

%if HAVE_AVX_EXTERNAL
INIT_XMM avx
v210_planar_unpack aligned
%endif



%macro v210_planar_unpack_12 1

; v210_planar_unpack(const uint32_t *src, uint16_t *y, uint16_t *u, uint16_t *v, int width)
cglobal v210_planar_unpack_%1, 5, 5, 14
    movsxdifnidn r4, r4d
    lea    r1, [r1+2*r4]
    add    r2, r4
    add    r3, r4
    neg    r4

    mova   ym5, [v210_mult]
    mova   ym6, [v210_mask]
    mova   ym7, [v210_luma_shuf1]
    mova   ym8, [v210_luma_shuf2]
    mova   ym9, [v210_luma_permute]
    mova   ym10, [v210_chroma_shuf1]
    mova   ym11, [v210_chroma_shuf2]
    mova   ym12, [v210_chroma_permute]
    mova   ym13, [v210_chroma_shuf3]

.loop:
%ifidn %1, unaligned
    movu   ym0, [r0]
%else
    mova   ym0, [r0]
%endif

	;
	; ymm0 = yB v5 yA  u5 y9 v4  y8 u4 y7  v3 y6 u3 y5 v2 y4  u2 y3 v1  y2 u1 y1  v0 y0 u0
	;

    vpmullw ym1, ym0, ym5
    vpsrlw  ym1, ym1, 6			; yB yA u5 v4 y8 y7 v3 u3 y5 y4 u2 v1 y2 y1 v0 u0

    vpsrld  ym0, ym0, 10		; __ v5 __ y9 __ u4 __ y6 __ v2 __ y3 __ u1 __ y0
    vpand   ym0, ym0, ym6		; 00 v5 00 y9 00 u4 00 y6 00 v2 00 y3 00 u1 00 y0	; could shift left by 12, then right 22

	vpshufb ym3, ym0, ym7		; 00 00 00 00 y9 00 00 y6 00 00 00 00 y3 00 00 y0 
	vpshufb ym4, ym1, ym8		; 00 00 yB yA 00 y8 y7 00 00 00 y5 y4 00 y2 y1 00

	vpor    ym3, ym3, ym4		; 00 00 yB yA y9 y8 y7 y6 00 00 y5 y4 y3 y2 y1 y0
	vpermd  ym3, ym9, ym3		; 00 00 00 00 yB yA y9 y8 y7 y6 y5 y4 y3 y2 y1 y0

    movu    [r1+2*r4], ym3

;   movq    [r1+2*r4], xm3
;   vextracti128 xm4, ym3, 1
;   vpextrq [r1+2*r4+8], xm3, 1
;   movq [r1+2*r4+16], xm4

	vpshufb ym1, ym1, ym10		; 00 00 v4 v3 00 u5 00 u3 00 00 v1 v0 00 u2 00 u0
	vpshufb ym0, ym0, ym11		; 00 v5 00 00 00 00 u4 00 00 v2 00 00 00 00 u1 00
	vpor    ym0, ym0, ym1		; 00 v5 v4 v3 00 u5 u4 u3 00 v2 v1 v0 00 u2 u1 u0

	vpermd  ym0, ym12, ym0		; 00 v5 v4 v3 00 v2 v1 v0 00 u5 u4 u3 00 u2 u1 u0
	vpshufb ym0, ym0, ym13		; 00 00 v5 v4 v3 v2 v1 v0 00 00 u5 u4 u3 u2 u1 u0

    movu   [r2+r4], xm0
	vextracti128 [r3+r4], ym0, 1

    add r0, mmsize				; mmsize would be 32 for AVX2
    add r4, 12
    jl  .loop

    REP_RET
%endmacro


%if HAVE_AVX2_EXTERNAL
INIT_YMM avx2
v210_planar_unpack_12 aligned
%endif

%if HAVE_AVX2_EXTERNAL
INIT_YMM avx2
v210_planar_unpack_12 unaligned
%endif
