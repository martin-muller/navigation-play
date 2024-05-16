import SwiftUI
import ComposableArchitecture
import TCAExtensions

public struct FeatureBNavigator: Reducer {
    @Reducer
    public enum Path {
        case detail(Detail)
        case edit(Edit)
    }
    
    public init() {}
    
    public var body: some NavigatorReducerOf<Path> {
        Reduce { state, action in
            switch action {
            case let .element(id: _, action: .screen(screenAction)):
                switch screenAction {
                case let .detail(.delegate(delegate)):
                    switch delegate {
                    case let .openEdit(value: value):
                        state.append(.edit(.init(value: value)))
                        return .none
                    }
                    
                case let .edit(.delegate(delegate)):
                    switch delegate {
                    case .save:
                        let updatedMessage: String
                        if let lastId = state.ids.last,
                            case var .screen(.edit(edit)) = state[id: lastId] {
                            updatedMessage = edit.value
                        } else {
                            return .none
                        }
                        
                        _ = state.popLast()
                        
                        guard let lastId = state.ids.last else {
                            return .none
                        }
                        
                        if case var .screen(.detail(detail)) = state[id: lastId] {
                            detail.message = updatedMessage
                            state[id: lastId] = .screen(.detail(detail))
                        }
                        
                        return .send(.element(id: lastId, action: .detail(.receiveAction)))
                    }
                    
                case .detail:
                    return .none
                    
                case .edit:
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

public struct FeatureBView: View {
    public init(store: StoreOf<FeatureBNavigator.Path>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<FeatureBNavigator.Path>
    
    public var body: some View {
        switch store.case {
        case .detail(let store):
            DetailView(store: store)
        case .edit(let store):
            EditView(store: store)
        }
    }
}
