//
//  ContentView.swift
//  AzulScoring
//
//  Created by Noah Brauner on 3/25/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = SquaresViewModel()
    @State var viewingTurn = 0
    
    var body: some View {
        VStack {
            headerView
            .padding(.top, 10)
            
            Divider()
            
            ZStack {
                Color(red: 242/255, green: 230/255, blue: 217/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 5) {
                    ForEach(0...4, id: \.self) { rowId in
                        HStack(spacing: 5) {
                            ForEach(0...4, id: \.self) { colId in
                                let square = vm.turns[viewingTurn].squares[rowId][colId]
                                Image(Square.getColor(x: rowId, y: colId) + (square.placed ? "Full" : "Empty"))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (screen.width - 30) / 5, height: (screen.width - 30) / 5)
                                    .onTapGesture {
                                        if viewingTurn == vm.turns.count - 1 {
                                            vm.place(index: (rowId, colId))
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: (screen.width - 30) / 50)
                                            .stroke(Color.green, lineWidth: square.new ? 4 : 0)
                                    )
                                    .opacity(square.placed ? 1 : 0.6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(width: screen.width, height: screen.width)
            .cornerRadius(10)
            
            Spacer()
            
            Divider()
            
            VStack {
                Stepper("Penalty: \(vm.turns[vm.turns.count-1].penalty) Points", value: $vm.turns[vm.turns.count-1].penalty, in: 0...14)
                
                HStack(spacing: 10) {
                    Button(action: {
                        vm.nextTurn()
                        viewingTurn += 1
                    }) {
                        ZStack {
                            Color.green
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Text("Next Turn")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(height: 50)
                    }
                    
                    Button(action: {
                        if viewingTurn != 0 {
                            viewingTurn -= 1
                        }
                        vm.deleteTurn()
                    }) {
                        ZStack {
                            Color.red
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Text("Delete Turn")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .onAppear {
            DatabaseManager.shared.fetchGame { players in
                print(players)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 5) {
            HStack {
                Button(action: {
                    viewingTurn -= 1
                }) {
                    Image(systemName: "chevron.left")
                }
                .opacity(viewingTurn == 0 ? 0.7 : 1)
                .disabled(viewingTurn == 0)
                
                
                Text("Viewing Turn \(viewingTurn + 1) of \(vm.turns.count)")
                
                Button(action: {
                    viewingTurn += 1
                }) {
                    Image(systemName: "chevron.right")
                }
                .opacity(viewingTurn == vm.turns.count - 1 ? 0.6 : 1)
                .disabled(viewingTurn == vm.turns.count - 1)
            }
            .foregroundColor(.primary)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            
            HStack {
                Text("Round score: \(vm.turns[viewingTurn].score)")
                
                Text("Total score: \(vm.totalScore)")
            }
            .font(.system(size: 18, weight: .regular, design: .rounded))
            
            Text(generateBonusText())
                .font(.system(size: 18, weight: .regular, design: .rounded))
            
            if vm.completeRows != 0 || vm.completeColumns != 0 || vm.completeTypes != 0 {
                Text("Score with bonuses: \(vm.scoreWithBonuses)")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
            }
        }
    }
        
    fileprivate func generateBonusText() -> String {
        let rows = vm.completeRows == 0 ? nil : "\(vm.completeRows) Rows"
        let columns = vm.completeColumns == 0 ? nil : "\(vm.completeColumns) Columns"
        let types = vm.completeTypes == 0 ? nil : "\(vm.completeTypes) Complete Pattern"
        return "Bonuses: \(rows == nil ? "" : rows! + "\(columns != nil || types != nil ? ", " : "")")\(columns == nil ? "" : columns! + "\(types != nil ? ", " : "")")\(types == nil ? "" : types!)\(rows == nil && columns == nil && types == nil ? "None" : "")"
    }
}

let screen = UIScreen.main.bounds

struct Square {
    var placed: Bool = false
    var new: Bool = false
    
    public mutating func place() {
        placed.toggle()
        new.toggle()
    }
    
    static func getColor(x: Int, y: Int) -> String {
        return [
            ["Blue", "Yellow", "Red", "Black", "Flower"],
            ["Flower", "Blue", "Yellow", "Red", "Black"],
            ["Black", "Flower", "Blue", "Yellow", "Red"],
            ["Red", "Black", "Flower", "Blue", "Yellow"],
            ["Yellow", "Red", "Black", "Flower", "Blue"]
        ][x][y]
    }
}

struct Player {
    let turns: [Turn]
    let name: String
}

struct Turn {
    var squares: [[Square]]
    
    var penalty = 0
    
    var score: Int {
        var thisRoundScore = 0
        
        for i in 0...4 {
            for j in 0...4 {
                let square = squares[i][j]
                if square.new {
                    var tileScore = 0
                    
                    var countedHorizontal = false
                    var countedVertical = false
                    
                    let surroundingRow = squares[i]
                    
                    // MARK: - To the left
                    var leftBound = j-1
                    
                    while leftBound != -1 {
                        let leftSquare = surroundingRow[leftBound]
                        if leftSquare.placed {
                            if !countedHorizontal {
                                countedHorizontal = true
                                tileScore += 1
                            }
                            
                            tileScore += 1
                            leftBound -= 1
                        }
                        else {
                            leftBound = -1
                        }
                    }
                    
                    // MARK: - To the right
                    var rightBound = j+1
                    
                    while rightBound != 5 {
                        let rightSquare = surroundingRow[rightBound]
                        if rightSquare.placed {
                            if !countedHorizontal {
                                countedHorizontal = true
                                tileScore += 1
                            }
                            tileScore += 1
                            rightBound += 1
                        }
                        else {
                            rightBound = 5
                        }
                    }
                    
                    let surroundingColumn: [Square] = squares.map { $0[j] }
                    
                    // MARK: - To the up
                    var upperBound = i-1
                    
                    while upperBound != -1 {
                        let upperSquare = surroundingColumn[upperBound]
                        if upperSquare.placed {
                            if !countedVertical {
                                countedVertical = true
                                tileScore += 1
                            }
                            tileScore += 1
                            upperBound -= 1
                        }
                        else {
                            upperBound = -1
                        }
                    }
                    
                    // MARK: - To the down
                    var lowerBound = i+1
                    
                    while lowerBound != 5 {
                        let lowerSquare = surroundingColumn[lowerBound]
                        if lowerSquare.placed {
                            if !countedVertical {
                                countedVertical = true
                                tileScore += 1
                            }
                            tileScore += 1
                            lowerBound += 1
                        }
                        else {
                            lowerBound = 5
                        }
                    }
                    
                    if !countedVertical && !countedHorizontal {
                        tileScore = 1
                    }
                    
                    thisRoundScore += tileScore
                }
            }
        }
        return thisRoundScore - penalty
    }
}

