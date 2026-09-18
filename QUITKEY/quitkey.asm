; ============================================================================
; QUITKEY.COM  --  Hotkey force-quit TSR for DOS programs with no exit option
; Version: 1.0
; ============================================================================
;
; What it does:
;   Installs as a small TSR (terminate-and-stay-resident) program. Once
;   installed, pressing Ctrl+Alt+Q or F12 at any time terminates whatever
;   program is currently running in the foreground and returns control to DOS
;   (COMMAND.COM), exactly as if that program had exited normally. This is
;   meant for old CGA games and other programs that have no built-in "quit"
;   key, so you no longer have to reboot the machine to get back to DOS.
;   F12 exists as a backup because some games use Alt themselves (e.g. for an
;   in-game menu), which would otherwise swallow the Ctrl+Alt+Q combo.
;
; How it works:
;   - Hooks INT 9 (keyboard hardware interrupt) to watch raw scan codes for
;     Ctrl+Alt+Q and F12, and set a pending-quit flag. The original INT 9
;     handler is always chained afterwards, so normal keyboard handling is
;     unaffected.
;   - Hooks INT 16h (BIOS keyboard services), which is how almost all DOS-era
;     games read the keyboard. When the pending-quit flag is set, and it is
;     currently safe to call DOS (checked via the InDOS and critical-error
;     flags obtained through INT 21h/34h), it issues INT 21h AH=4Ch to
;     terminate the currently running program and return to its parent
;     (normally COMMAND.COM). If DOS is not safe to call at that moment, the
;     flag is dropped and the key press is simply ignored; press it again.
;   - Hooks INT 2Fh (multiplex interrupt) purely so a second copy of this
;     program can detect that QUITKEY is already resident and refuse to load
;     twice.
;   - Before terminating a program, cleans up the common ways a killed DOS
;     program leaves the machine in a bad state: it silences the PC speaker,
;     resets the system timer (INT 8) back to its normal 18.2 Hz rate,
;     restores the INT 8/1Ch vectors and video mode that were active before
;     QUITKEY was installed, and re-installs its own INT 9/16h hooks in case
;     the terminated program had inserted its own handlers in front of them.
;     This is needed because INT 21h AH=4Ch does NOT restore vectors a
;     program changed (only INT 22h/23h/24h are restored automatically), so
;     games that hook the timer for music or the keyboard for custom input
;     would otherwise leave dangling pointers into freed memory.
;
; Usage:
;   QUITKEY          -> installs the TSR (prints a message; does nothing if
;                        already installed)
;   QUITKEY /?       -> shows help and exits without installing
;
; Limitations:
;   - Covers programs that read the keyboard through INT 16h (the standard
;     BIOS keyboard service used by the vast majority of DOS games). A
;     program that reads the raw keyboard buffer or port 60h itself without
;     ever calling INT 16h will not be interrupted by this tool.
;   - As a rule of thumb: QuitKey tends to work with slower-paced, menu- or
;     parser-driven games and simply-coded arcade clones. It tends NOT to
;     work with fast real-time action games (platformers, shooters, flight
;     or space sims), especially ports of arcade/8-bit-home-computer
;     originals, because those often read the keyboard hardware directly for
;     speed instead of going through BIOS. There is no way to know for
;     certain without trying it on a given game.
;   - Stays resident until the next reboot; there is no uninstall command
;     (this matches how these games are normally run: one TSR loaded once at
;     boot from AUTOEXEC.BAT).
;   - Targets 386+ machines running plain real-mode DOS; it does not attempt
;     to cooperate with EMM386/QEMM UMBs specially (it loads into conventional
;     memory), and it is not aware of Windows/DOS-extended games.
;
; Credit:
;   Written using vibe coding - By Retro Erik
;
; Compiling:
;   nasm -f bin quitkey.asm -o QUITKEY.COM
; ============================================================================

                org     100h

                jmp     install_entry

; ----------------------------------------------------------------------------
; RESIDENT DATA AND CODE
; Everything from here down to 'resident_end' must remain in memory for as
; long as QUITKEY is installed, because the interrupt handlers below use it.
; ----------------------------------------------------------------------------
MPLEX_ID        equ     0F3h            ; INT 2Fh AH= id used for our install check
SIG_INSTALLED   equ     0FFh            ; AL value our INT 2Fh handler answers with

ctrl_down       db      0               ; nonzero while Left/Right Ctrl is held
alt_down        db      0               ; nonzero while Left/Right Alt is held
hotkey_flag     db      0               ; set by INT 9 handler, consumed by INT 16h handler

