//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Martinez on 10/5/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct ScreenTwoReducer {
    @ObservableState
    public struct State {
        var number: Int
    }
    
    public enum Action {
        public enum Delegate {
            case openExternal
        }
        
        case goOutTapped
        case delegate(Delegate)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .goOutTapped:
                return .send(.delegate(.openExternal))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct ScreenTwo: View {
    let store: StoreOf<ScreenTwoReducer>
    
    var body: some View {
        VStack {
            Text("Passed \(store.number)")
            Button("go out") {
                store.send(.goOutTapped)
            }
        }
        .navigationTitle("A - Two")
    }
}

#Preview {
    ScreenTwo(store: .init(initialState: .init(number: 42), reducer: {
        ScreenTwoReducer()
    }))
}
