//  ContentView.swift
//  Audio Recorder
//
//  Created by Kavsoft on 03/06/20.
//  Copyright © 2020 Kavsoft. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import Speech


struct ContentView: View {
  var body: some View {
      
      Home()
          // always dark mode...
          .preferredColorScheme(.dark)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
      ContentView()
  }
}

struct Home : View {
    
    @State var record = false
    // Fetch Audios...
    @State var session: AVAudioSession!
    @State var recorder: AVAudioRecorder!
    @State var recorder2: AVAudioRecorder!
    @State var alert = false
    @State var audios: [URL] = []
    @State var player: AVAudioPlayer?
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State var transcript = ""
    var body: some View{
        
        NavigationSplitView{
            VStack{
                List(self.audios,id: \.self){
                    i in
                    Text(i.relativeString)
                }
                Button("Hear/Reset"){
                    do {
                        var u = self.audios[0]
                        self.player = try AVAudioPlayer(contentsOf: u)
                        self.player?.play()
                       let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        do {
                            for path in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
                                    
                            {
                                try FileManager.default.removeItem(at: path)
                           }
                        }
                        catch let error as NSError
                         {
                             print(error.localizedDescription)
                        }

                      }
                    catch {
                        // couldn't load file :(
                    }
                }
                Button(action: {
                    // Initialziation
                    
                    //store aduio in document directory
                    do{
                        if self.record {
                            //Already Started Recording
                            self.recorder.stop()
                            self.record.toggle()
                            //speechRecognizer.stopTranscribing()
                            //transcript = speechRecognizer.transcript
                            self.getAudios()
                            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
                            let request = SFSpeechURLRecognitionRequest(url: self.audios[0])

                            request.shouldReportPartialResults = true

                            if (recognizer?.isAvailable)! {

                                recognizer?.recognitionTask(with: request) { result, error in
                                    guard error == nil else { print("Error: \(error!)"); return }
                                    guard let result = result else { print("No result!"); return }

                                    transcript = result.bestTranscription.formattedString
                                }
                            } else {
                                print("Device doesn't support speech recognition")
                            }
                            return
                        }
                        
    
                        //speechRecognizer.resetTranscript()
                        //speechRecognizer.startTranscribing()
                        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let fileName = url.appendingPathComponent("myRcd\(self.audios.count + 1).m4a")
                        let settings = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        self.recorder = try AVAudioRecorder(url: fileName, settings: settings)
                        self.recorder.record()
                        self.record.toggle()
                        
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                    
                }) {
                    
                    ZStack{
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 90)
                        
                        if self.record{
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 6)
                                .frame(width: 85, height: 85)
                        }
                    }
                }
                .padding(.vertical, 25)
            }
            .navigationBarTitle("Record Audio")
        }
        detail: {
            VStack {
                Text(transcript)
            }
            .navigationTitle("Content")
            .padding()
        }.alert(isPresented: self.$alert, content: {
            Alert(title: Text("Error)"), message: Text("Enable Acess"))
        })
        .onAppear {
            
            do{
                //Initializing...
                self.session = AVAudioSession.sharedInstance()
                try self.session.setCategory(.playAndRecord)
                
                //requesting permission
                //for this we require microphone usage description in info.plist
                self.session.requestRecordPermission{(status) in
                    if !status{
                        //error messsage
                        self.alert.toggle()
                    }
                    else{
                        self.audios.removeAll()
                        // if permission granted means fetching all data...
                        self.getAudios()
                    }
                }
                
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }

    func getAudios(){
        do{
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            //fetch all data from docuemtn directory
            let result = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
            
            //updated means remove all old data
            self.audios.removeAll()
            
            
            for i in result{
                self.audios.append(i)
            }
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
}
