import SwiftUI
import Combine

class SolarSystemModel: ObservableObject {
    @Published var celestialBodies: [CelestialBody]
    @Published var currentTime: Double = 0 // Current simulation time in days
    @Published var speedFactor: Double = 0.01 // Reduced initial speed (was 0.025)
    @Published var zoomLevel: Double = 3.0 // Default zoom level for good initial visibility
    @Published var isSimulationPaused: Bool = false
    @Published var currentDate: Date = Date() // Current date in the simulation
    
    // Zoom limits
    let minZoomLevel: Double = 0.1
    let maxZoomLevel: Double = 100.0
    
    // Speed limits
    let minSpeedFactor: Double = 0.0
    let maxSpeedFactor: Double = 0.2 // Reduced to 20% of previous value (was 1.0)
    
    private var timer: AnyCancellable?
    private let baseTimeStep: Double = 1.0 / 60.0 // Base time step in days (1/60 of a day per frame)
    
    // Maximum speed in seconds per simulation day
    private let maxSpeed: Double = 2592.0 // Reduced to 20% of previous value (was 12960.0)
    
    // Calculate the current time scale based on the speed factor
    var currentTimeScale: Double {
        // Apply a non-linear curve to make lower speeds more precise
        let adjustedFactor = pow(speedFactor, 2.0) // Square the factor to make lower speeds slower
        return adjustedFactor * maxSpeed
    }
    
