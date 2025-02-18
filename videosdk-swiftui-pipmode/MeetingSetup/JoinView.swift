//
//  JoinView.swift
//  videosdk-swiftui-pipmode
//
//  Created by Deep Bhupatkar on 18/02/25.
//

import SwiftUI

struct JoinView: View {

    // State variables for
    @State var meetingId: String
    @State var name: String

    var body: some View {

            NavigationView {

                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VideoSDK")
                            .font(.largeTitle.bold())

                        Text("""
                             Picture-in-Picture Mode
                             Example in SwiftUI
                             """)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.gray)
                    }
                    .padding()

                    TextField("Enter MeetingId", text: $meetingId)
                        .foregroundColor(Color.black)
                        .autocorrectionDisabled()
                        .font(.headline)
                        .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .padding()
                            .offset(x: 10)
                            .foregroundColor(Color.gray)
                            .opacity(meetingId.isEmpty ? 0.0 : 1.0)
                            .onTapGesture {
                                UIApplication.shared.endEditing()
                                meetingId = ""
                            }
                        , alignment: .trailing)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.secondary.opacity(0.5))
                                .shadow(color: Color.gray.opacity(0.10), radius: 10))
                        .padding(.leading)
                        .padding(.trailing)

                    Text("Enter Meeting Id to join an existing meeting")

                    TextField("Enter Your Name", text: $name)
                        .foregroundColor(Color.black)
                        .autocorrectionDisabled()
                        .font(.headline)
                        .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .padding()
                            .offset(x: 10)
                            .foregroundColor(Color.gray)
                            .opacity(name.isEmpty ? 0.0 : 1.0)
                            .onTapGesture {
                                UIApplication.shared.endEditing()
                                name = ""
                            }
                        , alignment: .trailing)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.secondary.opacity(0.5))
                                .shadow(color: Color.gray.opacity(0.10), radius: 10))
                        .padding()

                    if meetingId.isEmpty == false {
                        NavigationLink(destination:{
                            if meetingId.isEmpty == false {
                                MeetingView(meetingId: self.meetingId, userName: name ?? "Guest")
                                    .navigationBarBackButtonHidden(true)
                            } else {
                            }
                        }) {
                            Text("Join Meeting")
                                .foregroundColor(Color.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 25.0)
                                        .fill(Color.blue))                    }
                    }

                    NavigationLink(destination: MeetingView(userName: name ?? "Guest")
                        .navigationBarBackButtonHidden(true)) {
                        Text("Start Meeting")
                            .foregroundColor(Color.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25.0)
                                    .fill(Color.blue))                    }
                }
            }
        }
    }

// preview to show screen into your canvas
#Preview {
    JoinView(meetingId: "", name: "")
}

extension UIApplication {

    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
