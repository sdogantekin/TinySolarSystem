import SwiftUI

struct ErrorScreen: View {
    let errorType: ErrorType
    let retryAction: () -> Void
    
    enum ErrorType {
        case apiFailure
        case offline
        
        var title: String {
            switch self {
            case .apiFailure:
                return "Something Went Wrong"
            case .offline:
                return "No Internet Connection"
            }
        }
        
        var message: String {
            switch self {
            case .apiFailure:
                return "We couldn't load the solar system data. Please try again later."
            case .offline:
                return "Please check your internet connection and try again."
            }
        }
        
        var icon: String {
            switch self {
            case .apiFailure:
                return "exclamationmark.triangle"
            case .offline:
                return "wifi.slash"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            StarsBackground()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: errorType.icon)
                    .font(.system(size: 70))
                    .foregroundColor(.yellow)
                
                Text(errorType.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(errorType.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: retryAction) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 200)
                        .background(Color.yellow)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ErrorScreen(errorType: .apiFailure, retryAction: {})
} 