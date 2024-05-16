import ComposableArchitecture

public typealias NavigatorReducerOf<P: Reducer> = Reducer<
    StackState<StackElement<P.State>>,
    StackAction<StackElement<P.State>, StackElement<P.Action>>
>

public enum StackElement<T> {
    case external(OpaqueStackElement)
    case screen(T)
}

public struct OpaqueStackElement {
    internal let element: Any
    
    internal init(element: Any) {
        self.element = element
    }
}

extension StackState {
    public mutating func append<T>(_ newElement: T) where Element == StackElement<T> {
        self.append(.screen(newElement))
    }
}

extension StackAction {
    public static func element<T>(id: StackElementID, action: T) -> Self where Action == StackElement<T> {
        .element(id: id, action: .screen(action))
    }
}

// TODO: How is the subscript going to work with enums...
extension StackState {
    public subscript<T>(id id: StackElementID) -> T? where Element == StackElement<T> {
//      _read { yield self._dictionary[id] }
//      _modify { yield &self._dictionary[id] }
//      set {
//        switch (self.ids.contains(id), newValue) {
//        case (true, _), (false, .some):
//          self._dictionary[id] = newValue
//        case (false, .none):
//            self._dictionary[id] = nil
//        }
//      }
        _read {
            switch self[id: id] {
            case let .screen(value):
                yield value
            case .external, .none:
                yield nil
            }
        }
        
        // TODO: How to mutate associated value in-place? do we need to?
//        _modify { }
        
        set {
            switch self[id: id] {
            case let .screen(value):
                if true {//newValue is value.Type {
                    self[id: id] = .screen(newValue!)
                } else {
                    // TODO: runtime diagnostics/test failure - should never happen
                    break
                }
            case .external, .none:
                // TODO: runtime diagnostics/test failure - should never happen
                break
            }
        }
    }
}

public struct NavigationPathReducer<
    IntegratorPathState,
    IntegratorPathAction: CasePathable,
    FeaturePathState,
    FeaturePathAction: CasePathable,
    FeatureNavigatorReducer: Reducer
>: Reducer where
FeatureNavigatorReducer.State == StackState<StackElement<FeaturePathState>>,
FeatureNavigatorReducer.Action == StackAction<StackElement<FeaturePathState>, StackElement<FeaturePathAction>>
{
    let statekp: AnyCasePath<IntegratorPathState, FeaturePathState>
    let actionkp: AnyCasePath<IntegratorPathAction, FeaturePathAction>
    let featureNavigatorReducer: FeatureNavigatorReducer
    
    public init(
        state: CaseKeyPath<IntegratorPathState, FeaturePathState>,
        action: CaseKeyPath<IntegratorPathAction, FeaturePathAction>,
        @ReducerBuilder<FeatureNavigatorReducer.State, FeatureNavigatorReducer.Action> featureNavigatorReducer: @escaping () -> FeatureNavigatorReducer
    ) {
        self.statekp = AnyCasePath(state)
        self.actionkp = AnyCasePath(action)
        self.featureNavigatorReducer = featureNavigatorReducer() // here or every time in the reduce?
    }
    
    public func reduce(
        into state: inout StackState<IntegratorPathState>,
        action: StackAction<IntegratorPathState, IntegratorPathAction>
    ) -> Effect<StackAction<IntegratorPathState, IntegratorPathAction>> {

        // Check the action is for the Feature and transform it
        guard let transformedAction: StackAction<StackElement<FeaturePathState>, StackElement<FeaturePathAction>> = switch action {
        case .element(id: let id, action: let featurePathAction):
            if let extracted = actionkp.extract(from: featurePathAction) {
                .element(id: id, action: .screen(extracted))
            } else {
                .element(id: id, action: .external(.init(element: featurePathAction)))
            }
            
        case let .popFrom(id: id):
            .popFrom(id: id)
        case let .push(id: id, state: state):
            if let extracted = statekp.extract(from: state) {
                .push(id: id, state: .screen(extracted))
            } else {
                .push(id: id, state: .external(.init(element: state)))
            }
            
        }
        else {
            return .none
        }
        
        // Transform the stackstate to a "view" for feature A
        var converted = StackState<StackElement<FeaturePathState>>()
        for (id, element) in zip(state.ids, state) {
            if let extracted = statekp.extract(from: element) {
                converted[id: id] = StackElement.screen(extracted)
            } else {
                converted[id: id] = StackElement.external(OpaqueStackElement(element: element))
            }
        }
                
        // Run feature a navigator
        let effects = featureNavigatorReducer.reduce(
            into: &converted,
            action: transformedAction
        )
        
        // Map back the now modified path array to the integrator "view" of it
        var new = StackState<IntegratorPathState>()
        for (id, element) in zip(converted.ids, converted) {
            switch element {
            case .external(let rootCase):
                new[id: id] = rootCase.element as! IntegratorPathState
            case .screen(let featureAElement):
                new[id: id] = statekp.embed(featureAElement)
            }
        }
        
        
        state = new
        
        let featureEffects: Effect<StackAction<IntegratorPathState, IntegratorPathAction>> = effects.map { (effect: StackAction<StackElement<FeaturePathState>, StackElement<FeaturePathAction>>) in
            
            switch effect {
            case let .element(id: id, action: featureAction):
                switch featureAction {
                case let .screen(screenAction):
                    return .element(id: id, action: actionkp.embed(screenAction))
                case let .external(externalAction):
                    return .element(id: id, action: externalAction.element as! IntegratorPathAction)
                }
                
            case let .popFrom(id: id):
                return .popFrom(id: id)
            case let .push(id: id, state: featureState):
                switch featureState {
                case let .screen(screenState):
                    return .push(id: id, state: statekp.embed(screenState))
                case let .external(externalState):
                    return .push(id: id, state: externalState.element as! IntegratorPathState)
                }
                
            }
        }

        return featureEffects
    }
}
