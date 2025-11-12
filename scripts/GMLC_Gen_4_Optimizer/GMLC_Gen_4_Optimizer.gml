#region Optimizer.gml
	#region Optimizer Module
	/*
	Purpose: To refine the AST for better performance during interpretation.
	
	Methods:
	
	optimize(ast): Entry function that takes an AST and returns an optimized AST.
	constantFolding(ast): Traverses the AST and evaluates expressions that can be determined at compile-time.
	deadCodeElimination(ast): Removes parts of the AST that do not affect the program outcome, such as unreachable code.
	*/
	#endregion
	function GMLC_Gen_4_Optimizer(_env) constructor  {
		env = _env;
		
		//init variables:
		
		ast = undefined;
		nodeStack = [];
		finished = false;
		optimization_occured = false; //used so all optimizers can register if a change has occured and we should re attempt optimizers
		
		static initialize = function(_ast) {
			ast = _ast;
			nodeStack = [];  // Stack to keep track of nodes to visit
			array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
			finished = !array_length(nodeStack);
			currentNode = undefined;
		};
		
		static cleanup = function() {
		
		}
		
		static parseAll = function() {
			while (!finished) {
				nextNode();
			}
			return ast;
		}
		
		static nextNode = function() {
			if (!array_length(nodeStack)) {
				
				//re push everything all over again and continue optimizing
				if (optimization_occured) {
					array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
				}
				else {
					finished = true;
					return;
				}
			}
		
		    // Get current node from the stack
			var currentNode = array_pop(nodeStack);
			
			//skip nodes from optimization
			while (currentNode.node.skipOptimization) {
				var currentNode = array_pop(nodeStack);
			}
			
			// Process children first (post-order traversal)
			if (currentNode.node.visited == false) {
				currentNode.node.visited = true;
				
				array_push(nodeStack, currentNode);
				
				// Push current node back onto stack to process after children
				currentNode.node.push_children_to_node_stack(nodeStack);
			}
			else {
				// Process the current node as all children have been processed
				var _node = optimize(currentNode);
				_node.visited = false;
				
				if (currentNode.parent == undefined) {
					//the entire tree has been optimized and we are at the top most "Program" node
					if (array_length(nodeStack)) {
						throw_gmlc_error($"We still have nodes in the nodeStack, we shouldnt be finished")
					}
					
					ast = _node;
					
					//re push everything all over again and continue optimizing
					if (optimization_occured) {
						optimization_occured = false;
						array_push(nodeStack, {node: ast, parent: undefined, key: undefined, index: undefined}) // Start with the root node
					}
					else {
						finished = true;
						return;
					}
				}
				else {
					//reset the visit so the next module can make use of it
					if (currentNode.index != undefined) {
						currentNode.parent[$ currentNode.key][currentNode.index] = _node;
					}
					else {
						currentNode.parent[$ currentNode.key] = _node;
					}
				}
				
			}
		};
		
		static optimize = function(_node_data) {
			var _start_node = undefined;
			
			//keep optimizing until there are no optimizers which change the node.
			while (_node_data.node != _start_node) {
				var _start_node = _node_data.node;
				
				_node_data.node = constantFolding(_node_data);
				_node_data.node = constantPropagation(_node_data);
				_node_data.node = eliminateDeadCode(_node_data);
				_node_data.node = strengthReduction(_node_data);
				//_node_data.node = optimizeAlternateFunctions(_node_data);
				
				if (_start_node != _node_data.node) {
					optimization_occured = true
					//log("Input Node :: ", json(__reStruct(_start_node)))
					//log("Output Node :: ", json(__reStruct(_node_data.node)))
				}
			}
			
			return _node_data.node;
		};
		
		#region Optimizers
		
		#region JSDocs
		/// @function    constantPropagation(_node)
		/// @description Propagates constants throughout the code, replacing occurrences of a constant with its value.
		/// @param       {ASTNode}    _astNode    The AST node containing constants.
		/// @return      {ASTNode}    _astNode    The optimized AST node with constants propagated.
		#endregion
		static constantPropagation = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
			
			var _found = false;
			var _constant_data = {
				identifier : undefined,
				value : undefined,
				known : false, //we only know it when we find this same node inside the parent
				assignment_node : undefined,
			}
			
			if (_node.type == __GMLC_NodeType.VariableDeclaration)
			&& (_node.expr.type == __GMLC_NodeType.Literal)
			&& (_node.expr.scope == ScopeType.LOCAL)
			{
				_found = true;
				
				_constant_data.identifier = _node.identifier;
				_constant_data.value = _node.expr.value;
				_constant_data.known = false; //we only know it when we find this same node inside the parent
				_constant_data.assignment_node = _node;
			}
			if (_node.type == __GMLC_NodeType.AssignmentExpression)
			&& (_node.operator == "=")
			&& (_node.left.type == __GMLC_NodeType.Identifier)
			&& (_node.right.type == __GMLC_NodeType.Literal)
			{
				_found = true;
				
				_constant_data.identifier = _node.left.value;
				_constant_data.value = _node.right.value;
				_constant_data.known = false; //we only know it when we find this same node inside the parent
				_constant_data.assignment_node = _node;
			}
			
			if (_found) {
				
				switch (_parent.type) {
					case __GMLC_NodeType.DoUntilStatement:
			        case __GMLC_NodeType.ForStatement:
					case __GMLC_NodeType.RepeatStatement:
					case __GMLC_NodeType.WhileStatement:
					case __GMLC_NodeType.WithStatement:
					case __GMLC_NodeType.UpdateExpression: {
						//break propigation
						return _node;
						
						/// Note: Block statements inside of these will still get propigated, this just mostly avoids conditionals and initializers
						
					break;}
				}
				
				var _should_be_propagating = false; // set to true when we found our assignment op
				
				var _children = _parent.get_children(true);
				var _i = 0; repeat(array_length(_children))
				{
					var _child_data = _children[_i];
					var _child = _child_data.node;
					
					if (_should_be_propagating)
					{
						var _return = __propagateConstants(_child, _constant_data)
						if (is_instanceof(_return, ASTNode))
						{
							if (_child_data.index == undefined)
							{
								_parent[$ _child_data.key] = _return;
							}
							else {
								_parent[$ _child_data.key][_child_data.index] = _return;
							}
						}
						else if (_return == true) {
							break;
						}
					}
					
					//if we found the node which assigns, we can begin propagating.
					if (_child == _node) {
						log($"Optimizer :: constantPropagation :: Has found Constant `{_constant_data.identifier}` in line ({_node.line}) `{_node.lineString}`")
						_should_be_propagating = true;
					}
					
				_i++}
			}
			
		    return _node;  // Return the updated AST node
		}
		static __propagateConstants = function(_node, _constant_data) {
			//log($"__propagateConstants :: typeof(_node) == {typeof(_node)} :: instanceof(_node) == {instanceof(_node)}")
			
			var _constant_identifier = _constant_data.identifier;
			var _constant_value = _constant_data.value;
			var _constant_known = _constant_data.known;
			var _constant_node  = _constant_data.assignment_node;
			
			switch (_node.type) {
		        //breakers
				case __GMLC_NodeType.AssignmentExpression: {
		            var _left = _node.left;
		            var _right = _node.right;
						
					if (_left.type == __GMLC_NodeType.Identifier) {
						//propigate to children incase the expression contains it's self and could be constant folded on additional optimize steps
						// example :: xx = xx + 1;
						var _return = __propagateConstants(_node.right, _constant_data)
						if (is_instanceof(_return, ASTNode))
						{
							_node.right = _return;
						}
						
					}
					
					if (_left.type == __GMLC_NodeType.Identifier)
					&& (_left.value == _constant_identifier)
					{
						if (_right.type == __GMLC_NodeType.Literal)
						{
							if (_node.operator == "=")
							{
								//this actually should already be handled as the parser is bottom up, and propigation is top down, so instead we are just going to return
								
								/// should break propagation
								return true;
							}
							else
							{
								switch (_node.operator) {
									case "+=":  _constant_value +=  _right.value break;
									case "-=":  _constant_value -=  _right.value break;
									case "*=":  _constant_value *=  _right.value break;
									case "/=":  _constant_value /=  _right.value break;
									case "^=":  _constant_value ^=  _right.value break;
									case "&=":  _constant_value &=  _right.value break;
									case "|=":  _constant_value |=  _right.value break;
									case "%=":  _constant_value %=  _right.value break;
									case "??=": _constant_value ??= _right.value break;
									default: {
										throw $"[ERROR] Optimizer :: constantPropagation :: Unexpected operator in line ({_node.line}) `{_node.lineString}`"
									}
								}
								
								log($"Optimizer :: constantPropagation :: Could us literal assignment of `{_constant_value}` in line ({_node.line}) `{_node.lineString}`")
								
								_constant_data.value = _constant_value
								var _new_ast = new ASTAssignmentExpression("=", _left, new ASTLiteral(_constant_value, _node.right.line, _node.right.lineString), _node.line, _node.lineString)
								_new_ast.skipOptimization = _node.skipOptimization;
								return _new_ast;
							}
						}
						
						/// should break propagation
						return true;
					}
					
					// safe to keep propagating
					return false;
					
		        break;}
                case __GMLC_NodeType.VariableDeclaration: {
					
					//propigate to children incase the expression contains it's self and could be constant folded on additional optimize steps
					// example :: var xx = xx + 1;
					var _return = __propagateConstants(_node.expr, _constant_data)
					if (is_instanceof(_return, ASTNode))
					{
						_node.expr = _return;
					}
					
					if (_node.identifier == _constant_identifier)
					{
						/// should break propagation
						return true;
					}
					
					// safe to continue propagation
					return false;
					
		        break;}
                
				case __GMLC_NodeType.Identifier: {
		            
					if (_node.value == _constant_identifier) {
						log($"Optimizer :: constantPropagation :: Could replace `{_constant_identifier}` with `{_constant_data.value}` in line ({_node.line}) `{_node.lineString}`")
						return new ASTLiteral(_constant_data.value, _node.line, _node.lineString, _node.name);
					}
					
					//safe to continue
					return false;
					
		        break;}
                
				case __GMLC_NodeType.IfStatement:
		        case __GMLC_NodeType.SwitchStatement:
		        case __GMLC_NodeType.TryStatement: {
					if (__hasIdentifierAssignment(_node, _constant_data)) {
						//if it has an assignment to it, then we know we can not ensure safety of constant propigation any longer, and its time to back out.
						//we could how wever still propigate top down until we run into the assignment 
					}
					else {
						//get stack of children bottom up
						return __propagateToChildren(_node, _constant_data)
					}
				break;}
		        
				case __GMLC_NodeType.DoUntilStatement: {
					if (__hasIdentifierAssignment(_node, _constant_data)) {
						//break propigation
						return true;
					}
					//this will return false
					return __propagateToChildren(_node, _constant_data)
				break;}
		        case __GMLC_NodeType.ForStatement:{
					if (__hasIdentifierAssignment(_node, _constant_data)) {
						//we can still safely propaget to the variable declaration
						var _return = __propagateConstants(_node.initialization, _constant_data)
						if (is_instanceof(_return, ASTNode))
						{
							_node.initialization = _return;
						}
						
						//break propigation
						return true;
					}
					//this will return false
					return __propagateToChildren(_node, _constant_data)
				break;}
		        case __GMLC_NodeType.RepeatStatement:{
					if (__hasIdentifierAssignment(_node.codeBlock, _constant_data)) {
						//we can still safely propagate to the condition
						var _return = __propagateConstants(_node.condition, _constant_data)
						if (is_instanceof(_return, ASTNode))
						{
							_node.condition = _return;
						}
						
						//break propigation
						return true;
					}
					//this will return false
					return __propagateToChildren(_node, _constant_data)
				break;}
		        case __GMLC_NodeType.WhileStatement:{
					if (__hasIdentifierAssignment(_node.codeBlock, _constant_data)) {
						//there is no additional propagation possible
						
						//break propigation
						return true;
					}
					//this will return false
					return __propagateToChildren(_node, _constant_data)
				break;}
		        case __GMLC_NodeType.WithStatement:{
					if (__hasIdentifierAssignment(_node.codeBlock, _constant_data)) {
						//we can still safely propagate to the condition
						var _return = __propagateConstants(_node.condition, _constant_data)
						if (is_instanceof(_return, ASTNode))
						{
							_node.condition = _return;
						}
						
						//break propigation
						return true;
					}
					//this will return false
					return __propagateToChildren(_node, _constant_data)
				break;}
		        
				case __GMLC_NodeType.UpdateExpression: {
					if (_node.expr.type == __GMLC_NodeType.Identifier) {
						_constant_data.value += (_node.operator == "++") ? 1 : -1;
						return false;
					}
					else {
						return __propagateToChildren(_node.expr, _constant_data)
					}
				break;}
		    }
			
			return __propagateToChildren(_node, _constant_data)
		}
		static __propagateToChildren = function(_node, _constant_data) {
			//log($"__propagateToChildren :: typeof(_node) == {typeof(_node)} :: instanceof(_node) == {instanceof(_node)}")
			
			var _children = _node.get_children(true)
			var _i=0; repeat(array_length(_children)) {
				var _child_data = _children[_i]
				var _child_node = _child_data.node
				var _return = __propagateConstants(_child_node, _constant_data)
				
				if (is_instanceof(_return, ASTNode))
				{
					if (_child_data.index == undefined)
					{
						_node[$ _child_data.key] = _return;
					}
					else {
						_node[$ _child_data.key][_child_data.index] = _return;
					}
				}
				else if (_return == true) {
					//inform parent we are done propigating
					return true;
				}
			_i++}
			
			//it is still safe to continue propigating
			return false;
		}
		static __hasIdentifierAssignment = function(_node, _constant_data, _break_on_first=true) {
			var _count = 0;
			
			if (_node.type == __GMLC_NodeType.AssignmentExpression)
			&& (_node.left.type == __GMLC_NodeType.Identifier)
			&& (_node.left.value == _constant_data.identifier) {
				return true;
			}
			
			if (_node.type == __GMLC_NodeType.VariableDeclaration)
			&& (_node.identifier == _constant_data.identifier) {
				return true;
			}
			
			if (_node.type == __GMLC_NodeType.UpdateExpression)
			&& (_node.expr.type == __GMLC_NodeType.Identifier) {
				return true;
			}
			
			var _children = _node.get_children(true);
			var _i=0; repeat(array_length(_children)) {
				
				if (__hasIdentifierAssignment(_children[_i].node, _constant_data)) {
					if (_break_on_first) {
						return true;
					}
					else {
						_count += 1;
					}
					
				}
				
			_i++}
			
			return _count;
		}
		
		#region JSDocs
		/// @function    constantFolding(_node)
		/// @description Performs constant folding by evaluating constant expressions at compile-time (e.g., `2 + 2` becomes `4`).
		/// @param       {ASTNode}    _astNode    The AST node representing the expression.
		/// @return      {ASTNode}    _astNode    The AST node with folded constants.
		#endregion
		static constantFolding = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
		    
			
			switch (_node.type) {
				case __GMLC_NodeType.BinaryExpression:{
					
					// double litteral
					if (_node.left.type == __GMLC_NodeType.Literal && _node.right.type == __GMLC_NodeType.Literal) {
					    // Both _nodes are literals, perform constant folding
					    switch (_node.operator) {
							case "|":{
								var _value = _node.left.value | _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "^":{
								var _value = _node.left.value ^ _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "&":{
								var _value = _node.left.value & _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "==":{
								var _value = _node.left.value == _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "!=":{
								var _value = _node.left.value != _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "<":{
								var _value = _node.left.value < _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "<=":{
								var _value = _node.left.value <= _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case ">":{
								var _value = _node.left.value > _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case ">=":{
								var _value = _node.left.value >= _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "<<":{
								var _value = _node.left.value << _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case ">>":{
								var _value = _node.left.value >> _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "+":{
								var _value = _node.left.value + _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "-":{
								var _value = _node.left.value - _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "*":{
								var _value = _node.left.value * _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "/":{
								var _value = _node.left.value / _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "mod":{
								if (_node.right.value == 0) {
									throw_gmlc_error($"DoMod :: Divide by zero")
								}
								var _value = _node.left.value mod _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "div":{
								if (_node.right.value == 0) {
									throw_gmlc_error($"DoRem :: Divide by zero")
								}
								var _value = _node.left.value div _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
						}
					}
					
					//single literal
					else if (_node.left.type == __GMLC_NodeType.Literal || _node.right.type == __GMLC_NodeType.Literal) {
					    switch (_node.operator) {
							case "+":{
								//adding zero
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (_node.left.value == 0) {
									log($"Optimizer :: constantFolding :: Could remove addtion of `0` in line ({_node.line}) `{_node.lineString}`")
									return _node.right;
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 0) {
									log($"Optimizer :: constantFolding :: Could remove addtion of `0` in line ({_node.line}) `{_node.lineString}`")
									return _node.left;
								}
								//adding infinity
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.left.value)) {
									var _value = _node.left.value
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.right.value)) {
									var _value = _node.right.value
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								
							break;}
							case "-":{
								//subtracting zero
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (_node.left.value == 0) {
									log($"Optimizer :: constantFolding :: Could remove subtraction of `0` in line ({_node.line}) `{_node.lineString}`")
									return _node.right;
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 0) {
									log($"Optimizer :: constantFolding :: Could remove subtraction of `0` in line ({_node.line}) `{_node.lineString}`")
									return _node.left;
								}
								//subtracting infinity
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.left.value)) {
									var _value = -_node.left.value
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.right.value)) {
									var _value = -_node.right.value
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								
							break;}
							case "*":{
								//multiply by zero
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (_node.left.value == 0) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 0) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								//multiply by 1
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (_node.left.value == 1) {
									log($"Optimizer :: constantFolding :: Could remove unneeded multiplication of `1` in line ({_node.line}) `{_node.lineString}`")
									return _node.right;
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 1) {
									log($"Optimizer :: constantFolding :: Could remove unneeded multiplication of `1` in line ({_node.line}) `{_node.lineString}`")
									return _node.left;
								}
								
							break;}
							case "/":{
								//infinity
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.left.value)) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (is_infinity(_node.right.value)) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								//divide by zero
								if (_node.left.type  == __GMLC_NodeType.Literal)
								&& (_node.left.value == 0) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 0) {
									var _value = 0;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								//divide by 1
								if (_node.right.type  == __GMLC_NodeType.Literal)
								&& (_node.right.value == 1) {
									log($"Optimizer :: constantFolding :: Could remove unneeded division of `1` in line ({_node.line}) `{_node.lineString}`")
									return _node.left;
								}
								
							break;}
							
					    }
					}
					
				break;}
				case __GMLC_NodeType.LogicalExpression:{
					if (_node.left.type == __GMLC_NodeType.Literal && _node.right.type == __GMLC_NodeType.Literal) {
					    switch (_node.operator) {
							case "||":{
								var _value = _node.left.value || _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "&&":{
								var _value = _node.left.value && _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "^^":{
								var _value = _node.left.value ^^ _node.right.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
					    }
					}
					else if (_node.left.type == __GMLC_NodeType.Literal || _node.right.type == __GMLC_NodeType.Literal) {
					    switch (_node.operator) {
							case "||":{
								if (_node.left.type  == __GMLC_NodeType.Literal && _node.left.value ) {
									var _value = true
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type == __GMLC_NodeType.Literal && _node.right.value) {
									var _value = true
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
							break;}
							case "&&":{
								if (_node.left.type  == __GMLC_NodeType.Literal && !_node.left.value ) {
									var _value = false;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
								if (_node.right.type == __GMLC_NodeType.Literal && !_node.right.value) {
									var _value = false;
									log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
									return new ASTLiteral(_value, _node.line, _node.lineString);
								}
							break;}
					    }
					}
				break;}
				case __GMLC_NodeType.NullishExpression:{
					if (_node.left.type == __GMLC_NodeType.Literal) {
						if (_node.left.value == undefined) {
							log($"Optimizer :: constantFolding :: Could collapse nullish express to right side only in line ({_node.line}) `{_node.lineString}`")
							return _node.right;
						}
						else {
							log($"Optimizer :: constantFolding :: Could collapse nullish express to left side only in line ({_node.line}) `{_node.lineString}`")
							return _node.left;
						}
					}
				break;}
				case __GMLC_NodeType.UnaryExpression:{
					if (_node.expr.type == __GMLC_NodeType.Literal) {
					    switch (_node.operator) {
							case "!":{
								var _value = !_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "+":{
								var _value = +_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "-":{
								var _value = -_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "~":{
								var _value = ~_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "++":{
								var _value = ++_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
							case "--":{
								var _value = --_node.expr.value
								log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
								return new ASTLiteral(_value, _node.line, _node.lineString);
							break;}
					    }
					}
				break;}
				case __GMLC_NodeType.ConditionalExpression:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
					    // If the condition is a literal, determine which branch to take
						if (_node.condition.value) {
							log($"Optimizer :: constantFolding :: Could collapse ternary expression to right side in line ({_node.line}) `{_node.lineString}`")
							return _node.trueExpr;
						}
						else {
							log($"Optimizer :: constantFolding :: Could collapse ternary expression to right side in line ({_node.line}) `{_node.lineString}`")
							return _node.falseExpr;
						}
					}
				break;}
				case __GMLC_NodeType.ExpressionStatement:{
					if (_node.expr.type == __GMLC_NodeType.Literal) {
					    // If the condition is a literal, determine which branch to take
						throw "\n\nWhy is this running, we shouldnt have any expression statements anymore\n\n"
						return new ASTLiteral(_node.expr.value, _node.line, _node.lineString);
					}
				break;}
				case __GMLC_NodeType.CallExpression:{
					if (_node.callee.type == __GMLC_NodeType.Literal) {
						switch (_node.callee.value) {
							case abs:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for abs is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(abs, _node);
							break;}
							case angle_difference:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for angle_difference is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(angle_difference, _node);
							break;}
							case ansi_char:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for ansi_char is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(ansi_char, _node);
							break;}
							case arccos:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for arccos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(arccos, _node);
							break;}
							case arcsin:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for arcsin is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(arcsin, _node);
							break;}
							case arctan:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for arctan is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(arctan, _node);
							break;}
							case arctan2:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for arctan2 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(arctan2, _node);
							break;}
							case buffer_sizeof:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for buffer_sizeof is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(buffer_sizeof, _node);
							break;}
							case ceil:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for ceil is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(ceil, _node);
							break;}
							case chr:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for chr is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(chr, _node);
							break;}
							case choose:{
								if (array_length(_node.arguments) == 1) {
									return _node.arguments[0];
								}
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								if (array_length(_node.arguments) == 1) {
									return new ASTLiteral(0, _node.line, _node.lineString, "choose()");
								}
								
							break;}
							case clamp:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for clamp is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(clamp, _node);
							break;}
							case color_get_blue:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_blue is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_blue, _node);
							break;}
							case color_get_green:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_green is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_green, _node);
							break;}
							case color_get_red:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_red is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_red, _node);
							break;}
							case colour_get_blue:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_blue is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_blue, _node);
							break;}
							case colour_get_green:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_green is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_green, _node);
							break;}
							case colour_get_red:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_red is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_red, _node);
							break;}
							case cos:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for cos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(cos, _node);
							break;}
							case darccos:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for darccos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(darccos, _node);
							break;}
							case darcsin:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for darcsin is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(darcsin, _node);
							break;}
							case darctan:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for darctan is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(darctan, _node);
							break;}
							case darctan2:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for darctan2 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(darctan2, _node);
							break;}
							case dcos:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for dcos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dcos, _node);
							break;}
							case degtorad:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for degtorad is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(degtorad, _node);
							break;}
							case dot_product:{
								if (array_length(_node.arguments) != 4) {
									throw_gmlc_error($"Argument count for dot_product is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dot_product, _node);
							break;}
							case dot_product_3d:{
								if (array_length(_node.arguments) != 6) {
									throw_gmlc_error($"Argument count for dot_product_3d is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dot_product_3d, _node);
							break;}
							case dot_product_3d_normalised:{
								if (array_length(_node.arguments) != 6) {
									throw_gmlc_error($"Argument count for dot_product_3d_normalised is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dot_product_3d_normalised, _node);
							break;}
							case dot_product_normalised:{
								if (array_length(_node.arguments) != 4) {
									throw_gmlc_error($"Argument count for dot_product_normalised is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dot_product_normalised, _node);
							break;}
							case dsin:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for dsin is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dsin, _node);
							break;}
							case dtan:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for dtan is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(dtan, _node);
							break;}
							case exp:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for exp is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(exp, _node);
							break;}
							case floor:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for floor is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(floor, _node);
							break;}
							case frac:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for frac is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(frac, _node);
							break;}
							case int64:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for int64 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(int64, _node);
							break;}
							case is_array:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_array is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_array, _node);
							break;}
							case is_bool:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_bool is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_bool, _node);
							break;}
							case is_callable:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_callable is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_callable, _node);
							break;}
							case is_handle:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_handle is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_handle, _node);
							break;}
							case is_infinity:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_infinity is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_infinity, _node);
							break;}
							case is_int32:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_int32 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_int32, _node);
							break;}
							case is_method:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_method is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_method, _node);
							break;}
							case is_nan:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_nan is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_nan, _node);
							break;}
							case is_numeric:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_numeric is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_numeric, _node);
							break;}
							case is_ptr:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_ptr is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_ptr, _node);
							break;}
							case is_string:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_string is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_string, _node);
							break;}
							case is_struct:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_struct is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_struct, _node);
							break;}
							case is_undefined:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for is_undefined is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(is_undefined, _node);
							break;}
							case lengthdir_x:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for lengthdir_x is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(lengthdir_x, _node);
							break;}
							case lengthdir_y:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for lengthdir_y is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(lengthdir_y, _node);
							break;}
							case lerp:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for lerp is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(lerp, _node);
							break;}
							case ln:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for ln is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(ln, _node);
							break;}
							case log10:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for log10 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(log10, _node);
							break;}
							case log2:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for log2 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(log2, _node);
							break;}
							case logn:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for logn is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(logn, _node);
							break;}
							case make_color_rgb:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for make_color_rgb is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(make_color_rgb, _node);
							break;}
							case make_colour_rgb:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for make_colour_rgb is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(make_colour_rgb, _node);
							break;}
							case max:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								//if (array_length(_node.arguments) < 1) {
								//	throw_gmlc_error($"Argument count for max is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								//}
								return __build_literal_from_function_call_constant_folding(max, _node);
							break;}
							case mean:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								//if (array_length(_node.arguments) < 1) {
								//	throw_gmlc_error($"Argument count for mean is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								//}
								return __build_literal_from_function_call_constant_folding(mean, _node);
							break;}
							case median:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								//if (array_length(_node.arguments) < 1) {
								//	throw_gmlc_error($"Argument count for median is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								//}
								return __build_literal_from_function_call_constant_folding(median, _node);
							break;}
							case min:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								//if (array_length(_node.arguments) < 1) {
								//	throw_gmlc_error($"Argument count for min is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								//}
								return __build_literal_from_function_call_constant_folding(min, _node);
							break;}
							case object_exists:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for object_exists is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(object_exists, _node);
							break;}
							case object_get_name:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for object_get_name is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(object_get_name, _node);
							break;}
							case object_get_parent:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for object_get_parent is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(object_get_parent, _node);
							break;}
							case object_get_physics:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for object_get_physics is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(object_get_physics, _node);
							break;}
							case object_is_ancestor:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for object_is_ancestor is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(object_is_ancestor, _node);
							break;}
							case ord:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for ord is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(ord, _node);
							break;}
							case os_get_config:{
								return __build_literal_from_function_call_constant_folding(os_get_config, _node);
							break;}
							case point_direction:{
								if (array_length(_node.arguments) != 4) {
									throw_gmlc_error($"Argument count for point_direction is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(point_direction, _node);
							break;}
							case point_distance:{
								if (array_length(_node.arguments) != 4) {
									throw_gmlc_error($"Argument count for point_distance is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(point_distance, _node);
							break;}
							case point_distance_3d:{
								if (array_length(_node.arguments) != 6) {
									throw_gmlc_error($"Argument count for point_distance_3d is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(point_distance_3d, _node);
							break;}
							case power:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for power is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(power, _node);
							break;}
							case radtodeg:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for radtodeg is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(radtodeg, _node);
							break;}
							case real:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for real is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(real, _node);
							break;}
							case round:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for round is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(round, _node);
							break;}
							case script_exists:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for script_exists is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(script_exists, _node);
							break;}
							case script_get_name:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for script_get_name is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(script_get_name, _node);
							break;}
							case sign:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for sign is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(sign, _node);
							break;}
							case sin:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for sin is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(sin, _node);
							break;}
							case sqr:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for sqr is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(sqr, _node);
							break;}
							case sqrt:{
								/// ==================================================
								/// NOTE:
								/// This is the only math operation that is affected by `math_set_epsilon`
								/// avoid optimizing this at compile time
								/// ==================================================
								return _node
							break;}
							case string_lower:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_lower is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_lower, _node);
							break;}
							case string_upper:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_upper is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_upper, _node);
							break;}
							case string_repeat:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_repeat is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_repeat, _node);
							break;}
							case tan:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for tan is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(tan, _node);
							break;}
						
							//organize these later....
						
							case code_is_compiled:{
								return __build_literal_from_function_call_constant_folding(code_is_compiled, _node);
							break;}
							case string_byte_length:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_byte_length is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_byte_length, _node);
							break;}
							case string_char_at:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_char_at is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_char_at, _node);
							break;}
							case string_concat_ext:{
								if (array_length(_node.arguments) < 1)
								|| (array_length(_node.arguments) > 3) {
									throw_gmlc_error($"Argument count for string_concat_ext is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_concat_ext, _node);
							break;}
							case string_copy:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_copy is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_copy, _node);
							break;}
							case string_count:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_count is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_count, _node);
							break;}
							case string_delete:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_delete is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_delete, _node);
							break;}
							case string_digits:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_digits is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_digits, _node);
							break;}
							case string_ends_with:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_ends_with is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_ends_with, _node);
							break;}
							case string_ext:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_ext is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_ext, _node);
							break;}
							case string_format:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_format is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_format, _node);
							break;}
							case string_hash_to_newline:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_hash_to_newline is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_hash_to_newline, _node);
							break;}
							case string_insert:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_insert is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_insert, _node);
							break;}
							case string_join_ext:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								if (array_length(_node.arguments) < 2) {
									return new ASTLiteral("", _node.line, _node.lineString, "string_join_ext()")
								}
								
								if (array_length(_node.arguments) < 2)
								|| (array_length(_node.arguments) > 4) {
									throw_gmlc_error($"Argument count for string_join_ext is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_join_ext, _node);
							break;}
							case string_last_pos:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_last_pos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_last_pos, _node);
							break;}
							case string_last_pos_ext:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_last_pos_ext is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_last_pos_ext, _node);
							break;}
							case string_length:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_length is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_length, _node);
							break;}
							case string_letters:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for string_letters is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_letters, _node);
							break;}
							case string_ord_at:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_ord_at is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_ord_at, _node);
							break;}
							case string_pos:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_pos is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_pos, _node);
							break;}
							case string_pos_ext:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_pos_ext is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_pos_ext, _node);
							break;}
							case string_replace:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_replace is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_replace, _node);
							break;}
							case string_replace_all:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_replace_all is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_replace_all, _node);
							break;}
							case string_set_byte_at:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for string_set_byte_at is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_set_byte_at, _node);
							break;}
							case string_starts_with:{
								if (array_length(_node.arguments) != 2) {
									throw_gmlc_error($"Argument count for string_starts_with is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_starts_with, _node);
							break;}
							case string_trim:{
								if (array_length(_node.arguments) < 1)
								|| (array_length(_node.arguments) > 2) {
									throw_gmlc_error($"Argument count for string_trim is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_trim, _node);
							break;}
							case string_trim_end:{
								if (array_length(_node.arguments) < 1)
								|| (array_length(_node.arguments) > 2) {
									throw_gmlc_error($"Argument count for string_trim_end is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_trim_end, _node);
							break;}
							case string_trim_start:{
								if (array_length(_node.arguments) < 1)
								|| (array_length(_node.arguments) > 2) {
									throw_gmlc_error($"Argument count for string_trim_start is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(string_trim_start, _node);
							break;}
							case md5_string_unicode:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for md5_string_unicode is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(md5_string_unicode, _node);
							break;}
							case md5_string_utf8:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for md5_string_utf8 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(md5_string_utf8, _node);
							break;}
							case color_get_hue:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_hue is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_hue, _node);
							break;}
							case colour_get_hue:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_hue is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_hue, _node);
							break;}
							case color_get_saturation:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_saturation is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_saturation, _node);
							break;}
							case colour_get_saturation:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_saturation is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_saturation, _node);
							break;}
							case color_get_value:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for color_get_value is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(color_get_value, _node);
							break;}
							case colour_get_value:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for colour_get_value is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(colour_get_value, _node);
							break;}
							case base64_encode:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for base64_encode is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(base64_encode, _node);
							break;}
							case base64_decode:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for base64_decode is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(base64_decode, _node);
							break;}
							case sha1_string_utf8:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for sha1_string_utf8 is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(sha1_string_utf8, _node);
							break;}
							case sha1_string_unicode:{
								if (array_length(_node.arguments) != 1) {
									throw_gmlc_error($"Argument count for sha1_string_unicode is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(sha1_string_unicode, _node);
							break;}
							case make_color_hsv:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for make_color_hsv is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(make_color_hsv, _node);
							break;}
							case make_colour_hsv:{
								if (array_length(_node.arguments) != 3) {
									throw_gmlc_error($"Argument count for make_colour_hsv is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
								return __build_literal_from_function_call_constant_folding(make_colour_hsv, _node);
							break;}
							
							
							//all of the ones above use the same code
							case string:{
								//Remove these if the request for change has been approved
								// This exists because of an oddity in the language
								/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8088
								if (array_length(_node.arguments) < 1) {
									/// Re add this if the oddity gets fixed
									//throw_gmlc_error($"Argument count for string is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
									
									//this is also an odd variable as its different depending on the situation
									/// https://github.com/YoYoGames/GameMaker-Bugs/issues/8090
									return new ASTLiteral("", _node.line, _node.lineString, "string()");
								}
								if (__argumentsAreLiteral(_node.arguments)) {
									return __build_literal_from_function_call_constant_folding(string, _node);
								}
								else if (_node.arguments[0].type == __GMLC_NodeType.Literal) {
									var _arr = _node.arguments;
									var _exec_arr = [_arr[0].value]; //the execution array
									var _new_arr = []; // the new arg array
									var _holder_index = 0;
									var _changed = false;
								
									var _i=1; repeat(array_length(_arr)-1) {
										var _sub_node = _arr[_i]
										if (_sub_node.type == __GMLC_NodeType.Literal) {
											_changed = true;
											array_push(_exec_arr, _sub_node.value);
										}
										else {
											array_push(_new_arr, _sub_node);
											array_push(_exec_arr, $"\{{_holder_index}\}");
											_holder_index++
										}
									_i+=1;}//end repeat loop
								
									if (_changed) {
										array_insert(_new_arr, 0, new ASTLiteral(script_execute_ext(string, _exec_arr), _node.line, _node.lineString))
										log($"Optimizer :: constantFolding :: Could use optimize `string` first argument to `{_new_arr[0].value}` in line ({_node.line}) `{_node.lineString}`")
										return new ASTCallExpression(_node.callee, _new_arr);
									}
								}
							break;}
							case string_concat:{
								if (array_length(_node.arguments) < 1) {
									throw_gmlc_error($"Argument count for string_concat is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
							
								if (__argumentsAreLiteral(_node.arguments)) {
									return __build_literal_from_function_call_constant_folding(string_concat, _node);
								}
								else {
									var _arr = _node.arguments;
									var _changed = false;
							
									var _i=0; repeat(array_length(_arr)-1) {
										if (_arr[_i].type == __GMLC_NodeType.Literal)
										&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
											_changed = true;
											
											var _value = string_concat(_arr[_i].value, _arr[_i+1].value);
											log($"Optimizer :: constantFolding :: Could use optimize a `string_concat` argument to `{_value}` in line ({_node.line}) `{_node.lineString}`")
											var _struct = new ASTLiteral(_value, _arr[_i].line, _arr[_i].lineString)
											
											array_delete(_arr, _i, 2)
											array_insert(_arr, _i, _struct);
											continue;
										}
									_i+=1;}//end repeat loop
								
									if (_changed) {
										return new ASTCallExpression(_node.callee, _arr, _node.line, _node.lineString);
									}
								}
							
							break;}
							case string_join:{
								if (array_length(_node.arguments) < 1) {
									throw_gmlc_error($"Argument count for string_join is incorrect!\nArgument Count : {array_length(_node.arguments)}\nline ({_node.line}) {_node.lineString}")
								}
							
								if (__argumentsAreLiteral(_node.arguments)) {
									return __build_literal_from_function_call_constant_folding(string_join, _node);
								}
								else if (_node.arguments[0].type == __GMLC_NodeType.Literal) { // delimiter is literal
									var _arr = _node.arguments;
									var _changed = false;
									
									var _i=1; repeat(array_length(_arr)-2) {
										
										if (_arr[_i].type == __GMLC_NodeType.Literal)
										&& (_arr[_i+1].type == __GMLC_NodeType.Literal) {
											_changed = true;
											
											var _value = string_join(_arr[0].value, _arr[_i].value, _arr[_i+1].value);
											log($"Optimizer :: constantFolding :: Could use optimize a `string_join` argument to `{_value}` in line ({_node.line}) `{_node.lineString}`")
											var _struct = new ASTLiteral(_value, _arr[_i].line, _arr[_i].lineString);
											
											array_delete(_arr, _i, 2)
											array_insert(_arr, _i, _struct);
											continue;
										}
										
									_i+=1;}//end repeat loop
								
									if (_changed) {
										return new ASTCallExpression(_node.callee, _arr);
									}
								}
							
							break;}
							
						}
						//end switch
					}
				break;}
				// Add more cases as needed for different _node types
			}
			
			return _node;
			
		}
		
		#region JSDocs
		/// @function    eliminateDeadCode(_node)
		/// @description Removes code that is never executed, such as code following a `return` or `break` statement.
		/// @param       {ASTNode}    _astNode    The AST node representing the block of code.
		/// @return      {ASTNode}    _astNode    The AST node with unreachable code removed.
		#endregion
		static eliminateDeadCode = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
		    
			switch (_node.type) {
				case __GMLC_NodeType.IfStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						if (_node.condition.value) {
							log($"Optimizer :: eliminateDeadCode :: Could optimize `if` statement to `true` block only in line ({_node.line}) `{_node.lineString}`")
							return _node.consequent;
						}
						else {
							if (_node.alternate != undefined) {
								log($"Optimizer :: eliminateDeadCode :: Could optimize `if` statement to `else` block only in line ({_node.line}) `{_node.lineString}`")
								return _node.alternate;
							}
							else {
								log($"Optimizer :: eliminateDeadCode :: Could remove `if` statement in line ({_node.line}) `{_node.lineString}`")
								return new ASTEmpty(_node.line, _node.lineString);
							}
						}
					}
				break;}
				case __GMLC_NodeType.ForStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						if (!_node.condition.value) {
							log($"Optimizer :: eliminateDeadCode :: Could optimize `for` by removing it entirely in line ({_node.line}) `{_node.lineString}`")
							return new ASTEmpty(_node.line, _node.lineString);
						}
					}
				break;}
				case __GMLC_NodeType.WhileStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						if (!_node.condition.value) {
							log($"Optimizer :: eliminateDeadCode :: Could optimize `while` by removing it entirely in line ({_node.line}) `{_node.lineString}`")
							return new ASTEmpty(_node.line, _node.lineString);
						}
					}
				break;}
				case __GMLC_NodeType.RepeatStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						if (!_node.condition.value) {
							log($"Optimizer :: eliminateDeadCode :: Could optimize `repeat` by removing it entirely in line ({_node.line}) `{_node.lineString}`")
							return new ASTEmpty(_node.line, _node.lineString);
						}
					}
				break;}
				case __GMLC_NodeType.DoUntilStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						
						/// There isnt really a way to optimizer this on the AST level, we can convert this into a breakable block statement on compile level, however if we want to re export as a string we dont want to mess with this on the AST optimization level.
						
						//if (_node.condition.value) {
						//	log($"Optimizer :: eliminateDeadCode :: Could optimize `do` by removing it entirely in line ({_node.line}) `{_node.lineString}`")
						//	return new ASTEmpty(_node.line, _node.lineString);
						//}
					}
				break;}
				case __GMLC_NodeType.WithStatement:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
						if (_node.condition.value == noone) {
							log($"Optimizer :: eliminateDeadCode :: Could optimize `with` by removing it entirely in line ({_node.line}) `{_node.lineString}`")
							return new ASTEmpty(_node.line, _node.lineString);
						}
					}
				break;}
				case __GMLC_NodeType.SwitchStatement:{
					if (_node.switchExpression.type == __GMLC_NodeType.Literal) {
						
						/// this was trash and doesnt account for inner statements breaking out, additionally it complicates break statements, and re exporting the code.
						
						//var _val = _node.switchExpression.value;
						//var _found_case = false;
						//var _found_break = false;
						//var _return = _node;
						
						//var _i=0; repeat(array_length(_node.cases)) {
						//	var _case = _node.cases[_i]
							
						//	if (_case.type == "CaseExpression" && _case.label == _val)
						//	|| (_case.type == "CaseDefault")
						//	{
						//		_found_case = true;
						//		_return = new ASTBlockStatement([], _node.line, _node.lineString);
						//		break;
						//	}
							
						//	if (_found_case) {
						//		var _arr = _case.codeBlock.statements;
						//		var _j=0; repeat(array_length(_arr)) {
						//			var _statement = _arr[_j]
						//			if (_statement.type == "BreakStatement") {
						//				_found_break = true;
						//				break;
						//			}
									
						//			array_push(_statements, _statement);
									
						//		_j+=1;}//end repeat loop
								
						//		if (_found_break) {
						//			break;
						//		}
								
						//	}
							
						//_i+=1;}//end repeat loop
						
						//return _return;
					}
				break;}
				case __GMLC_NodeType.ConditionalExpression:{
					if (_node.condition.type == __GMLC_NodeType.Literal) {
					    // If the condition is a literal, determine which branch to take
						log($"Optimizer :: eliminateDeadCode :: Could optimize ternary expression given a condition of {_node.condition.value} in line ({_node.line}) `{_node.lineString}`")
						return (_node.condition.value) ? _node.trueExpr : _node.falseExpr;
					}
				break;}
			}
			
			return _node;
		}
		
		#region JSDocs
		/// @function    strengthReduction(_astNode)
		/// @description Replaces existing functions with slightly optimized varients which prerform better for the specific task. IE: converting a value to a string is faster with `string_concat` then `string`, as `string` has several additional checks, and `string_concat` already converts a value to a string
		/// @param       {ASTNode}    _astNode    The AST node representing a small code block.
		/// @return      {ASTNode}    _astNode    The optimized AST node after peephole optimizations.
		#endregion
		static strengthReduction = function(_node_data) {
			var _node   = _node_data.node;
			var _parent = _node_data.parent;
			var _key    = _node_data.key;
			var _index  = _node_data.index;
			
			// Convert struct access using literals to hashed access
			//new ASTNode(Function, {value: currentToken.value, name: currentToken.name})
			if (_node.type == __GMLC_NodeType.CallExpression) {
				switch (_node.callee.value) {
					case struct_get:
					case variable_struct_get:{
						// Convert struct access using literals to hashed access
						var _arg = _node.arguments[1];
						if (_arg.type == __GMLC_NodeType.Literal) 
						&& (typeof(_arg.value) == "string") {
							return new ASTNode(__GMLC_NodeType.CallExpression, {
								callee: new ASTLiteral(struct_get_from_hash, _node.line, _node.lineString, "struct_get_from_hash"),
								arguments: [
									_node.arguments[0],
									new ASTNode(__GMLC_NodeType.Literal, {value: variable_get_hash(_arg.value), scope: ScopeType.CONST})
								]
							});
						}
					break;}
						
					case struct_set:
					case variable_struct_set:{
						// Convert struct access using literals to hashed access
						var _arg = _node.arguments[1];
						if (_arg.type == __GMLC_NodeType.Literal) 
						&& (typeof(_arg.value) == "string") {
							return new ASTNode(__GMLC_NodeType.CallExpression, {
								callee: new ASTLiteral(struct_set_from_hash, _node.line, _node.lineString, "struct_set_from_hash"),
								arguments: [
									_node.arguments[0],
									new ASTNode(__GMLC_NodeType.Literal, {value: variable_get_hash(_arg.value), scope: ScopeType.CONST}),
									_node.arguments[2]
								]
							});
						}
					break;}
					
					case string:{
						// String with single argument is faster to use string_concat
						if (array_length(_node.arguments) == 1) {
							var _arg = _node.arguments[0]
							if (_arg.type != __GMLC_NodeType.Literal) {
								return new ASTNode(__GMLC_NodeType.CallExpression, {
									callee: new ASTLiteral(string_concat, _node.line, _node.lineString, "string_concat"),
									arguments: _node.arguments
								});
							}
						}
					break;}
				}
			}
			
			return _node;
		};
		
		
		
		
		#region JSDocs
		/// @function    removeRedundantTypeChecks(_node)
		/// @description This function removes redundant type checks from code. If we can determine with certainty that a variable will never be of a particular type, 
		///              we remove the unnecessary check (e.g., `is_string()` when it’s known the value cannot be a string).
		/// @param       {ASTNode}    _astNode    The AST node to check for type redundancies.
		/// @return      {ASTNode}    _astNode    The optimized AST node without unnecessary type checks.
		#endregion
		static removeRedundantTypeChecks = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST tree to identify any type checks like is_string(), is_method(), etc.
		    // 2. Analyze the variable or expression to determine if the type check is needed.
		    // 3. Remove the check if it's redundant. 
		    //    Example: 
		    //      Before: if (is_string(value)) { ... }
		    //      After: Removed if it's known value is never a string.
		    // 4. Return the optimized AST node.
		}

		#region JSDocs
		/// @function    simplifyIncrementExpressions(_node)
		/// @description Simplifies expressions like `arr[0] = arr[0] + 1` to `arr[0]++` to save cycles and improve readability.
		/// @param       {ASTNode}    _astNode    The AST node containing an expression to simplify.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified increment/decrement expressions.
		#endregion
		static simplifyIncrementExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Look for patterns where a value is being assigned to itself with an increment/decrement operation.
		    // 2. Replace the expression with the more concise increment (++) or decrement (--) operator.
		    //    Example:
		    //      Before: arr[0] = arr[0] + 1;
		    //      After: arr[0]++;
		    // 3. Handle both prefix and postfix cases, ensuring side effects are preserved.
		    // 4. Return the updated AST node.
		}

		#region JSDocs
		/// @function    optimizeInfinityExpressions(_node)
		/// @description Optimizes mathematical expressions involving `infinity`, as the results can be deduced without computation. 
		///              For example, any multiplication by infinity results in infinity, and division by infinity results in 0.
		/// @param       {ASTNode}    _astNode    The AST node containing math expressions to optimize.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified infinity operations.
		#endregion
		static optimizeInfinityExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST to locate any expressions containing the keyword 'infinity'.
		    // 2. Apply the following transformations:
		    //    - Any number multiplied by infinity is infinity.
		    //    - Any number divided by infinity is 0.
		    //    Example:
		    //      Before: result = 5 * infinity;
		    //      After: result = infinity;
		    // 3. Ensure the changes reflect in the bytecode for execution efficiency.
		    // 4. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    inlineSimpleFunctions(_node)
		/// @description Inlines simple functions into the code when they are short and frequently called to avoid the overhead of function calls.
		/// @param       {ASTNode}    _astNode    The AST node representing the function call.
		/// @return      {ASTNode}    _astNode    The optimized AST node with inlined function bodies.
		#endregion
		static inlineSimpleFunctions = function(_node) {
		    // Pseudocode:
		    // 1. Identify functions that meet the criteria for inlining (e.g., short, no side effects, frequent calls).
		    // 2. Replace the function call in the AST with the body of the function.
		    //    Example:
		    //      Before: result = simpleFunction();
		    //      After: result = <inlined function body>;
		    // 3. Ensure that inlining respects variable scope and context.
		    // 4. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    simplifyConditionalExpressions(_node)
		/// @description Simplifies conditional expressions. For instance, `if (true && condition)` becomes `if (condition)`.
		/// @param       {ASTNode}    _astNode    The AST node representing the conditional expression.
		/// @return      {ASTNode}    _astNode    The simplified AST node.
		#endregion
		static simplifyConditionalExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the AST and locate conditional expressions (`if`, `else`, `ternary operators`).
		    // 2. Simplify expressions where possible, removing constant conditions.
		    //    Example:
		    //      Before: if (true && condition)
		    //      After: if (condition)
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    improveLoopIterations(_node)
		/// @description Optimizes loop iterations by removing unnecessary computations and using efficient constructs.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with improved iteration performance.
		#endregion
		static improveLoopIterations = function(_node) {
		    // Pseudocode:
		    // 1. Traverse loops (`for`, `repeat`, `while`, `doUntil`) and check for opportunities to improve iteration efficiency.
		    // 2. Ensure minimal work is done inside the loop, e.g., precompute values outside the loop.
		    //    Example: move constant expressions or variables that don't change outside the loop.
		    //    Before: for (var i = 0; i < expensiveCalculation(); i++) { ... }
		    //    After: var limit = expensiveCalculation(); for (var i = 0; i < limit; i++) { ... }
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    loopInvariantCodeMotion(_node)
		/// @description Hoists loop-invariant code outside loops to reduce unnecessary computations during iterations.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with loop-invariant code moved out.
		#endregion
		static loopInvariantCodeMotion = function(_node) {
		    // Pseudocode:
		    // 1. Traverse the loop and identify expressions or variables that don't change during loop execution.
		    // 2. Move these expressions outside the loop to avoid repeated calculations.
		    //    Example:
		    //      Before: for (var i = 0; i < n; i++) { var x = constantCalculation(); ... }
		    //      After: var x = constantCalculation(); for (var i = 0; i < n; i++) { ... }
		    // 3. Return the updated AST node.
		}
		
		#region JSDocs
		/// @function    shortCircuitBooleanEvaluation(_node)
		/// @description Optimizes boolean expressions by short-circuiting them. If the result of a boolean expression is already known, the rest is not evaluated.
		/// @param       {ASTNode}    _astNode    The AST node representing a boolean expression.
		/// @return      {ASTNode}    _astNode    The optimized AST node with short-circuiting applied.
		#endregion
		static shortCircuitBooleanEvaluation = function(_node) {
		    // Pseudocode:
		    // 1. Identify boolean expressions involving `&&` or `||`.
		    // 2. Apply short-circuiting logic. If the first operand determines the result, remove the rest of the expression.
		    //    Example:
		    //      Before: if (expensiveFunction() && true) { ... }
		    //      After: if (expensiveFunction()) { ... }
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    removeNullEmptyCheck(_node)
		/// @description Simplifies checks for null or empty values. For instance, replace `if (thing != undefined)` with `if (thing)`.
		/// @param       {ASTNode}    _astNode    The AST node representing a null/empty check.
		/// @return      {ASTNode}    _astNode    The optimized AST node with simplified checks.
		#endregion
		static removeNullEmptyCheck = function(_node) {
		    // Pseudocode:
		    // 1. Identify checks for null, empty, or undefined values.
		    // 2. Simplify them where appropriate. 
		    //    Example:
		    //      Before: if (thing != undefined)
		    //      After: if (thing)
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    foldLogicalExpressions(_node)
		/// @description Optimizes logical expressions like `a && false` by folding them to `false` at compile time.
		/// @param       {ASTNode}    _astNode    The AST node representing a logical expression.
		/// @return      {ASTNode}    _astNode    The optimized AST node with logical expressions folded.
		#endregion
		static foldLogicalExpressions = function(_node) {
		    // Pseudocode:
		    // 1. Identify logical expressions where one of the operands makes the result obvious.
		    //    Example:
		    //      Before: a && false
		    //      After: false
		    // 2. Apply folding for both `&&` and `||` cases.
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    foldAssignments(_node)
		/// @description Optimizes assignments like `a = a + 1` to use more efficient operators like `a++`.
		/// @param       {ASTNode}    _astNode    The AST node representing an assignment.
		/// @return      {ASTNode}    _astNode    The optimized AST node with folded assignments.
		#endregion
		static foldAssignments = function(_node) {
		    // Pseudocode:
		    // 1. Identify assignment patterns like `a = a + 1` or `b = b * a`.
		    // 2. Replace them with more efficient operators:
		    //    - `a = a + 1` becomes `a++`
		    //    - `b = b * a` becomes `b *= a`
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    loopUnrolling(_node)
		/// @description Unrolls loops if the number of iterations is small and known at compile time, improving performance by reducing loop overhead.
		/// @param       {ASTNode}    _astNode    The AST node representing a loop.
		/// @return      {ASTNode}    _astNode    The optimized AST node with loop unrolling applied.
		#endregion
		static loopUnrolling = function(_node) {
		    // Pseudocode:
		    // 1. Check if the loop has a small, fixed iteration count.
		    // 2. Unroll the loop by manually duplicating the body of the loop.
		    //    Example:
		    //      Before: for (var i = 0; i < 4; i++) { ... }
		    //      After: (body of the loop repeated 4 times)
		    // 3. Ensure that the total expression size remains within reasonable limits (e.g., 1024 bytes).
		    // 4. Return the unrolled AST node.
		}
		
		#region JSDocs
		/// @function    commonSubexpressionElimination(_astNode)
		/// @description Eliminates repeated subexpressions by calculating them once and reusing the result.
		/// @param       {ASTNode}    _astNode    The AST node containing common subexpressions.
		/// @return      {ASTNode}    _astNode    The optimized AST node with common subexpressions eliminated.
		#endregion
		static commonSubexpressionElimination = function(_node) {
		    // Pseudocode:
		    // 1. Identify repeated expressions within the same scope.
		    //    Example:
		    //      Before: c = (a - b) + 1; d = (a - b) + 2;
		    //      After: var _temp = (a - b); c = _temp + 1; d = _temp + 2;
		    // 2. Store the result of the first evaluation and reuse it for subsequent calculations.
		    // 3. Return the optimized AST node.
		}
		
		#region JSDocs
		/// @function    peepholeOptimizations(_astNode)
		/// @description Performs small, localized optimizations that can be found by looking at a few adjacent instructions.
		/// @param       {ASTNode}    _astNode    The AST node representing a small code block.
		/// @return      {ASTNode}    _astNode    The optimized AST node after peephole optimizations.
		#endregion
		static peepholeOptimizations = function(_node) {
		    // Pseudocode:
		    // 1. Look for small, low-level optimizations by examining adjacent instructions or expressions.
		    // 2. Examples include:
		    //    - Removing redundant loads and stores.
		    //    - Merging adjacent operations (e.g., a = b; b = a can be optimized away).
		    // 3. Return the optimized AST node.
		}
		
		
		//array_push(parserSteps, constantFolding);
		
		//array_push(parserSteps, removeRedundantTypeChecks);
		//array_push(parserSteps, simplifyIncrementExpressions);
		//array_push(parserSteps, optimizeInfinityExpressions);
		//array_push(parserSteps, inlineSimpleFunctions);
		//array_push(parserSteps, simplifyConditionalExpressions);
		//array_push(parserSteps, optimizeVariableScope);
		//array_push(parserSteps, optimizePickOneFunctions);
		//array_push(parserSteps, improveLoopIterations);
		//array_push(parserSteps, loopInvariantCodeMotion);
		//array_push(parserSteps, constantPropagation);
		//array_push(parserSteps, shortCircuitBooleanEvaluation);
		//array_push(parserSteps, removeNullEmptyCheck);
		//array_push(parserSteps, foldLogicalExpressions);
		//array_push(parserSteps, foldAssignments);
		//array_push(parserSteps, strengthReduction);
		//array_push(parserSteps, loopUnrolling);
		//array_push(parserSteps, commonSubexpressionElimination);
		//array_push(parserSteps, peepholeOptimizations);
		//array_push(parserSteps, optimizeAlternateFunctions);
		
		
		
		#endregion
		
		#region Helper Functions
		static __argumentsAreLiteral = function(_arguments) {
			var _i=0; repeat(array_length(_arguments)) {
				if (_arguments[_i].type != __GMLC_NodeType.Literal) {
					return false;
				}
			_i+=1;}//end repeat loop
			return true;
		}
		
		static __build_literal_from_function_call_constant_folding = function(_script, _node) {
			if (!__argumentsAreLiteral(_node.arguments)) return _node;
			
			//remap the arguments
			var _arr = _node.arguments;
			var _new_arr = [];
			var _i=0; repeat(array_length(_arr)) {
				_new_arr[_i] = _arr[_i].value;
			_i+=1;}//end repeat loop
			
			try {
				var _value = script_execute_ext(_script, _new_arr)
			}
			catch (err) {
				throw_gmlc_error($"{err.message}\nline ({_node.line}) {_node.lineString}")
			}
			
			log($"Optimizer :: constantFolding :: Could use literal of `{_value}` in line ({_node.line}) `{_node.lineString}`")
			return new ASTLiteral(_value, _node.line, _node.lineString);
		}
		
		#endregion
	}
#endregion


