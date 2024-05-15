//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Martinez on 10/5/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct Edit {
    @ObservableState
    public struct State {
        var value: String
    }
    
    public enum Action {
        public enum Delegate {
            case save
        }
        
        case saveTapped
        case valueDidChange(String)
        case delegate(Delegate)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .valueDidChange(value):
                state.value = value
                
                return .none
                
            case .saveTapped:
                return .send(.delegate(.save))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct EditView: View {
    @Bindable var store: StoreOf<Edit>
    
    var body: some View {
        VStack {
            TextField("Value", text: $store.value.sending(\.valueDidChange))
            Button("Save") {
                store.send(.saveTapped)
            }
        }
        .navigationTitle("B - Edit")
    }
}
