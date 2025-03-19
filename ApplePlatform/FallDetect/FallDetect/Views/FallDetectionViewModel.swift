import SwiftUI
import AVFoundation
import Vision
import CoreML

class FallDetectionViewModel: NSObject, ObservableObject {
    @Published var isDetecting = false
    @Published var fallDetected = false
    @Published var fallConfidence: Double = 0.0
    @Published var detectedObjects: [DetectedObject] = []
    
    @Published var session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var yoloModel: VNCoreMLModel?
    
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
                print("模型加载成功")
            } catch {
                print("加载模型失败: \(error)")
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
                            self.fallDetected = true
                            self.fallConfidence = Double(confidence)
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
            print("视觉请求失败: \(error)")
        }
    }
    
    func requestHelp() {
        print("请求摔倒帮助")
        // 在此实现请求帮助的逻辑，如发送通知、呼叫紧急联系人等
    }
    
    func cancelFallAlert() {
        fallDetected = false
    }
    
    func toggleDetection() {
        isDetecting.toggle()
    }
    
    func resetDetection() {
        fallDetected = false
        fallConfidence = 0.0
    }
}

extension FallDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetecting, !fallDetected, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        processFrame(pixelBuffer)
    }
} 