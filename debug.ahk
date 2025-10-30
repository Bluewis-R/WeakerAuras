#SingleInstance Force
#NoEnv
; #Warn
SendMode Input
#Persistent
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 3
SetMouseDelay, -1
SetControlDelay, -1

#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
Process, Priority, , H
SetKeyDelay, -1, -1
SetDefaultMouseSpeed, 0
SetBatchLines,-1

SetKeyDelay, 0, 10, Play  ; Note that both 0 and -1 are the same in SendPlay mode.
SetMouseDelay, 10, Play

CoordMode, Mouse, Screen

#MaxThreads 255
#MaxThreadsPerHotkey 255

;================================================================
;                         Variables
;================================================================

;==========colours;==========
; colorBG := 11213a
global GUIcolorBG := "ffffff"
; whitecolour := 762e1c

global toggleAppliction := false
;old
; global listOfKeyboardKeys = "``1234567890-=qwertyuiop[]\asdfghjkl;'zxcvbnm,./"
global listOfKeyboardKeys := ["space", "`", "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "\", "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" ]


global mousex, mousey
MouseGetPos, mousex, mousey
;============================Data============================
global ListOfSkills := {}
global fieldsToSave := ["durationTextbox", "key", "checkbox", "xposbox", "yposbox"]
global fieldsToSaveCount := fieldsToSave.Count()
global guiElements := ["durationTextbox", "enableText", "keyText", "key", "checkbox", "xposText", "xposbox", "yposText", "yposbox"]
global guiElementsCount := guiElements.Count()

ListOfSkills[1] := { title : "Elemental Weakness", durationtextbox : "10.0",  key : "space", Checkbox : true, xposbox : "1000", yposbox : "900", imageSize : {x:64, y:64}, icon : "Elemental_Weakness_skill_icon.png", durationdescription : "durationdescription",  enable : false,  elementOffset : {x:0, y:0}, TimeAtLastHotkeyPress : 0, index : 0 } 
ListOfSkills[2] := { title : "Enduring", durationtextbox : "8.0",  key : "e", Checkbox : true, xposbox : "1100", yposbox : "900", imageSize : {x:64, y:64}, icon : "Enduring_Cry_skill_icon.png", durationdescription : "durationdescription",  enable : false,  elementOffset : {x:0, y:70}, TimeAtLastHotkeyPress : 0, index : 0 }
ListOfSkills[3] := { title : "Hatred", durationtextbox : "10.0",  key : "r", Checkbox : true, xposbox : "1200", yposbox : "900", imageSize : {x:64, y:64}, icon : "Hatred_skill_icon.png", durationdescription : "durationdescription",  enable : false,  elementOffset : {x:0, y:140}, TimeAtLastHotkeyPress : 0, index : 0 } 
IndexSkills()

global skillTemplatePosition := { iconPosition: {x:0, y:0, w:64, h:64}, title: {x:75, y:0, w:90, h:20}, timerText: {x:75, y:2, w:90, h:20}, durationTextbox: {x:110, y:2, w:90, h:20}, keyText: {x:74, y:26, w:90, h:20}, key: {x:110, y:24, w:40, h:20}, enableText: {x:74, y:45, w:50, h:20}, checkbox: {x:160, y:43, w:20, h:20}, xposText: {x:204, y:20, w:40, h:20}, xposbox: {x:234, y:20, w:40, h:20}, yposText: {x:204, y:45, w:40, h:20}, yposbox: {x:234, y:45, w:40, h:20}, posButton: {x:284, y:20, w:60, h:20}, onScreenImage: {x:0, y:0}}


InitiliseUTimes()
CreateGUIElements()


LoadSettings()
UpdateUIFromJson()

RefreshOSI()
setUpHotkeys()


;================================================================
;                           Functions			 
;================================================================

; Goes through the elements and draws save button
CreateGUIElements(){
	global
	Gui, 2:+ToolWindow -Caption +AlwaysOnTop +E0x20 +LastFound
	Gui, 2:Color, %GUIcolorBG%
	; Gui, 2:-Caption +AlwaysOnTop +Disabled +E0x20 +LastFound
	Gui, 2:Show, w1920 h1080 NA ;, onScreenIcons
	WinSet, TransColor, %GUIcolorBG% 225
	
	; offset := {x:0, y:0}   
	For theKey, theSkill in ListOfSkills{
		; skill.elementOffset += offset
		DrawSkillElement(A_Index, theSkill)	
	}
	; Save button
	pos := "x234 y"(ListOfSkills.Count()*70)
	Gui, Add, Button, %pos% vsaveButton gsaveProgram , Save
	Gui, Show,, Window Name
}

DrawImage(_name, _imageLocation, _position, _Display := False){
	tempwidthx := 64
	tempwidthy := 64
	posi := "x" _position.x " y" _position.y
	size := "w" tempwidthx " h" tempwidthy

	result_img_location := ""  
	result_img_location = %A_WorkingDir%\resources\%_imageLocation%

	if(_Display == False){
		id := "picture" _name
		GUIImage("Add", posi, size, id, result_img_location)
	} else {
		id := "pictureOSI" _name
		id2 := %id%
		GUIImage("2:Add", posi, size, id, result_img_location)
		GuiControl, 2:Hide, %id%
	}
}

GUIImage(_subcommand, _pos, _size, _ID, _imageLocation){
	global
	Gui, %_subcommand%, Picture, %_pos% %_size% v%_ID%, % _imageLocation
}

;================================================================

DrawSkillElement(_index, _element){
	; everything in this function is kind of gross im sorry
	global
	local elementGroup := "_Element" _index
	; "deepclones" a template of the positions
	elementPositions := ObjFullyClone(SkillTemplatePosition)
	updatePositions(elementPositions, _element.elementOffset)

	DrawImage(elementGroup, _element.icon, elementPositions.iconPosition)

	local tempPos

	FontHandler("title")
	tempPos := positionAndSizeToString2(elementPositions.title)
	Gui, Add, Text, %tempPos% , 	;title
	FontHandler("def")
	tempPos := positionAndSizeToString2(elementPositions.timerText)
	Gui, Add, Text, %tempPos% , Timer	;timerText
	tempPos := positionAndSizeToString2(elementPositions.durationTextbox)
	Gui, Add, Edit, %tempPos% vdurationTextbox%elementGroup%,  ; durationTextbox
	tempPos := positionAndSizeToString2(elementPositions.enableText)
	Gui, Add, Text, %tempPos% , enabled ;enableText
	
	;some deluxe dogshit naming here, FIX
	tempPos := positionAndSizeToString2(elementPositions.keyText)
	Gui, Add, Text, %tempPos% , Key	;timerText6
	tempPos := positionAndSizeToString2(elementPositions.key)
	Gui, Add, Edit, %tempPos% vkey%elementGroup%,  ; durationTextbox


	; yposbox%elementGroup% := ""

	tempPos := positionAndSizeToString2(elementPositions.checkbox)
	Gui, Add, CheckBox, %tempPos% vcheckbox%elementGroup%  ;Checked ;checkbox
	tempPos := positionAndSizeToString2(elementPositions.xposText)
	Gui, Add, Text, %tempPos%  , xpos	;xposText
	tempPos := positionAndSizeToString2(elementPositions.xposbox)
	Gui, Add, Edit, %tempPos% 0 vxposbox%elementGroup% , ; xposbox		gUpdated, gUpdateOnScreenIMG
	tempPos := positionAndSizeToString2(elementPositions.yposText)
	Gui, Add, Text, %tempPos% , 	;yposText
	tempPos := positionAndSizeToString2(elementPositions.yposbox)
	Gui, Add, Edit, %tempPos% 0 vyposbox%elementGroup% , ;yposbox 		gUpdated, gUpdateOnScreenIMG

	; onscreen image
	defaultPos := {x: 0, y: _element.elementOffset.y}
	DrawImage(elementGroup, _element.icon, defaultPos, true)
}


;================================================================
; Writes the value of the JSON to the Settings.ini file
SaveSettings(){
	For key, skill in ListOfSkills{
		elementSuffix := "_Element" A_Index
		loop, %fieldsToSaveCount% {
			elementType := fieldsToSave[A_Index]
			element := fieldsToSave[A_Index] elementSuffix
			elementContents := %element%
			IniWrite, %elementContents%, .\settings.ini, %key%, %elementType%
		}
	}
	; UpdateUIFromJson()
}

;================================================================
; reads the .ini file and outputs it to the internal Json object
LoadSettings(){
	path := ""
	path = %A_WorkingDir%\settings.ini
	bb := % FileExist(path)
	OutputDebug, %bb%
	if(FileExist(path) = ""){
		; Cretaesa Default Settings
		UpdateUIFromJson()
		SaveSettings()
	}else{

		output := ""
		IniRead, sectionOutput, settings.ini
		sections := StrSplit(sectionOutput, "`n")
		
		;itterating throgh sections and throught the variable of those sections
		for index in sections{
			elementSuffix := "_Element" A_Index
			section := sections[index]
			; title := ListOfSkills[section].title
			
			loop, %fieldsToSaveCount% {
				elementType := fieldsToSave[A_Index]
				element := fieldsToSave[A_Index] elementSuffix
				result := ""
				IniRead, result, .\settings.ini, %section%, %elementType%
				ListOfSkills[index][elementType] := result
			}
		}
	}
}

;================================================================
; Updates the JSON with values UI
; UpdateJSON2(){
; 		For key, skill in ListOfSkills{
; 		elementSuffix := "_Element" A_Index
; 		loop, %guiElementsCount% {
; 			elementType := guiElements[A_Index]
; 			element := guiElements[A_Index] elementSuffix
; 			; tmeme := skill[elementType]
; 			; t2meme := %element%
; 			skill[elementType] := %element%
; 		}
; 	}
; }

;================================================================
;;update the internal Json object with values from the UI
UpdateJSONfromUI(){
	For key, skill in ListOfSkills{
		elementSuffix := "_Element" A_Index
		loop, %guiElementsCount% {
			elementType := guiElements[A_Index]
			element := elementType elementSuffix
			temp := ""
			GuiControlGet, temp,, %element% 
			
			skill[elementType] := temp

			; ; skill[elementType] := temp
			; GuiControl,, %element%, %temp% 
		}
	}
	; Gui, 2:Show, w1920 h1080 NA ;, onScreenIcons
}
;================================================================
;;update the UI fields from the internal object
UpdateUIFromJson(){
	For key, skill in ListOfSkills{
		elementSuffix := "_Element" A_Index
		loop, %fieldsToSaveCount% {
			elementType := fieldsToSave[A_Index]
			element := elementType elementSuffix
			JSONdata := skill[elementType]
			
			%element% := JSONdata
			GuiControl,, %element%, %JSONdata% 
		}
	}
}
; OLD_UpdateUIFromJson(){
; 	;;referesh the GUI with uptadated variables
; 	For key, skill in ListOfSkills{
; 		elementSuffix := "_Element" A_Index
; 		loop, %fieldsToSaveCount% {
; 			elementType := fieldsToSave[A_Index]
; 			element := elementType elementSuffix
; 			GuiControl,, %element%, %element% 
; 		}
; 		; GuiControl,, %tempvar%, "x"mousex "y"mousey
; 	}
; }

RefreshOSI(){
	;;referesh the OnScreenImages with updated locations
	For key, skill in ListOfSkills{
		elementGroup := "_Element" A_Index

		GUIxposbox := skill.xposbox
		GUIyposbox := skill.yposbox

		posi := "x" GUIxposbox " y" GUIyposbox " w64 h64"
		imgName := "pictureOSI" elementGroup
		GuiControl, 2:move, %imgName%, %posi%
	}
}

;not used yet?
UpdateOnScreenIMG(){

}

;================================================================

setUpHotkeys(){
	ListOfHotkeyKeys := []

	For k, Skill in ListOfSkills{
		elementGroup := "_Element" A_Index

		keboard_key := "key" elementGroup
		value := %keboard_key%

		keyArray := []
		
		keyArray.Push(value)
		keyArray.Push(Skill)
		
		ListOfHotkeyKeys.Push(keyArray)
	}

	; for index in ListOfHotkeyKeys{

	; If I dont look at the count it doen't exist :3
	count := 0
    For k, key in listOfKeyboardKeys
    {   
		if(IsElementInArray(key, ListOfHotkeyKeys) == true){
			count++
			argument := ""
			argument := count	

			FuncText := "RenderImage" count
			functionVariable := Func(FuncText).Bind(argument)

			hKey := "~"key
			HotKey % hKey, % functionVariable
		}
    }
}

RenderImage1(_arg){
	Control(_arg)
}
RenderImage2(_arg){
	Control(_arg)
}
RenderImage3(_arg){
	Control(_arg)
}
RenderImage4(_arg){
	Control(_arg)
}
RenderImage5(_arg){
	Control(_arg)
}

Control(_i){
	this_skill := ListOfSkills[_i]
	this_skill.TimeAtLastHotkeyPress := A_TickCount
	variableName := "pictureOSI" "Element" _i
	OnscreenImage := "pictureOSI_Element"_i

	this_skill.enable := true
	GuiControl, 2:Show, %OnscreenImage%
	timerNumber := "Timer" _i
	
	SetTimer, %timerNumber%, 10
}

TimerFunction(_skill){
	_id := _skill.index
	timerNumber := "Timer" _id

	time := 1*_skill.durationtextbox
	positionx := _skill.xposbox + 5
	positiony := _skill.yposbox + 30

	Elapsed := ((A_TickCount-_skill.TimeAtLastHotkeyPress)/1000)
	Seconds := Round(time - Elapsed, 1)
		
	ToolTip % Seconds, %positionx%, %positiony%, %_id%
	If( Elapsed >= time ){
		this_skill.enable := true
		GuiControl, 2:Hide, pictureOSI_Element%_id%
		SetTimer, %timerNumber%, Off
		ToolTip,,,,%_id%
	}
}
; I don't know how to pass a variable into this function so this monstrosity is here
Timer1:
	TimerFunction(ListOfSkills[1])
return
Timer2:
	TimerFunction(ListOfSkills[2])
return
Timer3:
	TimerFunction(ListOfSkills[3])
return
Timer4:
	TimerFunction(ListOfSkills[4])
return
Timer5:
	TimerFunction(ListOfSkills[5])
return
Timer6:
	TimerFunction(ListOfSkills[6])
return
Timer7:
	TimerFunction(ListOfSkills[7])
return
Timer8:
	TimerFunction(ListOfSkills[8])
return
Timer9:
	TimerFunction(ListOfSkills[9])
return





;================================================================

InitiliseUTimes(){

}

saveProgram:
	UpdateJSONfromUI()
	SaveSettings()
	UpdateUIFromJson()
	; UpdateJSONfromUI()
return


GuiClose:
	ExitApp
return

F2::
{
	toggleAppliction := !toggleAppliction
}

F6::
{
	LoadSettings()
}


;================================================================

IndexSkills(){
	indexCount = 0
	For key, skill in ListOfSkills{
		indexCount++
		If(indexCount => 20){
			Exception("Max number of icons reached  (20)")
		}
		else{
			skill.index := indexCount
		}
	}
}
;================================================================

ObjFullyClone(obj)
{
	nobj := obj.Clone()
	for k,v in nobj
		if IsObject(v)
			nobj[k] := A_ThisFunc.(v)
	return nobj
}
;================================================================

FontHandler(_keyword){
	Switch _keyword, off{
	Case "title":
		Gui, Font, s11 ; Title
	Case "button":
		Gui, Font, s7 ; Title

	Default:
		Gui, Font
	}
}
;================================================================

IsElementInArray(_element, _array){
	for i, ab in _array{
		if(ab[1] == _element){
			return true
		}
	}
	return false
}
;================================================================
; delete after adding defaults to skillTemplatePosition

positionToString(_vector2){
	test := "x" _vector2.x " y" _vector2.y
	return test
}
positionAndSizeToString(_vector4){
	test := "x" _vector4.x " y" _vector4.y ;" w" _vector4.w " h" _vector4.h
	return test 
}
positionAndSizeToString2(_vector4){
	test := "x" _vector4.x " y" _vector4.y " w" _vector4.w " h" _vector4.h
	return test 
}

;================================================================

AddVectorXY(_vector1, _vector2){
	tempVector := {x:0, y:0}
	tempVector.x := _vector1.x + _vector2.x	
	tempVector.y := _vector1.y + _vector2.y
	return tempVector
}

updatePositions(_positions, _vector2D){
	For key, possy in _positions{
		possy.x += _vector2D.x
		possy.y += _vector2D.y
	}
}