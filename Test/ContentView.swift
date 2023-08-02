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
    
//TEST ON DEVICE
//    @State var audioEngine = AVAudioEngine()
//    @State var speechRecognizer = SFSpeechRecognizer()
//    @State var request = SFSpeechAudioBufferRecognitionRequest()
//    @State var recognitionTask: SFSpeechRecognitionTask?
//    @State var transcriptionOutputLabel = ""
//
    
    @State var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    @State var transcript = ""
    @State var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    @State var recognitionTask: SFSpeechRecognitionTask?
    
    @State var audioEngine = AVAudioEngine()
    
    var body: some View{
        
        NavigationSplitView{
            VStack{
                List(self.audios,id: \.self){
                    i in
                    Text(i.relativeString)
                }
                Button("Hear/Reset"){
                    do {
                        self.getAudios()
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
                        self.getAudios()

                      }
                    catch {
                        // couldn't load file :(
                    }
                }
                Button(action: {
                    // Initialziation
                    recordButtonTapped()
                //store aduio in document directory
                    //if self.record {
                        //TEST ON DEVICE
//                        self.audioEngine.stop()
//                        self.request.endAudio()
//                        self.recognitionTask?.cancel()
                       //audioEngine.inputNode.removeTap(onBus: 0)
                       
                   //     return
                   // }
                    
                    // TEST ON DEVICE
//                    let node = audioEngine.inputNode
//                    let recordingFormat = node.outputFormat(forBus: 0)
//                    node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
//                        self.request.append(buffer)
//                    }
//                    
//                    audioEngine.prepare()
//                       do {
//                           try audioEngine.start()
//                       } catch {
//                           //Nothing
//                       }
//                    
//                    
//                    self.recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { (result, _) in
//                        if let transcription = result?.bestTranscription {
//                            self.transcriptionOutputLabel = transcription.formattedString
//                        }
//                        })
                    //self.record.toggle()
                        
                    
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
                Text(self.transcript)
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
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        self.record = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.transcript = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.record = false
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.record = true
        } else {
            self.record = false
        }
    }
    
    func recordButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.record = false
        } else {
            do {
                try startRecording()
            } catch {
            }
        }
    }
}
