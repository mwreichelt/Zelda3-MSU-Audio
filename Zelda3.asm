MSU_STATUS	=	$2000
MSU_READ	=	$2001
MSU_ID		=	$2002
MSU_SEEK	=	$2000
MSU_TRACK	=	$2004
MSU_VOLUME	=	$2006
MSU_CONTROL	=	$2007
SCRATCH_MSU_VOL = $00C2
SCRATCH_MSU_DEC = $00C3

lorom

ORG $04EC1C
CheckForMSU: 		;Is the MSU-1 chip present? If not, then go to PullAAndPlay()
PHA					;Push A onto the stack
LDA MSU_ID			;Load the MSU-ID's address
CMP #$53			; 'S'
BNE PullAAndPlay	;MSU-1 not detected.

MSUFound: 			;We have an MSU-1 chip detected, so let's use it.
PLA					;Pull A off the stack
SEP #$30			;Set registers to 8-bit
STZ SCRATCH_MSU_DEC ;stop any fade out that we might be doing
STA $0130			;Store our BGM command
CMP #$F1			;Is the command to fade out?
BEQ PlayNonMSUTrack	;If so, call FadeOut()
CMP #$F2			;Is it to set to half volume?
BEQ HalfVol			;If so, call HalfVol()
CMP #$F3			;Is it to set to full volume?
BEQ FullVol			;If so, call FullVol()
CMP #$08 			;Is it the mirror warp sound?
BEQ PlayNonMSUTrack	;Don't play the mirror warp sound over MSU because we're not going to have it.
STA MSU_TRACK		;If it is none of the above special commands, then tell the MSU-1 what track to look for.
PHA					;Push A
STZ $2005			;Clear $2005 so that the MSU-1 will load the new track
LDA #$FF			;Load max volume into A
STA MSU_VOLUME		;Set volume to max
loop:
BIT MSU_STATUS		;Wait for the MSU-1 to finish seeking
BVS loop			;BVS loop (?)
LDA #$03			;
STA MSU_CONTROL		; Set audio state to play, with repeat.
LDA #$F1			;
STA $2140			;If the audio track is not missing, then
STA $0133			;we need to mute the game audio
; We need to status check here. If the track is no good, then we need to branch to PlayNonMSUTrack
LDA MSU_STATUS		;Load A into MSU_Status
AND #$08			;AND the error bit 
BNE PullAAndPlay	;If the error bit is set, the audio track is missing
PLA					;Pull A off the stack
RTL					;Return to where we were in code

PullAAndPlay:
PLA					;Pull A off the stack
BRA PlayNonMSUTrack ;Play the non-MSU track

PlayNonMSUTrack:
STA $2140			;Load the bgm command normally into $2140
STA $0133			;Also set it here
PHA					;Push A onto the stack
LDA #$00			;
STA MSU_CONTROL		;Make the MSU-1 stop playing audio
PLA					;Pull A off the stack
RTL					;Return

FadeOut: 
;lda MSU_VOLUME		;This doesn't work and causes problems. So I'm just going to cut the music out entirely when I get the fade out command until I can fix it.
;sbc #$0F
;sta MSU_VOLUME
;sta SCRATCH_MSU_VOL
;lda #$0F
;sta SCRATCH_MSU_DEC
LDA #$00			;Load the lowest volume setting
STA MSU_VOLUME		;Set the volume of the MSU-1
RTL					;Return

HalfVol:
STA $2140			;
STA $0133			;Send the fade out command to the SPU
LDA #$7F			;Load the half volume setting
STA MSU_VOLUME		;Set the volume of the MSU-1
STA SCRATCH_MSU_VOL	;Store this value to the Scrach RAM for the MSU volume
RTL	;Go play the non-MSU-1 track

FullVol:
STA $2140			;
STA $0133			;Send the fade out command to the SPU
LDA #$FF			;Load the full volume setting
STA MSU_VOLUME		;Set the volume of the MSU-1
STA SCRATCH_MSU_VOL	;Store this value tot he scractch RAM for the MSU volume
RTL	;Go play the non-MSU-1 track

;Single hijack point for playing music
ORG $0080F3
JSL CheckForMSU
NOP
NOP

ORG $0080FD ;Overwrites the game's efforts to write a track number itself.
NOP
NOP
NOP
