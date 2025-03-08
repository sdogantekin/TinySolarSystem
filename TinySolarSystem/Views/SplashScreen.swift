import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    // Define our delightful yellow color
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        if isActive {
            MainView()
        } else {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Stars background
                StarsBackground()
                
                VStack {
                    Image(systemName: "sun.max.stars")
                        .font(.system(size: 80))
                        .foregroundColor(accentColor)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text("Tiny Solar System")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                    
                    Text("Explore the wonders of our tiny solar system!")
                        .font(.headline)
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(.top, 2)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .padding(.top, 30)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                // Simulate loading time
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct StarsBackground: View {
    let starsCount = 200
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<starsCount, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...1.0)))
                    .frame(width: Double.random(in: 1...3))
                    .position(
                        x: Double.random(in: 0...geometry.size.width),
                        y: Double.random(in: 0...geometry.size.height)
                    )
            }
        }
    }
}

#Preview {
    SplashScreen()
} 
