/*
add(var/atom/movable/hud_element/newElement) -> /atom/movable/hud_element/newElement
- adds child element into parent element, element position is relative to parent

remove(var/atom/movable/hud_element/element) -> /atom/movable/hud_element/element
- removes child and usets childs parent

getClickProc() -> /proc/clickProc
setClickProc(var/proc/P) -> src
- sets a proc that will be called when element is clicked, in byond proc Click()

getHideParentOnClick() -> boolean
setHideParentOnClick(var/boolean) -> src
- sets whether element will call hide() on parent after being clicked

getDeleteOnHide() -> boolean
setDeleteOnHide(var/boolean) -> src
- sets whether element will delete itself when hide() is called on this element

getHideParentOnHide() -> boolean
setHideParentOnHide(var/boolean) -> src
- sets whether element will call hide() on parent when hide() is called on this element

getPassClickToParent() -> boolean
setPassClickToParent(var/boolean) -> src
- sets whether element passes Click() events to parent

scaleToSize(var/width, var/height) -> src
- scales element to desired width and height, argument values are in pixels
- null width or height indicate not to change the relevant scaling

getRectangle() -> /list/bounds
- gets bottom-left and top-right corners of a rectangle in which the element and all child elements reside, relative to element itself

setHeight(var/height) -> src
setWidth(var/width) -> src
setDimensions(var/width, var/height) -> src
- sets artificial width/height of an element, relevant only if icon is smaller than set values, argument values are in pixels

getWidth() -> width
getHeight() -> height
- gets the actual width/height of an element, after scaling, return values are in pixels

setIcon(var/icon/I) -> src
- sets element icon

mimicAtomIcon(var/atom/A) -> src
- takes on byond icon related vars from any atom

getIconWidth() -> width
getIconHeight() -> height
- gets icon width/height without scaling, return values are in pixels
- note that all icons in a .dmi share the same width/height
- it is recommended to use separate image files for each non-standard sized image to fully utilize automatic functions from this framework

updateIconInformation() -> src
- if you for some reason have to manually set byond icon vars for an element, call this after you're done to update the element
- automatically called by procs changing icon and in New()

getAlignmentVertical() -> alignmentVertical
getAlignmentHorizontal() -> alignmentHorizontal
setAlignment(var/horizontal, var/vertical) -> src
- sets alignment behavior for element, relative to parent, null arguments indicate not to change the relevant alignment
- look HUD_defines.dm for arguments


getPositionX() -> x
getPositionY() -> y
getPosition() -> list(x,y)
setPosition(var/x, var/y) -> src
- sets position of the element relative to parent, argument values are in pixels, null indicates no change
- values are in pixels, arguments are rounded

getAbsolutePositionX() -> x
getAbsolutePositionY() -> y
- gets element position on client view screen map, values are in pixels

getElements() -> /list/atom/movable/hud_element
- gets list of child elements

getParent() -> /atom/movable/hud_element
- gets parent element

setName(var/new_name, var/nameAllElements = FALSE)
- sets byond name var for element, option for recursive naming of all child elements, useful only for debug

getData(var/indexString) -> value
- gets stored data, indexString must be a valid list association index

setData(var/indexString, var/value) -> src
- stores value into element data storage list, indexString must be a valid list association index

getIdentifier() -> identifier
- gets element identifier, each client can have only 1 element shown for each unique identifier
- identifier must be a valid list association index

getObserver() -> /client
- gets client that currently sees the element, element can be seen by only 1 client at a time

show(var/client/C) -> src
- shows element to client

hide() -> src || null
- hides element from client
- returns null if element deleted itself

setIconOverlays(var/icon/iconOverlays)
- sets icon overlays
- overlays must be named list
- accepts only associative list
-	for overlay names see HUD_defines

updateIcon()
- Updates icon using overlays

getIconOverlays() -> _iconOverlays
- gets icon overlays

getChildElementWithID(var/id) -> /atom/movable/hud_element || null
- return child element with identifier id or null if none

moveChildOnTop(var/id) -> /atom/movable/hud_element || null
- return moved element with identifier id or null if none

moveChildToBottom(var/id) -> /atom/movable/hud_element || null
- return moved element with identifier id or null if none

alignElements(var/horizontal, var/vertical, var/list/atom/movable/hud_element/targets) -> /atom/movable/hud_element || null
- return src if aligned atleast one objects from targets


*/


