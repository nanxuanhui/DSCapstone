import SwiftUI
import AVFoundation
import Vision
import CoreML

// 关键点数据结构 - 类似OpenPose的关键点表示
struct Keypoint {
    let position: CGPoint
    let confidence: Float
    
    var isValid: Bool {
        return confidence > 0.5
    }
}

// 姿态数据结构
class Pose {
    // 身体关键点
    var nose: Keypoint?
    var neck: Keypoint?
    var rightShoulder: Keypoint?
    var rightElbow: Keypoint?
    var rightWrist: Keypoint?
    var leftShoulder: Keypoint?
    var leftElbow: Keypoint?
    var leftWrist: Keypoint?
    var rightHip: Keypoint?
    var rightKnee: Keypoint?
    var rightAnkle: Keypoint?
    var leftHip: Keypoint?
    var leftKnee: Keypoint?
    var leftAnkle: Keypoint?
    var rightEye: Keypoint?
    var leftEye: Keypoint?
    var rightEar: Keypoint?
    var leftEar: Keypoint?
    
    // 计算躯干角度 - 检测是否倾斜
    func trunkAngle() -> Double? {
        guard let neck = neck, neck.isValid,
              let midHip = midpointBetween(leftHip, rightHip),
              midHip.isValid else {
            return nil
        }
        
        // 计算躯干与垂直线的夹角
        let dy = midHip.position.y - neck.position.y
        let dx = midHip.position.x - neck.position.x
        let angle = abs(atan2(dx, dy) * 180 / .pi) // 转换为度数
        
        return angle
    }
    
    // 计算腿部角度 - 检测是否弯曲或倒地
    func legAngle() -> Double? {
        // 使用左右腿的平均角度
        let leftLegAngle = angleBetween(leftHip, leftKnee, leftAnkle)
        let rightLegAngle = angleBetween(rightHip, rightKnee, rightAnkle)
        
        if leftLegAngle != nil && rightLegAngle != nil {
            return (leftLegAngle! + rightLegAngle!) / 2
        } else {
            return leftLegAngle ?? rightLegAngle
        }
    }
    
    // 计算两个关键点之间的中点
    private func midpointBetween(_ a: Keypoint?, _ b: Keypoint?) -> Keypoint? {
        guard let a = a, a.isValid, let b = b, b.isValid else {
            return nil
        }
        
        let x = (a.position.x + b.position.x) / 2
        let y = (a.position.y + b.position.y) / 2
        let confidence = min(a.confidence, b.confidence)
        
        return Keypoint(position: CGPoint(x: x, y: y), confidence: confidence)
    }
    
    // 计算三个点之间的角度
    private func angleBetween(_ a: Keypoint?, _ b: Keypoint?, _ c: Keypoint?) -> Double? {
        guard let a = a, a.isValid,
              let b = b, b.isValid,
              let c = c, c.isValid else {
            return nil
        }
        
        // 计算向量
        let v1x = a.position.x - b.position.x
        let v1y = a.position.y - b.position.y
        let v2x = c.position.x - b.position.x
        let v2y = c.position.y - b.position.y
        
        // 计算角度 (0-180度)
        let dot = v1x * v2x + v1y * v2y
        let cross = v1x * v2y - v1y * v2x
        let angle = atan2(cross, dot) * 180 / .pi
        
        return abs(angle)
    }
    
    // 判断是否处于摔倒姿态
    func isFallingPose() -> (Bool, Double) {
        var fallConfidence = 0.0
        
        // 检查躯干倾斜角度
        if let trunkAngle = trunkAngle() {
            // 躯干水平(接近90度)表示可能倒地
            let trunkFactor = min(1.0, trunkAngle / 75.0)
            fallConfidence += trunkFactor * 0.6 // 躯干角度权重为60%
        }
        
        // 检查腿部角度
        if let legAngle = legAngle() {
            // 腿部伸直或过度弯曲可能表示摔倒
            let normalLegAngle = 150.0 // 正常站立时腿部接近180度
            let legFactor = 1.0 - min(1.0, abs(legAngle - normalLegAngle) / 70.0)
            fallConfidence += (1.0 - legFactor) * 0.4 // 腿部异常权重为40%
        }
        
        // 判断是否摔倒(信心值>0.7视为摔倒)
        return (fallConfidence > 0.7, fallConfidence)
    }
}

class FallDetectionViewModel: NSObject, ObservableObject {
    @Published var isDetecting = false
    @Published var fallDetected = false
    @Published var fallConfidence: Double = 0.0
    @Published var detectedObjects: [DetectedObject] = []
    @Published var currentPose: Pose?
    @Published var showPoseOverlay: Bool = true
    
    @Published var session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var yoloModel: VNCoreMLModel?
    private var consecutiveFallFrames = 0
    private let fallFrameThreshold = 5 // 连续检测到5帧才确认摔倒
    
    struct DetectedObject {
        let label: String
        let confidence: Float
        let boundingBox: CGRect
    }
    
    override init() {
        super.init()
        loadModel()
        setupCamera()
    }
    
