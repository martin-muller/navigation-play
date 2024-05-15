import SwiftUI
import ComposableArchitecture

@Reducer
public struct ScreenOneReducer {
    @ObservableState
    public struct State {
        var message = "Hello World"
        
        public init() {}
    }
    
    public enum Action {
        @CasePathable
        public enum Delegate {
            case goToScreenTwo(Int)
        }
        
        case buttonOneTapped
        case buttonTwoTaped
        case delegate(Delegate)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .buttonOneTapped:
                return .send(.delegate(.goToScreenTwo(1)))
            case .buttonTwoTaped:
                return .send(.delegate(.goToScreenTwo(2)))
            case .delegate:
                return .none
            }
        }
    }
}

struct ScreenOne: View {
    let store: StoreOf<ScreenOneReducer>
    
    var body: some View {
        VStack {
            Text("\(store.message)")
            HStack {
                Button("One") {
                    store.send(.buttonOneTapped)
                }
                Button("Two") {
                    store.send(.buttonTwoTaped)
                }
            }
        }
        .navigationTitle("A - One")
    }
}

#Preview {
    ScreenOne(store: .init(initialState: .init(), reducer: {
        ScreenOneReducer()
    }))
}