/atom/movable/hud_element/proc/add(atom/movable/hud_element/newElement)
	RETURN_TYPE(/atom/movable/hud_element)
	newElement = newElement || new
	_connectElement(newElement)

	return newElement

/atom/movable/hud_element/proc/remove(atom/movable/hud_element/element)
	if(_disconnectElement(element))
		return element

/atom/movable/hud_element/proc/setClickProc(P, holder)
	_clickProc = P
	_holder = holder
	return src

/atom/movable/hud_element/proc/getClickProc()
	return _clickProc

/atom/movable/hud_element/proc/setHideParentOnClick(value)
	_hideParentOnClick = value

	return src

/atom/movable/hud_element/proc/getHideParentOnClick()
	return _hideParentOnClick


/atom/movable/hud_element/proc/setDeleteOnHide(value)
	_deleteOnHide = value

	return src

/atom/movable/hud_element/proc/getDeleteOnHide()
	return _deleteOnHide


/atom/movable/hud_element/proc/setHideParentOnHide(value)
	_hideParentOnHide = value

	return src

/atom/movable/hud_element/proc/getHideParentOnHide()
	return _hideParentOnHide


/atom/movable/hud_element/proc/setPassClickToParent(value)
	_passClickToParent = value

	return src

/atom/movable/hud_element/proc/getPassClickToParent()
	return _passClickToParent


/atom/movable/hud_element/proc/scaleToSize(width, height) //in pixels
	var/matrix/M = matrix()
	if (width != null)
		_scaleWidth = width/_iconWidth
		M.Scale(_scaleWidth,1)
		M.Translate((_scaleWidth-1)*_iconWidth/2,0)

	if (height != null)
		_scaleHeight = height/_iconHeight
		M.Scale(1,_scaleHeight)
		M.Translate(0,(_scaleHeight-1)*_iconHeight/2)

	transform = M

	_updatePosition()

	return src

/atom/movable/hud_element/proc/getRectangle()
	var/result_x1 = 0
	var/result_y1 = 0
	var/result_x2 = getWidth()
	var/result_y2 = getHeight()

	var/list/atom/movable/hud_element/elements = getElements()
	for(var/atom/movable/hud_element/E in elements)
		var/list/rectangle = E.getRectangle()

		var/x1 = E.getPositionX() + rectangle[1]
		var/y1 = E.getPositionY() + rectangle[2]

		if (x1 < result_x1)
			result_x1 = x1
		if (y1 < result_y1)
			result_y1 = y1

		var/x2 = x1 + rectangle[3]
		var/y2 = y1 + rectangle[4]

		if (x2 > result_x2)
			result_x2 = x2
		if (y2 > result_y2)
			result_y2 = y2

	var/list/bounds = new(result_x1, result_y1, result_x2, result_y2)

	return bounds

/atom/movable/hud_element/proc/setDimensions(width, height)
	if (width != null)
		_width = width
	if (height != null)
		_height = height

	_updatePosition()

	return src

/atom/movable/hud_element/proc/setWidth(width)
	_width = width

	_updatePosition()

	return src

/atom/movable/hud_element/proc/setHeight(height)
	_height = height

	_updatePosition()

	return src

/atom/movable/hud_element/proc/getWidth()
	return max(getIconWidth(), _width)*_scaleWidth

/atom/movable/hud_element/proc/getHeight()
	return max(getIconHeight(), _height)*_scaleHeight


/atom/movable/hud_element/proc/setIcon(icon/I)
	icon = I
	updateIconInformation()
	updateIcon()

	return src

/atom/movable/hud_element/proc/setIconFromDMI(filename, iconState, iconDir)
	icon = filename
	icon_state = iconState
	dir = iconDir
	updateIconInformation()
	updateIcon()

	return src

/atom/movable/hud_element/proc/getIconWidth()
	return _iconWidth

/atom/movable/hud_element/proc/getIconHeight()
	return _iconHeight

/atom/movable/hud_element/proc/mimicAtomIcon(atom/A)
	icon = A.icon
	icon_state = A.icon_state
	dir = A.dir
	color = A.color
	alpha = A.alpha
	overlays = A.overlays
	underlays = A.underlays

	updateIconInformation()
	updateIcon()

	return src

