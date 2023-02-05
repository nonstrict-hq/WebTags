//
//  WebRefCrawlResultTransformer.swift
//  WebTags
//
//  Created by Nonstrict on 02/02/2023.
//

import Foundation
import Logging

struct WebRefCrawlResultTransformer {
    private let crawlResult: WebRefCrawl.Result
    private let elementsURL: URL
    private let dfnsURL: URL
    private let logger: Logger
    
    private let decoder = JSONDecoder()
    
    init(crawlResult: WebRefCrawl.Result, baseURL: URL, parentLogger: Logger) throws {
        guard crawlResult.standing == "good" else {
            throw InvalidCrawlResultError(message: "Crawl result is not in good standing, standing is '\(crawlResult.standing)'.", result: crawlResult)
        }
        guard let elementsPath = crawlResult.elements, let elementsURL = URL(string: elementsPath, relativeTo: baseURL) else {
            throw InvalidCrawlResultError(message: "Missing or invalid elements path.", result: crawlResult)
        }
        guard let dfnsPath = crawlResult.dfns, let dfnsURL = URL(string: dfnsPath, relativeTo: baseURL) else {
            throw InvalidCrawlResultError(message: "Missing or invalid dfns path.", result: crawlResult)
        }
        
        self.crawlResult = crawlResult
        self.elementsURL = elementsURL
        self.dfnsURL = dfnsURL
        self.logger = parentLogger.withMetadata(["spec": "\(crawlResult.shortname)"])
    }
    
    func transform() throws -> Spec {
        // Fetch elements
        logger.debug("Loading elements...", source: "\(Self.self)")
        let craweledElementsData = try Data(contentsOf: elementsURL)
        logger.debug("Parsing elements data...", metadata: ["length": "\(craweledElementsData.count)"], source: "\(Self.self)")
        let craweledElements = try decoder.decode(WebRefCrawl.Elements.self, from: craweledElementsData)
        logger.info("Elements loaded.", metadata: ["elements": "\(craweledElements.elements.count)"], source: "\(Self.self)")
        
        // Fetch dfns
        logger.debug("Loading dfns...", source: "\(Self.self)")
        let crawledDfnsData = try Data(contentsOf: dfnsURL)
        logger.debug("Parsing dfns data...", metadata: ["length": "\(crawledDfnsData.count)"], source: "\(Self.self)")
        let crawledDfns = try decoder.decode(WebRefCrawl.Dfns.self, from: crawledDfnsData)
        logger.info("Dfns loaded.", metadata: ["dfns": "\(crawledDfns.dfns.count)"], source: "\(Self.self)")
        
        // Transform to Spec structure
        logger.debug("Building spec...", source: "\(Self.self)")
        let spec = try Spec(crawlResult: crawlResult, crawledElements: craweledElements.elements, crawledDfns: crawledDfns.dfns)
        logger.info("Spec built.", source: "\(Self.self)")
        
        // Warn about orphans
        logger.debug("Warning about orphans...", source: "\(Self.self)")
        for orphan in spec.orphanedAttributes {
            logger.warning("Orphaned attribute.", metadata: ["attrName": "\(orphan.name)", "href": "\(orphan.url.absoluteString)"], source: "\(Self.self)")
        }
        for orphan in spec.orphanedAttributeValues {
            logger.warning("Orphaned attribute value.", metadata: ["attrValue": "\(orphan.value)", "href": "\(orphan.url.absoluteString)"], source: "\(Self.self)")
        }
        logger.info("Warned about orphans.", source: "\(Self.self)")

        return spec
    }
}