    // For backward compatibility
    enum TimeScale: Double, CaseIterable, Identifiable {
        case realTime = 1.0 // 1 second = 1 second
        case minute = 60.0 // 1 second = 1 minute
        case hour = 3600.0 // 1 second = 1 hour
        case day = 86400.0 // 1 second = 1 day
        case week = 604800.0 // 1 second = 1 week
        case month = 2592000.0 // 1 second = 1 month (30 days)
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .realTime: return "Real Time"
            case .minute: return "1 sec = 1 min"
            case .hour: return "1 sec = 1 hour"
            case .day: return "1 sec = 1 day"
            case .week: return "1 sec = 1 week"
            case .month: return "1 sec = 1 month"
            }
        }
    }
    
    init() {
        // Initialize with solar system data
        self.celestialBodies = SolarSystemModel.createSolarSystem()
        startSimulation()
    }
    
    func startSimulation() {
        timer?.cancel()
        
        timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isSimulationPaused else { return }
                
                // Update time based on speed factor
                let timeStep = self.baseTimeStep * self.currentTimeScale
                self.currentTime += timeStep
                
                // Update current date based on time step
                self.currentDate = self.currentDate.addingTimeInterval(timeStep * 24 * 60 * 60)
            }
    }
    
    func resetSimulation() {
        currentTime = 0
        currentDate = Date() // Reset to current date
        celestialBodies = SolarSystemModel.createSolarSystem()
    }
    
    func setDate(_ date: Date) {
        // Calculate the time difference in days between the new date and the current date
        let timeInterval = date.timeIntervalSince(currentDate)
        let daysDifference = timeInterval / (24 * 60 * 60)
        
        // Update the current time and date
        currentTime += daysDifference
        currentDate = date
    }
    
    func togglePause() {
        isSimulationPaused.toggle()
    }
    
    func removeCelestialBody(id: UUID) {
        if let index = celestialBodies.firstIndex(where: { $0.id == id }) {
            celestialBodies[index].isRemoved = true
        }
    }
    
    func restoreCelestialBody(id: UUID) {
        if let index = celestialBodies.firstIndex(where: { $0.id == id }) {
            celestialBodies[index].isRemoved = false
        }
    }
    
    func updateDistanceFromSun(id: UUID, newDistance: Double) {
        if let index = celestialBodies.firstIndex(where: { $0.id == id }) {
            let originalDistance = celestialBodies[index].originalDistanceFromSun
            let originalPeriod = celestialBodies[index].originalOrbitalPeriod
            let originalEccentricity = celestialBodies[index].originalEccentricity
            
            // Update the distance
            celestialBodies[index].distanceFromSun = newDistance
            
            // Recalculate orbital parameters using physics
            let (newPeriod, newEccentricity) = PhysicsEngine.recalculateOrbit(
                originalDistance: originalDistance,
                newDistance: newDistance,
                originalPeriod: originalPeriod,
                originalEccentricity: originalEccentricity
            )
            
            celestialBodies[index].orbitalPeriod = newPeriod
            celestialBodies[index].eccentricity = newEccentricity
            
            // Calculate new temperature
            if celestialBodies[index].type != .star {
                celestialBodies[index].temperature = PhysicsEngine.calculatePlanetTemperature(
                    distanceFromSun: newDistance
                )
            }
            
            // Check if moons remain stable (for planets)
            if celestialBodies[index].type == .planet {
                updateMoonsStability(planetId: id)
            }
        }
    }
    
    private func updateMoonsStability(planetId: UUID) {
        guard let planetIndex = celestialBodies.firstIndex(where: { $0.id == planetId }) else { return }
        let planet = celestialBodies[planetIndex]
        
        // Find all moons of this planet
        let moonIndices = celestialBodies.indices.filter { 
            celestialBodies[$0].parentBodyID == planetId 
        }
        
        for moonIndex in moonIndices {
            let moon = celestialBodies[moonIndex]
            
            // Check if the moon would be stable at the planet's new distance
            let isStable = PhysicsEngine.isMoonStable(
                planetDistanceFromSun: planet.distanceFromSun,
                moonDistanceFromPlanet: moon.distanceFromParent ?? 0,
                planetMass: planet.mass
            )
            
            // If not stable, mark the moon as removed with a reason
            if !isStable && !moon.isRemoved {
                celestialBodies[moonIndex].isRemoved = true
                celestialBodies[moonIndex].removalReason = "Escaped \(planet.name)'s gravity due to solar tides"
            } 
            // If stable and was previously removed due to instability, restore it
            else if isStable && moon.isRemoved && moon.removalReason?.contains("gravity") == true {
                celestialBodies[moonIndex].isRemoved = false
                celestialBodies[moonIndex].removalReason = nil
            }
        }
    }
    
    func resetDistanceFromSun(id: UUID) {
        if let index = celestialBodies.firstIndex(where: { $0.id == id }) {
            // Reset to original values
            celestialBodies[index].distanceFromSun = celestialBodies[index].originalDistanceFromSun
            celestialBodies[index].orbitalPeriod = celestialBodies[index].originalOrbitalPeriod
            celestialBodies[index].eccentricity = celestialBodies[index].originalEccentricity
            
            // Recalculate temperature
            if celestialBodies[index].type != .star {
                celestialBodies[index].temperature = PhysicsEngine.calculatePlanetTemperature(
                    distanceFromSun: celestialBodies[index].originalDistanceFromSun
                )
            }
            
            // Check if moons should be restored
            if celestialBodies[index].type == .planet {
                updateMoonsStability(planetId: id)
            }
        }
    }
    
    func resetChanges() {
        for i in 0..<celestialBodies.count {
            celestialBodies[i].isRemoved = false
            celestialBodies[i].distanceFromSun = celestialBodies[i].originalDistanceFromSun
        }
    }
    
    // Create solar system with accurate data
    static func createSolarSystem() -> [CelestialBody] {
        // Create bodies first so we can reference Earth's ID for the Moon
        let sun = CelestialBody(
            name: "Sun",
            type: .star,
            diameter: 1392700,
            mass: 1.989e30,
            distanceFromSun: 0,
            orbitalPeriod: 0,
            rotationPeriod: 25.38,
            color: Color(red: 1.0, green: 0.85, blue: 0.2), // Brighter yellow-orange
            texture: "sun",
            funFact: "The Sun contains 99.86% of the mass in the Solar System and is hot enough to turn a diamond into vapor.",
            moonCount: 0
        )
        
        let mercury = CelestialBody(
            name: "Mercury",
            type: .planet,
            diameter: 4879,
            mass: 3.3e23,
            distanceFromSun: 0.39,
            orbitalPeriod: 88,
            rotationPeriod: 58.6,
            eccentricity: 0.206,
            initialPhaseAngle: 0.0,
            color: Color(red: 0.6, green: 0.6, blue: 0.6), // Gray with slight brown tint
            texture: "mercury",
            funFact: "Mercury's day is longer than its year! It takes 88 Earth days to orbit the Sun but 176 Earth days to rotate once.",
            moonCount: 0
        )
        
        let venus = CelestialBody(
            name: "Venus",
            type: .planet,
            diameter: 12104,
            mass: 4.87e24,
            distanceFromSun: 0.72,
            orbitalPeriod: 225,
            rotationPeriod: -243, // Retrograde rotation
            eccentricity: 0.007,
            initialPhaseAngle: 0.4,
            color: Color(red: 0.95, green: 0.85, blue: 0.5), // Pale yellow
            texture: "venus",
            funFact: "Venus rotates backwards compared to other planets and has a surface hot enough to melt lead (462°C).",
            moonCount: 0
        )
                
        var earth = CelestialBody(
            name: "Earth",
            type: .planet,
            diameter: 12756,
            mass: 5.97e24,
            distanceFromSun: 1.0,
            orbitalPeriod: 365.25,
            rotationPeriod: 1.0,
            eccentricity: 0.017,
            initialPhaseAngle: 0.8,
            color: Color(red: 0.2, green: 0.5, blue: 0.8), // Blue with green tint
            texture: "earth",
            funFact: "Earth is the only planet known to support life and has the highest density of any planet in our solar system.",
            moonCount: 1
        )
        earth.moons.append(CelestialBody(
            name: "Moon",
            type: .moon,
            diameter: 3475,
            mass: 7.34e22,
            distanceFromSun: 1.0, // Same as Earth, but not used for moons
            orbitalPeriod: 27.32, // Sidereal orbital period in days
            rotationPeriod: 27.32, // Tidally locked to Earth
            eccentricity: 0.0549,
            initialPhaseAngle: 0.0,
            color: Color(white: 0.85), // Slightly brighter gray
            texture: "moon",
            parentBodyID: earth.id,
            distanceFromParent: 0.03, // Increased from 0.025 for better visibility
            funFact: "The Moon is moving away from Earth at a rate of 3.8 cm per year and always shows the same face to Earth."
        ))
        
        let mars = CelestialBody(
            name: "Mars",
            type: .planet,
            diameter: 6792,
            mass: 6.42e23,
            distanceFromSun: 1.52,
            orbitalPeriod: 687,
            rotationPeriod: 1.03,
            eccentricity: 0.093,
            initialPhaseAngle: 1.2,
            color: Color(red: 0.9, green: 0.3, blue: 0.1), // Rusty red
            texture: "mars",
            funFact: "Mars has the largest dust storms in the solar system, sometimes engulfing the entire planet for months.",
            moonCount: 2
        )
        
        var jupiter = CelestialBody(
            name: "Jupiter",
            type: .planet,
            diameter: 142984,
            mass: 1.898e27,
            distanceFromSun: 5.2,
            orbitalPeriod: 4333,
            rotationPeriod: 0.41,
            eccentricity: 0.048,
            initialPhaseAngle: 1.6,
            color: Color(red: 0.85, green: 0.7, blue: 0.55), // Sandy beige with orange bands
            texture: "jupiter",
            hasRings: false,
            ringColor: Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.7),
            funFact: "Jupiter's Great Red Spot is a storm that has been raging for at least 400 years and is larger than Earth.",
            moonCount: 79
        )
        
        // Add Jupiter's major moons
        jupiter.moons.append(contentsOf: [
            CelestialBody(
                name: "Io",
                type: .moon,
                diameter: 3642,
                mass: 8.93e22,
                distanceFromSun: 5.2,
                orbitalPeriod: 1.77, // Days
                rotationPeriod: 1.77, // Tidally locked
                eccentricity: 0.004,
                initialPhaseAngle: 0.0,
                color: Color(red: 0.9, green: 0.8, blue: 0.3), // Yellowish due to sulfur
                texture: "io",
                parentBodyID: jupiter.id,
                distanceFromParent: 0.002,
                funFact: "Io is the most volcanically active body in the Solar System, with hundreds of active volcanoes."
            ),
            CelestialBody(
                name: "Europa",
                type: .moon,
                diameter: 3122,
                mass: 4.8e22,
                distanceFromSun: 5.2,
                orbitalPeriod: 3.55, // Days
                rotationPeriod: 3.55, // Tidally locked
                eccentricity: 0.009,
                initialPhaseAngle: 0.5,
                color: Color(white: 0.9), // Icy white
                texture: "europa",
                parentBodyID: jupiter.id,
                distanceFromParent: 0.004,
                funFact: "Europa's surface is made of ice, and scientists believe it has a liquid water ocean beneath."
            ),
            CelestialBody(
                name: "Ganymede",
                type: .moon,
                diameter: 5268,
                mass: 1.48e23,
                distanceFromSun: 5.2,
                orbitalPeriod: 7.16, // Days
                rotationPeriod: 7.16, // Tidally locked
                eccentricity: 0.001,
                initialPhaseAngle: 1.0,
                color: Color(red: 0.6, green: 0.6, blue: 0.6), // Gray-brown
                texture: "ganymede",
                parentBodyID: jupiter.id,
                distanceFromParent: 0.007,
                funFact: "Ganymede is the largest moon in the Solar System, even bigger than the planet Mercury."
            ),
            CelestialBody(
                name: "Callisto",
                type: .moon,
                diameter: 4821,
                mass: 1.08e23,
                distanceFromSun: 5.2,
                orbitalPeriod: 16.69, // Days
                rotationPeriod: 16.69, // Tidally locked
                eccentricity: 0.007,
                initialPhaseAngle: 1.5,
                color: Color(red: 0.4, green: 0.4, blue: 0.4), // Dark gray
                texture: "callisto",
                parentBodyID: jupiter.id,
                distanceFromParent: 0.012,
                funFact: "Callisto is the most heavily cratered object in the Solar System."
            )
        ])
        
        var saturn = CelestialBody(
            name: "Saturn",
            type: .planet,
            diameter: 120536,
            mass: 5.68e26,
            distanceFromSun: 9.5,
            orbitalPeriod: 10759,
            rotationPeriod: 0.45,
            eccentricity: 0.054,
            initialPhaseAngle: 2.0,
            color: Color(red: 0.95, green: 0.85, blue: 0.55), // Pale gold
            texture: "saturn",
            hasRings: true,
            ringColor: Color(red: 0.95, green: 0.9, blue: 0.7),
            funFact: "Saturn's rings are made mostly of ice particles and could fit between Earth and the Moon despite being only about 10 meters thick.",
            moonCount: 82
        )
        
        // Add Saturn's largest moon, Titan
        saturn.moons.append(
            CelestialBody(
                name: "Titan",
                type: .moon,
                diameter: 5150,
                mass: 1.35e23,
                distanceFromSun: 9.5,
                orbitalPeriod: 15.95, // Days
                rotationPeriod: 15.95, // Tidally locked
                eccentricity: 0.0288,
                initialPhaseAngle: 0.0,
                color: Color(red: 0.8, green: 0.6, blue: 0.2), // Orange-yellow due to atmosphere
                texture: "titan",
                parentBodyID: saturn.id,
                distanceFromParent: 0.008,
                funFact: "Titan is the only moon known to have a dense atmosphere and liquid on its surface (though it's liquid methane, not water)."
            )
        )
        
        let uranus = CelestialBody(
            name: "Uranus",
            type: .planet,
            diameter: 51118,
            mass: 8.68e25,
            distanceFromSun: 19.2,
            orbitalPeriod: 30687,
            rotationPeriod: -0.72, // Retrograde rotation
            eccentricity: 0.047,
            initialPhaseAngle: 2.4,
            color: Color(red: 0.6, green: 0.85, blue: 0.9), // Pale cyan-blue
            texture: "uranus",
            hasRings: true,
            ringColor: Color(red: 0.6, green: 0.85, blue: 0.9).opacity(0.6),
            funFact: "Uranus rotates on its side with an axial tilt of 98 degrees, likely caused by a massive collision in its early history.",
            moonCount: 27
        )
        
        let neptune = CelestialBody(
            name: "Neptune",
            type: .planet,
            diameter: 49528,
            mass: 1.02e26,
            distanceFromSun: 30.1,
            orbitalPeriod: 60190,
            rotationPeriod: 0.67,
            eccentricity: 0.009,
            initialPhaseAngle: 2.8,
            color: Color(red: 0.1, green: 0.3, blue: 0.9), // Deep blue
            texture: "neptune",
            hasRings: false,
            ringColor: Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.5),
            funFact: "Neptune has the strongest winds in the solar system, reaching speeds of 2,100 km/h (1,300 mph).",
            moonCount: 14
        )
        
        let pluto = CelestialBody(
            name: "Pluto",
            type: .dwarfPlanet,
            diameter: 2376,
            mass: 1.3e22,
            distanceFromSun: 39.48,
            orbitalPeriod: 90560,
            rotationPeriod: -6.39, // Negative indicates retrograde rotation
            eccentricity: 0.2488,
            initialPhaseAngle: 4.0,
            color: Color(red: 0.7, green: 0.6, blue: 0.5), // Brownish-gray
            texture: "pluto",
            funFact: "Pluto was reclassified from a planet to a dwarf planet in 2006 and has a heart-shaped glacier on its surface.",
            moonCount: 5
        )
        
        return [sun, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune, pluto]
    }
    
    // Helper method to find a parent body's position
    func findParentPosition(for body: CelestialBody, at time: Double, scale: Double) -> CGPoint? {
        guard let parentID = body.parentBodyID else { return nil }
        
        if let parentBody = celestialBodies.first(where: { $0.id == parentID }) {
            return parentBody.position(at: time, scale: scale)
        }
        
        return nil
    }
} 