/atom/movable/hud_element/proc/updateIconInformation()
	if (!icon)
		_iconWidth = 0
		_iconHeight = 0

		_updatePosition()

		return src

	var/icon/I = new(fcopy_rsc(icon),icon_state,dir)
	var/newIconWidth = I.Width()
	var/newIconHeight = I.Height()
	if ((newIconWidth == _iconWidth) && (newIconHeight == _iconHeight))
		return src
	_iconWidth = newIconWidth
	_iconHeight = newIconHeight

	_updatePosition()

	return src

/atom/movable/hud_element/proc/setAlignment(horizontal, vertical)
	if (horizontal != null)
		_currentAlignmentHorizontal = horizontal

	if (vertical != null)
		_currentAlignmentVertical = vertical

	_updatePosition()

	return src

/atom/movable/hud_element/proc/getAlignmentVertical()
	return _currentAlignmentVertical

/atom/movable/hud_element/proc/getAlignmentHorizontal()
	return _currentAlignmentHorizontal


/atom/movable/hud_element/proc/setPosition(x, y) //in pixels
	if (x != null)
		_relativePositionX = round(x)

	if (y != null)
		_relativePositionY = round(y)

	_updatePosition()

	return src

/atom/movable/hud_element/proc/getPositionX()
	return _relativePositionX

/atom/movable/hud_element/proc/getPositionY()
	return _relativePositionY

/atom/movable/hud_element/proc/getPosition()
	return list(_relativePositionX,_relativePositionY)

/atom/movable/hud_element/proc/getAbsolutePositionX()
	return _absolutePositionX

/atom/movable/hud_element/proc/getAbsolutePositionY()
	return _absolutePositionY

/atom/movable/hud_element/proc/getAbsolutePosition()
	return list(_absolutePositionX,_absolutePositionY)


/atom/movable/hud_element/proc/getElements()
	return _elements

/atom/movable/hud_element/proc/getParent()
	return _parent

/atom/movable/hud_element/proc/setName(new_name, nameAllElements = FALSE)
	name = new_name
	if (nameAllElements)
		var/list/atom/movable/hud_element/elements = getElements()
		for(var/atom/movable/hud_element/E in elements)
			E.setName(new_name, TRUE)

/atom/movable/hud_element/proc/getData(indexString)
	if (_data)
		return _data[indexString]

/atom/movable/hud_element/proc/setData(indexString, value)
	_data = _data || new
	_data[indexString] = value

	return src

/atom/movable/hud_element/proc/getIdentifier()
	return _identifier

/atom/movable/hud_element/proc/getObserver()
	return _observer

/atom/movable/hud_element/proc/show(client/C)
	var/client/observer = getObserver()
	if (observer)
		if (observer != C)
			log_to_dd("Error: HUD element already shown to client '[observer]'")
			return

		return src

	_setObserver(C)

	var/identifier = getIdentifier()
	if (identifier)
		var/list/observerHUD = _getObserverHUD()
		var/atom/movable/hud_element/currentClientElement = observerHUD[identifier]
		if (currentClientElement)
			if (currentClientElement == src)
				return src

			qdel(currentClientElement)

		observerHUD[identifier] = src

	C.screen += src

	var/list/atom/movable/hud_element/elements = getElements()
	for(var/atom/movable/hud_element/E in elements)
		E.show(C)

	return src

/atom/movable/hud_element/proc/hide()
	var/client/observer = getObserver()
	if (!observer)
		if (QDELETED(src))
			return
		return src

	var/identifier = getIdentifier()
	if (identifier)
		var/list/observerHUD = _getObserverHUD()
		var/atom/movable/hud_element/currentClientElement = observerHUD[identifier]
		if (currentClientElement)
			if (currentClientElement == src)
				observerHUD[identifier] = null
			else
				log_to_dd("Error: HUD element identifier '[identifier]' was occupied by another element during hide()")
				return

	observer.screen -= src

	_setObserver()

	var/list/atom/movable/hud_element/elements = getElements()
	for(var/atom/movable/hud_element/E in elements)
		E.hide()

	if (_hideParentOnHide)
		var/atom/movable/hud_element/parent = getParent()
		if (parent)
			parent = parent.hide()
			if (!parent) //parent deleted
				return

	if (_deleteOnHide && !QDELETED(src))
		qdel(src)
		return

	return src

