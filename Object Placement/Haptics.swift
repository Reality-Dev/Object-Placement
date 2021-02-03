//
//  Haptics.swift
//  Hello Augmented World
//
//  Created by Grant Jarvis on 7/30/20.
//


import UIKit
import CoreHaptics



extension ViewController {
    
    func createAndStartHapticEngine() {
        guard supportsHaptics else { return }
        
        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine()
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        
        // The stopped handler alerts engine stoppage.
        engine.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                print("Audio session interrupt")
            case .applicationSuspended:
                print("Application suspended")
            case .idleTimeout:
                print("Idle timeout")
            case .notifyWhenFinished:
                print("Finished")
            case .systemError:
                print("System error")
            default:
                print("Breaking")
                break
            }
            
            // Indicate that the next time the app requires a haptic, the app must call engine.start().
            self.engineNeedsStart = true
        }
        
        // The reset handler notifies the app that it must reload all its content.
        // If necessary, it recreates all players and restarts the engine in response to a server restart.
        engine.resetHandler = {
            print("The engine reset --> Restarting now!")
            
            // Tell the rest of the app to start the engine the next time a haptic is necessary.
            self.engineNeedsStart = true
        }
        
        // Start haptic engine to prepare for use.
        do {
            try engine.start()
            
            // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
            engineNeedsStart = false
        } catch let error {
            print("The engine failed to start with error: \(error)")
        }
    }
    
    
    
    public func addObservers() {

        backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                 object: nil,
                                                                 queue: nil) { [weak self] _ in
            guard let self = self, self.supportsHaptics else { return }
            
            // Stop the haptic engine.
            self.engine.stop { error in
                if let error = error {
                    print("Haptic Engine Shutdown Error: \(error)")
                    return
                }
                self.engineNeedsStart = true
            }

        }

        foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                 object: nil,
                                                                 queue: nil) { [weak self] _ in
            guard let self = self, self.supportsHaptics else { return }
                                                                    
            // Restart the haptic engine.
            self.engine.start { error in
                if let error = error {
                    print("Haptic Engine Startup Error: \(error)")
                    return
                }
                self.engineNeedsStart = false
            }
        }
    }
    
    
    /// - Tag: MapVelocity

    func makeHapticBump(){
            // Play collision haptic for supported devices.
            guard supportsHaptics else { return }
            
            // Play haptic here.
            do {
                // Start the engine if necessary.
                if engineNeedsStart {
                    try engine.start()
                    engineNeedsStart = false
                }
                
                
                // Create a haptic pattern player from normalized magnitude.
                let hapticPlayer = try playerForMagnitude(1.0)
                
                // Start player and fire.
                try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
            } catch let error {
                print("Haptic Playback Error: \(error)")
            }
        }
    
        public func playerForMagnitude(_ magnitude: Float) throws -> CHHapticPatternPlayer? {
            let volume = linearInterpolation(alpha: magnitude, min: 0.4, max: 0.8)
            let decay: Float = linearInterpolation(alpha: magnitude, min: 0.0, max: 0.1)
            let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
                CHHapticEventParameter(parameterID: .audioPitch, value: -0.15),
                CHHapticEventParameter(parameterID: .audioVolume, value: volume),
                CHHapticEventParameter(parameterID: .decayTime, value: decay),
                CHHapticEventParameter(parameterID: .sustained, value: 0)
            ], relativeTime: 0)
            
            let sharpness = linearInterpolation(alpha: magnitude, min: 0.9, max: 0.5)
            let intensity = linearInterpolation(alpha: magnitude, min: 0.375, max: 1.0)
            let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            ], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [audioEvent, hapticEvent], parameters: [])
            return try engine.makePlayer(with: pattern)
    }
    
    
    private func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + (alpha * (max - min))
        //where I am (min) +
        // a portion of the difference between where want to be and where I am.
    }
    
    
    
}
