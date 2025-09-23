import SwiftUI
import Combine

// MARK: - Grid types
struct GridPos: Hashable, Comparable, Codable {
    let r: Int
    let c: Int
    static func < (lhs: GridPos, rhs: GridPos) -> Bool { (lhs.r, lhs.c) < (rhs.r, rhs.c) }
}

enum Orientation: String, Hashable, Codable { case horizontal, vertical }

enum BuildMode { case fence, rail }

// Нормализованное ребро между двумя соседними клетками (блокируется забором)
struct Edge: Hashable, Codable {
    let a: GridPos
    let b: GridPos
    init(_ p: GridPos, _ q: GridPos) { if p < q { a = p; b = q } else { a = q; b = p } }
}

// Отрисовочный сегмент забора (привязан к клетке), логически блокирует грань между клетками
struct FenceSeg: Hashable, Codable { let pos: GridPos; let orientation: Orientation }

// Незавершённая постройка забора (строится 0.5 c)
struct PendingFence: Hashable, Codable { let seg: FenceSeg; let commitAt: Date }

// Поезд, едет по готовой горизонтальной линии рельс слева направо
struct Train: Identifiable, Hashable { let id = UUID(); let row: Int; var col: Int; var nextMoveAt: Date }

// MARK: - ViewModel: лес, заборы, рельсы и поезда
final class ForestVM: ObservableObject {
    // Лес: какая клетка занята и какой вариант спрайта 1..4 у неё
    @Published var variants: [GridPos : Int] = [:]
    
    // Заборы
    @Published var pendingFences: [PendingFence] = []    // строятся, НЕ блокируют лес
    @Published var activeFences: [FenceSeg : Date] = [:] // активные, блокируют; value = expiresAt (жизнь 10 c)
    
    // Рельсы (только горизонтальные сегменты — по клеткам)
    @Published var rails: Set<GridPos> = []
    
    // Поезда и победа/поражение
    @Published var trains: [Train] = []
    @Published var trainsCompleted: Int = 0
    @Published var isWin: Bool = false
    @Published var isLose: Bool = false
    
    // UI режимы
    @Published var buildMode: BuildMode = .rail
    @Published var fenceOrientation: Orientation = .horizontal
    
    let rows: Int
    let cols: Int
    
    private var forest: Set<GridPos> = []
    private var blocked: Set<Edge> = [] // рассчитывается из activeFences
    
    // Таймеры
    private var growthTicker: AnyCancellable? // 1.0s — рост леса
    private var pulseTicker: AnyCancellable?  // ~20 Гц — апдейт заборов/поездов/победы
    
    init(rows: Int, cols: Int) { self.rows = rows; self.cols = cols }
    
