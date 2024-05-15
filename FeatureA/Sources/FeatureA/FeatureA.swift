import SwiftUI
import ComposableArchitecture
import TCAExtensions

// could this be useufl somehow? it links the Navigator reducer to its Path reducer. 🤔
public protocol NavigatorReducer: Reducer {
    associatedtype Path: Reducer & CaseReducer
}

public struct FeatureANavigator: NavigatorReducer {
    @Reducer
    public enum Path {
        case screenOne(ScreenOneReducer)
        case screenTwo(ScreenTwoReducer)
    }
    
    public init() {}
    
    public var body: some NavigatorReducerOf<Self, Path> {
        Reduce { state, action in
            switch action {
                
            case let .element(id: _, action: .screenOne(.delegate(delegate))):
                switch delegate {
                case let .goToScreenTwo(number):
                    state.append(.screenTwo(.init(number: number)))
                }
//                state.append(.external(22)) // can't do it cause OpaqueStackElement
                return .none
            
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
    public init(store: StoreOf<FeatureANavigator.Path>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<FeatureANavigator.Path>
    
    public var body: some View {
        switch store.case {
        case .screenOne(let store):
            ScreenOne(store: store)
        case .screenTwo(let store):
            ScreenTwo(store: store)
        }
    }
}
