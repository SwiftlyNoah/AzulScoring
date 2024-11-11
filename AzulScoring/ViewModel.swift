//
//  ViewModel.swift
//  AzulScoring
//
//  Created by Noah Brauner on 3/27/22.
//

import SwiftUI

class SquaresViewModel: ObservableObject {
    @Published var turns: [Turn] = turnsStartingArray {
        didSet {
            DatabaseManager.shared.updateSelf(turns: turns)
            updateScores()
            updateBonuses()
        }
    }
    @Published var totalScore: Int = 0
    
    @Published var completeRows: Int = 0
    @Published var completeColumns: Int = 0
    @Published var completeTypes: Int = 0
    
    var scoreWithBonuses: Int {
        totalScore + completeRows * 2 + completeColumns * 7 + completeTypes * 10
    }
    
    let db = DatabaseManager.shared
    
    static let turnsStartingArray = [
        Turn(squares: [
            [
                Square(),
                Square(),
                Square(),
                Square(),
                Square()
            ],
            [
                Square(),
                Square(),
                Square(),
                Square(),
                Square()
            ],
            [
                Square(),
                Square(),
                Square(),
                Square(),
                Square()
            ],
            [
                Square(),
                Square(),
                Square(),
                Square(),
                Square()
            ],
            [
                Square(),
                Square(),
                Square(),
                Square(),
                Square()
            ]
        ]
            )
    ]
    
    public func place(index: (Int, Int)) {
        if (turns[turns.count-1].squares[index.0][index.1].placed &&  turns[turns.count-1].squares[index.0][index.1].new) || !turns[turns.count-1].squares[index.0][index.1].placed {
            turns[turns.count-1].squares[index.0][index.1].place()
        }
    }
    
    fileprivate func updateScores() {
        totalScore = turns.map({ $0.score }).reduce(0, +)
    }
    
    fileprivate func updateBonuses() {
        completeRows = 0
        completeColumns = 0
        completeTypes = 0
        
        for i in 0...4 {
            let row = turns[turns.count - 1].squares[i]
            
            for j in 0...4 {
                let square = row[j]
                if !square.placed {
                    break
                }
                else if j == 4 {
                    completeRows += 1
                }
            }
        }
        
        for i in 0...4 {
            let column = turns[turns.count - 1].squares.map { $0[i] }
            
            for j in 0...4 {
                let square = column[j]
                if !square.placed {
                    break
                }
                else if j == 4 {
                    completeColumns += 1
                }
            }
        }
        
        var allPatterns = ["Blue", "Yellow", "Red", "Black", "Flower"]
        
        for i in 0...5 {
            for j in 0...5 {
                let square = turns[turns.count - 1].squares[i][j]
                if !square.placed {
                    if let index = allPatterns.firstIndex(of: Square.getColor(x: i, y: j)) {
                        allPatterns.remove(at: index)
                    }
                }
            }
        }
        
        completeTypes = allPatterns.count
    }
    
    public func nextTurn() {
        var oldTurn = turns[turns.count-1]
        oldTurn.squares.indices.forEach({ index1 in
            oldTurn.squares[index1].indices.forEach({ index2 in
                oldTurn.squares[index1][index2].new = false
            })
        })
        turns.append(oldTurn)
    }
    
    public func deleteTurn() {
        if turns.count == 1 {
            turns = Self.turnsStartingArray
        }
        else {
            turns.removeLast()
            db.deleteTurn(turnNumber: turns.count)
        }
    }
}