    func start() {
        reset()
        // Рост леса: 1 сегмент/сек
        growthTicker = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.growOne() }
        // Пульс UI/логики
        pulseTicker = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.pulse(now: now) }
    }
    
    func stop() { growthTicker?.cancel(); growthTicker = nil; pulseTicker?.cancel(); pulseTicker = nil }
    
    func reset() {
        stop()
        variants.removeAll(); forest.removeAll(); activeFences.removeAll(); pendingFences.removeAll(); blocked.removeAll()
        rails.removeAll(); trains.removeAll(); trainsCompleted = 0; isWin = false; isLose = false
        // стартовая точка — случайная
        let seed = GridPos(r: Int.random(in: 0..<rows), c: Int.random(in: 0..<cols))
        forest.insert(seed)
        variants[seed] = Int.random(in: 1...4)
    }
    
    // MARK: Пользовательские действия
    func tap(at pos: GridPos) {
        guard !isWin && !isLose else { return }
        switch buildMode {
        case .fence:
            placeFence(at: pos)
        case .rail:
            placeRail(at: pos)
        }
    }
    
    private func placeFence(at cell: GridPos) {
        let seg = FenceSeg(pos: cell, orientation: fenceOrientation)
        if activeFences[seg] != nil { return }
        if pendingFences.contains(where: { $0.seg == seg }) { return }
        guard let neighbor = neighborForFence(from: cell, orientation: fenceOrientation), isAdjacent(cell, neighbor) else { return }
        pendingFences.append(.init(seg: seg, commitAt: Date().addingTimeInterval(0.5)))
    }
    
    private func placeRail(at cell: GridPos) {
        // Рельсу можно ставить только в пустой/не лесной клетке — запретим поверх леса
        guard variants[cell] == nil else { return }
        rails.insert(cell)
        // Проверим, не собрана ли непрерывная горизонтальная линия от левого до правого края по этой строке
        checkAndLaunchTrainIfLineReady(row: cell.r)
    }
    
    // MARK: Логика рельс/поездов
    private func checkAndLaunchTrainIfLineReady(row: Int) {
        // Нужны рельсы во всех столбцах 0..cols-1 на этой строке
        for c in 0..<cols { if !rails.contains(GridPos(r: row, c: c)) { return } }
        // Уже есть поезд на этой строке, который едет или доехал? Если едет — не дублируем. Если доехал — неважно, можно не запускать второй.
        if trains.contains(where: { $0.row == row }) { return }
        // Запускаем поезд в (row, 0)
        let start = GridPos(r: row, c: 0)
        guard rails.contains(start) else { return }
        let firstMoveAt = Date().addingTimeInterval(0.0) // старт сразу
        let train = Train(row: row, col: 0, nextMoveAt: firstMoveAt)
        trains.append(train)
    }
    
    private func advance(trainIndex i: Int, now: Date) {
        guard i < trains.count else { return }
        var t = trains[i]
        guard now >= t.nextMoveAt else { return }
        // Следующая клетка справа
        let nextC = t.col + 1
        if nextC >= cols {
            // Поезд доехал до правого края
            trains.remove(at: i)
            trainsCompleted += 1
            return
        }
        let nextPos = GridPos(r: t.row, c: nextC)
        // Можно двигаться только если там есть рельса и НЕТ леса
        if rails.contains(nextPos) && variants[nextPos] == nil {
            t.col = nextC
            t.nextMoveAt = now.addingTimeInterval(2.0) // 1 сегмент / 2 сек
            trains[i] = t
        } else {
            // Блокировано лесом — подождём, вдруг игрок защитит забором и лес отступит (в нашей модели лес не отступает, но может не нарасти)
            t.nextMoveAt = now.addingTimeInterval(0.5)
            trains[i] = t
        }
    }
    
    // MARK: Таймерный пульс
    private func pulse(now: Date) {
        // Коммит/истечение заборов
        updateFences(now: now)
        // Двигаем поезда
        var idx = 0
        while idx < trains.count {
            let before = trains.count
            advance(trainIndex: idx, now: now)
            if trains.count == before { idx += 1 } // если поезд не удалён (доехал), идём дальше
        }
        // Победа/Поражение
        evaluateWinLose()
    }
    
    private func updateFences(now: Date) {
        if !pendingFences.isEmpty {
            var keep: [PendingFence] = []
            for item in pendingFences {
                if now >= item.commitAt {
                    activeFences[item.seg] = now.addingTimeInterval(10.0)
                    if let nb = neighborForFence(from: item.seg.pos, orientation: item.seg.orientation) {
                        blocked.insert(Edge(item.seg.pos, nb))
                    }
                } else { keep.append(item) }
            }
            pendingFences = keep
        }
        if !activeFences.isEmpty {
            for (seg, exp) in activeFences where now >= exp {
                activeFences.removeValue(forKey: seg)
                if let nb = neighborForFence(from: seg.pos, orientation: seg.orientation) {
                    blocked.remove(Edge(seg.pos, nb))
                }
            }
        }
    }
    
    // MARK: Лес
    private func canPass(from p: GridPos, to q: GridPos) -> Bool { !blocked.contains(Edge(p, q)) }
    
    private func growOne() {
        guard !isWin && !isLose else { return }
        var candidates: [GridPos] = []
        for p in forest {
            for nb in neighbors(of: p) where !forest.contains(nb) && canPass(from: p, to: nb) {
                candidates.append(nb)
            }
        }
        guard let next = candidates.randomElement() else { return }
        forest.insert(next)
        variants[next] = Int.random(in: 1...4)
    }
    
    private func neighbors(of p: GridPos) -> [GridPos] {
        var res: [GridPos] = []
        if p.r > 0 { res.append(.init(r: p.r-1, c: p.c)) }
        if p.r+1 < rows { res.append(.init(r: p.r+1, c: p.c)) }
        if p.c > 0 { res.append(.init(r: p.r, c: p.c-1)) }
        if p.c+1 < cols { res.append(.init(r: p.r, c: p.c+1)) }
        return res
    }
    
    // MARK: Победа/Поражение
    private func evaluateWinLose() {
        if trainsCompleted >= 3 { isWin = true }
        // Проигрыш: все клетки стали лесом
        if forest.count >= rows * cols { isLose = true }
    }
    
    // MARK: Helpers для View
    func isFenceActive(at pos: GridPos, orientation: Orientation) -> Bool { activeFences[FenceSeg(pos: pos, orientation: orientation)] != nil }
    func isFencePending(at pos: GridPos, orientation: Orientation) -> Bool { pendingFences.contains { $0.seg == FenceSeg(pos: pos, orientation: orientation) } }
    func pendingProgress(at pos: GridPos, orientation: Orientation, now: Date = Date()) -> Double {
        guard let item = pendingFences.first(where: { $0.seg == FenceSeg(pos: pos, orientation: orientation) }) else { return 0 }
        let total: TimeInterval = 0.5
        let remaining = max(0, item.commitAt.timeIntervalSince(now))
        return min(1, 1 - remaining / total)
    }
    func hasRail(_ pos: GridPos) -> Bool { rails.contains(pos) }

    private func neighborForFence(from p: GridPos, orientation: Orientation) -> GridPos? {
        switch orientation {
        case .vertical:
            if p.c + 1 < cols { return GridPos(r: p.r, c: p.c + 1) }
            if p.c - 1 >= 0   { return GridPos(r: p.r, c: p.c - 1) }
            return nil
        case .horizontal:
            if p.r + 1 < rows { return GridPos(r: p.r + 1, c: p.c) }
            if p.r - 1 >= 0   { return GridPos(r: p.r - 1, c: p.c) }
            return nil
        }
    }

    private func isAdjacent(_ a: GridPos, _ b: GridPos) -> Bool {
        (a.r == b.r && abs(a.c - b.c) == 1) || (a.c == b.c && abs(a.r - b.r) == 1)
    }
    
}

