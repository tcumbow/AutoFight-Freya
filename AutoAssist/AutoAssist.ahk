CoordMode, Pixel, Screen
global LastPixelColor := "dummy"
global LastActionTime := 0

StartHeavyAttack()
{
	if (!GetKeyState("6"))
		Send {6 down}
}
EndHeavyAttack()
{
	if (GetKeyState("6"))
		Send {6 up}
}
StartBlock()
{
	if (!GetKeyState("9"))
		Send {9 down}
}
EndBlock()
{
	if (GetKeyState("9"))
		Send {9 up}
}

Loop{
    WinWaitActive Elder Scrolls Online
    PixelGetColor, PixelColor, 0, 0, RGB
    if (not (GetKeyState("F10"))) ; I have F10 bound to several key buttons on my controller. It acts as a kill switch so that, for example, while I'm holding down the Start button to resurect someone, AHK doesn't interfere
    {
        Switch PixelColor
        {
            Case "0x000000": ;DoNothing
                EndHeavyAttack()
            Case "0x000001": ;Ability 1
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 1
                    LastActionTime := A_TickCount
                }
            Case "0x000002": ;Ability 2
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 2
                    LastActionTime := A_TickCount
                }
            Case "0x000003": ;Ability 3
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 3
                    LastActionTime := A_TickCount
                }
            Case "0x000004": ;Ability 4
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 4
                    LastActionTime := A_TickCount
                }
            Case "0x000005": ;Ability 5
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 5
                    LastActionTime := A_TickCount
                }
            Case "0x000006": ;DoHeavyAttack
                StartHeavyAttack()
            Case "0x000007": ;DoRollDodge
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 7
                    LastActionTime := A_TickCount
                }
            Case "0x000008": ;DoBreakFreeInterrupt
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 8
                    LastActionTime := A_TickCount
                }
            Case "0x000009": ;DoBlock
                EndHeavyAttack()
                Send {9 down}
                Sleep 1500
                Send {9 up}
            Case "0x00000a": ;ReelInFish
                EndHeavyAttack()
                Send e
                Sleep 2000
                Send e
                Sleep 2000
            Case "0x00000b": ;LightAttack
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 6
                    LastActionTime := A_TickCount
                }
            Case "0x00000c": ;DoInteract
                EndHeavyAttack()
                Send e
            Case "0x00000d": ;DoSprint
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 2000) <= A_TickCount )) {
                    Send {Shift}
                    LastActionTime := A_TickCount
                }
            Case "0x00000e": ;DoMountSprint
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 2000) <= A_TickCount )) {
                    Send {Shift}
                    LastActionTime := A_TickCount
                }
            Case "0x00000f": ;DoCrouch
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 2000) <= A_TickCount )) {
                    Send {Ctrl}
                    LastActionTime := A_TickCount
                }
            Case "0x000010": ;DoFrontBar
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send 0
                    LastActionTime := A_TickCount
                }
            Case "0x000011": ;DoBackBar
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send -
                    LastActionTime := A_TickCount
                }
            Case "0x000012": ;DoStartBlock
                EndHeavyAttack()
                if (not GetKeyState("9"))
                    Send {9 down}
            Case "0x000013": ;DoStopBlock
                if (GetKeyState("9"))
                    Send {9 up}
            Case "0x000014": ;DoUltimate
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send r
                    LastActionTime := A_TickCount
                }
            Case "0x000015": ;DoQuickslot
                EndHeavyAttack()
                if (LastPixelColor != PixelColor Or ((LastActionTime + 200) <= A_TickCount )) {
                    Send q
                    LastActionTime := A_TickCount
                }
			Case "0x000016": ;DoNeutral - like DoNothing, but doesn't end blocks or heavy attacks
                Sleep 1
            Default: ;Same as DoNothing
                EndHeavyAttack()
        }
        LastPixelColor := PixelColor
    }   
}


f9::
Send /reloadui{enter}
Reload
return
