//
//  Command.swift
//  WebTags
//
//  Created by Nonstrict on 02/02/2023.
//

import ArgumentParser
import Foundation
import Logging

@main
struct Command: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "webtags",
        abstract: "Element definitions from web specifications.",
        discussion: "Generates JSON output describing all elements, attributes and predefined attribute values from the given web browser specifications.",
        version: "0.1"
    )
    
    @Option(name: .customLong("specs"), help: "Short names of the specs to parse and output.")
    var specsToGenerate: [String] = ["html", "SVG2", "svg-animations", "mathml-core"]
    
    @Flag(help: "Pretty print the JSON output.")
    var prettyPrint: Bool = false
    
    @Option(name: .customLong("webref-index"), help: "URL to the Webref data index, file:// URL are supported.")
    var webRefIndex = "https://w3c.github.io/webref/ed/index.json"
    
    @Option(name: .customLong("loglevel"), help: "Log level to use.")
    var logLevel: Logger.Level = .warning
    
    func run() throws {
        // Bootstrap logger
        LoggingSystem.bootstrap(StreamLogHandler.standardError)
        let logger = Logger(label: "WebTags")
            .withLogLevel(logLevel)
        logger.notice("Started run.", metadata: ["logLevel": "\(logLevel)", "webRefIndex": "\(webRefIndex)", "specsToGenerate": "\(specsToGenerate.joined(separator: ","))"], source: "\(Self.self)")
        
        // Parse URL
        logger.debug("Parsing URL to webref index...", source: "\(Self.self)")
        guard let indexURL = URL(string: webRefIndex) else {
            logger.critical("Invalid URL to webref index.", metadata: ["url": "\(webRefIndex)"], source: "\(Self.self)")
            fatalError("Invalid URL to webref index.")
        }
        logger.info("URL to webref index parsed.", metadata: ["url": "\(indexURL.absoluteString)"], source: "\(Self.self)")
        
        do {
            // Fetch webref index
            logger.debug("Loading webref index...", source: "\(Self.self)")
            let data = try Data(contentsOf: indexURL)
            logger.debug("Parsing webref index data...", metadata: ["length": "\(data.count)"], source: "\(Self.self)")
            let crawl = try JSONDecoder().decode(WebRefCrawl.Index.self, from: data)
            logger.info("Webref index loaded.", metadata: ["results": "\(crawl.results.count)", "crawled": "\(crawl.stats.crawled)", "crawlErrors": "\(crawl.stats.errors)"], source: "\(Self.self)")
            
            // Parse the requested specs
            logger.debug("Parsing specs...", metadata: ["specsToGenerate": "\(specsToGenerate.joined(separator: ","))"], source: "\(Self.self)")
            let parsedSpecs = try crawl.results
                .filter { specsToGenerate.contains($0.shortname) }
                .map { try WebRefCrawlResultTransformer(crawlResult: $0, baseURL: indexURL, parentLogger: logger) }
                .map { try $0.transform() }
            logger.info("Specs parsed.", metadata: ["specsToGenerate": "\(specsToGenerate.joined(separator: ","))"], source: "\(Self.self)")            
            
            // Encode output as JSON
            logger.debug("Generating JSON...", source: "\(Self.self)")
            let encoder = JSONEncoder()
            if prettyPrint {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            } else {
                encoder.outputFormatting = [.withoutEscapingSlashes]
            }
            let jsonData = try encoder.encode(parsedSpecs)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw EncodingFailedError(message: "Failed to convert JSON data to string.")
            }
            logger.info("Generated JSON.", source: "\(Self.self)")
            
            print(jsonString)
        } catch let error as NSError {
            logger.critical("\(error.debugDescription)", source: "\(Self.self)")
            throw error
        }
    }
}