/atom/movable/hud_element/proc/setIconAdditionsData(additionType, list/additionsData)
	if(additionType != HUD_ICON_UNDERLAY && additionType != HUD_ICON_OVERLAY)
		error("Trying to add icon addition data without setting type (HUD_ICON_UNDERLAY/HUD_ICON_OVERLAY).")
		return

	if(!is_associative(additionsData))
		error("OverlayData list is not associative")
		return

	for (var/additionName in additionsData)
		var/list/data = additionsData[additionName]
		if(!is_associative(data))
			error("OverlayData list contains not associative data list with name\"[additionName]\".")
			continue
		setIconAddition(additionType, additionName, data["icon"], data["icon_state"], data["dir"], data["color"], data["alpha"], data["is_plain"])
	return src

/atom/movable/hud_element/proc/setIconAddition(additionType, additionName, addIcon, addIconState, addDir, color, alpha, isPlain)
	if(additionType != HUD_ICON_UNDERLAY && additionType != HUD_ICON_OVERLAY)
		error("Trying to add icon addition without setting type (HUD_ICON_UNDERLAY/HUD_ICON_OVERLAY).")
		return
	if(!additionName)
		error("No addition name was passed")
		return

	var/list/data = getIconAdditionData(additionType, additionName)
	// if passed only overlay name and there is overlay with this name then we null delete it
	if(data && (!icon && !color && !alpha))
		data[additionName] = null
		qdel(_iconsBuffer["[additionType]_[additionName]"])
		_iconsBuffer["[additionType]_[additionName]"] = null
		updateIcon()
		return src

	if(!data)
		data = list()
		if(additionType == HUD_ICON_UNDERLAY)
			_iconUnderlaysData[additionName] = data
		else if(additionType == HUD_ICON_OVERLAY)
			_iconOverlaysData[additionName] = data

	if(addIcon)
		data["icon"] = addIcon
		data["icon_state"] = addIconState
		data["dir"] = addDir
		data["is_plain"] = isPlain
	else
		data["icon"] = null

	setIconAdditionAlpha(additionType, additionName, alpha, noIconUpdate = TRUE)
	setIconAdditionColor(additionType, additionName, color, noIconUpdate = TRUE)

	_assembleAndBufferIcon(additionType, additionName, data)
	updateIcon()

	return src

/atom/movable/hud_element/proc/setIconAdditionAlpha(additionType, additionName, alpha, noIconUpdate = FALSE)
	if(additionType != HUD_ICON_UNDERLAY && additionType != HUD_ICON_OVERLAY)
		error("Trying to set icon addition alpha without setting type (HUD_ICON_UNDERLAY/HUD_ICON_OVERLAY).")
		return
	var/list/data = getIconAdditionData(additionType, additionName)
	if(!data)
		error("Can't set overlay icon alpha, no addition data.")
		return
	data["alpha"] = alpha
	if(!noIconUpdate)
		_assembleAndBufferIcon(additionType, additionName, data)
		updateIcon()
	return src

/atom/movable/hud_element/proc/setIconAdditionColor(additionType, additionName, color, noIconUpdate = FALSE)
	if(additionType != HUD_ICON_UNDERLAY && additionType != HUD_ICON_OVERLAY)
		error("Trying to set icon addition color without setting type (HUD_ICON_UNDERLAY/HUD_ICON_OVERLAY).")
		return
	var/list/data = getIconAdditionData(additionType, additionName)
	if(!data)
		error("Can't set overlay icon color, no addition data.")
		return
	data["color"] = color
	if(!noIconUpdate)
		_assembleAndBufferIcon(additionType, additionName, data)
		updateIcon()
	return src

/atom/movable/hud_element/proc/getIconAdditionData(additionType, additionName)
	if(additionType != HUD_ICON_UNDERLAY && additionType != HUD_ICON_OVERLAY)
		error("Trying to get icon addition data without setting type (HUD_ICON_UNDERLAY/HUD_ICON_OVERLAY).")
		return

	if(additionType == HUD_ICON_UNDERLAY)
		return _iconUnderlaysData[additionName]

	else if(additionType == HUD_ICON_OVERLAY)
		return _iconOverlaysData[additionName]

