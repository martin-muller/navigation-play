import SwiftUI
import ComposableArchitecture
import TCAExtensions

/*
 Simple example of `StackReducer` implementation that appends destinations on the stack.
 */

public struct FeatureA: Reducer {
    @Reducer
    public enum Path {
        case screenOne(ScreenOneReducer)
        case screenTwo(ScreenTwoReducer)
    }
    
    public init() {}
    
    public var body: some StackReducerOf<Path> {
        Reduce { state, action in
            switch action {
                
            case let .element(id: _, action: .internal(internalAction)):
                switch internalAction {
                case let .screenOne(.delegate(delegate)):
                    switch delegate {
                    case let .goToScreenTwo(number):
                        state.append(.screenTwo(.init(number: number)))
                    }
                    return .none
                    
                case .screenTwo:
                    return .none
                    
                case .screenOne:
                    return .none
                }
                
            case .element:
                return .none
                
            case .popFrom:
                return .none
                
            case .push:
                return .none
            }
        }
    }
}

public struct FeatureAView: View {
    public init(store: StoreOf<FeatureA.Path>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<FeatureA.Path>
    
    public var body: some View {
        switch store.case {
        case .screenOne(let store):
            ScreenOne(store: store)
        case .screenTwo(let store):
            ScreenTwo(store: store)
        }
    }
}
