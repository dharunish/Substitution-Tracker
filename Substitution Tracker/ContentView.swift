import SwiftUI

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var position: String?
    var location: CGPoint
}

struct ContentView: View {
    @State private var allPlayers: [Player] = [
        Player(name: "Player A", position: nil, location: CGPoint(x: 100, y: 500)),
        Player(name: "Player B", position: nil, location: CGPoint(x: 160, y: 500)),
        Player(name: "Player C", position: nil, location: CGPoint(x: 220, y: 500)),
        Player(name: "Player D", position: nil, location: CGPoint(x: 280, y: 500)),
        Player(name: "Player E", position: nil, location: CGPoint(x: 340, y: 500))
    ]

    @State private var selectedPlayers: [UUID] = []

    // Timer states
    @State private var timer: Timer? = nil
    @State private var secondsElapsed: Int = 0
    @State private var isRunning = false
    @State private var manualInput = ""
    
    @State private var record = []
    let positions = ["GK", "CB", "LB", "RB", "CM", "CAM", "CDM", "LW", "RW", "ST"]

    var body: some View {
        VStack {
            // Timer UI
            HStack {
                Text("Time: \(formatTime(secondsElapsed))")
                    .font(.title2)
                Spacer()
                Button(isRunning ? "Pause" : "Start") {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }
                Button("Reset") {
                    resetTimer()
                }
                TextField("mm:ss", text: $manualInput, onCommit: {
                    setManualTime()
                })
                .frame(width: 80)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            GeometryReader { geo in
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(height: geo.size.height / 2)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: geo.size.height / 2)
                    }

                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 2)
                        Spacer()
                    }

                    ForEach(allPlayers) { player in
                        DraggablePlayer(player: player,
                                        onDrag: { translation in
                                            if let index = allPlayers.firstIndex(of: player) {
                                                allPlayers[index].location.x += translation.width
                                                allPlayers[index].location.y += translation.height
                                            }
                                        },
                                        onTap: {
                                            toggleSelection(for: player)
                                        },
                                        onPositionChange: { newPos in
                                            if let index = allPlayers.firstIndex(of: player) {
                                                allPlayers[index].position = newPos
                                            }
                                        },
                                        positions: positions,
                                        isSelected: selectedPlayers.contains(player.id),
                                        isOnField: player.location.y < geo.size.height / 2)
                            .position(player.location)
                    }
                }
            }
        }
    }

    private func toggleSelection(for player: Player) {
        if selectedPlayers.contains(player.id) {
            selectedPlayers.removeAll { $0 == player.id }
        } else {
            selectedPlayers.append(player.id)
            if selectedPlayers.count == 2 {
                swapPlayers()
            }
        }
    }

    private func swapPlayers() {
        if selectedPlayers.count == 2,
           let firstIndex = allPlayers.firstIndex(where: { $0.id == selectedPlayers[0] }),
           let secondIndex = allPlayers.firstIndex(where: { $0.id == selectedPlayers[1] }) {
            let tempPosition = allPlayers[firstIndex].position
            let tempLocation = allPlayers[firstIndex].location

            allPlayers[firstIndex].position = allPlayers[secondIndex].position
            allPlayers[firstIndex].location = allPlayers[secondIndex].location

            allPlayers[secondIndex].position = tempPosition
            allPlayers[secondIndex].location = tempLocation
        }
        selectedPlayers.removeAll()
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsElapsed += 1
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        secondsElapsed = 0
    }

    private func setManualTime() {
        let parts = manualInput.split(separator: ":")
        if parts.count == 2,
           let mins = Int(parts[0]),
           let secs = Int(parts[1]),
           mins >= 0, secs >= 0, secs < 60 {
            secondsElapsed = mins * 60 + secs
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    
}

struct DraggablePlayer: View {
    var player: Player
    var onDrag: (CGSize) -> Void
    var onTap: () -> Void
    var onPositionChange: (String) -> Void
    var positions: [String]
    var isSelected: Bool
    var isOnField: Bool

    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        VStack {
            Text(player.name)
                .padding(8)
                .background(isSelected ? Color.orange : (isOnField ? Color.blue : Color.red))
                .cornerRadius(10)
                .onTapGesture {
                    onTap()
                }
            Menu {
                ForEach(positions, id: \ .self) { pos in
                    Button(pos) {
                        onPositionChange(pos)
                    }
                }
            } label: {
                Text(player.position ?? "Set Position")
                    .font(.caption)
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(6)
            }
        }
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    onDrag(value.translation)
                }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