// MARK: - View: задний фон — SwiftUI; поверх сетка леса/рельс/заборов и поезда
struct ForestGrowthView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var vm: ForestVM
    private let rows: Int
    private let cols: Int

    init(rows: Int = 10, cols: Int = 18) {
        _vm = StateObject(wrappedValue: ForestVM(rows: rows, cols: cols))
        self.rows = rows; self.cols = cols
    }

    private var columns: [GridItem] { Array(repeating: .init(.flexible(), spacing: 0), count: cols) }

    
    @StateObject private var shopVM = MCShopViewModel()
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            

            GeometryReader { geo in
                let cell = min(geo.size.width / CGFloat(cols), geo.size.height / CGFloat(rows))
                let gridW = cell * CGFloat(cols)
                let gridH = cell * CGFloat(rows)
                let originX = (geo.size.width  - gridW) / 2
                let originY = (geo.size.height - gridH) / 2

                ZStack {
                    // Сетка клеток
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<(rows*cols), id: \.self) { idx in
                            let r = idx / cols
                            let c = idx % cols
                            let pos = GridPos(r: r, c: c)
                            ZStack {
                                // РЕЛЬСЫ (под лесом визуально):
                                if vm.hasRail(pos) {
                                    railImage(cell: cell)
                                }
                                // ЛЕС (перекрывает рельсы, если вырос):
                                if let v = vm.variants[pos], let currentBg = shopVM.currentBgItem {
                                    Image("\(currentBg.image)_forest_\(v)")
                                        .resizable()
                                        .scaledToFit()
                                        .transition(.opacity)
                                }
                                // ЗАБОРЫ — строятся
                                if vm.isFencePending(at: pos, orientation: .horizontal) {
                                    fenceBuilding(cell: cell, orientation: .horizontal, progress: vm.pendingProgress(at: pos, orientation: .horizontal))
                                }
                                if vm.isFencePending(at: pos, orientation: .vertical) {
                                    fenceBuilding(cell: cell, orientation: .vertical, progress: vm.pendingProgress(at: pos, orientation: .vertical))
                                }
                                // ЗАБОРЫ — активные
                                if vm.isFenceActive(at: pos, orientation: .horizontal) { fenceImage(cell: cell, orientation: .horizontal) }
                                if vm.isFenceActive(at: pos, orientation: .vertical) { fenceImage(cell: cell, orientation: .vertical) }
                            }
                            .frame(width: cell, height: cell)
                            .contentShape(Rectangle())
                            .onTapGesture { vm.tap(at: pos) }
                        }
                    }
                    .frame(width: gridW, height: gridH)
                    .position(x: geo.size.width/2, y: geo.size.height/2)

                    // Поезда (иконки), позиционируем поверх сетки по центрам клеток
                    ForEach(vm.trains) { t in
                        let x = originX + (CGFloat(t.col) + 0.5) * cell
                        let y = originY + (CGFloat(t.row) + 0.5) * cell
                        Image("train")
                            .resizable()
                            .scaledToFit()
                            .frame(height: cell * 1)
                            .position(x: x, y: y)
                    }
                }

                // HUD сверху
                VStack {
                    HStack {
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(.backIconMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:50)
                        }
                        
                        Text("🚂 Train: \(vm.trainsCompleted)/3")
                            .font(.headline)
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        
                    }
                    .padding([.top,.horizontal])
                    Spacer()
                }
            }

            // Нижняя левая панель управления
            HStack(spacing: 8) {
                Button { withAnimation { vm.buildMode = .rail } } label: {
                    Image(.railsBtnMC)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 25)
                }
                .padding(2)
                .background(vm.buildMode == .rail ? .green : .gray)

                Button { withAnimation { vm.buildMode = .fence } } label: {
                    Image(.zaborBtnMC)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 25)
                }
                .padding(2)
                .background(vm.buildMode == .fence ? .green : .gray)

                Button {
                    withAnimation { vm.fenceOrientation = (vm.fenceOrientation == .horizontal ? .vertical : .horizontal) }
                } label: {
                    Image(systemName: vm.fenceOrientation == .horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(.black.opacity(0.8))
                .cornerRadius(6)
            }
            .padding([.leading, .bottom], 16)
            
            if vm.isWin {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    HStack {
                        Spacer()
                        ZStack {
                            Image(.winBgMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                            
                            VStack{
                                Spacer()
                                
                                HStack {
                                    Button {
                                        presentationMode.wrappedValue.dismiss()
                                        
                                    } label: {
                                        Image(.backIconMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 65)
                                    }
                                    
                                    Button {
                                        vm.reset()
                                        vm.start()
                                        
                                    } label: {
                                        Image(.nextBtnMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 80)
                                    }
                                    
                                    Image(.backIconMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 65)
                                        .opacity(0)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            
            if vm.isLose {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    HStack {
                        Spacer()
                        ZStack {
                            Image(.loseBgMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                            
                            VStack{
                                Spacer()
                                
                                HStack {
                                    Button {
                                        presentationMode.wrappedValue.dismiss()
                                        
                                    } label: {
                                        Image(.backIconMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 65)
                                    }
                                    
                                    Button {
                                        vm.reset()
                                        vm.start()
                                        
                                    } label: {
                                        Image(.restartBtnMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 80)
                                    }
                                    
                                    Image(.backIconMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 65)
                                        .opacity(0)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .navigationTitle("Rails & Forest — Step 4 (Rails + Trains)")
        .background(
            ZStack {
                if let currentBg = shopVM.currentBgItem {
                    Image(currentBg.image)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            }
        )
    }

    // MARK: - Вспомогательные вьюхи
    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(text == "Победа" ? .green : .red, in: Capsule())
    }

    private func railImage(cell: CGFloat) -> some View {
        Image("rail_h") // ассет горизонтального сегмента рельс
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: cell * 0.95, height: cell * 1)
            .clipped()
    }

    // Рендер активного забора
    @ViewBuilder
    private func fenceImage(cell: CGFloat, orientation: Orientation) -> some View {
        let length = cell * 0.95
        let thick  = cell * 0.18
        let base = Image("fence_segment").resizable().aspectRatio(contentMode: .fill)
        if orientation == .horizontal {
            base.frame(width: length, height: thick).clipped().shadow(radius: 1).opacity(0.98)
        } else {
            base.frame(width: length, height: thick).rotationEffect(.degrees(90)).frame(width: thick, height: length).clipped().shadow(radius: 1).opacity(0.98)
        }
    }

    // Рендер сегмента в процессе стройки (0.5c)
    @ViewBuilder
    private func fenceBuilding(cell: CGFloat, orientation: Orientation, progress: Double) -> some View {
        let p = max(0.1, min(1.0, progress))
        let length = cell * 0.95
        let thick  = cell * 0.18
        let current = max(thick, length * p)
        let base = Image("fence_segment").resizable().aspectRatio(contentMode: .fill)
        if orientation == .horizontal {
            base.frame(width: current, height: thick).clipped().opacity(0.3 + 0.7 * p)
        } else {
            base.frame(width: current, height: thick).rotationEffect(.degrees(90)).frame(width: thick, height: current).clipped().opacity(0.3 + 0.7 * p)
        }
    }
}

// MARK: - Превью / Точка входа
struct ForestGrowthView_Previews: PreviewProvider {
    static var previews: some View { ForestGrowthView().preferredColorScheme(.dark) }
}

