//
//  File.swift
//  
//
//  Created by Martin Muller on 15.05.2024.
//

import Foundation
import ComposableArchitecture

public protocol PathableReducer: Reducer, CaseReducer {
    associatedtype NavigaationReducer: Reducer
    static func navigationReducer() -> NavigaationReducer
}

extension Reducer {
    public func forEach<DestinationState: CaseReducerState, DestinationAction, Navigator: Reducer>(
        _ state: WritableKeyPath<State, StackState<DestinationState>>,
        action: CaseKeyPath<Action, StackAction<DestinationState, DestinationAction>>,
        @ReducerBuilder<StackState<DestinationState>, StackAction<DestinationState, DestinationAction>> navigation: () -> Navigator
    ) -> some ReducerOf<Self> where DestinationState.StateReducer.Action == DestinationAction,
                                    Navigator.Action == StackAction<DestinationState, DestinationAction>,
                                    Navigator.State == StackState<DestinationState>
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
    
    public func forEach<DestinationState: CaseReducerState, DestinationAction, PathReducer: PathableReducer>(
        _ state: WritableKeyPath<State, StackState<DestinationState>>,
        action: CaseKeyPath<Action, StackAction<DestinationState, DestinationAction>>,
        for pathReducer: PathReducer.Type
    ) -> some ReducerOf<Self> where DestinationState.StateReducer.Action == DestinationAction,
    
    StackAction<DestinationState, DestinationAction> == PathReducer.NavigaationReducer.Action,
    StackState<DestinationState> == PathReducer.NavigaationReducer.State
    
    {
        CombineReducers {
            self.forEach(state, action: action) {
                DestinationState.StateReducer.body
            }
            Scope(state: state, action: action) {
                pathReducer.navigationReducer()
            }
        }
    }
}
