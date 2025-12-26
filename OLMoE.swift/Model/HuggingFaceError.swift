//
//  HuggingFaceError.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

public enum HuggingFaceError: Error {
    case network(statusCode: Int)
    case noFilteredURL
    case urlIsNilForSomeReason
}

extension HuggingFaceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network(let statusCode):
            return "Network error (HTTP \(statusCode))."
        case .noFilteredURL:
            return "No compatible download URL found."
        case .urlIsNilForSomeReason:
            return "Download failed: temporary URL is missing."
        }
    }
}
