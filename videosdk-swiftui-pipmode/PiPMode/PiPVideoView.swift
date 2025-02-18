//
//  PiPVideoView.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//

import UIKit
import VideoSDKRTC
import AVKit

class PiPVideoView: UIView {
    private var frameProcessor: PiPFrameProcessor?
    private var currentTrack: RTCVideoTrack?
    private var displayLayer: AVSampleBufferDisplayLayer?
    
    private var isRendering = false
    private var isActive = true
    
    override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        displayLayer = layer as? AVSampleBufferDisplayLayer
        displayLayer?.videoGravity = .resizeAspectFill
        displayLayer?.backgroundColor = CGColor(gray: 0, alpha: 1)
        
        if let displayLayer = displayLayer {
            displayLayer.videoGravity = .resizeAspectFill
            displayLayer.flushAndRemoveImage()
            
            // Set real-time properties
            if #available(iOS 13.0, *) {
                displayLayer.preventsDisplaySleepDuringVideoPlayback = true
            }
            
            // Create frame processor immediately
            frameProcessor = PiPFrameProcessor(displayLayer: displayLayer)
        }
        
        backgroundColor = .black
        isOpaque = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer?.frame = bounds
        
        // Re-enable track after layout
        if let currentTrack = currentTrack {
            currentTrack.isEnabled = true
        }
    }
    
    func addVideoTrack(_ track: RTCVideoTrack) {
        removeCurrentTrack()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isActive = true
            track.isEnabled = true
            
            if let frameProcessor = self.frameProcessor {
                track.add(frameProcessor)
                self.currentTrack = track
            }
        }
    }
    
    func removeCurrentTrack() {
        guard !isRendering else { return }
        isRendering = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                self?.isRendering = false
                return
            }
            
            if let currentTrack = self.currentTrack,
               let frameProcessor = self.frameProcessor {
                currentTrack.remove(frameProcessor)
                self.currentTrack = nil
            }
            
            self.displayLayer?.flushAndRemoveImage()
            self.isRendering = false
        }
    }
    
    deinit {
        removeCurrentTrack()
    }
}
