class Cell

	# The constructor for the cell
	#
	constructor: ( params = {}, start = 0 ) ->
		@_creation = Date.now()
		@_modules = []
		@_substrates = {}
		
		starts = {}
		starts[ params.name ? "cell" ] = start
		module = new Module( 
			{ 
				k: params.k ? 1
				consume: params.consume ? "p_int"
				lipid: params.lipid ? "lipid"
				protein: params.protein ? "protein"
				name: params.name ? "cell"
			},
			( t, substrates ) -> 
			
				results = {}
								
				# Gracefull fallback if props are not apparent
				if ( @_test( substrates, @consume ) )
					lipid = substrates[@lipid] ? 1
					protein = substrates[@lipid] ? 1
					mu = substrates[@consume] * substrates[@lipid] * substrates[@protein]
				
				if ( mu and @_test( substrates, @name ) )
					
					results[@name] = mu * substrates[@name]
					results[@consume] = -mu * substrates[@consume]
					
					if ( @_test( substrates, @lipid ) )
						results[@lipid] = -mu * substrates[@lipid]
					if ( @_test( substrates, @lipid ) )
						results[@protein] = -mu * substrates[@protein]
					
				return results
				
			, starts
		)
		
		Object.defineProperty( @, 'module',
			get: ->
				return module
		)
		
		Object.seal @
		@add module
	
	# Add module to cell
	#
	# @param [Module] module module to add to this cell
	# @returns [self] chainable instance
	#
	add: ( module ) ->
		@_modules.push module
		return this
		
	# Add substrate to cell
	#
	# @param [String] substrate substrate to add
	# @param [Integer] amount amount of substrate to add
	# @returns [self] chainable instance
	#
	add_substrate: ( substrate, amount ) ->
		@_substrates[ substrate ] = amount
		return this
		
	# Remove module from cell
	#
	# @param [Module] module module to remove from this cell
	# @returns [self] chainable instance
	#
	remove: ( module ) ->
		@_modules.splice( @_modules.indexOf module, 1 ) #TODO: update to use underscore without
		return this
		
	# Removes this substrate from cell
	#
	# @param [String] substrate substrate to remove from this cell
	# @returns [self] chainable instance
	#
	remove_substrate: ( substrate ) ->
		delete @_substrates[ substrate ]
		return this
		
	# Checks if this cell has a module
	#
	# @param [Module] module the module to check
	# @returns [Boolean] true if the module is included
	#
	has: ( module ) ->
		# TODO: ? check module type instead of object ref
		return @_modules.indexOf( module ) isnt -1
	
	# Returns the amount of substrate in this cell
	# @param string substrate substrate to check
	# @returns int amount of substrate
	amount_of: ( substrate ) ->
		return @_substrates[ substrate ]
	
		
	# Runs this cell
	#
	# @param [Integer] timespan the time it should run for
	# @returns [self] chainable instance
	#
	run : ( timespan ) ->
		
		substrates = {}
		variables = [ ]
		values = [ ]
						
		# We would like to get all the variables in all the equations, so
		# that's what we are going to do. Then we can insert the value indices
		# into the equations.
			
		for module in @_modules
			for substrate, value of module.substrates
				variables.push substrate
				values.push value
			
		for substrate, value of @_substrates
			index = _(variables).indexOf( substrate ) 
			if ( index is -1 )
				variables.push substrate
				values.push value
			else
				values[index] += value

		# Create the mapping from variable to value index
		mapping = { }
		for i, variable of variables
			mapping[variable] = parseInt i
			
		map = ( values ) => 
			variables = { }
			for variable, i of mapping
				variables[ variable ] = values[ i ]
			return variables
			
		console.log mapping
		return
		
		# The step function for this module
		#
		# @param [Integer] t the current time
		# @param [Array] v the current value array
		# @returns [Array] the delta values	
		#
		step = ( t, v ) =>
		
			results = [ ]
			variables = [ ]
			
			# All dt are 0, so that when a variable was NOT processed, the
			# value remains the same
			for variable, index of mapping
				results[ index ] = 0
				
			# All the substrates are at LEAST 0, so here we lower bound the
			# values. Because of interpolation and float precision, substrates
			# might deteriorate to extreme values when they don't change anymore.
			v = _(v).map (value) -> 
				return if value < 0 then 0 else value
				
			# Get those substrates named
			mapped = map v
				
			# Run all the equations
			for module in @_modules
				module_results = module.step( t, mapped )
				for variable, result of module_results
					current = results[ mapping[ variable ] ] ? 0
					results[ mapping[ variable ] ] = current + result
								
			return results
			
		# Run the ODE from 0...timespan with starting values and step function
		sol = numeric.dopri( 0, timespan, values, step )
		
		# Return the system results
		return { results: sol, map: mapping }
	
	# Visualizes this cell
	#
	# @param [Integer] duration A duration for the simulation.
	# @param [Object] container A container for the graphs.
	# @param [Integer] dt the step value
	# @returns [Object] Returns the graphs
	#
	# options { dt: 1, decimals: 5, 
	#
	visualize: ( duration, container, options = { } ) ->
		
		cell_run = @run duration
		results = cell_run.results
		mapping = cell_run.map
		
		dt = options.dt ? 1
		decimals = options.decimals ? 5
		rounder = Math.pow( 10, decimals )
		
		# Get the interpolation for a fixed timestep instead of the adaptive timestep
		# generated by the ODE. This should be fairly fast, since the values all 
		# already there ( ymid and f )
		interpolation = []
		for time in [ 0 .. duration ] by dt
			interpolation[ time ] = results.at time;
 
		graphs = options.graphs ? { }
		graph_options = { dt : dt }
		if ( options.graph )
			graph_options = _( options.graph[ key ] ? options.graph ).extend( graph_options  ) 
			
		# Draw all the substrates
		for key, value of mapping
		
			dataset = []
			if ( !graphs[ key ] )
				graphs[ key ] = new Graph( key, graph_options ) 
			
			# Push all the values, but round for float rounding errors
			for time in [ 0 .. duration ] by dt
				dataset.push( Math.round( interpolation[ time ][ value ] * rounder ) / rounder )
			
			graphs[ key ].addData( dataset, graph_options )
				.render(container)

		# Return graphs
		return graphs

	# The properties
	Object.defineProperties @prototype,
		creation: 
			get : -> @_creation
		

# Makes this available globally. Use require later, but this will work for now.
(exports ? this).Cell = Cell
