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
                    
                //store aduio in document directory
                    if self.record {
                        //Already Started Recording
                        self.speechRecognizer.stopTranscribing()
                        self.record.toggle()
                        return
                    }
                    
                    self.speechRecognizer.resetTranscript()
                    self.speechRecognizer.startTranscribing()
                    self.record.toggle()
                    
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
                Text(self.speechRecognizer.transcript)
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
