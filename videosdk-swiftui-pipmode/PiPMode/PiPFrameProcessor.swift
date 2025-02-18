//
//  PiPFrameProcessor.swift
//  VideoSDKSwiftUIExample
//
//  Created by Deep Bhupatkar on 17/02/25.
//
import VideoSDKRTC
import AVFoundation

class PiPFrameProcessor: NSObject, RTCVideoRenderer {
    private weak var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private var pixelBufferPool: CVPixelBufferPool?
    private var currentSize: CGSize = .zero
    private let maxFrameRate: Int32 = 25
    
    private let frameQueue = DispatchQueue(label: "com.videosdk.rtc.frame", qos: .userInteractive)
    private let processingQueue = DispatchQueue(label: "com.videosdk.rtc.processing", qos: .userInteractive)
    private var frameBuffer: RTCVideoFrame?
    private var isProcessing = false
    
    init(displayLayer: AVSampleBufferDisplayLayer) {
        super.init()
        self.sampleBufferDisplayLayer = displayLayer
    }
    
    func setSize(_ size: CGSize) {
        currentSize = size
        setupPixelBufferPool(with: size)
    }
    
    private func setupPixelBufferPool(with size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: 3]
        let pixelAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferMetalCompatibilityKey as String: true
        ] as [String : Any]
        
        CVPixelBufferPoolCreate(kCFAllocatorDefault,
                              poolAttributes as CFDictionary,
                              pixelAttributes as CFDictionary,
                              &pixelBufferPool)
    }
    
    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else { return }
        
        frameQueue.async { [weak self] in
            self?.processNewFrame(frame)
        }
    }
    
    private func processNewFrame(_ frame: RTCVideoFrame) {
        // Store latest frame
        frameBuffer = frame
        
        // Process if not already processing
        if !isProcessing {
            processNextFrame()
        }
    }
    
    private func processNextFrame() {
        guard !isProcessing,
              let frame = frameBuffer,
              let displayLayer = sampleBufferDisplayLayer else { return }
        
        isProcessing = true
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            autoreleasepool {
                if let pixelBuffer = self.getPixelBuffer(from: frame),
                   let sampleBuffer = self.createSampleBuffer(from: pixelBuffer) {
                    DispatchQueue.main.async {
                        displayLayer.enqueue(sampleBuffer)
                        self.isProcessing = false
                        // Process next frame if available
                        if self.frameBuffer !== frame {
                            self.processNextFrame()
                        }
                    }
                } else {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        
        // Use more precise timing
        var timing = CMSampleTimingInfo()
        timing.presentationTimeStamp = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 90000)
        timing.duration = CMTime(value: 1, timescale: Int32(maxFrameRate))
        timing.decodeTimeStamp = .invalid
        
        var formatDesc: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                   imageBuffer: pixelBuffer,
                                                   formatDescriptionOut: &formatDesc)
        
        if let formatDesc = formatDesc {
            CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                             imageBuffer: pixelBuffer,
                                             dataReady: true,
                                             makeDataReadyCallback: nil,
                                             refcon: nil,
                                             formatDescription: formatDesc,
                                             sampleTiming: &timing,
                                             sampleBufferOut: &sampleBuffer)
        }
        
        return sampleBuffer
    }
    
    private func getPixelBuffer(from frame: RTCVideoFrame) -> CVPixelBuffer? {
        if let cvBuffer = frame.buffer as? RTCCVPixelBuffer {
            return cvBuffer.pixelBuffer
        }
        else if let i420Buffer = frame.buffer as? RTCI420Buffer {
            return createPixelBuffer(from: i420Buffer, width: Int(frame.width), height: Int(frame.height))
        }
        return nil
    }
    
    private func createPixelBuffer(from i420Buffer: RTCI420Buffer, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ] as [String: Any]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       width,
                                       height,
                                       kCVPixelFormatType_32BGRA,
                                       attrs as CFDictionary,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        
        let yData = i420Buffer.dataY
        let uData = i420Buffer.dataU
        let vData = i420Buffer.dataV
        let yStride = Int(i420Buffer.strideY)
        let uStride = Int(i420Buffer.strideU)
        let vStride = Int(i420Buffer.strideV)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let bgraBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for row in 0..<height {
            for col in 0..<width {
                let yIndex = row * yStride + col
                let uvIndex = (row / 2) * uStride + (col / 2)
                
                let y = Int(yData[yIndex])
                let u = Int(uData[uvIndex]) - 128
                let v = Int(vData[uvIndex]) - 128
                
                // YUV to RGB conversion
                var r = (y * 298 + v * 409 + 128) >> 8
                var g = (y * 298 - u * 100 - v * 208 + 128) >> 8
                var b = (y * 298 + u * 516 + 128) >> 8
                
                // Clamp values
                r = max(0, min(255, r))
                g = max(0, min(255, g))
                b = max(0, min(255, b))
                
                let pixelOffset = row * bytesPerRow + col * 4
                
                // BGRA format
                bgraBuffer[pixelOffset + 0] = UInt8(b)     // B
                bgraBuffer[pixelOffset + 1] = UInt8(g)     // G
                bgraBuffer[pixelOffset + 2] = UInt8(r)     // R
                bgraBuffer[pixelOffset + 3] = 255          // A
            }
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
    
    deinit {
        pixelBufferPool = nil
        sampleBufferDisplayLayer?.flushAndRemoveImage()
    }
}
