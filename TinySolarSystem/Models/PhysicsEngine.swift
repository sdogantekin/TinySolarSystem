import Foundation

// Physics constants
struct PhysicsConstants {
    static let G: Double = 6.67430e-11 // Gravitational constant (m^3 kg^-1 s^-2)
    static let AU: Double = 149597870700.0 // 1 Astronomical Unit in meters
    static let solarMass: Double = 1.989e30 // Mass of the Sun in kg
    static let earthMass: Double = 5.97e24 // Mass of the Earth in kg
    static let dayInSeconds: Double = 86400.0 // Seconds in a day
    static let yearInDays: Double = 365.25 // Days in a year
}

class PhysicsEngine {
    
    // Calculate orbital period using Kepler's Third Law
    // T^2 = (4π^2 / GM) * a^3
    // Where:
    // T = orbital period
    // G = gravitational constant
    // M = mass of the central body (Sun)
    // a = semi-major axis of the orbit
    static func calculateOrbitalPeriod(distanceFromSun: Double, centralMass: Double = PhysicsConstants.solarMass) -> Double {
        // Convert distance from AU to meters
        let semiMajorAxis = distanceFromSun * PhysicsConstants.AU
        
        // Calculate orbital period in seconds
        let periodInSeconds = 2.0 * Double.pi * sqrt(pow(semiMajorAxis, 3) / (PhysicsConstants.G * centralMass))
        
        // Convert to days
        return periodInSeconds / PhysicsConstants.dayInSeconds
    }
    
    // Calculate orbital velocity at a given distance
    // v = sqrt(GM/r)
    // Where:
    // v = orbital velocity
    // G = gravitational constant
    // M = mass of the central body (Sun)
    // r = distance from the central body
    static func calculateOrbitalVelocity(distanceFromSun: Double, centralMass: Double = PhysicsConstants.solarMass) -> Double {
        // Convert distance from AU to meters
        let distance = distanceFromSun * PhysicsConstants.AU
        
        // Calculate orbital velocity in m/s
        return sqrt(PhysicsConstants.G * centralMass / distance)
    }
    
    // Calculate escape velocity at a given distance from the Sun
    // v_escape = sqrt(2GM/r)
    // Where:
    // v_escape = escape velocity
    // G = gravitational constant
    // M = mass of the central body (Sun)
    // r = distance from the central body
    static func calculateEscapeVelocity(distanceFromSun: Double, centralMass: Double = PhysicsConstants.solarMass) -> Double {
        // Convert distance from AU to meters
        let distance = distanceFromSun * PhysicsConstants.AU
        
        // Calculate escape velocity in m/s
        return sqrt(2.0 * PhysicsConstants.G * centralMass / distance)
    }
    
    // Calculate escape velocity from a planet's surface
    // v_escape = sqrt(2GM/r)
    // Where:
    // v_escape = escape velocity
    // G = gravitational constant
    // M = mass of the planet
    // r = radius of the planet
    static func calculateEscapeVelocity(mass: Double, distance: Double) -> Double {
        // Calculate escape velocity in m/s (distance should be in meters)
        return sqrt(2.0 * PhysicsConstants.G * mass / distance)
    }
    
    // Calculate gravitational force between two bodies
    // F = G * (m1 * m2) / r^2
    // Where:
    // F = gravitational force
    // G = gravitational constant
    // m1, m2 = masses of the two bodies
    // r = distance between the bodies
    static func calculateGravitationalForce(mass1: Double, mass2: Double, distance: Double) -> Double {
        return PhysicsConstants.G * mass1 * mass2 / (distance * distance)
    }
    
    // Calculate the Hill sphere radius (region where a planet's gravity dominates over the Sun's)
    // r_Hill = a * (m / (3 * M))^(1/3)
    // Where:
    // r_Hill = radius of Hill sphere
    // a = semi-major axis of the planet's orbit
    // m = mass of the planet
    // M = mass of the Sun
    static func calculateHillSphereRadius(distanceFromSun: Double, planetMass: Double, centralMass: Double = PhysicsConstants.solarMass) -> Double {
        // Convert distance from AU to meters
        let semiMajorAxis = distanceFromSun * PhysicsConstants.AU
        
        // Calculate Hill sphere radius in meters
        let hillRadius = semiMajorAxis * pow(planetMass / (3.0 * centralMass), 1.0/3.0)
        
        // Convert back to AU
        return hillRadius / PhysicsConstants.AU
    }
    
    // Recalculate orbital parameters when a planet's distance changes
    // Returns a tuple with updated orbital period and eccentricity
    static func recalculateOrbit(originalDistance: Double, newDistance: Double, originalPeriod: Double, originalEccentricity: Double) -> (period: Double, eccentricity: Double) {
        // Calculate new orbital period using Kepler's Third Law
        let newPeriod = calculateOrbitalPeriod(distanceFromSun: newDistance)
        
        // For eccentricity, we'll use a simplified model:
        // If moving closer to the Sun, eccentricity increases slightly
        // If moving away from the Sun, eccentricity decreases slightly
        // This simulates the effect of orbital perturbations
        let distanceRatio = newDistance / originalDistance
        let eccentricityFactor = distanceRatio < 1.0 ? 1.1 : 0.9
        let newEccentricity = min(0.9, max(0.001, originalEccentricity * eccentricityFactor))
        
        return (newPeriod, newEccentricity)
    }
    
    // Check if a moon would be stable at a given planet's new distance
    static func isMoonStable(planetDistanceFromSun: Double, moonDistanceFromPlanet: Double, planetMass: Double) -> Bool {
        // Calculate Hill sphere radius
        let hillRadius = calculateHillSphereRadius(distanceFromSun: planetDistanceFromSun, planetMass: planetMass)
        
        // Convert moon distance to AU if it's in Earth radii
        let moonDistanceAU = moonDistanceFromPlanet * (6371.0 / PhysicsConstants.AU) // Earth radius in km / AU in km
        
        // A moon is generally stable if it's within about 1/3 to 1/2 of the Hill sphere
        return moonDistanceAU < (hillRadius / 2.5)
    }
    
    // Calculate temperature of a planet based on distance from Sun
    // T = 278 * (1-A)^0.25 / sqrt(d)
    // Where:
    // T = temperature in Kelvin
    // A = albedo (reflectivity, 0-1)
    // d = distance from Sun in AU
    static func calculatePlanetTemperature(distanceFromSun: Double, albedo: Double = 0.3) -> Double {
        return 278.0 * pow(1.0 - albedo, 0.25) / sqrt(distanceFromSun)
    }
} 