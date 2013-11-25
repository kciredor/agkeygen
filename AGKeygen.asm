    .386
    .model flat, stdcall
    option casemap :none

    include d:\masm32\include\windows.inc
    include d:\masm32\include\user32.inc
    include d:\masm32\include\kernel32.inc
    include d:\masm32\include\masm32.inc
    include d:\masm32\include\gdi32.inc
    include d:\masm32\include\shell32.inc

    includelib d:\masm32\lib\user32.lib
    includelib d:\masm32\lib\kernel32.lib
    includelib d:\masm32\lib\masm32.lib
    includelib d:\masm32\lib\gdi32.lib
    includelib d:\masm32\lib\shell32.lib

; #########################################################################

    szText MACRO Name, Text:VARARG
        LOCAL lbl

        jmp lbl
        Name db Text, 0
        lbl:
    ENDM

    WndProc           PROTO :DWORD,:DWORD,:DWORD,:DWORD
    CheckBlacklist    PROTO :DWORD
    CheckHyperLink    PROTO :DWORD,:DWORD,:DWORD,:DWORD

; #########################################################################

    .data
    hInstance         dd 0
    rndFormat         db "%X", 0
    OriginalSerial    db 11 dup (?)
    DecOriginalSerial dd ?
    First5Chars       db 5 dup (0)
    finalFormat       db "%X%X", 0
    _pnt              PAINTSTRUCT <?>
    rect              RECT <>
    pt                POINT <>
    hf                LOGFONT <>
    LinkText          db 255 dup (?)
    LinkHandle        dd 0
    LinkCursor        dd 0
    LinkDC            dd 0
    LinkFont          dd 0
    NormalCursor      dd 0
    hActiveLink       dd 0
    OldLinkFont       dd 0


    Blacklist         db "02D5F.03426.2B2F1.12345.11D5F.1125F.01426.03DCA.1264C.0364C.E4C96.1D15F.05144.0738B.", \
                         "145E1.08BD0.05EDE.34386.44386.54386.61386.14144.0A67C.02A22.FFFFF.13F51.14144.055E1", 0

    .data?
    hIcon             dd ?
    hBitmap           dd ?
    PS                PAINTSTRUCT <>

; #########################################################################

    .code
start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke LoadIcon, eax, 500
    mov hIcon, eax

    invoke DialogBoxParam, hInstance, 100, 0, ADDR WndProc, 0
    invoke ExitProcess, eax

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    .if uMsg == WM_INITDIALOG
        invoke SendMessage, hWin, WM_SETICON, ICON_BIG, hIcon
        invoke LoadBitmap, hInstance, 2001
        mov hBitmap, eax
        invoke SendDlgItemMessage, hWin, 600, STM_SETIMAGE, IMAGE_BITMAP, eax
        invoke SetClassLong,hWin, GCL_HCURSOR, NULL
        invoke LoadCursor, NULL, IDC_ARROW
        mov NormalCursor, eax
        invoke SetCursor, NormalCursor
        invoke LoadCursor, hInstance, 700
        mov LinkCursor, eax
        invoke SendMessage, hWin, WM_GETFONT, 0, 0
        mov OldLinkFont, eax
        invoke GetObject, OldLinkFont, SIZEOF hf, ADDR hf
        mov hf.lfUnderline, TRUE
        invoke CreateFontIndirect, ADDR hf
        mov LinkFont, eax
        jmp _calculate

    .elseif uMsg == WM_PAINT
        invoke BeginPaint, hWin, ADDR PS
        invoke FrameWindow, hWin, 0, 1, 0
        invoke FrameWindow, hWin, 2, 1, 1
        invoke EndPaint, hWin, ADDR PS

    .elseif uMsg == WM_MOUSEMOVE
        invoke CheckHyperLink, hWin, uMsg, lParam, 107 ; 107=homepage link
        invoke CheckHyperLink, hWin, uMsg, lParam, 108 ; 108=email

    .elseif uMsg == WM_LBUTTONDOWN
        invoke CheckHyperLink, hWin, uMsg, lParam, 107 ; 107=homepage link | eax=TRUE if clicked

        .IF eax == TRUE
            szText Op, "open"
            szText weblink, "http://rotaderP.cjb.net"
            invoke ShellExecute, hWin, OFFSET Op, OFFSET weblink, 0, 0, SW_SHOWMAXIMIZED
            ret
        .ENDIF

        invoke CheckHyperLink, hWin, uMsg, lParam, 108 ; 108=email | eax=TRUE if clicked

        .IF eax == TRUE
            szText  emaillink, "mailto:Predator@PhrozenCrew.org?subject=Audiograbber_Keygenerator_Feedback"
            invoke  ShellExecute, hWin, OFFSET Op, OFFSET emaillink, 0, 0, SW_SHOWNORMAL
            ret
        .ENDIF

    .elseif uMsg == WM_CLOSE
        invoke EndDialog, hWin, 0

    .elseif uMsg == WM_COMMAND
        .if wParam == 104

            ; GENERATE RANDOM 10 CHARS
            _calculate:
            invoke GetTickCount
            imul eax, eax
            shl eax, 8
            mov DecOriginalSerial, eax
            invoke wsprintf, OFFSET OriginalSerial, OFFSET rndFormat, DecOriginalSerial
            mov eax, OFFSET OriginalSerial
            add eax, 5
            mov byte ptr [eax], 0
            invoke CheckBlacklist, OFFSET OriginalSerial
            test eax, eax
            jnz _calculate

            ; PREPARE CHARS 1-5 (STR2INT)
            mov edx, OFFSET First5Chars     ; result : 65,87,09
            mov eax, DecOriginalSerial      ; input  : 98765432(10)
            xor ecx, ecx
            shr eax, 0Ch
            mov byte ptr [edx+3], 0
            mov byte ptr [edx], al
            shr eax, 8
            inc edx
            mov byte ptr [edx], al
            shr eax, 8
            inc edx
            mov byte ptr [edx], al

            ; ENCRYPT FIRST5CHARS
            push esi
            mov eax, OFFSET First5Chars
            mov esi, 0Ah

            _EncryptLoop:
            xor dword ptr [eax], 0A5A5h
            mov edx, dword ptr [eax]
            mov ecx, edx
            shl edx, 3
            sub edx, ecx
            lea edx, [edx*4+ecx]
            shl edx, 4
            sub edx, ecx
            mov dword ptr [eax], edx
            xor dword ptr [eax], 0B80000h
            inc esi
            xor dword ptr [eax], 0AA0000h
            cmp esi, 14h
            mov edx, dword ptr [eax]
            lea edx, [edx*4+edx]
            mov dword ptr [eax], edx
            jl _EncryptLoop

            pop esi
            and dword ptr [eax], 0FFFFFh

            ; CREATE (COMBINE) ENCRYPTED SERIAL
            ; OFFSET First5Chars = 9F,31,00 -> xxxxx0319F | xxxxx = random
            invoke GetTickCount
            mul eax
            shr eax, 7
            and eax, 0FFFh
            mov ecx, eax
            mov edx, OFFSET First5Chars
            movzx eax, byte ptr [edx]
            mov edx, OFFSET OriginalSerial
            add edx, 5
            invoke wsprintf, edx, OFFSET finalFormat, ecx, eax
            invoke lstrlen, OFFSET OriginalSerial
            mov ecx, OFFSET OriginalSerial
            movzx ecx, byte ptr [ecx]

            .IF ecx == 31h
                jmp _calculate
            .ENDIF

            .IF eax == 10
                invoke SetDlgItemText, hWin, 101, OFFSET OriginalSerial
                invoke GetDlgItem, hWin,101
                invoke SetFocus, eax
                invoke SendDlgItemMessage, hWin, 101, EM_SETSEL, 0, -1
            .ELSEIF
                jmp _calculate
            .ENDIF
        .ENDIF
    .ENDIF

    mov eax,0
    ret
