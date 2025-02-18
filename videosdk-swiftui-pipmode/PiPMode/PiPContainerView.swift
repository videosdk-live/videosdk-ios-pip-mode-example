//
//  PiPContainerView.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//

import UIKit
import VideoSDKRTC
import AVKit

class PiPContainerView: UIView {
    private let localVideoView: PiPVideoView
    private let remoteVideoView: PiPVideoView
    private var localTrack: RTCVideoTrack?
    private var remoteTrack: RTCVideoTrack?
    
    override init(frame: CGRect) {
        localVideoView = PiPVideoView(frame: .zero)
        remoteVideoView = PiPVideoView(frame: .zero)
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Add video views with remote first (as background)
        addSubview(remoteVideoView)
        addSubview(localVideoView)
        
        // Configure views
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Remote video view (full screen)
            remoteVideoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            remoteVideoView.topAnchor.constraint(equalTo: topAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Local video view (smaller, in corner)
            localVideoView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            localVideoView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            localVideoView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.25),
            localVideoView.heightAnchor.constraint(equalTo: localVideoView.widthAnchor, multiplier: 16.0/9.0)
        ])
        
        // Set background colors
        backgroundColor = .black
        localVideoView.backgroundColor = .black
        remoteVideoView.backgroundColor = .black
    }
    
    func updateVideoTracks(local: RTCVideoTrack?, remote: RTCVideoTrack?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update remote track
            if self.remoteTrack !== remote {
                self.remoteTrack = remote
                if let remote = remote {
                    remote.isEnabled = true
                    self.remoteVideoView.addVideoTrack(remote)
                } else {
                    self.remoteVideoView.removeCurrentTrack()
                }
            }
            
            // Update local track
            if self.localTrack !== local {
                self.localTrack = local
                if let local = local {
                    local.isEnabled = true
                    self.localVideoView.addVideoTrack(local)
                } else {
                    self.localVideoView.removeCurrentTrack()
                }
            }
        }
    }
    
    deinit {
        localVideoView.removeCurrentTrack()
        remoteVideoView.removeCurrentTrack()
    }
}
