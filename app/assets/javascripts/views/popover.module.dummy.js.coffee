# Displays the properties of a dummy module in a neat HTML popover
#
class View.DummyModuleProperties extends View.ModuleProperties

	# Constructs a new DummyModuleProperties view.
	#
	# @param parent [View.Module] the accompanying module view
	# @param cellView [View.Cell] the accompanying cell view
	# @param cell [Model.Cell] the parent cell of the module
	# @param modulector [Function] the constructor for the dummy module
	# @param params [Object] options
	#
	constructor: ( parent, @_cellView, @_cell, @modulector, params = {} ) ->
		@_dummyId = _.uniqueId('dummy-module-')

		@_changes = {}

		@_compounds = @_cell.getCompoundNames()
		@_metabolites = @_cell.getMetaboliteNames()
		@_selectables = []

		# Behold, the mighty super constructor train! Reminds me of some super plumber called Mario.
		@constructor.__super__.constructor.__super__.constructor.apply( @, [parent, @modulector.name, 'module-properties', 'bottom'] )

		@_bind('module.selected.changed', @, @onModuleSelected)

		@_bind('module.creation.started', @, @onModuleCreationStarted)
		@_bind('module.creation.finished', @, @onModuleCreationFinished)
		@_bind('module.creation.aborted', @, @onModuleCreationAborted)

		@_setSelected off

	# Gets the id for this popover
	#
	getFormId: ( ) ->
		return 'properties-form-' + @_dummyId

	# Gets the id for an input with a certain key
	#
	# @param key [String] the key for which to get the id
	#
	getInputId: ( key ) ->
		return 'property-' + @_dummyId + '-' + key

	# Create the popover header
	#
	# @return [Array<jQuery.Elem>] the header and the button element
	#
	_createHeader: ( ) ->
		@_header = $('<div class="popover-title"></div>')

		onclick = () => @_trigger( 'module.creation.aborted', @_parent )
		@_closeButton = $('<button class="close">&times;</button>')
		@_closeButton.on('click', onclick ) if onclick?
		
		@_header.append @title
		@_header.append @_closeButton
		return [ @_header, @_closeButton ]

	#  Create footer content and append to footer
	#
	# @param onclick [Function] the function to yield on click
	# @param saveText [String] the text on the save button
	# @return [Array<jQuery.Elem>] the footer and the button element
	#
	_createFooter: ( removeText = '<i class="icon-trash icon-white"></i>', saveText = '<i class=" icon-ok icon-white"></i> Save' ) ->
		@_footer = $('<div class="modal-footer"></div>')

		save = () => @_save()
		@_saveButton = $('<button class="btn btn-primary">' + saveText + '</button>')
		@_saveButton.on('click', save ) if save?

		@_footer.append @_saveButton
		return [ @_footer, @_saveButton ]

	# Draws a certain property
	#
	# @param key [String] property
	# @param type [String] property type
	# @param params [Object] additional parameters
	# @return [jQuery.elem] elements
	#
	_drawProperty: ( key, type, params = {} ) ->
		value = ''
		return @_drawInput( type, key, value, params )		

	# Returns the properties of our module to be
	#
	_getModuleProperties: ( ) ->
		properties = @modulector::_getParameterMetaData().properties

		unless properties.parameters?
			properties.parameters = []

		properties.parameters.push('amount')
		return properties

	# Saves all changed properties to the module.
	#
	_save: ( ) ->
		@_trigger('module.creation.finished', @_parent, [@_changes])

	# Binds an on change event to a selectable input that sets the key
	#
	# @param key [String] property to set
	# @param selectable [jQuery.Elem] the selectable to set it on
	# 
	_bindOnSelectableChange: ( key, selectable ) ->
		((key) => 
			selectable.on('change', (event) => 
				value = event.target.value
				if ( selectable.closest('[data-multiple]').data( 'multiple' ) is on )
					@_changes[ key ] = [] unless @_changes[ key ]
					if event.target.checked
						@_changes[ key ].push value
					else
						@_changes[ key ] = _( @_changes[ key ] ).without value
				else
					@_changes[ key ] = value
			)
		) key

	# Will be called when the creation process of a module has started
	#
	# @param dummy [DummyModule] the dummy module for which to start the creation
	#
	onModuleCreationStarted: ( dummy ) ->
		if dummy is @_parent
			@setPosition()
			@_setSelected on
		else
			@_setSelected off

	# Will be called when the creation process of a module has aborted
	#
	# @param dummy [DummyModule] the dummy module for which to abort the creation
	#
	onModuleCreationAborted: ( dummy ) ->
		if dummy is @_parent
			@_setSelected off
			@clear()
			@draw()

	# Will be called when the creation process of a module has finished
	#
	# @param dummy [DummyModule] the dummy module for which to finish the creation
	#
	onModuleCreationFinished: ( dummy ) ->
		if dummy is @_parent
			@_setSelected off
			@clear()
			@draw()


