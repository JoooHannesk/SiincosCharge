//
//  Errors.swift
//  SiincosChargeEdge
//
//  Created by Johannes Kinzig on 03.04.26.
//


/// Car Charger Errors
///
enum SystemError: Error {
    case boundaryViolation
    case dataMissing
    case chargersMissing
    case powerMetersMissing
}
