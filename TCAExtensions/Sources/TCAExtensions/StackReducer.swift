import ComposableArchitecture
import XCTestDynamicOverlay

/// Wraps elements in context-aware `StackState`
public enum StackElement<T> {
    /// Element unavailable in the current context
    case external(OpaqueStackElement)
    /// Element available in the current context
    case `internal`(T)
}

/// Erases external stack element type
public struct OpaqueStackElement {
    let element: Any
    
    init(element: Any) {
        self.element = element
    }
}

extension StackAction {
    /// An action sent to the associated stack element at a given identifier.
    public static func element<T>(id: StackElementID, action: T) -> Self where Action == StackElement<T> {
        .element(id: id, action: .internal(action))
    }
}

extension StackState {
    /// Adds an element wrapped in `internal` to the end of the collection.
    public mutating func append<T>(_ newElement: T) where Element == StackElement<T> {
        self.append(.internal(newElement))
    }
}

/// Accesses the value associated with the given id for reading and writing.
///
/// Allows operations only on internal elements, operations on external elements will result in test failure.
extension StackState {
    public subscript<T>(id id: StackElementID) -> T? where Element == StackElement<T> {
        _read {
            switch self[id: id] {
            case let .internal(value):
                yield value
            case .external, .none:
                yield nil
            }
        }
        
        _modify {
            switch self[id: id] {
            case let .internal(value):
                var copy: T? = value
                yield &copy
                if let copy {
                    self[id: id] = .internal(copy)
                }
            case .external:
                var copy: T? = nil
                yield &copy
                XCTFail("Modifying external element is not allowed")
                
            case .none:
                var copy: T? = nil
                yield &copy
            }
        }
        
        set {
            switch self[id: id] {
            case let .internal(value):
                self[id: id] = if let newValue {
                    .internal(newValue)
                } else {
                    nil
                }
            case .external:
                XCTFail("Setting external elements is not allowed")
                break
                
            case .none:
                break
            }
        }
    }
}

/// Convenience for constraining ``StackReducer``'s `Child`
public typealias StackReducerOf<P: Reducer> = Reducer<
    StackState<StackElement<P.State>>,
    StackAction<StackElement<P.State>, StackElement<P.Action>>
>

/// Reducer operating on specific cases of `StackState` and `StackAction`
public struct StackReducer<
    ParentState,
    ParentAction: CasePathable,
    ChildElementState,
    ChildElementAction: CasePathable,
    Child: Reducer
>: Reducer where
Child.State == StackState<StackElement<ChildElementState>>,
Child.Action == StackAction<StackElement<ChildElementState>, StackElement<ChildElementAction>>
{
    @usableFromInline
    let toChildElementState: AnyCasePath<ParentState, ChildElementState>
    
    @usableFromInline
    let toChildElementAction: AnyCasePath<ParentAction, ChildElementAction>
    
    @usableFromInline
    let child: Child
    
    @inlinable
    public init(
        state toChildElementState: CaseKeyPath<ParentState, ChildElementState>,
        action toChildElementAction: CaseKeyPath<ParentAction, ChildElementAction>,
        @ReducerBuilder<Child.State, Child.Action> child: @escaping () -> Child
    ) {
        self.toChildElementState = AnyCasePath(toChildElementState)
        self.toChildElementAction = AnyCasePath(toChildElementAction)
        self.child = child()
    }
    
    // TODO: internal access control of OpaqueStackElement prohibits this function from being inlinable, we can bypass by adding usableFromInline internal init that's called by public init. eg. property can stay internal but init will be public, we can also annotate the type as frozen
    //    @inlinable
    public func reduce(
        into state: inout StackState<ParentState>,
        action: StackAction<ParentState, ParentAction>
    ) -> Effect<StackAction<ParentState, ParentAction>> {
        // Map parent state and action to child state and action
        
        let childAction: Child.Action = switch action {
        case .element(id: let id, action: let elementAction):
            if let extracted = toChildElementAction.extract(from: elementAction) {
                .element(id: id, action: .internal(extracted))
            } else {
                .element(id: id, action: .external(.init(element: elementAction)))
            }
            
        case let .popFrom(id: id):
                .popFrom(id: id)
            
        case let .push(id: id, state: state):
            if let extracted = toChildElementState.extract(from: state) {
                .push(id: id, state: .internal(extracted))
            } else {
                .push(id: id, state: .external(.init(element: state)))
            }
        }
        
        var childState = Child.State()
        for (id, element) in zip(state.ids, state) {
            if let extracted = toChildElementState.extract(from: element) {
                childState[id: id] = .internal(extracted)
            } else {
                childState[id: id] = .external(.init(element: element))
            }
        }
        
        // Run child reducer
        let childEffects = child.reduce(
            into: &childState,
            action: childAction
        )
        
        // Map child state and action to parent state and action
        
        var parentState = State()
        for (id, element) in zip(childState.ids, childState) {
            switch element {
            case .external(let rootCase):
                parentState[id: id] = rootCase.element as! ParentState
            case .internal(let internalElement):
                parentState[id: id] = toChildElementState.embed(internalElement)
            }
        }
        
        let parentEffects: Effect<Action> = childEffects.map { effect in
            switch effect {
            case let .element(id: id, action: elementAction):
                switch elementAction {
                case let .internal(internalAction):
                    return .element(id: id, action: toChildElementAction.embed(internalAction))
                case let .external(externalAction):
                    return .element(id: id, action: externalAction.element as! ParentAction)
                }
                
            case let .popFrom(id: id):
                return .popFrom(id: id)
            case let .push(id: id, state: featureState):
                switch featureState {
                case let .internal(internalState):
                    return .push(id: id, state: toChildElementState.embed(internalState))
                case let .external(externalState):
                    return .push(id: id, state: externalState.element as! ParentState)
                }
            }
        }
        
        state = parentState
        
        return parentEffects
    }
}

extension Reducer {
    /// Provides opportunity to run `StackReducers`
    public func forEach<
        DestinationState: CaseReducerState,
        DestinationAction,
        StackReducer: Reducer
    >(
        _ state: WritableKeyPath<State, StackState<DestinationState>>,
        action: CaseKeyPath<Action, StackAction<DestinationState, DestinationAction>>,
        @ReducerBuilder<StackState<DestinationState>, StackAction<DestinationState, DestinationAction>> navigation: () -> StackReducer
    ) -> some ReducerOf<Self> where DestinationState.StateReducer.Action == DestinationAction,
                                    StackReducer.Action == StackAction<DestinationState, DestinationAction>,
                                    StackReducer.State == StackState<DestinationState>
    {
        CombineReducers {
            self.forEach(state, action: action) {
                DestinationState.StateReducer.body
            }
            Scope(state: state, action: action) {
                navigation()
            }
        }
    }
}
