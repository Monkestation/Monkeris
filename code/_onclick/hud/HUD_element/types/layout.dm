/*
	Layout object that used to align multiple UI elements

	TODO: insert elements
*/

/atom/movable/hud_element/layout
	var/list/_paddingData = list()
	var/_alignment
	debugColor = COLOR_YELLOW

/atom/movable/hud_element/layout/setIcon()
	return

/atom/movable/hud_element/layout/scaleToSize()
	return

/atom/movable/hud_element/layout/updateIconInformation()
	return

/atom/movable/hud_element/layout/proc/_spreadElements()

/atom/movable/hud_element/layout/proc/alignElements(horizontal, vertical, list/atom/movable/hud_element/targets, padding = 0)
	return src

/atom/movable/hud_element/layout/horizontal/alignElements(horizontal, vertical, list/atom/movable/hud_element/targets, padding = 0)
	_alignment = horizontal
	if(targets && targets.len)
		for (var/atom/movable/hud_element/T in targets)
			add(T,padding,padding)
			//we are using _aligment to align elements in alignElements()
			T.setAlignment(HUD_HORIZONTAL_WEST_INSIDE_ALIGNMENT,vertical)
	else
		return
	. = ..()

/atom/movable/hud_element/layout/vertical/alignElements(horizontal, vertical, list/atom/movable/hud_element/targets, padding = 0)
	_alignment = vertical
	if(targets && targets.len)
		for (var/atom/movable/hud_element/T in targets)
			add(T,padding,padding)
			//we are using _aligment to align elements in alignElements()
			T.setAlignment(horizontal, HUD_VERTICAL_SOUTH_INSIDE_ALIGNMENT)
	else
		return
	. = ..()

/atom/movable/hud_element/layout/horizontal/_spreadElements()
	setWidth(0)

	if(!_paddingData.len)
		return

	if (_alignment == HUD_HORIZONTAL_WEST_INSIDE_ALIGNMENT)
		for(var/i = 1; i <= _paddingData.len; i++)
			var/atom/movable/hud_element/E = _paddingData[i]
			var/list/data = _paddingData[E]
			setWidth(getWidth() + data["left"])
			E.setPosition(getWidth())
			setWidth(getWidth() + E.getWidth())
			setWidth(getWidth() + data["right"])

	else if (_alignment == HUD_HORIZONTAL_EAST_INSIDE_ALIGNMENT)
		for(var/i = _paddingData.len; i >= 1; i--)
			var/atom/movable/hud_element/E = _paddingData[i]
			var/list/data = _paddingData[E]
			setWidth(getWidth() + data["right"])
			E.setPosition(getWidth())
			setWidth(getWidth() + E.getWidth())
			setWidth(getWidth() + data["left"])

/atom/movable/hud_element/layout/vertical/_spreadElements()
	setHeight(0)

	if(!_paddingData.len)
		return

	if (_alignment == HUD_VERTICAL_NORTH_INSIDE_ALIGNMENT)
		for(var/i = 1; i <= _paddingData.len; i++)
			var/atom/movable/hud_element/E = _paddingData[i]
			var/list/data = _paddingData[E]
			setHeight(getHeight() + data["bottom"])
			E.setPosition(null, getHeight())
			setHeight(getHeight() + E.getHeight())
			setHeight(getHeight() + data["top"])

	else if (_alignment == HUD_VERTICAL_SOUTH_INSIDE_ALIGNMENT)
		for(var/i = _paddingData.len; i >= 1; i--)
			var/atom/movable/hud_element/E = _paddingData[i]
			var/list/data = _paddingData[E]
			setHeight(getHeight() + data["top"])
			E.setPosition(null, getHeight())
			setHeight(getHeight() + E.getHeight())
			setHeight(getHeight() + data["bottom"])

/atom/movable/hud_element/layout/proc/setPadding()
	return FALSE

/atom/movable/hud_element/layout/horizontal/setPadding(atom/movable/hud_element/element, paddingLeft, paddingRight)
	if(!element)
		error("No element was passed to padding setting.")
		return FALSE

	if(!(locate(element) in getElements()))
		error("Trying to set padding for element that is not connected to layout.")
		return

	var/list/data = _paddingData[element]
	if(!data)
		data = list()
		_paddingData[element] = data

	if(paddingLeft)
		data["left"] = paddingLeft
	if(paddingRight)
		data["right"] = paddingRight

	_spreadElements()
	return TRUE

/atom/movable/hud_element/layout/vertical/setPadding(atom/movable/hud_element/element, paddingBottom, paddingTop)
	if(!element)
		error("No element was passed to padding setting.")
		return FALSE

	if(!(locate(element) in getElements()))
		error("Trying to set padding for element that is not connected to layout.")
		return

	var/list/data = _paddingData[element]
	if(!data)
		data = list()
		_paddingData[element] = data

	if(paddingBottom)
		data["bottom"] = paddingBottom
	if(paddingTop)
		data["top"] = paddingTop

	_spreadElements()
	return TRUE

/atom/movable/hud_element/layout/horizontal/add(atom/movable/hud_element/newElement, paddingLeft = 0, paddingRight = 0)
	. = ..()
	setPadding(newElement, paddingLeft, paddingRight)
	setHeight(max(getHeight(), newElement.getHeight()))

	_spreadElements()

/atom/movable/hud_element/layout/vertical/add(atom/movable/hud_element/newElement, paddingBottom = 0, paddingTop = 0)
	. = ..()
	setPadding(newElement, paddingBottom, paddingTop)
	setWidth(max(getWidth(), newElement.getWidth()))

	_spreadElements()

/atom/movable/hud_element/layout/remove(atom/movable/hud_element/element)
	. = ..()
	if(!getElements())
		setHeight(0)
		setWidth(0)

	if(_paddingData[element])
		_paddingData[element] = null

	_spreadElements()

/atom/movable/hud_element/layout/setDimensions(width, height)
	return
/*
/atom/movable/hud_element/layout/setWidth(width)
	return

/atom/movable/hud_element/layout/setHeight(height)
	return
*/
