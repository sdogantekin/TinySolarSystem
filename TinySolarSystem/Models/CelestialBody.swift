import SwiftUI

struct CelestialBody: Identifiable {
    var id = UUID()
    var name: String
    var type: BodyType
    var diameter: Double // in km
    var mass: Double // in kg
    var distanceFromSun: Double // in AU (Astronomical Units)
    var orbitalPeriod: Double // in Earth days
    var rotationPeriod: Double // in Earth days
    var eccentricity: Double // orbital eccentricity (0 = circle, >0 = ellipse)
    var initialPhaseAngle: Double // initial position in radians
    var color: Color
    var texture: String // image name for texture
    var hasRings: Bool = false // Whether the celestial body has rings (like Saturn)
    var ringColor: Color = .white // Color of the rings if present
    var funFact: String = "" // Fun fact about the celestial body
    var moonCount: Int = 0 // Number of moons (for planets)
    
    // For moons
    var parentBodyID: UUID? = nil
    var distanceFromParent: Double? = nil // in Earth radii
    
    // For "what if" scenarios
    var isRemoved: Bool = false
    var removalReason: String? = nil // Reason for removal (e.g., "Moon escaped planet's gravity")
    var originalDistanceFromSun: Double
    var originalOrbitalPeriod: Double // Store original orbital period for reset
    var originalEccentricity: Double // Store original eccentricity for reset
    var temperature: Double? = nil // Temperature in Kelvin, calculated based on distance from Sun
    
    enum BodyType: String {
        case star
        case planet
        case dwarfPlanet
        case moon
        case asteroid
        case comet
    }
    
    init(name: String, type: BodyType, diameter: Double, mass: Double, distanceFromSun: Double, 
         orbitalPeriod: Double, rotationPeriod: Double, eccentricity: Double = 0.0, 
         initialPhaseAngle: Double = 0.0, color: Color, texture: String,
         parentBodyID: UUID? = nil, distanceFromParent: Double? = nil,
         hasRings: Bool = false, ringColor: Color = .white,
         funFact: String = "", moonCount: Int = 0) {
        self.name = name
        self.type = type
        self.diameter = diameter
        self.mass = mass
        self.distanceFromSun = distanceFromSun
        self.originalDistanceFromSun = distanceFromSun
        self.orbitalPeriod = orbitalPeriod
        self.originalOrbitalPeriod = orbitalPeriod
        self.rotationPeriod = rotationPeriod
        self.eccentricity = eccentricity
        self.originalEccentricity = eccentricity
        self.initialPhaseAngle = initialPhaseAngle
        self.color = color
        self.texture = texture
        self.parentBodyID = parentBodyID
        self.distanceFromParent = distanceFromParent
        self.hasRings = hasRings
        self.ringColor = ringColor
        self.funFact = funFact
        self.moonCount = moonCount
        
        // Calculate initial temperature
        if type != .star {
            self.temperature = PhysicsEngine.calculatePlanetTemperature(distanceFromSun: distanceFromSun)
        }
    }
    
