#SingleInstance, Force
#NoEnv
;#Warn All
SetWorkingDir %A_ScriptDir%
#Include Gdip_All.ahk
#Include Jxon.ahk
GroupAdd, PoEexe, ahk_exe PathOfExile.exe
GroupAdd, PoEexe, ahk_exe PathOfExileSteam.exe
GroupAdd, PoEexe, ahk_exe PathOfExile_x64.exe
GroupAdd, PoEexe, ahk_exe PathOfExile_x64Steam.exe

global G
global pPen
global hwnd1
global hdc
global StashX
global StashY
global StashWidth
global StashHeight
global quad
global currentId
global maxId
global one_hand_weaponMax
global two_hand_weaponMax
global weaponMax
global helmetMax
global glovesMax
global bootsMax
global bodyMax
global beltMax
global ringMax
global amuletMax
global chaos_recipe
global accountName
global poesessid
global league

; *****************************************************
; ***************** INITIALIZATION ********************
; *****************************************************

; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
getStashPosition(StashX, StashY, StashWidth, StashHeight)
Width := StashWidth + stashX
Height := StashHeight + stashY
currentId := 1
maxId := 0
quad := 0

IniRead, accountName, config.ini, DEFAULT, accountName
IniRead, poesessid, config.ini, DEFAULT, poesessid
IniRead, league, config.ini, DEFAULT, league

if (accountName == "ERROR" or poesessid == "ERROR" or league == "ERROR") {
	MsgBox, Your config.ini seems to be empty.
	ExitApp
}

If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit



; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs

; Show the window
Gui, 1: Show, NA

; Get a handle to this window we have created in order to update it later
hwnd1 := WinExist()

; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
hbm := CreateDIBSection(Width, Height)

; Get a device context compatible with the screen
hdc := CreateCompatibleDC()

; Select the bitmap into the device context
obm := SelectObject(hdc, hbm)

; Get a pointer to the graphics of the bitmap, for use with drawing functions
G := Gdip_GraphicsFromHDC(hdc)

; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
Gdip_SetSmoothingMode(G, 4)

; Create a slightly transparent (66) blue pen (ARGB = Transparency, red, green, blue) to draw a rectangle
; This pen is wider than the last one, with a thickness of 10
pPen := Gdip_CreatePen(0xff0000ff, 2)

; Draw a rectangle onto the graphics of the bitmap using the pen just created
; Draws the rectangle from coordinates (250,80) a rectangle of 300x200 and outline width of 10 (specified when creating the pen)
; Gdip_DrawRectangle(G, pPen, StashX, StashY, StashWidth, StashHeight)

; ; Update the specified window we have created (hwnd1) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
; ; So this will position our gui at (0,0) with the Width and Height specified earlier
UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)

Return

; *****************************************************
; ******************* FUNCTIONS ***********************
; *****************************************************

getStashPosition(ByRef stashX, ByRef stashY, ByRef stashWidth, ByRef stashHeight) {
    ;WinGetPos, poeX, poeY, poeWidth, poeHeight, Path of Exile
    stashX := 15
    stashY := 160
    stashWidth := 635
    stashHeight := 635
}

highlight(x, y, w, h) {
    size := (1 + quad) * 12
	Gdip_DrawRectangle(G, pPen, StashX + Round(x * StashWidth / size), StashY + Round(y * StashWidth / size), Round(w * StashWidth / size), Round(h * StashHeight / size))
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
}

highlightItem(item) {
	highlight(item.x, item.y, item.w, item.h)
}
highlightChaos(items) {	
    size := (1 + quad) * 12
	for index, item in items {
		Gdip_DrawRectangle(G, pPen, StashX + Round(item.x * StashWidth / size), StashY + Round(item.y * StashWidth / size), Round(item.w * StashWidth / size), Round(item.h * StashHeight / size))
	}
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
}

update(stashId) {
	RunWait, retrieve_data.exe -a %accountName% -p %poesessid% -l %league% -t %stashId%,,Hide,
	currentId := 1

	GoSub, parseJSON

	next()
}

