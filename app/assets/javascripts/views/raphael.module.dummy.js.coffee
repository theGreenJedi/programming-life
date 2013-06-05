# The module dummy view shows a potential module.
# It also allows for interaction adding this potential module to a cell.
#
class View.DummyModule extends View.RaphaelBase
	
	# Creates a new module view
	# 
	# @param paper [Raphael.Paper] the raphael paper
	# @param _parent [View.Cell] the cell view this dummy belongs to
	# @param _cell [Model.Cell] the cell model displayed in the parent
	# @param _modulector [Function] the module constructor
	# @param _number [Integer] the number of instances allowed [ -1 is unlimted, 0 is none ]
	# @param _params [Object] the params
	#
	constructor: ( paper, parent, @_cell, @_modulector, @_number, @_params = {} ) ->
		
		super paper, parent
		
		@_type = @_modulector.name
		@_count = @_cell.numberOf @_modulector

		@_visible = @_number is -1 or @_count < @_number

		@_createBindings()

		@_propertiesView = new View.DummyModuleProperties( @, @_parent, @_cell, @_modulector, @_params )
		@_notificationsView = new View.ModuleNotification( @, @_parent, @_cell, @ )
		
		Object.defineProperty( @, 'visible',
			get: ->
				return @_visible
		)
		
		Object.defineProperty( @, 'type',
			get: ->
				return @_type
		)
	
	# Creates event bindings
	#
	_createBindings: ( ) ->
		@_bind( 'cell.module.added', @, @onModuleAdd )
		@_bind( 'cell.module.removed', @, @onModuleRemove )
		@_bind( 'cell.metabolite.added', @, @onModuleAdd )		
		@_bind( 'cell.metabolite.removed', @, @onModuleRemove )
		@_bind( 'module.creation.started', @, @onModuleCreationStarted)
		@_bind( 'module.creation.aborted', @, @onModuleCreationAborted )
		@_bind( 'module.creation.finished', @, @onModuleCreationFinished )
		@_bind "module.properties.change", @, @onModulePropertiesChange
		@_bind "module.selected.changed", @, @onModuleSelected

	# Gets called when a module creation has started
	#
	# @param dummy [View.DummyModule] the dummy for which the module creation has started
	#
	onModuleCreationStarted: ( dummy ) ->
		if dummy is @
			@_setSelected on
		else
			if @_selected
				@_setSelected off
		
		
	# Gets called when a module creation was aborted
	#
	# @param dummy [View.DummyModule] the dummy for which the module creation was aborted
	#
	onModuleCreationAborted: ( dummy ) ->
		if dummy is @
			@_setSelected off
			@_notificationsView.hide()
	
	# Gets called on a change in the module properties
	#
	# @param source [View.DummyModule] The source of the change
	# @param key [String] The property
	# @oaram value [Object] The new value
	#
	@catchable
		onModulePropertiesChange:( source, key, value ) ->
			if source is @
				@module[ key ] = value
				@_notificationsView.hide()

				@_trigger "module.creation.changed", @, [@module]

	# Clicked the add button
	#
	# @params caller [Context] the caller of the event
	# @params dummy [View.DummyModule] the dummy to activate
	# @params params [Object] the params to pass to the constructor
	#
	@catchable
		onModuleCreationFinished : ( dummy, params ) ->
			if dummy isnt this
				return

			@_setSelected off

			params = _( params ).defaults( @_params )
			@module = new @_modulector( _( params ).clone( true ) )

			@_trigger "module.created", @, [ @module ]
	
	# On Module Added to the Cell
	#
	# @param cell [Model.Cell] the cell added to
	# @param module [Model.Module] the module added
	#
	onModuleAdd : ( cell, module ) ->
		if cell is @_cell and module instanceof @_modulector 
			@_count += 1
			if @_number isnt -1 and @_number <= @_count
				@hide() if @_visible
			else
				@setPosition()

	# On Module Removed from the Cell
	#
	# @param cell [Model.Cell] the cell removed from
	# @param module [Model.Module] the module removed
	#
	onModuleRemove : ( cell, module ) ->
		if cell is @_cell and module instanceof @_modulector 
			@_count -= 1
			if @_number > @_count
				@show() unless @_visible
			else
				@setPosition()

	getFullType: ( ) ->
		return @_modulector::getFullType(@_params.direction, @_params.type, @_params.placement)

	# Returns the bounding box of this view
	#
	# @return [Object] a bounding box object with coordinates
	#
	getBBox: ( ) -> 
		return @_box?.getBBox() ? { x:0, y:0, x2:0, y2:0, width:0, height:0 }

	# Returns the coordinates of either the entrance or exit of this view
	#
	# @param location [View.Module.Location] the location (entrance or exit)
	# @return [[float, float]] a tuple of the x and y coordinates
	#
	getPoint: ( location ) ->
		box = @getBBox()

		switch location
			when View.Module.Location.Left
				return [box.x ,@y]
			when View.Module.Location.Right
				return [box.x2 ,@y]
			when View.Module.Location.Top
				return [@x, box.y]
			when View.Module.Location.Bottom
				return [@x, box.y2]

	#
	#
	getAbsolutePoint: ( location ) ->
		[x, y] = @getPoint(location)
		return @getAbsoluteCoords(x, y)

	# Draws this view
	#
	draw: ( x = null, y = null ) ->		
		unless x? and y?
			[x, y] = @_parent?.getViewPlacement(@) ? [0, 0]

		super(x, y)

		#unless @_visible
		#	return

		padding = 15
		
		# Start a set for contents
		contents = @drawContents( @x, @y, padding )
		
		# Draw box
		@_box = @drawBox( contents )
		@_box.insertBefore contents
		
		# Draw hitbox
		hitbox = @drawHitbox(@_box)

		hitbox.mouseover =>
			@_setHovered(on)

		hitbox.mouseout =>
			@_setHovered(off)

		hitbox.click =>
			unless @_selected
				@module = new @_modulector( _( @_params ).clone( true ) )
				@_trigger 'module.creation.started', @, [ @module ]
			else
				@_trigger 'module.creation.aborted', @, [ @module ]
		
		@_contents.push hitbox
		@_contents.push contents
		@_contents.push @_box

		unless @_visible
			@hide(off)
		
	# Hides this view
	#
	hide: ( animate = on ) ->
		done = ( ) =>
			@_contents.hide()
			@_visible = off
		

		if animate
			@_contents.attr('opacity', 1)
			@_contents.animate Raphael.animation(
				opacity: 0
			, 200, 'ease-in', done)
		else
			done()

		return this
		
	# Shows this view
	#
	show: ( animate = on ) ->
		done = ( ) =>
			@_visible = on

		@setPosition(off)		

		if animate
			@_contents.attr('opacity', 0)
			@_contents.show()
			@_contents.animate Raphael.animation(
				opacity: 1
			, 100, 'ease-out', done)
		else
			done()

		return this
		
	# Kills this view
	#
	kill: () ->
		super()
		@_propertiesView?.kill()
		@_notificationsView?.kill()

	# Sets wether or not the module is selected
	#
	# @param selected [Boolean] selection state
	#
	_setSelected: ( selected ) ->
		if selected isnt @_selected
			@_selected = selected
			if selected
				@_setHovered off
				$(@_box.node).addClass('selected')
			else
				$(@_box.node).removeClass('selected')
				@_trigger "module.creation.aborted", @, [@module]

		return this

	# Sets wether or not the module is hovered
	#
	# @param hovered [Boolean] hover state
	#
	_setHovered: ( hovered ) ->
		if hovered isnt @_hovered 
			if hovered and not @_selected
				$(@_box.node).addClass('hovered')
			else
				$(@_box.node).removeClass('hovered')

		@_hovered = hovered
		return this
		
	# Draws the box
	#
	# @param elem [Raphael] element to draw for
	# @return [Raphael] the contents
	#
	drawBox : ( elem ) ->
		rect = elem.getBBox()
		padding = 15
		box = @paper.rect(rect.x - padding, rect.y - padding, rect.width + 2 * padding, rect.height + 2 * padding)

		classname = 'module-box inactive dummy dummy-' + @_type.toLowerCase()
		classname += ' hovered' if @_hovered
		classname += ' selected' if @_selected
		$(box.node).addClass classname
		box.attr('r', 9)
		
		return box
		
	# Draws contents
	#
	# @param x [Integer] x position
	# @param y [Integer] y position
	# @return [Raphael] the contents
	#
	drawContents: ( ) ->
		
		@paper.setStart()
		text = @paper.text( @x, @y, _.escape "Add #{@_type}" )
		$(text.node).addClass('module-text')

		return @paper.setFinish()
		
	# Draws this view hitbox
	#
	# @param elem [Raphael] element to draw for
	# @return [Raphael] the contents
	#
	drawHitbox : ( elem ) ->
		rect = elem.getBBox()
		hitbox = @paper.rect(rect.x, rect.y, rect.width, rect.height)
		hitbox.node.setAttribute('class', 'module-hitbox hitdummy-' + @_type.toLowerCase() )	

		return hitbox
	

	# Gets called when a module view selected.
	#
	# @param module [Module] the module that is being selected
	# @param selected [Boolean] the selection state of the module
	#
	onModuleSelected: ( module, selected ) ->
		unless module is @module
			if @_selected
				@_setSelected off
