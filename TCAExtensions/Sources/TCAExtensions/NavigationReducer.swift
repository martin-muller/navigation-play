import ComposableArchitecture

public typealias NavigatorReducerOf<P: Reducer> = Reducer<
    StackState<StackElement<P.State>>,
    StackActionOf<P>
>

public enum StackElement<T> {
    case external(OpaqueStackElement) // we could even make an opaque wrapper that doesn't even let you get the element. but what we can't do is to not have the assocaited value.
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
FeatureNavigatorReducer.Action == StackAction<FeaturePathState, FeaturePathAction>
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
    
    public func reduce(into state: inout StackState<IntegratorPathState>, action:  StackAction<IntegratorPathState, IntegratorPathAction>) -> Effect< StackAction<IntegratorPathState, IntegratorPathAction>> {

        // Check the action is for the Feature and transform it
        guard let transformedAction: StackAction<FeaturePathState, FeaturePathAction> =  switch action {
        case .element(id: let id, action: let featurePathAction):
            if let extracted = actionkp.extract(from: featurePathAction) {
                .element(id: id, action: extracted)
            } else {
                nil
            }
            
            // Should we forward these 2 too? makes sense a feature wants to listen for other features changes? or maybe just fw its own but then there is no points since is the same code taht is doing the action.
        case .popFrom(id: _):
            nil
        case .push(id: _, state: _):
            nil
        }
        else {
            return .none
        }
        print(transformedAction)
        
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
        
        let featureEffects: Effect<StackAction<IntegratorPathState, IntegratorPathAction>> = effects.map { (effect: StackAction<FeaturePathState, FeaturePathAction>) in
            
            switch effect {
            case let .element(id: id, action: featureAction):
                return .element(id: id, action: actionkp.embed(featureAction))
            case let .popFrom(id: id):
                return .popFrom(id: id)
            case let .push(id: id, state: featureState):
                return .push(id: id, state: statekp.embed(featureState))
            }
        }

        return featureEffects
    }
}
