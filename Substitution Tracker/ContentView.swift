import SwiftUI
import MessageUI

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
    @State private var swapLog: [String] = []
    @State private var showReport = false

    // Timer states
    @State private var timer: Timer? = nil
    @State private var secondsElapsed: Int = 0
    @State private var isRunning = false
    @State private var manualInput = ""

    let positions = ["None", "GK", "CB", "LB", "RB", "CM", "CAM", "CDM", "LW", "RW", "ST"]

    var body: some View {
        VStack {
            // Timer UI and Report Button
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
                Button("Report") {
                    showReport = true
                }
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
                            toggleSelection(for: player, boundary:geo.size.height / 2)
                                        },
                                        onPositionChange: { newPos in
                                            if let index = allPlayers.firstIndex(of: player) {
                                                let oldPos = allPlayers[index].position
                                                allPlayers[index].position = newPos
                                                if player.location.y < geo.size.height / 2 {
                                                    if oldPos == "None" || oldPos == nil {
                                                        let log = "\(allPlayers[index].name) is moved to \(newPos) at \(formatTime(secondsElapsed))"
                                                        swapLog.append(log)
                                                    }
                                                    else if oldPos != newPos && newPos != "None" {
                                                        let log = "\(allPlayers[index].name) is moved from \(oldPos!) to \(newPos) at \(formatTime(secondsElapsed))"
                                                        swapLog.append(log)
                                                    }
                                                }
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
        .fullScreenCover(isPresented: $showReport) {
            ReportView(log: $swapLog, dismissAction: { showReport = false })
        }
    }

    private func toggleSelection(for player: Player, boundary: CGFloat) {
        if selectedPlayers.contains(player.id) {
            selectedPlayers.removeAll { $0 == player.id }
        } else {
            selectedPlayers.append(player.id)
            if selectedPlayers.count == 2 {
                swapPlayers(boundary:boundary)
            }
        }
    }

    private func swapPlayers(boundary: CGFloat) {
        if selectedPlayers.count == 2,
           let firstIndex = allPlayers.firstIndex(where: { $0.id == selectedPlayers[0] }),
           let secondIndex = allPlayers.firstIndex(where: { $0.id == selectedPlayers[1] }) {
            let p1 = allPlayers[firstIndex]
            let p2 = allPlayers[secondIndex]
            let p1OnField = p1.location.y < boundary
            let p2OnField = p2.location.y < boundary

            let tempPosition = p1.position
            let tempLocation = p1.location

            allPlayers[firstIndex].position = p2.position
            allPlayers[firstIndex].location = p2.location

            allPlayers[secondIndex].position = tempPosition
            allPlayers[secondIndex].location = tempLocation

            if p1OnField && !p2OnField {
                if let pos = p1.position {
                    let log = "\(p2.name) is subbed in for \(p1.name) in position \(pos) at \(formatTime(secondsElapsed))"
                    swapLog.append(log)
                }
            } else if !p1OnField && p2OnField {
                if let pos = p2.position {
                    let log = "\(p1.name) is subbed in for \(p2.name) in position \(pos) at \(formatTime(secondsElapsed))"
                    swapLog.append(log)
                }
            } else if p1OnField && p2OnField {
                if let p1Pos = p1.position, let p2Pos = p2.position {
                    let log1 = "\(p1.name) is moved from \(p1Pos) to \(p2Pos) at \(formatTime(secondsElapsed))"
                    let log2 = "\(p2.name) is moved from \(p2Pos) to \(p1Pos) at \(formatTime(secondsElapsed))"
                    swapLog.append(log1)
                    swapLog.append(log2)
                }
            }
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

struct ReportView: View {
    @Binding var log: [String]
    var dismissAction: () -> Void
    @State private var showMailView = false
    @State private var showMailError = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Match Report")
                    .font(.title)
                    .padding()
                TextEditor(text: Binding(
                    get: { log.joined(separator: "\n") },
                    set: { newText in
                        log = newText.components(separatedBy: "\n")
                    })
                )
                .padding()
                .border(Color.gray)

                HStack {
                    Button("Back") {
                        dismissAction()
                    }
                    Spacer()
                    Button("Send") {
                        if MFMailComposeViewController.canSendMail() {
                            showMailView = true
                        } else {
                            showMailError = true
                        }
                    }
                }
                .padding()
                .sheet(isPresented: $showMailView) {
                    MailView(subject: "Match Report", body: log.joined(separator: "\n"))
                }
                .alert("Mail services are not available. Please set up a mail account.", isPresented: $showMailError) {
                    Button("OK", role: .cancel) {}
                }
            }
            .padding()
        }
    }
}

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    var subject: String
    var body: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView

        init(parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.parent.presentation.wrappedValue.dismiss()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
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
                Text(player.position ?? "None")
                    .font(.caption)
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(6)
                    .frame(minWidth: 60)
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
