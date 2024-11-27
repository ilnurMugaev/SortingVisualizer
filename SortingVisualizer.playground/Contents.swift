import UIKit
import PlaygroundSupport

// MARK: - Протокол для алгоритмов сортировки
protocol SortingAlgorithm {
    static func sort(_ array: inout [Int], visualizer: SortingVisualizer) async throws
}

// MARK: - Визуализатор сортировки
@MainActor
class SortingVisualizer: UIView {
    // Настраиваемые параметры
    struct Configuration {
        var barColor: UIColor = .systemBlue
        var highlightColors: [Int: UIColor] = [
            0: .systemGreen,  // Текущий минимум
            1: .systemRed,    // Сравниваемый элемент
            2: .systemYellow, // Обмен
            3: .systemGray    // Отсортированный
        ]
        var barSpacing: CGFloat = 2
        var labelFont: UIFont = .systemFont(ofSize: 10, weight: .regular)
        var barWidthRatio: CGFloat = 0.8
    }
    
    var configuration: Configuration
    var array: [Int]
    private var barViews: [CAShapeLayer] = []
    private var numberLabels: [UILabel] = []
    private var arrowLayers: [CAShapeLayer] = []
    private let maxValue: CGFloat
    
    init(
        frame: CGRect,
        array: [Int],
        configuration: Configuration = Configuration()
    ) {
        self.array = array
        self.configuration = configuration
        self.maxValue = CGFloat(array.max() ?? 1)
        
        super.init(frame: frame)
        setupVisualization()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisualization() {
        createBarsAndLabels()
    }
    
    private func createBarsAndLabels() {
        let barWidth = (bounds.width / CGFloat(array.count)) - configuration.barSpacing
        let maxHeight = bounds.height * 0.8
        
        for (index, value) in array.enumerated() {
            // Создание бара как CAShapeLayer
            let barHeight = maxHeight * CGFloat(value) / maxValue
            let barLayer = CAShapeLayer()
            barLayer.path = UIBezierPath(
                roundedRect: CGRect(
                    x: CGFloat(index) * (barWidth + configuration.barSpacing),
                    y: bounds.height - barHeight - 20,
                    width: barWidth * configuration.barWidthRatio,
                    height: barHeight
                ).integral,
                cornerRadius: 4
            ).cgPath
            barLayer.fillColor = configuration.barColor.cgColor
            layer.addSublayer(barLayer)
            barViews.append(barLayer)
            
            // Создание метки
            let label = UILabel(frame: CGRect(
                x: CGFloat(index) * (barWidth + configuration.barSpacing),
                y: bounds.height - barHeight - 40,
                width: barWidth,
                height: 20
            ))
            label.text = "\(value)"
            label.font = configuration.labelFont
            label.textAlignment = .center
            addSubview(label)
            numberLabels.append(label)
        }
    }
    
    // MARK: - Обновление визуализации
    func updateVisualization(
        highlights: [Int: Int]? = nil,
        updatedArray: [Int]? = nil,
        sortedIndices: Set<Int> = []
    ) {
        clearArrows() // Очищаем стрелки перед обновлением
        
        if let updatedArray = updatedArray {
            array = updatedArray
        }
        
        for (index, bar) in barViews.enumerated() {
            let barHeight = (bounds.height * 0.8) * CGFloat(array[index]) / maxValue
            
            // Обновление высоты бара
            bar.path = UIBezierPath(
                roundedRect: CGRect(
                    x: bar.path?.boundingBox.origin.x ?? 0,
                    y: bounds.height - barHeight - 20,
                    width: bar.path?.boundingBox.width ?? 0,
                    height: barHeight
                ).integral,
                cornerRadius: 4
            ).cgPath
            
            // Обновление цвета
            if sortedIndices.contains(index) {
                bar.fillColor = configuration.highlightColors[3]?.cgColor // Серый цвет для отсортированных элементов
            } else if let highlights = highlights,
                      let colorIndex = highlights[index] {
                bar.fillColor = configuration.highlightColors[colorIndex]?.cgColor
            } else {
                bar.fillColor = configuration.barColor.cgColor
            }
            
            // Обновление метки
            numberLabels[index].text = "\(array[index])"
            numberLabels[index].frame.origin.y = bounds.height - barHeight - 40
        }
    }

    func addArrow(
        from fromIndex: Int,
        to toIndex: Int
    ) {
        clearArrows()
        
        let barWidth = (bounds.width / CGFloat(array.count)) - configuration.barSpacing
        
        // Позиции начала и конца линии
        let fromX = CGFloat(fromIndex) * (barWidth + configuration.barSpacing) + barWidth / 2
        let toX = CGFloat(toIndex) * (barWidth + configuration.barSpacing) + barWidth / 2
        let labelHeight: CGFloat = 20 // Высота метки
        let lineStartY = bounds.height - (bounds.height * 0.8) * CGFloat(array[fromIndex]) / maxValue - labelHeight - 10
        let lineEndY = bounds.height - (bounds.height * 0.8) * CGFloat(array[toIndex]) / maxValue - labelHeight - 10
        let arcHeight: CGFloat = 40 // Высота скругления наверху
        
        // Создание пути
        let path = UIBezierPath()
        path.move(to: CGPoint(x: fromX, y: lineStartY))
        path.addLine(to: CGPoint(x: fromX, y: lineStartY - arcHeight)) // Подъем к скруглению
        path.addQuadCurve(
            to: CGPoint(x: toX, y: lineEndY - arcHeight),
            controlPoint: CGPoint(x: (fromX + toX) / 2, y: lineStartY - arcHeight - 20)
        )
        path.addLine(to: CGPoint(x: toX, y: lineEndY)) // Спуск от скругления
        
        // Создание слоя линии
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.systemBlue.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        lineLayer.lineCap = .round
        layer.addSublayer(lineLayer)
        arrowLayers.append(lineLayer)
    }

    
    // MARK: - Очистка стрелок
    private func clearArrows() {
        for arrow in arrowLayers {
            arrow.removeFromSuperlayer()
        }
        arrowLayers.removeAll()
    }
}

// MARK: - Алгоритмы сортировки

/// Сортировка выбором (Selection Sort)
struct SelectionSort: SortingAlgorithm {
    static func sort(_ array: inout [Int], visualizer: SortingVisualizer) async throws {
        var sortedIndices = Set<Int>()
        
        for i in 0..<array.count - 1 {
            var minIndex = i
            for j in (i + 1)..<array.count {
                await MainActor.run {
                    visualizer.updateVisualization(
                        highlights: [
                            minIndex: 0,
                            j: 1
                        ],
                        sortedIndices: sortedIndices
                    )
                }
                try await Task.sleep(nanoseconds: 50_000_000)
                
                if array[j] < array[minIndex] {
                    minIndex = j
                }
            }
            
            if i != minIndex {
                await MainActor.run {
                    visualizer.addArrow(from: i, to: minIndex)
                }
                try await Task.sleep(nanoseconds: 100_000_000)
                
                array.swapAt(i, minIndex)
                await MainActor.run {
                    visualizer.updateVisualization(
                        highlights: [i: 2, minIndex: 2],
                        updatedArray: array,
                        sortedIndices: sortedIndices
                    )
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            
            sortedIndices.insert(i) // Добавляем индекс в отсортированные
            await MainActor.run {
                visualizer.updateVisualization(
                    highlights: [i: 3],
                    sortedIndices: sortedIndices
                )
            }
        }
        
        sortedIndices.insert(array.count - 1) // Последний элемент всегда отсортирован
        await MainActor.run {
            visualizer.updateVisualization(
                highlights: [array.count - 1: 3],
                sortedIndices: sortedIndices
            )
        }
    }
}

/// Пузырьковая сортировка (Bubble Sort)
struct BubbleSort: SortingAlgorithm {
    static func sort(_ array: inout [Int], visualizer: SortingVisualizer) async throws {
        var sortedIndices = Set<Int>()
        
        for i in 0..<array.count {
            for j in 0..<(array.count - i - 1) {
                await MainActor.run {
                    visualizer.updateVisualization(
                        highlights: [
                            j: 1,
                            j + 1: 1
                        ],
                        sortedIndices: sortedIndices
                    )
                }
                try await Task.sleep(nanoseconds: 50_000_000)
                
                if array[j] > array[j + 1] {
                    await MainActor.run {
                        visualizer.addArrow(from: j, to: j + 1)
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)
                    
                    array.swapAt(j, j + 1)
                    await MainActor.run {
                        visualizer.updateVisualization(
                            highlights: [j: 2, j + 1: 2],
                            updatedArray: array,
                            sortedIndices: sortedIndices
                        )
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            
            sortedIndices.insert(array.count - i - 1) // Добавляем индекс в отсортированные
            await MainActor.run {
                visualizer.updateVisualization(
                    highlights: [array.count - i - 1: 3],
                    sortedIndices: sortedIndices
                )
            }
        }
    }
}

// MARK: - Пример использования -

let arraySize = 50
let randomArray = (0..<arraySize).map { _ in Int.random(in: 1...100) }

var configuration = SortingVisualizer.Configuration()
configuration.barColor = .systemPurple

let visualizer = SortingVisualizer(
    frame: CGRect(x: 0, y: 0, width: 1000, height: 500),
    array: randomArray,
    configuration: configuration
)

PlaygroundPage.current.liveView = visualizer

Task {
    var mutableArray = visualizer.array
    try? await SelectionSort.sort(&mutableArray, visualizer: visualizer)
//    try? await BubbleSort.sort(&mutableArray, visualizer: visualizer)
}
