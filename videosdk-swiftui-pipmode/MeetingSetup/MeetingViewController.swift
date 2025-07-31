//
//  MeetingViewController.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//


import Foundation
import VideoSDKRTC
import AVKit

class MeetingViewController: ObservableObject {

    var token = "YOUR_TOKEN_HERE"
    var meetingId: String = ""
    var name: String = ""

    @Published var meeting: Meeting? = nil
    @Published var localParticipantView: VideoView? = nil
    @Published var videoTrack: RTCVideoTrack?
    @Published var participants: [Participant] = []
    @Published var meetingID: String = ""
    
    // for pip
    private var pipVideoCallViewController: PiPVideoCallViewController?
    @Published var isPiPActive = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid


    func initializeMeeting(meetingId: String, userName: String) {
        meeting = VideoSDK.initMeeting(
            meetingId: meetingId,
            participantName: userName,
            micEnabled: true,
            webcamEnabled: true
        )
        meeting?.join()
        meeting?.addEventListener(self)
        setupBackgroundHandling()
        startPiP()

    }
    
    private func setupBackgroundHandling() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleWillResignActive),
                                              name: UIApplication.willResignActiveNotification,
                                              object: nil)

        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleEnterBackground),
                                            name: UIApplication.didEnterBackgroundNotification,
                                            object: nil)
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleEnterForeground),
                                            name: UIApplication.willEnterForegroundNotification,
                                            object: nil)
    }
    
    @objc private func handleWillResignActive() {
        print("App will resign active")
        if !isPiPActive {
            startPiP()
        }
    }

    @objc private func handleEnterBackground() {
        print("App entering background")
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        if let localParticipant = meeting?.localParticipant {
            localParticipant.enableWebcam()
        }
        
        if !isPiPActive {
            startPiP()
        }
    }
    
    @objc private func handleEnterForeground() {
        print("App entering foreground")
        endBackgroundTask()
        
        if let localParticipant = meeting?.localParticipant {
            localParticipant.enableWebcam()
        }
        
        if isPiPActive {
            startPiP()
            updatePiPVideoTrack()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - PiP Integration

    func startPiP() {
        if pipVideoCallViewController == nil {
            pipVideoCallViewController = PiPVideoCallViewController(meetingViewController: self)
        }
        pipVideoCallViewController?.setupPiP()
        isPiPActive = true
    }
    
    func stopPiP() {
        pipVideoCallViewController?.stopPiP()
        isPiPActive = false
    }

    func updatePiPVideoTrack() {
        pipVideoCallViewController?.updateVideoTracks()
    }
}

extension MeetingViewController: MeetingEventListener {

    func onMeetingJoined() {

        guard let localParticipant = self.meeting?.localParticipant else { return }

        // add to list
        participants.append(localParticipant)

        // add event listener
        localParticipant.addEventListener(self)

        localParticipant.setQuality(.high)
    }

    func onParticipantJoined(_ participant: Participant) {

        participants.append(participant)

        // add listener
        participant.addEventListener(self)

        participant.setQuality(.high)
    }

    func onParticipantLeft(_ participant: Participant) {
        participants = participants.filter({ $0.id != participant.id })
    }

    func onMeetingLeft() {

        meeting?.localParticipant.removeEventListener(self)
        meeting?.removeEventListener(self)
    }

    func onMeetingStateChanged(meetingState: MeetingState) {
        switch meetingState {

        case .DISCONNECTED:
            participants.removeAll()

        default:
            print("")
        }
    }
}

extension MeetingViewController: ParticipantEventListener {
    func onStreamEnabled(_ stream: MediaStream, forParticipant participant: Participant) {

        if participant.isLocal {
            if let track = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = track
                }
            }
        } else {
            if let track = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = track
                }
            }
        }
    }

    func onStreamDisabled(_ stream: MediaStream, forParticipant participant: Participant) {

        if participant.isLocal {
            if let _ = stream.track as? RTCVideoTrack {
                DispatchQueue.main.async {
                    self.videoTrack = nil
                }
            }
        } else {
            self.videoTrack = nil
        }
    }
}

extension MeetingViewController {
    // create a new meeting id
    func joinRoom(userName: String) {

        let urlString = "https://api.videosdk.live/v2/rooms"
        let session = URLSession.shared
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(self.token, forHTTPHeaderField: "Authorization")

        session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in

            if let data = data, let utf8Text = String(data: data, encoding: .utf8)
            {
                print("UTF =>=>\(utf8Text)") // original server data as UTF8 string
                do{
                    let dataArray = try JSONDecoder().decode(RoomStruct.self,from: data)
                    DispatchQueue.main.async {
                        print(dataArray.roomID)
                        self.meetingID = dataArray.roomID!
                        self.joinMeeting(meetingId: dataArray.roomID!, userName: userName)
                    }
                    print(dataArray)
                } catch {
                    print(error)
                }
            }
        }
        ).resume()
    }

    // initialise a meeting with give meeting id (either new or existing)
    func joinMeeting(meetingId: String, userName: String) {

        if !token.isEmpty {
            // use provided token for the meeting
            self.meetingID = meetingId
            self.initializeMeeting(meetingId: meetingId, userName: userName)
        }
        else {
            print("Auth token required")
        }
    }
}

struct RoomStruct: Codable {
    let roomID: String?

    enum CodingKeys: String, CodingKey {
        case roomID = "roomId"
    }
}