WndProc endp

; #########################################################################

; [LINK]
CheckHyperLink proc hWin :DWORD, uMsg :DWORD, lParam :DWORD, LinkID :DWORD
    ; check mouse hover
    mov eax, lParam
    and eax, 0FFFFh
    mov pt.x, eax
    mov eax, lParam
    shr eax, 16
    mov pt.y, eax
    invoke ClientToScreen, hWin, ADDR pt
    invoke GetDlgItem, hWin, LinkID
    mov LinkHandle, eax
    invoke GetWindowRect, LinkHandle, OFFSET rect
    invoke PtInRect, OFFSET rect, pt.x, pt.y
    test eax, eax
    jz _nolink

    ; check for mouseclick
    .IF uMsg == WM_LBUTTONDOWN
        mov eax, TRUE
        ret
    .ENDIF

    ; make link
    mov eax, hActiveLink

    .IF eax != LinkHandle
        mov eax, LinkHandle
        mov hActiveLink, eax
        invoke GetDC, LinkHandle
        mov LinkDC, eax
        invoke GetDlgItemText, hWin, LinkID, OFFSET LinkText, 255
        invoke GetSysColor, COLOR_3DFACE
        invoke SetBkColor, LinkDC, eax
        invoke SetTextColor, LinkDC, 0FF4422h
        invoke SelectObject, LinkDC, LinkFont
        invoke lstrlen, OFFSET LinkText
        invoke TextOut, LinkDC, 0, 0, OFFSET LinkText, eax
        invoke SetCursor, LinkCursor
        invoke ReleaseDC, LinkHandle, LinkDC
        mov eax, FALSE ; no button down
        ret
    .ELSEIF
        ret
    .ENDIF

    ; undo link
    _nolink:
    mov eax, hActiveLink

    .IF eax == LinkHandle
        invoke GetDC,LinkHandle
        mov LinkDC, eax
        invoke GetDlgItemText, hWin, LinkID, OFFSET LinkText, 255
        invoke GetSysColor, COLOR_3DFACE
        invoke SetBkColor, LinkDC, eax
        invoke SetTextColor, LinkDC, Black
        invoke SelectObject, LinkDC, OldLinkFont
        invoke lstrlen, OFFSET LinkText
        invoke TextOut, LinkDC, 0, 0, OFFSET LinkText, eax
        invoke ReleaseDC, LinkHandle, LinkDC
        mov hActiveLink, NULL
        invoke SetCursor,NormalCursor
        mov eax, FALSE ; no button down
    .ENDIF

    ret
CheckHyperLink endp

; #########################################################################

CheckBlacklist proc Lead :DWORD
    mov ecx, SIZEOF Blacklist
    mov esi, Lead
    movzx eax, byte ptr [esi]
    mov edi, OFFSET Blacklist

    _loopseek:
    repnz scasb
    test ecx, ecx
    jz _return0

    push ecx
    push edi
    push esi
    dec edi
    mov ecx, 5
    repz cmpsb
    test ecx, ecx
    jz _return1

    pop esi
    pop edi
    pop ecx
    jmp _loopseek

    _return1:
    mov eax, 1 ; blacklisted
    ret

    _return0:
    xor eax, eax
    ret
CheckBlacklist endp

; #########################################################################

end start
