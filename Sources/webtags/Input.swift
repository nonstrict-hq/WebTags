//
//  Input.swift
//  WebTags
//
//  Created by Nonstrict on 05/02/2023.
//

import Foundation

struct WebRefCrawl {
    // MARK: - Webref crawl index
    
    struct Index: Decodable {
        let results: [Result]
        let stats: Stats
    }
    
    struct Stats: Decodable {
        let crawled: Int
        let errors: Int
    }
    
    struct Result: Decodable {
        let shortname: String
        let title: String
        let organization: String
        let url: URL
        let standing: String
        let date: String
        let dfns: String?
        let elements: String?
    }
    
    // MARK: - Webref elements JSON
    
    struct Elements: Decodable {
        let elements: [Element]
    }
    
    struct Element: Decodable {
        let name: String
        let obsolete: Bool?
    }
    
    // MARK: - Webref DFNs JSON
    
    struct Dfns: Decodable {
        let dfns: [Dfn]
    }
    
    struct Dfn: Decodable {
        let type: String
        let href: URL
        let linkingText: [String]
        let `for`: [String]
        let heading: Heading
    }
    
    struct Heading: Decodable {
        let title: String
        let number: String?
    }
}