old_int09       dd      0               ; previous INT 9 vector (chained to)
old_int16       dd      0               ; previous INT 16h vector (chained to)
old_int2f       dd      0               ; previous INT 2Fh vector (chained to)
old_int08       dd      0               ; INT 8 vector as it was before install (restored on quit)
old_int1c       dd      0               ; INT 1Ch vector as it was before install (restored on quit)

indos_ptr       dd      0               ; far pointer to DOS' InDOS flag (INT 21h/34h)
                                        ; the byte immediately before it is the
                                        ; critical-error flag on DOS 3.0+

resident_seg    dw      0               ; our own resident segment (informational)
orig_video_mode db      0               ; video mode active before install (INT 10h/0Fh)

; ----------------------------------------------------------------------------
; INT 9 handler - keyboard hardware interrupt (IRQ1)
; Only tracks Ctrl/Alt state and the Q key, then always chains to the
; original handler so normal keyboard input keeps working.
; ----------------------------------------------------------------------------
int09_handler:
                push    ax
                in      al, 60h                 ; read the raw scan code
                cmp     al, 1Dh                 ; Ctrl make (left or right, via E0 prefix)
                jne     .chk_ctrl_up
                mov     byte [cs:ctrl_down], 1
                jmp     .done
.chk_ctrl_up:
                cmp     al, 9Dh                 ; Ctrl break
                jne     .chk_alt_dn
                mov     byte [cs:ctrl_down], 0
                jmp     .done
.chk_alt_dn:
                cmp     al, 38h                 ; Alt make (left or right)
                jne     .chk_alt_up
                mov     byte [cs:alt_down], 1
                jmp     .done
.chk_alt_up:
                cmp     al, 0B8h                ; Alt break
                jne     .chk_q
                mov     byte [cs:alt_down], 0
                jmp     .done
.chk_q:
                cmp     al, 10h                 ; 'Q' make code
                jne     .chk_f12
                cmp     byte [cs:ctrl_down], 0
                je      .done
                cmp     byte [cs:alt_down], 0
                je      .done
                mov     byte [cs:hotkey_flag], 1
                jmp     .done