    // Calculate current position based on time with kid-friendly scaling
    func position(at time: Double, scale: Double, parentPosition: CGPoint? = nil) -> CGPoint {
        if isRemoved {
            return CGPoint(x: 0, y: 0) // Off-screen if removed
        }
        
        // For moons, calculate position relative to parent body
        if type == .moon, let parentPosition = parentPosition, let distanceFromParent = distanceFromParent {
            // Calculate angle based on orbital period and time, plus initial phase
            let angle = (2 * Double.pi * time) / orbitalPeriod + initialPhaseAngle
            
            // Use simplified circular orbits for moons to make them visible
            let radius = distanceFromParent
            
            // Scale for moons is different to make them visible
            // Use exactly 50 as the scaling factor to match MoonOrbitPath
            let moonScale = scale * 50
            
            // Position moon relative to parent (Earth) - this makes Earth the center of the moon's orbit
            let x = parentPosition.x + radius * cos(angle) * moonScale
            let y = parentPosition.y + radius * sin(angle) * moonScale
            
            return CGPoint(x: x, y: y)
        }
        
        // For planets and other bodies orbiting the sun
        // Calculate angle based on orbital period and time, plus initial phase
        let angle = (2 * Double.pi * time) / orbitalPeriod + initialPhaseAngle
        
        // Apply kid-friendly scaling to make distances more understandable
        let kidFriendlyDistance: Double
        
        if type == .star {
            kidFriendlyDistance = 0
        } else {
            // Use a more spread out scale to prevent overlapping
            switch type {
            case .planet, .dwarfPlanet:
                // For inner planets (Mercury to Mars), use more spacing
                if distanceFromSun <= 1.8 {
                    // Dramatically increase spacing between inner planets
                    kidFriendlyDistance = 1.0 + distanceFromSun * 8.0
                } else if distanceFromSun <= 10 {
                    // Medium distance planets (Jupiter, Saturn)
                    kidFriendlyDistance = 15.0 + (distanceFromSun - 1.8) * 3.0
                } else {
                    // For outer planets, use logarithmic scaling to compress distances
                    kidFriendlyDistance = 40.0 + log(distanceFromSun/10) * 10.0
                }
            default:
                kidFriendlyDistance = distanceFromSun
            }
        }
        
        // Use simplified elliptical orbits with reduced eccentricity for better visualization
        // Use exactly 0.2 as the eccentricity factor to match EllipticalOrbitPath
        let adjustedEccentricity = eccentricity * 0.2
        let semiMajorAxis = kidFriendlyDistance
        let radius = semiMajorAxis * (1 - adjustedEccentricity * adjustedEccentricity) / (1 + adjustedEccentricity * cos(angle))
        
        let x = radius * cos(angle) * scale
        let y = radius * sin(angle) * scale
        
        return CGPoint(x: x, y: y)
    }
    
    // Calculate display size based on zoom level with kid-friendly adjustments
    func displaySize(zoomLevel: Double) -> CGFloat {
        // Base size on diameter but with adjustments to make planets more visible
        // while maintaining relative proportions
        var baseSize: Double
        
        switch type {
        case .star:
            // Sun size scales more aggressively with zoom to make it more visible
            baseSize = log(diameter) * 2.5 * sqrt(zoomLevel)
        case .planet:
            // Make planets more proportional to their actual sizes but much more visible
            // Apply a non-linear scaling based on zoom level for better visibility
            let zoomFactor = sqrt(zoomLevel) // Square root scaling for smoother size increase
            
            if diameter > 100000 { // Gas giants (Jupiter, Saturn)
                baseSize = log(diameter) * 0.8 * zoomFactor
            } else if diameter > 40000 { // Ice giants (Uranus, Neptune)
                baseSize = log(diameter) * 0.7 * zoomFactor
            } else if diameter > 10000 { // Terrestrial planets (Earth, Venus)
                baseSize = log(diameter) * 0.6 * zoomFactor
            } else { // Small planets (Mercury, Mars)
                baseSize = log(diameter) * 0.5 * zoomFactor
            }
        case .dwarfPlanet:
            // Dwarf planets need more size boost at higher zoom levels
            baseSize = log(diameter) * 0.4 * sqrt(zoomLevel) * 1.2
        case .moon:
            // Moons need to be visible but proportionally correct
            // Increase visibility at higher zoom levels
            let zoomFactor = zoomLevel > 5 ? sqrt(zoomLevel) * 1.5 : sqrt(zoomLevel)
            baseSize = log(diameter) * 0.4 * zoomFactor * 1.2
        default:
            baseSize = log(diameter) * 0.4 * sqrt(zoomLevel)
        }
        
        // Ensure minimum size for visibility but keep them small
        // Minimum size increases slightly with zoom for better visibility
        let minSize = 2.0 + (zoomLevel > 10 ? log(zoomLevel/10) : 0)
        baseSize = max(baseSize, minSize)
        
        return CGFloat(baseSize)
    }
    
    // Get formatted temperature string
    func formattedTemperature() -> String {
        guard let temp = temperature else { return "Unknown" }
        
        // Convert from Kelvin to Celsius
        let celsius = temp - 273.15
        
        return String(format: "%.1f°C (%.1f K)", celsius, temp)
    }
    
    // Determine if planet is in habitable zone
    func isInHabitableZone() -> Bool {
        guard let temp = temperature, type == .planet || type == .dwarfPlanet else { return false }
        
        // Simple habitable zone check: between -50°C and 50°C
        let celsius = temp - 273.15
        return celsius > -50 && celsius < 50
    }
} 