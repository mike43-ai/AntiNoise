import SwiftUI

enum AppMotion {
    static let quick:    Animation = .easeOut(duration: 0.15)
    static let standard: Animation = .easeInOut(duration: 0.25)
    static let slow:     Animation = .easeInOut(duration: 0.40)
}