next() {
	
	Gosub, clear
	if (currentId > maxId) {
		MsgBox, There are no chaos recipes left
		return
	}
	chaos_list := []

	if (currentId <= chaos_recipe.two_hand_weapon.MaxIndex()) {
		weapon := chaos_recipe.two_hand_weapon[currentId]
		chaos_list.push(weapon)
	} else {
		chaos_list.push(chaos_recipe.one_hand_weapon[2*currentId])
		chaos_list.push(chaos_recipe.one_hand_weapon[2*currentId + 1])
	}
	chaos_list.push(chaos_recipe.helmet[currentId])
	chaos_list.push(chaos_recipe.gloves[currentId])
	chaos_list.push(chaos_recipe.boots[currentId])
	chaos_list.push(chaos_recipe.body[currentId])
	chaos_list.push(chaos_recipe.belt[currentId])
	chaos_list.push(chaos_recipe.ring[2*currentId])
	chaos_list.push(chaos_recipe.ring[2*currentId + 1])
	chaos_list.push(chaos_recipe.amulet[currentId])

	regal := True
	for index, item in chaos_list {
		if (item.ilvl < 75) {
			regal := False
			break
		}
	}
	if (regal) {
		for index, item in chaos_list {
			i := 1
			while (currentId + i <= chaos_recipe[item.type].maxIndex()) {
				replacement := chaos_recipe[item.type][currentId + i]
				if (replacement.ilvl < 75) {
					chaos_recipe[item.type].remove(currentId + i)
					chaos_recipe[item.type].InsertAt(currentId, replacement)

					chaos_list.remove(index)
					chaos_list.InsertAt(index, replacement)

					regal := False
					break
				} else {
					i += 1
				}
			} 
			if (!regal) {
				break
			}
		}
	}
	if(regal) {
		MsgBox, There are only regal recipes left
		maxId = 0
		return
	}
highlightChaos(chaos_list)
	currentId += 1
}

; *****************************************************
; ********************* LABELS ************************
; *****************************************************

parseJSON:

	FileRead json, chaos_recipe.json
	chaos_recipe := Jxon_load(json)

	quad := chaos_recipe.quad

	one_hand_weaponMax := chaos_recipe.one_hand_weapon.MaxIndex() // 2
	two_hand_weaponMax := chaos_recipe.two_hand_weapon.MaxIndex()
	if (one_hand_weaponMax == "") {
		weaponMax := two_hand_weaponMax
	} else if (two_hand_weaponMax == "") {
		weaponMax := one_hand_weaponMax
	} else {
		weaponMax := one_hand_weaponMax + two_hand_weaponMax
	}
	helmetMax := chaos_recipe.helmet.MaxIndex()
	glovesMax := chaos_recipe.gloves.MaxIndex()
	bootsMax := chaos_recipe.boots.MaxIndex()
	bodyMax := chaos_recipe.body.MaxIndex()
	beltMax := chaos_recipe.belt.MaxIndex()
	ringMax := chaos_recipe.ring.MaxIndex() // 2
	amuletMax := chaos_recipe.amulet.MaxIndex()
    
	maxId := Min(weaponMax, helmetMax, glovesMax, bootsMax, bodyMax, beltMax, ringMax, amuletMax)
	return

clear:
	Gdip_GraphicsClear(G)
	Gdip_GraphicsClear(pPen)
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)

	return
Exit:

	; Delete the brush as it is no longer needed and wastes memory
	Gdip_DeletePen(pPen)

	; Select the object back into the hdc
	SelectObject(hdc, obm)

	; Now the bitmap may be deleted
	DeleteObject(hbm)

	; Also the device context related to the bitmap may be deleted
	DeleteDC(hdc)

	; The graphics may now be deleted
	Gdip_DeleteGraphics(G)

	; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)

	ExitApp
	Return


; *****************************************************
; ******************** HOTKEYS ************************
; *****************************************************

^!x::ExitApp
^!r::
Reload
return
^!c::
Gosub, clear
return

^j::
update(0)
return
^k::
update(1)
return
^l::
update(2)
return
^n::
next()
return
^m::
MsgBox %  one_hand_weaponMax " - " two_hand_weaponMax " - " weaponMax " - " helmetMax " - " glovesMax " - " bootsMax " - " bodyMax " - " beltMax " - " ringMax " - " amuletMax