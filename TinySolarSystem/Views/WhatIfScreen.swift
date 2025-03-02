import SwiftUI

struct WhatIfScreen: View {
    @ObservedObject var model: SolarSystemModel
    @Environment(\.presentationMode) var presentationMode
    
    // Define our delightful yellow color to match the main screen
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Experiment with the Solar System")
                            .font(.headline)
                            .foregroundColor(accentColor)
                            .padding(.top)
                        
                        // List all planets with toggles and sliders
                        ForEach(model.celestialBodies.filter { $0.type == .planet || $0.type == .dwarfPlanet }) { body in
                            PlanetControlCard(
                                model: model,
                                celestialBody: body
                            )
                        }
                        
                        // Reset all button
                        Button(action: {
                            model.resetChanges()
                        }) {
                            Text("Reset All Changes")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .foregroundColor(accentColor)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(accentColor, lineWidth: 1)
                                )
                        }
                        .padding(.vertical)
                    }
                    .padding()
                }
            }
            .navigationTitle("What If Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PlanetControlCard: View {
    @ObservedObject var model: SolarSystemModel
    var celestialBody: CelestialBody
    
    // Helper function to get the current body from the model
    private func getCurrentBody() -> CelestialBody? {
        return model.celestialBodies.first(where: { $0.id == celestialBody.id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(celestialBody.texture)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                Text(celestialBody.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Break down the complex binding
                let isVisible = Binding<Bool>(
                    get: { 
                        let body = self.getCurrentBody()
                        return !(body?.isRemoved ?? false)
                    },
                    set: { newValue in
                        if newValue {
                            self.model.restoreCelestialBody(id: celestialBody.id)
                        } else {
                            self.model.removeCelestialBody(id: celestialBody.id)
                        }
                    }
                )
                
                Toggle("", isOn: isVisible)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
            }
            
            // Get the current body state
            if let currentBody = getCurrentBody(), !currentBody.isRemoved {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance from Sun: \(String(format: "%.2f", currentBody.distanceFromSun)) AU")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("0.2")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Break down the complex binding
                        let distanceBinding = Binding<Double>(
                            get: { 
                                return self.getCurrentBody()?.distanceFromSun ?? celestialBody.distanceFromSun
                            },
                            set: { newValue in
                                self.model.updateDistanceFromSun(id: celestialBody.id, newDistance: newValue)
                            }
                        )
                        
                        Slider(value: distanceBinding, in: 0.2...50)
                            .accentColor(Color.accentColor)
                        
                        Text("50")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Display recalculated orbital period
                    Text("Orbital Period: \(String(format: "%.1f", currentBody.orbitalPeriod)) Earth days")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    // Display temperature
                    if let temp = currentBody.temperature {
                        Text("Temperature: \(currentBody.formattedTemperature())")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        // Show habitable zone indicator
                        if currentBody.isInHabitableZone() {
                            Text("Potentially Habitable! 🌱")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Display warning for unstable moons if applicable
                    if currentBody.type == .planet && currentBody.moonCount > 0 {
                        // Check if any moons are unstable
                        let moons = model.celestialBodies.filter { $0.parentBodyID == currentBody.id }
                        let unstableMoons = moons.filter { $0.isRemoved && $0.removalReason != nil }
                        
                        if !unstableMoons.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warning: Unstable Moons!")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                
                                ForEach(unstableMoons) { moon in
                                    Text("• \(moon.name): \(moon.removalReason ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(6)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                    
                    Button(action: {
                        self.model.resetDistanceFromSun(id: celestialBody.id)
                    }) {
                        Text("Reset")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                }
            } else if let currentBody = getCurrentBody(), let reason = currentBody.removalReason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    WhatIfScreen(model: SolarSystemModel())
} 