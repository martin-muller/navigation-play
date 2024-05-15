//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Martinez on 10/5/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct Detail {
    @ObservableState
    public struct State {
        var message = "Hello World"
        var receivedAction = false
        
        public init() {}
    }
    
    public enum Action {
        @CasePathable
        public enum Delegate {
            case openEdit(value: String)
        }
        
        case editTapped
        case receiveAction
        
        case delegate(Delegate)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .editTapped:
                return .send(.delegate(.openEdit(value: state.message)))
                
            case .receiveAction:
                state.receivedAction = true
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

struct DetailView: View {
    let store: StoreOf<Detail>
    
    var body: some View {
        VStack {
            Text("Received action: \(store.receivedAction)")
            
            Text("value: \(store.message)")
            
            HStack {
                Button("Edit") {
                    store.send(.editTapped)
                }
            }
        }
        .navigationTitle("B - Detail")
    }
}
