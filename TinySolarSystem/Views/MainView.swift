import SwiftUI
import Foundation

struct MainView: View {
    @StateObject private var model = SolarSystemModel()
    @State private var showWhatIfScreen = false
    @State private var selectedBody: CelestialBody? = nil
    @State private var showSpeedSlider = false
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var is3DView: Bool = false // Default to 2D view
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    
    // Define our delightful yellow color
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4) // Delightful inspiring yellow
    
    // Date formatter for displaying the current date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        ZStack {
            // Background with gestures
            Color.black
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    SimultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                self.dragOffset = CGSize(
                                    width: self.lastDragValue.width + value.translation.width,
                                    height: self.lastDragValue.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                self.lastDragValue = self.dragOffset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / self.lastScale
                                self.lastScale = value
                                
                                // Apply zoom with limits and smoother scaling
                                let newZoom = model.zoomLevel * Double(delta)
                                model.zoomLevel = min(max(newZoom, model.minZoomLevel), model.maxZoomLevel)
                            }
                            .onEnded { _ in
                                self.lastScale = 1.0
                            }
                    )
                )
            
            StarsBackground()
            
            // Solar System View without gestures
            SolarSystemView(model: model, dragOffset: $dragOffset, scale: scale, is3DView: is3DView)
            
            // Controls overlay
            VStack {
                // Top controls with title
                VStack {
                    // Title
                    Text("Tiny Solar System")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(.top, 10)
                    
                    // Current date display
                    Text(dateFormatter.string(from: model.currentDate))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(.top, 5)
                    
                    HStack {
                        // 2D/3D view switch
                        Button(action: {
                            withAnimation {
                                is3DView.toggle()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: is3DView ? "cube.fill" : "square.fill")
                                Text(is3DView ? "3D" : "2D")
                            }
                            .font(.headline)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // Zoom controls
                        HStack(spacing: 15) {
                            Button(action: {
                                model.zoomLevel = max(model.minZoomLevel, model.zoomLevel - 0.5)
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title2)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(accentColor)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(accentColor, lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                model.zoomLevel = min(model.maxZoomLevel, model.zoomLevel + 0.5)
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title2)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(accentColor)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(accentColor, lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                // Auto-adjust zoom to fit all visible planets
                                autoFitZoom()
                                // Reset drag offset when auto-fitting
                                dragOffset = .zero
                                lastDragValue = .zero
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.title2)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(accentColor)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(accentColor, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                Spacer()
                
                // Zoom level indicator has been removed
                
                Spacer()
                
                // Speed slider (appears when speed button is selected)
                if showSpeedSlider {
                    VStack(spacing: 15) {
                        Slider(
                            value: $model.speedFactor,
                            in: model.minSpeedFactor...model.maxSpeedFactor
                        )
                        .accentColor(accentColor)
                        .padding(.horizontal)
                        
                        Button("Done") {
                            withAnimation {
                                showSpeedSlider = false
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(accentColor)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(accentColor, lineWidth: 1)
                        )
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor, lineWidth: 1)
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Date picker sheet
                if showDatePicker {
                    VStack(spacing: 15) {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .accentColor(accentColor)
                        .padding()
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                withAnimation {
                                    showDatePicker = false
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                            
                            Button("Set Date") {
                                model.setDate(selectedDate)
                                withAnimation {
                                    showDatePicker = false
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(accentColor)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor, lineWidth: 1)
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom controls
                HStack(spacing: 20) {
                    // Reset button
                    Button(action: {
                        model.resetChanges()
                        model.resetSimulation()
                        model.speedFactor = 0.01 // Reset speed to default value
                        selectedDate = Date() // Reset to current date
                        // Reset drag offset and zoom
                        dragOffset = .zero
                        lastDragValue = .zero
                    }) {
                        Text("Reset")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                    }
                    
                    // Speed button
                    Button(action: {
                        withAnimation {
                            showSpeedSlider.toggle()
                        }
                    }) {
                        Text("Speed")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                    }
                    
                    // Date button
                    Button(action: {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    }) {
                        Text("Date")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                    }
                    
                    // What If button
                    Button(action: {
                        showWhatIfScreen.toggle()
                    }) {
                        Text("What If")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(accentColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
            }
            
            // Planet info popup
            if let body = selectedBody {
                CelestialBodyInfoView(celestialBody: body, isPresented: Binding(
                    get: { selectedBody != nil },
                    set: { if !$0 { selectedBody = nil } }
                ))
            }
        }
        .sheet(isPresented: $showWhatIfScreen) {
            WhatIfScreen(model: model)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Set up notification observer for celestial body selection
            NotificationCenter.default.addObserver(forName: Notification.Name("SelectCelestialBody"), object: nil, queue: .main) { notification in
                if let body = notification.object as? CelestialBody {
                    self.selectedBody = body
                }
            }
            
            // Initialize with current date
            selectedDate = Date()
            model.setDate(selectedDate)
        }
    }
    
    private func autoFitZoom() {
        // Find the furthest visible planet
        let visibleBodies = model.celestialBodies.filter { !$0.isRemoved }
        if let furthestBody = visibleBodies.max(by: { $0.distanceFromSun < $1.distanceFromSun }) {
            // Set zoom to fit the furthest planet
            // Adjust the scaling factor based on our new distance calculations
            if furthestBody.distanceFromSun <= 1.8 {
                // For inner planets only
                model.zoomLevel = 40.0 / (1.0 + furthestBody.distanceFromSun * 8.0)
            } else if furthestBody.distanceFromSun <= 10 {
                // For medium distance planets
                model.zoomLevel = 40.0 / (15.0 + (furthestBody.distanceFromSun - 1.8) * 3.0)
            } else {
                // For outer planets
                model.zoomLevel = 40.0 / (40.0 + log(furthestBody.distanceFromSun/10) * 10.0)
            }
            
            // Ensure zoom level is within reasonable bounds
            model.zoomLevel = min(max(model.zoomLevel, model.minZoomLevel), model.maxZoomLevel)
        }
    }
}

struct SolarSystemView: View {
    @ObservedObject var model: SolarSystemModel
    @Binding var dragOffset: CGSize
    var scale: CGFloat
    var is3DView: Bool
    
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        GeometryReader { geometry in
            // Main container for 3D transformation
            ZStack {
                // Center indicator for the Sun
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .blur(radius: 10)
                    
                    // Middle glow
                    Circle()
                        .fill(Color.yellow.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .blur(radius: 5)
                    
                    // Inner circle
                    Circle()
                        .fill(Color.yellow.opacity(0.8))
                        .frame(width: 30, height: 30)
                    
                    // Sun label removed
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .zIndex(10)
                .onTapGesture {
                    // Find the Sun in the model and post notification to select it
                    if let sun = model.celestialBodies.first(where: { $0.type == .star }) {
                        NotificationCenter.default.post(
                            name: Notification.Name("SelectCelestialBody"),
                            object: sun
                        )
                    }
                }
                
                // Draw orbits and bodies in a single coordinate system
                ForEach(model.celestialBodies) { body in
                    if !body.isRemoved {
                        Group {
                            // Draw orbit paths
                            if body.type != .star {
                                EllipticalOrbitPath(
                                    semiMajorAxis: body.distanceFromSun,
                                    eccentricity: body.eccentricity,
                                    scale: model.zoomLevel,
                                    bodyType: body.type
                                )
                                .stroke(accentColor.opacity(min(0.6, 0.3 + model.zoomLevel * 0.03)),
                                        lineWidth: min(1.5, 0.8 + model.zoomLevel * 0.07))
                            }
                            
                            // Draw celestial body
                            CelestialBodyView(celestialBody: body, model: model, geometry: geometry, is3DView: is3DView)
                        }
                    }
                }
            }
            .offset(dragOffset)
            .if(is3DView) { view in
                view.rotation3DEffect(
                    .degrees(30),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 1
                )
            }
        }
    }
}

struct CelestialBodyView: View {
    let celestialBody: CelestialBody
    let model: SolarSystemModel
    let geometry: GeometryProxy
    let is3DView: Bool
    
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        let position = calculatePosition()
        
        // Use a fixed large size for the Sun, and normal calculations for other bodies
        let size = celestialBody.type == .star 
            ? 100.0  // Fixed large size for the Sun (100 pixels)
            : celestialBody.displaySize(zoomLevel: model.zoomLevel)
        
        ZStack {
            // Add a glow effect for the Sun
            if celestialBody.type == .star {
                // Outer glow
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: size * 1.8, height: size * 1.8)
                    .blur(radius: 15)
                
                // Middle glow
                Circle()
                    .fill(Color.yellow.opacity(0.5))
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: 10)
                
                // Inner glow
                Circle()
                    .fill(Color.yellow.opacity(0.7))
                    .frame(width: size * 1.2, height: size * 1.2)
                    .blur(radius: 5)
            }
            
            // The celestial body
            Group {
                if celestialBody.type == .star {
                    Circle()
                        .fill(celestialBody.color)
                        .frame(width: size, height: size)
                } else {
                    // Use texture for planets and moons with lighting effect
                    ZStack {
                        Image(celestialBody.texture)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                        
                        // Add a radial gradient for day/night effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0),
                                        Color.black.opacity(0.7)
                                    ]),
                                    center: .leading,
                                    startRadius: size * 0.1,
                                    endRadius: size * 0.8
                                )
                            )
                            .frame(width: size, height: size)
                    }
                    .clipShape(Circle())
                    // Apply rotation based on the body's rotation period
                    .rotationEffect(.degrees(celestialBody.rotationPeriod != 0 
                        ? (360.0 * model.currentTime / abs(celestialBody.rotationPeriod)) * (celestialBody.rotationPeriod > 0 ? 1 : -1)
                        : 0))
                }
            }
            .if(is3DView && celestialBody.type != .star) { view in
                view.shadow(color: .black.opacity(0.7), radius: size * 0.2, x: size * 0.1, y: size * 0.1)
            }
            
            // Rings for gas giants (Jupiter, Saturn, Uranus, Neptune)
            if celestialBody.type == .planet && 
               (celestialBody.name == "Saturn" ||
                celestialBody.name == "Uranus" ) {
                PlanetRings(bodySize: size, 
                           ringColor: celestialBody.ringColor, 
                           is3DView: is3DView,
                           ringScale: celestialBody.name == "Saturn" ? 2.5 : 1.8,
                            ringCount: celestialBody.name == "Saturn" ? 2 : 1)
            }
            
            // Draw moons if this is a planet
            if celestialBody.type == .planet && !celestialBody.moons.isEmpty {
                ForEach(celestialBody.moons, id: \.id) { moon in
                    // Calculate moon's position relative to its parent planet
                    let moonAngle = (model.currentTime / moon.orbitalPeriod) * 2 * Double.pi + moon.initialPhaseAngle
                    let moonDistance = moon.distanceFromParent ?? 0
                    
                    // Calculate moon's size to be smaller than the parent planet
                    let moonSize = min(size * 0.3, moon.displaySize(zoomLevel: model.zoomLevel))
                    
                    // Calculate moon's orbit radius based on planet and moon radii
                    let planetRadius = size / 2
                    let moonRadius = moonSize / 2
                    let baseOrbitRadius = planetRadius * 1.5 // Start at 2x planet radius
                    let orbitSpacing = (planetRadius + moonRadius) * 0.6 // Each moon spaced by 0.8x combined radii
                    let moonIndex = celestialBody.moons.firstIndex(where: { $0.id == moon.id }) ?? 0
                    let moonOrbitRadius = baseOrbitRadius + (Double(moonIndex) * orbitSpacing)
                    
                    // Calculate moon's position on its orbit
                    let moonX = moonOrbitRadius * Foundation.cos(moonAngle)
                    let moonY = moonOrbitRadius * Foundation.sin(moonAngle)
                    
                    // Draw moon orbit when zoomed in enough
                    if model.zoomLevel > 3 {
                        Circle()
                            .stroke(accentColor.opacity(0.7), lineWidth: 1.5)
                            .frame(width: moonOrbitRadius * 2, height: moonOrbitRadius * 2)
                    }
                    
                    // Draw the moon with label and tap gesture
                    ZStack {
                        // Use texture for moons with lighting effect
                        ZStack {
                            Image(moon.texture)
                                .resizable()
                                .scaledToFit()
                                .frame(width: moonSize, height: moonSize)
                            
                            // Add a radial gradient for day/night effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0),
                                            Color.black.opacity(0.7)
                                        ]),
                                        center: .leading,
                                        startRadius: moonSize * 0.1,
                                        endRadius: moonSize * 0.8
                                    )
                                )
                                .frame(width: moonSize, height: moonSize)
                        }
                        .clipShape(Circle())
                        // Apply rotation based on the moon's rotation period
                        .rotationEffect(.degrees(moon.rotationPeriod != 0 
                            ? (360.0 * model.currentTime / abs(moon.rotationPeriod))
                            : 0))
                        
                        // Show moon label when zoomed in enough
                        if model.zoomLevel > 3 {
                            Text(moon.name)
                                .font(.system(size: min(12, 6 + sqrt(model.zoomLevel) * 2)))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                                .offset(y: -moonSize - 8)
                                .opacity(min(1.0, model.zoomLevel * 0.5))
                        }
                    }
                    .offset(x: moonX, y: moonY)
                    .onTapGesture {
                        NotificationCenter.default.post(
                            name: Notification.Name("SelectCelestialBody"),
                            object: moon
                        )
                    }
                }
                .zIndex(10) // Ensure moons and their orbits are above the planet
            }
        }
        .position(x: geometry.size.width / 2 + position.x,
                 y: geometry.size.height / 2 + position.y)
        .onTapGesture {
            NotificationCenter.default.post(
                name: Notification.Name("SelectCelestialBody"),
                object: celestialBody
            )
        }
        
        // Show labels for all celestial bodies EXCEPT the Sun (which has its own label)
        if (model.zoomLevel > 0.3 || celestialBody.type == .star) && celestialBody.type != .star {
            Text(celestialBody.name)
                .font(.system(size: min(14, 8 + sqrt(model.zoomLevel) * 3)))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .position(x: geometry.size.width / 2 + position.x,
                         y: geometry.size.height / 2 + position.y - size - 10)
                .opacity(min(1.0, model.zoomLevel * 0.5))
                .zIndex(1)
        }
    }
    
    private func calculatePosition() -> CGPoint {
        let basePosition = celestialBody.position(at: model.currentTime, scale: model.zoomLevel)
        
        // Apply the same scaling as the orbit paths for consistency
        if celestialBody.type == .planet || celestialBody.type == .dwarfPlanet {
            let orbitScale: Double
            if celestialBody.distanceFromSun <= 1.8 {
                // Inner planets
                orbitScale = celestialBody.distanceFromSun * 10.0
            } else if celestialBody.distanceFromSun <= 10 {
                // Middle planets
                orbitScale = 18.0 + (celestialBody.distanceFromSun - 1.8) * 4.0
            } else {
                // Outer planets
                orbitScale = 50.0 + (celestialBody.distanceFromSun - 10.0) * 3.0
            }
            
            // Calculate the angle from the base position
            let angle = atan2(basePosition.y, basePosition.x)
            
            // Calculate the radius with eccentricity adjustment
            let eccentricityFactor = celestialBody.distanceFromSun <= 10 ? 0.3 : 0.4
            let adjustedEccentricity = celestialBody.eccentricity * eccentricityFactor
            let radius = orbitScale * (1 - adjustedEccentricity * adjustedEccentricity) / 
                        (1 + adjustedEccentricity * Foundation.cos(angle))
            
            // Calculate the new position using the scaled radius
            return CGPoint(
                x: radius * Foundation.cos(angle) * model.zoomLevel,
                y: radius * Foundation.sin(angle) * model.zoomLevel
            )
        }
        
        return basePosition
    }
}

// Extension to conditionally apply modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// New struct for planet rings
struct PlanetRings: View {
    let bodySize: CGFloat
    let ringColor: Color
    let is3DView: Bool
    let ringScale: CGFloat // New parameter for ring size
    let ringCount: Int
    
    var body: some View {
        ZStack {
            // Outer ring
            Ellipse()
                .stroke(ringColor.opacity(0.7), lineWidth: 1.5)
                .frame(width: bodySize * ringScale, height: bodySize * (is3DView ? 0.6 : 0.8))
            if (ringCount > 1) {
                // Inner ring
                Ellipse()
                    .stroke(ringColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: bodySize * (ringScale - 0.3), height: bodySize * (is3DView ? 0.5 : 0.7))
                
                // Inner ring shadow
                Ellipse()
                    .fill(ringColor.opacity(0.2))
                    .frame(width: bodySize * (ringScale - 0.2), height: bodySize * (is3DView ? 0.55 : 0.75))
            }
        }
        .rotationEffect(.degrees(15)) // Tilt the rings
        .if(is3DView) { view in
            view.rotation3DEffect(
                .degrees(60),
                axis: (x: 1, y: 0, z: 0)
            )
        }
    }
}

struct EllipticalOrbitPath: Shape {
    let semiMajorAxis: Double
    let eccentricity: Double
    let scale: Double
    let bodyType: CelestialBody.BodyType
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if semiMajorAxis <= 0.001 {
            return path
        }
        
        let steps = 100
        
        // Unified scaling for orbit visualization
        let orbitScale: Double
        
        if bodyType == .star {
            orbitScale = 0
        } else if bodyType == .planet || bodyType == .dwarfPlanet {
            if semiMajorAxis <= 1.8 {
                // Inner planets (Mercury to Mars)
                orbitScale = semiMajorAxis * 10.0
            } else if semiMajorAxis <= 10 {
                // Middle planets (Jupiter to Saturn)
                orbitScale = 18.0 + (semiMajorAxis - 1.8) * 4.0
            } else {
                // Outer planets (Uranus, Neptune, Pluto)
                orbitScale = 50.0 + (semiMajorAxis - 10.0) * 3.0
            }
        } else {
            orbitScale = semiMajorAxis
        }
        
        // Adjust eccentricity effect based on distance
        let eccentricityFactor = semiMajorAxis <= 10 ? 0.3 : 0.4
        let adjustedEccentricity = eccentricity * eccentricityFactor
        
        // Draw the elliptical orbit
        for i in 0...steps {
            let angle = Double(i) * 2 * Double.pi / Double(steps)
            let radius = orbitScale * (1 - adjustedEccentricity * adjustedEccentricity) / (1 + adjustedEccentricity * Foundation.cos(angle))
            let x = radius * Foundation.cos(angle) * scale
            let y = radius * Foundation.sin(angle) * scale
            
            if i == 0 {
                path.move(to: CGPoint(x: rect.midX + x, y: rect.midY + y))
            } else {
                path.addLine(to: CGPoint(x: rect.midX + x, y: rect.midY + y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct CelestialBodyInfoView: View {
    let celestialBody: CelestialBody
    @Binding var isPresented: Bool
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with celestial body name and close button
            HStack {
                HStack(spacing: 12) {
                    // Replace solid color circle with texture image and rings if applicable
                    ZStack {
                        Image(celestialBody.texture)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        
                        // Add rings for Saturn and Uranus
                        if celestialBody.type == .planet && celestialBody.hasRings {
                            PlanetRings(
                                bodySize: 32,
                                ringColor: celestialBody.ringColor,
                                is3DView: false,
                                ringScale: celestialBody.name == "Saturn" ? 2.5 : 1.8,
                                ringCount: celestialBody.name == "Saturn" ? 2 : 1
                            )
                        }
                    }
                    
                    Text(celestialBody.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(accentColor.opacity(0.8))
                }
            }
            .padding(.bottom, 4)
            
            // Type indicator with smaller text
            Text(celestialBody.type.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.15))
                .cornerRadius(6)
            
            Divider()
                .background(accentColor.opacity(0.3))
                .padding(.vertical, 6)
            
            // Main info grid with reduced spacing and text sizes
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 12) {
                InfoCell(title: "Diameter", value: "\(formatNumber(celestialBody.diameter))", unit: "km")
                InfoCell(title: "Mass", value: "\(formatScientific(celestialBody.mass))", unit: "kg")
                
                if celestialBody.type == .moon, let _ = celestialBody.parentBodyID {
                    InfoCell(title: "Orbits", value: "Parent Body", unit: "")
                    if let distanceFromParent = celestialBody.distanceFromParent {
                        InfoCell(title: "Distance", value: "\(formatNumber(distanceFromParent * 149597870.7))", unit: "km")
                    }
                } else {
                    InfoCell(title: "Distance", value: "\(formatNumber(celestialBody.distanceFromSun))", unit: "AU")
                }
                
                InfoCell(title: "Orbital Period", value: "\(formatNumber(celestialBody.orbitalPeriod))", unit: "days")
                InfoCell(title: "Rotation", value: "\(formatNumber(abs(celestialBody.rotationPeriod)))", unit: "days")
                InfoCell(title: "Eccentricity", value: "\(formatNumber(celestialBody.eccentricity))", unit: "")
                
                if celestialBody.type == .planet || celestialBody.type == .dwarfPlanet {
                    InfoCell(title: "Moons", value: "\(celestialBody.moonCount)", unit: "")
                }
                
                if celestialBody.type != .star, let temp = celestialBody.temperature {
                    InfoCell(title: "Temperature", value: celestialBody.formattedTemperature(), unit: "")
                }
            }
            
            // Habitable zone indicator with smaller text
            if celestialBody.isInHabitableZone() {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Potentially Habitable!", systemImage: "leaf.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text("This celestial body has a temperature that could potentially support liquid water, a key ingredient for life as we know it.")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding(.vertical, 6)
            }
            
            // Physics information section with smaller text
            if celestialBody.type == .planet || celestialBody.type == .dwarfPlanet {
                Divider()
                    .background(accentColor.opacity(0.3))
                    .padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Label("Physics Data", systemImage: "atom")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    let escapeVelocity = PhysicsEngine.calculateEscapeVelocity(
                        mass: celestialBody.mass,
                        distance: celestialBody.diameter / 2 * 1000
                    )
                    
                    let orbitalVelocity = PhysicsEngine.calculateOrbitalVelocity(
                        distanceFromSun: celestialBody.distanceFromSun
                    )
                    
                    Text("Escape Velocity: \(formatNumber(escapeVelocity / 1000)) km/s")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13))
                    
                    Text("Orbital Velocity: \(formatNumber(orbitalVelocity / 1000)) km/s")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13))
                    
                    if celestialBody.distanceFromSun != celestialBody.originalDistanceFromSun {
                        Text("Original Distance: \(formatNumber(celestialBody.originalDistanceFromSun)) AU")
                            .foregroundColor(.orange.opacity(0.9))
                            .font(.system(size: 13))
                        
                        Text("Original Orbital Period: \(formatNumber(celestialBody.originalOrbitalPeriod)) days")
                            .foregroundColor(.orange.opacity(0.9))
                            .font(.system(size: 13))
                    }
                }
                .padding(10)
                .background(accentColor.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Fun fact section with smaller text
            if !celestialBody.funFact.isEmpty {
                Divider()
                    .background(accentColor.opacity(0.3))
                    .padding(.vertical, 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Label("Fun Fact", systemImage: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Text(celestialBody.funFact)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 2)
                }
                .padding(10)
                .background(accentColor.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.1), radius: 20, x: 0, y: 0)
        .padding()
        .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 500))
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value == 0 {
            return "0"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func formatScientific(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.positiveFormat = "0.##E+0"
        formatter.exponentSymbol = "e"
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

struct InfoCell: View {
    let title: String
    let value: String
    let unit: String
    
    private let accentColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(accentColor.opacity(0.8))
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}

#Preview {
    MainView()
} 
