//
//  Logging.swift
//  WebTags
//
//  Created by Nonstrict on 02/02/2023.
//

import ArgumentParser
import Logging

extension Logger {
    func withLogLevel(_ logLevel: Logger.Level?) -> Logger {
        guard let logLevel else { return self }
        
        var logger = self
        logger.logLevel = logLevel
        return logger
    }
    
    func withMetadata(_ metadata: Metadata) -> Logger {
        var logger = self
        for (key, value) in metadata {
            logger[metadataKey: key] = value
        }
        return logger
    }
}

extension Logger.Level: ExpressibleByArgument {}