.chk_f12:
                cmp     al, 58h                 ; F12 make code - backup hotkey, no modifiers
                jne     .done                   ; (didn't exist on games-era 84-key keyboards)
                mov     byte [cs:hotkey_flag], 1
.done:
                pop     ax
                jmp     far [cs:old_int09]      ; always chain; never IRETs from here directly

; ----------------------------------------------------------------------------
; INT 16h handler - BIOS keyboard services (AH=00h/01h/10h/11h etc.)
; This is where the actual "quit" happens, because it runs in the calling
; program's own foreground context (not inside a hardware ISR), which makes
; it safe to call DOS from here once the InDOS/critical-error check passes.
; ----------------------------------------------------------------------------
int16_handler:
                cmp     byte [cs:hotkey_flag], 0
                je      .chain
                push    ax
                push    bx
                push    dx
                push    ds
                push    es
                mov     byte [cs:hotkey_flag], 0        ; consume it; only try once per press
                les     bx, [cs:indos_ptr]
                cmp     byte [es:bx], 0                  ; InDOS busy?
                jne     .not_safe
                dec     bx
                cmp     byte [es:bx], 0                  ; critical error active?
                jne     .not_safe

                ; About to kill the current program - undo anything it may have
                ; left behind before DOS reuses its memory.

                in      al, 61h                          ; silence a PC-speaker tone left playing
                and     al, 0FCh
                out     61h, al

                mov     al, 36h                          ; reset PIT channel 0 to 18.2 Hz
                out     43h, al
                xor     al, al
                out     40h, al
                out     40h, al

                mov     dx, [cs:old_int08]               ; undo an INT 8 music/timing hook
                mov     ax, [cs:old_int08+2]
                mov     ds, ax
                mov     ax, 2508h
                int     21h

                mov     dx, [cs:old_int1c]               ; undo an INT 1Ch music/timing hook
                mov     ax, [cs:old_int1c+2]
                mov     ds, ax
                mov     ax, 251Ch
                int     21h

                push    cs                               ; re-assert our own hooks in case the
                pop     ds                                ; program inserted itself in front of them
                mov     dx, int09_handler
                mov     ax, 2509h
                int     21h
                mov     dx, int16_handler
                mov     ax, 2516h
                int     21h

                mov     al, [cs:orig_video_mode]         ; leave 40-column/graphics modes behind
                mov     ah, 0
                int     10h

                mov     ax, 4C00h
                int     21h                              ; terminate current process -> back to DOS
                                                          ; (never returns)
.not_safe:
                pop     es
                pop     ds
                pop     dx
                pop     bx
                pop     ax
.chain:
                jmp     far [cs:old_int16]

; ----------------------------------------------------------------------------
; INT 2Fh handler - multiplex interrupt, used only for "are you installed?"
; ----------------------------------------------------------------------------
int2f_handler:
                cmp     ah, MPLEX_ID
                jne     .chain2f
                cmp     al, 0
                jne     .chain2f
                mov     al, SIG_INSTALLED
                mov     bx, [cs:resident_seg]
                iret
.chain2f:
                jmp     far [cs:old_int2f]

resident_end:

; ----------------------------------------------------------------------------
; MESSAGES (transient - not needed once resident)
; ----------------------------------------------------------------------------
install_msg     db      'QuitKey installed. Press Ctrl+Alt+Q or F12 to force-quit the ', 13, 10
                db      'current program and return to DOS.', 13, 10, '$'

installed_msg   db      'QuitKey is already installed.', 13, 10, '$'

help_msg        db      'QuitKey - force-quit a DOS program that has no exit option', 13, 10
                db      13, 10
                db      'Usage:', 13, 10
                db      '  QUITKEY      install the TSR (does nothing if already installed)', 13, 10
                db      '  QUITKEY /?   show this help and exit without installing', 13, 10
                db      13, 10
                db      'Once installed, press Ctrl+Alt+Q or F12 at any time to terminate', 13, 10
                db      'the currently running program and return to DOS, just as if that', 13, 10
                db      'program had exited normally. F12 is a backup in case a game uses', 13, 10
                db      'Alt itself (e.g. for a menu).', 13, 10
                db      13, 10
                db      'Works best with slower-paced, menu/parser-driven, or simply-coded', 13, 10
                db      'games. Less likely to work with fast real-time action games (e.g.', 13, 10
                db      'platformers, shooters, flight/space sims), especially ports of', 13, 10
                db      'arcade or 8-bit home-computer originals, since these often read', 13, 10
                db      'the keyboard hardware directly instead of through DOS/BIOS.', 13, 10
                db      13, 10
                db      'QuitKey stays resident until the next reboot.', 13, 10
                db      13, 10
                db      'Written using vibe coding - By Retro Erik', 13, 10, '$'

; ----------------------------------------------------------------------------
; TRANSIENT INSTALL CODE - runs once, then either exits or goes resident.
; ----------------------------------------------------------------------------
install_entry:
                ; ---- show help and exit if the command tail contains '?' ----
                mov     cl, [80h]
                xor     ch, ch
                mov     si, 81h
.scan_help:
                jcxz    .check_installed
                mov     al, [si]
                cmp     al, '?'
                je      .do_help
                inc     si
                dec     cx
                jmp     .scan_help

.do_help:
                mov     dx, help_msg
                mov     ah, 9
                int     21h
                mov     ax, 4C00h
                int     21h

                ; ---- refuse to load twice ----
.check_installed:
                mov     ax, MPLEX_ID << 8              ; AH=MPLEX_ID, AL=0
                int     2Fh
                cmp     al, SIG_INSTALLED
                je      .already

                ; ---- save the vectors we are about to replace ----
                mov     ax, 3509h
                int     21h
                mov     [old_int09], bx
                mov     [old_int09+2], es

                mov     ax, 3516h
                int     21h
                mov     [old_int16], bx
                mov     [old_int16+2], es

                mov     ax, 352Fh
                int     21h
                mov     [old_int2f], bx
                mov     [old_int2f+2], es

                mov     ax, 3508h
                int     21h
                mov     [old_int08], bx
                mov     [old_int08+2], es

                mov     ax, 351Ch
                int     21h
                mov     [old_int1c], bx
                mov     [old_int1c+2], es

                ; ---- remember where DOS keeps its InDOS flag ----
                mov     ah, 34h
                int     21h
                mov     [indos_ptr], bx
                mov     [indos_ptr+2], es

                mov     [resident_seg], cs

                ; ---- remember the video mode active before we take over ----
                mov     ah, 0Fh
                int     10h
                mov     [orig_video_mode], al

                ; ---- install our handlers (DS already = CS for a .COM file) ----
                mov     dx, int09_handler
                mov     ax, 2509h
                int     21h

                mov     dx, int16_handler
                mov     ax, 2516h
                int     21h

                mov     dx, int2f_handler
                mov     ax, 252Fh
                int     21h

                mov     dx, install_msg
                mov     ah, 9
                int     21h

                mov     ax, resident_end + 15           ; round up to a whole paragraph
                mov     cl, 4
                shr     ax, cl
                mov     dx, ax                          ; paragraphs to keep resident
                mov     ax, 3100h
                int     21h                             ; terminate and stay resident

.already:
                mov     dx, installed_msg
                mov     ah, 9
                int     21h
                mov     ax, 4C00h
                int     21h
