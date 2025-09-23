import SwiftUI
train.scheduleNextMove(scene: self, stepSeconds: 2.0)
}


private func updateTrains(_ currentTime: TimeInterval) {
// Clean finished trains
var keep: [Train] = []
for t in activeTrains {
if t.isFinished { continue }
keep.append(t)
}
activeTrains = keep
}


fileprivate func trainArrived(_ train: Train) {
// Remove sprite, count, try spawn more
train.node.removeFromParent()
if let hud = hud {
hud.trainsCompleted += 1
if hud.trainsCompleted < hud.trainsRequired { checkForNewPathsAndLaunchTrains() }
}
}
}


// MARK: - Train object
final class Train {
let node: SKSpriteNode
let path: [GridPos]
private(set) var index: Int = 0 // current target index in path
var isFinished: Bool = false


init(node: SKSpriteNode, path: [GridPos]) {
self.node = node
self.path = path
}


func scheduleNextMove(scene: RailDefenseScene, stepSeconds: TimeInterval) {
guard !isFinished else { return }
// If blocked by forest ahead, wait and retry
if index+1 < path.count {
let next = path[index+1]
if scene.isForest(next) {
// wait 0.5s and retry (player must defend)
node.run(.sequence([.wait(forDuration: 0.5), .run { [weak self] in self?.scheduleNextMove(scene: scene, stepSeconds: stepSeconds) }]))
return
}
}
guard index+1 < path.count else {
isFinished = true
scene.trainArrived(self)
return
}
index += 1
let dst = scene.posToPoint(path[index])
let move = SKAction.move(to: dst, duration: stepSeconds)
node.run(.sequence([move, .run { [weak self] in
guard let self, !self.isFinished else { return }
if self.index+1 >= self.path.count {
self.isFinished = true
scene.trainArrived(self)
} else {
self.scheduleNextMove(scene: scene, stepSeconds: stepSeconds)
}
}]))
}
}


// MARK: - SwiftUI Preview / App Entrypoint
struct RailDefenseRootView_Previews: PreviewProvider {
static var previews: some View {
RailDefenseRootView()
.preferredColorScheme(.dark)
}
}