/atom/movable/hud_element/proc/updateIcon()
	_updateLayers()
	return src

/atom/movable/hud_element/proc/getChildElementWithID(id)
	for(var/atom/movable/hud_element/element in getElements())
		if(element.getIdentifier() == id)
			return element
	error("No element found with id \"[id]\".")

/atom/movable/hud_element/proc/moveChildOnTop(id)
	if(!_elements.len)
		error("Element has no child elements.")
		return
	var/atom/movable/hud_element/E = getChildElementWithID(id)
	if (E)
		_elements.Remove(E)
		_elements.Insert(1,E)
		return E
	else
		error("moveChildOnTop(): No element with id \"[id]\" found.")

/atom/movable/hud_element/proc/moveChildToBottom(id)
	if(!_elements.len)
		error("Element has no child elements.")
		return
	var/atom/movable/hud_element/E = getChildElementWithID(id)
	if (E)
		_elements.Remove(E)
		_elements.Add(E)
		return E
	else
		error("moveChildToBottom(): No element with id \"[id]\" found.")

/atom/movable/hud_element/proc/setClickedInteraction(state, list/iconData , duration = 8)
	if(!iconData || duration <= 0)
		error("incorrect button interaction setup.")
		_onClickedInteraction = FALSE
		return
	_onClickedInteraction = state
	if (state)
		_onClickedHighlightDuration = duration

		setIconAddition(HUD_ICON_OVERLAY, HUD_OVERLAY_CLICKED, iconData["icon"], iconData["icon_state"], color = iconData["color"], alpha = iconData["alpha"], isPlain = iconData["is_plain"])
	else
		_onClickedState = FALSE


/atom/movable/hud_element/proc/setHoveredInteraction(state, list/iconData)
	if(!iconData)
		error("incorrect button interaction setup.")
		_onHoveredInteraction = FALSE
		return
	_onHoveredInteraction = state
	if (state)
		setIconAddition(HUD_ICON_OVERLAY, HUD_OVERLAY_HOVERED, iconData["icon"], iconData["icon_state"], color = iconData["color"], alpha = iconData["alpha"], isPlain = iconData["is_plain"])
	else
		_onHoveredState = FALSE

/atom/movable/hud_element/proc/setToggledInteraction(state, list/iconData)
	if(!iconData)
		error("incorrect button interaction setup.")
		_onToggledInteraction = FALSE
		return
	_onToggledInteraction = state
	if (state)
		setIconAddition(HUD_ICON_OVERLAY, HUD_OVERLAY_TOGGLED, iconData["icon"], iconData["icon_state"], color = iconData["color"], alpha = iconData["alpha"], isPlain = iconData["is_plain"])
	else
		_onToggledState = FALSE

/atom/movable/hud_element/proc/toggleDebugMode()
	debugMode = !debugMode
	if(debugMode)
		var/atom/movable/hud_element/debugBox = new("\[debug_box\]([type])_[getIdentifier()]")
		debugBox.setName("\[debug_box\]([type])_[getIdentifier()]")
		debugBox.setIconFromDMI('icons/mob/screen/misc.dmi',"white_box")
		debugBox.setPosition(getAbsolutePositionX(), getAbsolutePositionY())
		debugBox.scaleToSize(getWidth(),getHeight())
		debugBox.setDimensions(getWidth(),getHeight())
		debugBox.color = debugColor
		debugBox.alpha = 80
		debugBox.updateIconInformation()
		_connectElement(debugBox)
		debugBox.show(_observer)
	else
		var/atom/movable/hud_element/debugBox = getChildElementWithID("\[debug_box\]([type])_[getIdentifier()]")
		debugBox.hide()
		_disconnectElement(debugBox)
		qdel(debugBox)
	/*
		I.DrawBox(ReadRGB(COLOR_BLACK),0,0,getWidth(),getHeight())
		I.DrawBox(ReadRGB(debugColor),1,1,getWidth()-1,getHeight()-1)
		setIconOverlay(HUD_OVERLAY_DEBUG,I, alpha = 80)*/

	updateIcon()

// mob clicks overrides
/atom/movable/hud_element/move_camera_by_click()
	return

/atom/movable/hud_element/attack_ghost(mob/observer/ghost/user as mob)
	return
