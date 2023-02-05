//
//  Output.swift
//  WebTags
//
//  Created by Nonstrict on 06/02/2023.
//

import Foundation

private let globalElementIdentifiers: Set<String> = [
    "global", "html-global", "htmlsvg-global", // HTML
    "core-attributes", // SVG2
]

struct Spec: Encodable {
    let organization: String
    let title: String
    let shortname: String
    let url: URL
    let date: String
    
    let globalAttributes: [Attribute]
    let elements: [Element]
    
    let orphanedAttributes: [Attribute]
    let orphanedAttributeValues: [AttributeValue]
    
    enum CodingKeys: CodingKey {
        case organization
        case title
        case shortname
        case url
        case date
        case globalAttributes
        case elements
    }
    
    init(crawlResult: WebRefCrawl.Result, crawledElements: [WebRefCrawl.Element], crawledDfns: [WebRefCrawl.Dfn]) throws {
        organization = crawlResult.organization
        title = crawlResult.title
        shortname = crawlResult.shortname
        url = crawlResult.url
        date = crawlResult.date
        
        let attributes = try crawledDfns.compactMap(Attribute.init)
        let attributeValues = try crawledDfns.compactMap(AttributeValue.init)
        
        globalAttributes = attributes
            .filter { $0.for.isEmpty || !$0.for.intersection(globalElementIdentifiers).isEmpty }
            .map {
                var resultAttribute = $0
                resultAttribute.values = attributeValues.filter { $0.isFor(resultAttribute.name, on: globalElementIdentifiers) }
                return resultAttribute
            }
        
        elements = crawledElements.map { element in
            Element(crawledElement: element, allAttributes: attributes, allAttributeValues: attributeValues)
        }
        
        let usedGlobalAttributeNames = Set(globalAttributes.map(\.name))
        let usedElementAttributeNames = Set(elements.flatMap(\.attributes).map(\.name))
        let availableAttributeNames = Set(attributes.map(\.name))
        let orphanedAttributeNames = availableAttributeNames.subtracting(usedGlobalAttributeNames.union(usedElementAttributeNames))
        orphanedAttributes = attributes.filter { orphanedAttributeNames.contains($0.name) }
        
        let usedGlobalAttributeValues = Set(globalAttributes.flatMap(\.values).map(\.value))
        let usedElementAttributeValues = Set(elements.flatMap(\.attributes).flatMap(\.values).map(\.value))
        let availableAttributeValues = Set(attributeValues.map(\.value))
        let orphanedAttributeValueValues = availableAttributeValues.subtracting(usedGlobalAttributeValues.union(usedElementAttributeValues))
        orphanedAttributeValues = attributeValues.filter { orphanedAttributeValueValues.contains($0.value) }
    }
}

struct Element: Encodable {
    let name: String
    let obsolete: Bool
    let attributes: [Attribute]
    
    init(crawledElement: WebRefCrawl.Element, allAttributes: [Attribute], allAttributeValues: [AttributeValue]) {
        name = crawledElement.name
        obsolete = crawledElement.obsolete ?? false
        attributes = allAttributes
            .filter { [name] in $0.`for`.contains(name) }
            .map { [name] in
                var resultAttribute = $0
                resultAttribute.values = allAttributeValues.filter { $0.isFor(resultAttribute.name, on: [name]) }
                return resultAttribute
            }
    }
}

struct Attribute: Encodable {
    let name: String
    let obsolete: Bool
    let url: URL
    var values: [AttributeValue]
    
    let `for`: Set<String>
    
    enum CodingKeys: CodingKey {
        case name
        case obsolete
        case url
        case values
    }
    
    init?(dfn: WebRefCrawl.Dfn) throws {
        guard dfn.type == "element-attr" else { return nil }
        guard dfn.linkingText.count == 1, let linkingText = dfn.linkingText.first else {
            throw InvalidDfnError(message: "Not exactly one linking text in dfn.", dfn: dfn)
        }
        
        name = linkingText
        obsolete = dfn.href.absoluteString.contains("obsolete.html")
        url = dfn.href
        values = []

        `for` = Set(dfn.`for`)
        guard `for`.count == dfn.for.count else {
            throw InvalidDfnError(message: "Duplicate `for` values on dfn.", dfn: dfn)
        }
    }
}

struct AttributeValue: Encodable {
    let value: String
    let obsolete: Bool
    let url: URL

    private let `for`: [String: Set<String>]
    
    enum CodingKeys: CodingKey {
        case value
        case obsolete
        case url
    }
    
    init?(dfn: WebRefCrawl.Dfn) throws {
        guard dfn.type == "attr-value" else { return nil }
        guard dfn.linkingText.count == 1, let linkingText = dfn.linkingText.first else {
            throw InvalidDfnError(message: "Not exactly one linking text in dfn.", dfn: dfn)
        }
        
        value = linkingText
        obsolete = dfn.href.absoluteString.contains("obsolete.html")
        url = dfn.href
        
        let parsedFor = try dfn.`for`.map {
            let splitFor = $0.split(separator: "/")
            guard splitFor.count == 2, let elementName = splitFor.first, let attrName = splitFor.last else {
                throw InvalidDfnError(message: "Invalid 'for' value '\($0)'.", dfn: dfn)
            }
            return (element: String(elementName), attribute: String(attrName))
        }
        `for` = Dictionary(grouping: parsedFor, by: \.element).mapValues { Set($0.map(\.attribute)) }
    }
    
    func isFor(_ attributeName: String, on elementNames: Set<String>) -> Bool {
        elementNames.contains { elementName in
            `for`[elementName, default: []].contains(attributeName)
        }
    }
}