    private func loadModel() {
        // 加载YOLOv5模型
        if let modelURL = Bundle.main.url(forResource: "FallDetectionModel", withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                yoloModel = try VNCoreMLModel(for: model)
                print("YOLOv5模型加载成功")
            } catch {
                print("加载YOLOv5模型失败: \(error)")
            }
        }
    }
    
    func setupCamera() {
        // 相机设置代码...
        let captureSession = AVCaptureSession()
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        session = captureSession
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func setupVisionProCamera() {
        #if os(visionOS)
        print("设置Vision Pro相机")
        // 在Vision Pro上的相机设置，可以为模拟实现
        #endif
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // 使用YOLO识别人体和摔倒情况
        detectObjectsWithYOLO(pixelBuffer)
        
        // 使用Vision框架的姿态估计
        detectHumanPose(pixelBuffer)
    }
    
    private func detectObjectsWithYOLO(_ pixelBuffer: CVPixelBuffer) {
        guard let model = yoloModel else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self, error == nil else { return }
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                DispatchQueue.main.async {
                    self.detectedObjects = results.map { observation in
                        let bestLabel = observation.labels.first?.identifier ?? "unknown"
                        let confidence = observation.labels.first?.confidence ?? 0
                        
                        // 检查是否检测到摔倒
                        if bestLabel == "fall" && confidence > 0.7 {
                            self.yoloDetectedFall(confidence: Double(confidence))
                        }
                        
                        return DetectedObject(
                            label: bestLabel,
                            confidence: confidence,
                            boundingBox: observation.boundingBox
                        )
                    }
                }
            }
        }
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch {
            print("YOLO检测失败: \(error)")
        }
    }
    
    private func detectHumanPose(_ pixelBuffer: CVPixelBuffer) {
        // 创建人体姿态请求
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  error == nil else {
                return
            }
            
            // 处理最大的一个人的姿态
            if let observation = observations.first {
                DispatchQueue.main.async {
                    self.processPoseObservation(observation)
                }
            }
        }
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch {
            print("姿态检测失败: \(error)")
        }
    }
    
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation) {
        let pose = Pose()
        
        // 转换Vision框架的关键点到我们的Pose数据结构
        // 注意：使用实际Vision API中可用的关键点标识符
        if let points = try? observation.recognizedPoints(.all) {
            // 从Vision框架获取每个关键点
            if let point = points[.nose] {
                pose.nose = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 脖子位置（Vision框架可能没有直接提供，可以估算）
            if let leftShoulder = points[.leftShoulder], let rightShoulder = points[.rightShoulder] {
                let x = (leftShoulder.location.x + rightShoulder.location.x) / 2
                let y = (leftShoulder.location.y + rightShoulder.location.y) / 2
                let confidence = min(leftShoulder.confidence, rightShoulder.confidence)
                pose.neck = Keypoint(position: CGPoint(x: x, y: 1 - y), confidence: confidence)
            }
            
            // 肩膀
            if let point = points[.rightShoulder] {
                pose.rightShoulder = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftShoulder] {
                pose.leftShoulder = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 手肘
            if let point = points[.rightElbow] {
                pose.rightElbow = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftElbow] {
                pose.leftElbow = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 手腕
            if let point = points[.rightWrist] {
                pose.rightWrist = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftWrist] {
                pose.leftWrist = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 臀部
            if let point = points[.rightHip] {
                pose.rightHip = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftHip] {
                pose.leftHip = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 膝盖
            if let point = points[.rightKnee] {
                pose.rightKnee = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftKnee] {
                pose.leftKnee = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 踝关节
            if let point = points[.rightAnkle] {
                pose.rightAnkle = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftAnkle] {
                pose.leftAnkle = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            
            // 眼睛和耳朵
            if let point = points[.rightEye] {
                pose.rightEye = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftEye] {
                pose.leftEye = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.rightEar] {
                pose.rightEar = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
            if let point = points[.leftEar] {
                pose.leftEar = Keypoint(position: CGPoint(x: point.location.x, y: 1 - point.location.y), confidence: point.confidence)
            }
        }
        
        // 更新当前姿态
        currentPose = pose
        
        // 检查姿态是否表示摔倒
        let (isFalling, confidence) = pose.isFallingPose()
        if isFalling {
            poseDetectedFall(confidence: confidence)
        } else {
            consecutiveFallFrames = 0
        }
    }
    
    private func yoloDetectedFall(confidence: Double) {
        // YOLO检测到摔倒直接触发警报
        DispatchQueue.main.async {
            self.fallDetected = true
            self.fallConfidence = confidence
        }
    }
    
    private func poseDetectedFall(confidence: Double) {
        // 增加连续检测计数
        consecutiveFallFrames += 1
        
        // 如果连续多帧都检测到摔倒，才触发警报
        if consecutiveFallFrames >= fallFrameThreshold {
            DispatchQueue.main.async {
                self.fallDetected = true
                self.fallConfidence = confidence
            }
        }
    }
    
    func requestHelp() {
        print("请求摔倒帮助")
        // 在此实现请求帮助的逻辑，如发送通知、呼叫紧急联系人等
    }
    
    func cancelFallAlert() {
        fallDetected = false
        consecutiveFallFrames = 0
    }
    
    func toggleDetection() {
        isDetecting.toggle()
        if !isDetecting {
            fallDetected = false
            consecutiveFallFrames = 0
        }
    }
    
    func togglePoseOverlay() {
        showPoseOverlay.toggle()
    }
}

extension FallDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetecting, !fallDetected, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        processFrame(pixelBuffer)
    }
} 