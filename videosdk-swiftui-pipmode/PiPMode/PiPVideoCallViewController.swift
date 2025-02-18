//
//  PiPVideoCallViewController.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//

import UIKit
import AVKit
import VideoSDKRTC

class PiPVideoCallViewController: AVPictureInPictureVideoCallViewController {
    private weak var meetingViewController: MeetingViewController?
    var pipController: AVPictureInPictureController?
    private var containerView: PiPContainerView?
    
    init(meetingViewController: MeetingViewController) {
        self.meetingViewController = meetingViewController
        super.init(nibName: nil, bundle: nil)
        loadViewIfNeeded() // Force view to load immediately
        setupViews()
        setupPiPController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Always keep video stream alive in PiP
        if pipController?.isPictureInPictureActive == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.updateVideoTracks()
            }
        }
    }

    
    private func setupViews() {
        containerView = PiPContainerView(frame: view.bounds)
        if let containerView = containerView {
            view.addSubview(containerView)
            containerView.frame = view.bounds
            containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            updateVideoTracks()
        }
    }
    
    private func setupPiPController() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("PiP is not supported on this device")
            return
        }
        
        // Create PiP controller with proper source view
        let source = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: containerView ?? view,
            contentViewController: self
        )
        
        pipController = AVPictureInPictureController(contentSource: source)
        
        if let pipController = pipController {
            pipController.delegate = self
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
        } else {
            print("Failed to create PiP controller")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        containerView?.frame = view.bounds
    }
    
    func updateVideoTracks() {
        guard let meetingViewController = meetingViewController,
              let containerView = containerView else { return }
        
        // Get local track
        var localTrack: RTCVideoTrack? = nil
        if let localParticipant = meetingViewController.meeting?.localParticipant,
           let localStream = localParticipant.streams.first(where: { $1.kind == .state(value: .video) })?.value,
           let track = localStream.track as? RTCVideoTrack {
            localTrack = track
            print("Found local track for participant: \(localParticipant.id)")
        }
        
        // Get remote track from the first non-local participant
        var remoteTrack: RTCVideoTrack? = nil
        if let remoteParticipant = meetingViewController.participants.first(where: { !$0.isLocal }),
           let remoteStream = remoteParticipant.streams.first(where: { $1.kind == .state(value: .video) })?.value,
           let track = remoteStream.track as? RTCVideoTrack {
            remoteTrack = track
            print("Found remote track for participant: \(remoteParticipant.id)")
        }
        
        // Update both tracks
        containerView.updateVideoTracks(local: localTrack, remote: remoteTrack)
    }
    
    func startPiP() {
        // Ensure PiP controller exists
        if pipController == nil {
            setupPiPController()
        }
        guard let pipController = pipController else {
            return
        }
        
        if pipController.isPictureInPictureActive {
            return
        }
        // Ensure we have a video track
        updateVideoTracks()
        
        // Add view to window hierarchy if needed
        if view.window == nil {
            print("Adding view to window hierarchy")
            if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                keyWindow.addSubview(view)
                view.frame = keyWindow.bounds
                print("Added view to key window")
            } else {
                print("No key window found")
            }
        }
        
        // Start PiP with a slight delay to ensure view hierarchy is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if pipController.isPictureInPicturePossible {
                print("Starting PiP controller")
                pipController.startPictureInPicture()
            }
        }
    }
    
    func stopPiP() {
        guard let pipController = pipController,
              pipController.isPictureInPictureActive else { return }
        pipController.stopPictureInPicture()
        view.removeFromSuperview()
    }
}

extension PiPVideoCallViewController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        meetingViewController?.isPiPActive = true
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        meetingViewController?.isPiPActive = true
        // Re-enable tracks after PiP starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateVideoTracks()
        }
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        meetingViewController?.isPiPActive = false
        view.removeFromSuperview()
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        updateVideoTracks()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        meetingViewController?.isPiPActive = false
        view.removeFromSuperview()
    }
}
 
