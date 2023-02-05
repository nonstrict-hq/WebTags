//
//  Errors.swift
//  WebTags
//
//  Created by Nonstrict on 05/02/2023.
//

import Foundation

struct InvalidCrawlResultError: Error {
    let message: String
    let result: WebRefCrawl.Result
}

struct InvalidDfnError: Error {
    let message: String
    let dfn: WebRefCrawl.Dfn
}

struct EncodingFailedError: Error {
    let message: String
}
