//
//  DatabaseManager.swift
//  AzulScoring
//
//  Created by Noah Brauner on 3/27/22.
//

import Firebase

let name = "Ilana"

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private init() {}
    
    private let database = Database.database().reference()
    
    public func updateSelf(currentBoard: [[Square]], score: Int, scoreWithBonuses: Int) {
        var binaryString = ""
        for sqaure in currentBoard.flatMap({ $0 }) {
            binaryString.append(sqaure.placed ? "1" : "0")
        }
                
        
        database.child("players/\(name)").setValue(
            [
                "b" : binaryString,
                "s": score,
                "sb": scoreWithBonuses
            ]
        )
    }
    
    public func fetchGame(completion: @escaping ([Player]) -> Void) {
        database.child("players").observe(.value) { [weak self] snap in
            guard let value = snap.value as? [String : Any] else {
                completion([])
                return
            }
            
            completion(
                value.map { playerName, playerTurns in
                    guard let playerTurns = playerTurns as? [String : String] else {
                        return Player(turns: [], name: "")
                    }
                    return Player(turns: self?.getTurnsFromBase64(playerTurns) ?? [], name: playerName)
                }
            )
        }
    }
    
    fileprivate func getTurnsFromBase64(_ turnDict: [String : String]) -> [Turn] {
        var turns = [Turn]()
        for (_, turnData) in turnDict {
            let data = Data(base64Encoded: turnData)
            let uint8s = [UInt8](data!)
            var bits = Bit.bits(fromBytes: uint8s)
            
            var turn = Turn(squares: Array(repeating: Array(repeating: Square(), count: 5), count: 5), penalty: 0)
            
            turn.penalty = Int(Bit.byte(fromBits: Array(Array(repeating: Bit(rawValue: 0)!, count: 4) + bits.suffix(4))))
            
            bits.removeLast(7)
            
            for i in 0...5 {
                for j in 0...5 {
                    turn.squares[i][j].placed = bits[i*5+j].boolValue
                }
            }
            
            turns.append(turn)
        }
        
        return turns
    }
}
