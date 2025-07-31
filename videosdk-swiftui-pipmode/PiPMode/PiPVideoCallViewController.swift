//
//  PiPVideoCallViewController.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//

import UIKit
import AVKit
import VideoSDKRTC

class PiPVideoCallViewController: NSObject, AVPictureInPictureControllerDelegate {
    private weak var meetingViewController: MeetingViewController?
     var pipController: AVPictureInPictureController?
    private var pipViewController: AVPictureInPictureVideoCallViewController?
    private var containerView: PiPContainerView?

    init(meetingViewController: MeetingViewController) {
        self.meetingViewController = meetingViewController
        super.init()
        setupContainerView()
    }

    private func setupContainerView() {
        containerView = PiPContainerView(frame: UIScreen.main.bounds)
        if let containerView = containerView {
            updateVideoTracks()
        }
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
        }
        
        // Get remote track from the first non-local participant
        var remoteTrack: RTCVideoTrack? = nil
        if let remoteParticipant = meetingViewController.participants.first(where: { !$0.isLocal }),
           let remoteStream = remoteParticipant.streams.first(where: { $1.kind == .state(value: .video) })?.value,
           let track = remoteStream.track as? RTCVideoTrack {
            remoteTrack = track
        }

        containerView.updateVideoTracks(local: localTrack, remote: remoteTrack)
        
    }

    func setupPiP() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  AVPictureInPictureController.isPictureInPictureSupported(),
                  let rootView = UIApplication.shared.connectedScenes
                      .compactMap({ $0 as? UIWindowScene })
                      .flatMap({ $0.windows })
                      .first(where: { $0.isKeyWindow })?.rootViewController?.view,
                  let containerView = self.containerView else {
                return
            }

            let pipVC = AVPictureInPictureVideoCallViewController()
            pipVC.preferredContentSize = CGSize(width: 120, height: 90)

            pipVC.view.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: pipVC.view.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: pipVC.view.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: pipVC.view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: pipVC.view.trailingAnchor)
            ])

            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: rootView,
                contentViewController: pipVC
            )

            self.pipController = AVPictureInPictureController(contentSource: contentSource)
            self.pipController?.delegate = self
            self.pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            self.pipViewController = pipVC

        }
    }

    func startPiP() {
        setupPiP()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if self.pipController?.isPictureInPictureActive == false {
                self.pipController?.startPictureInPicture()
            }
        }
    }

    func stopPiP() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.pipController?.isPictureInPictureActive == true {
                self.pipController?.stopPictureInPicture()
            }
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        if let view = self.containerView {
            view.removeFromSuperview()
        }
        pipViewController = nil
        pipController = nil
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        meetingViewController?.isPiPActive = true
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        meetingViewController?.isPiPActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateVideoTracks()
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        meetingViewController?.isPiPActive = false
        if let view = self.containerView {
            view.removeFromSuperview()
        }
        pipViewController = nil
        pipController = nil
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        updateVideoTracks()
    }
}
 
