# WebTags

A machine-readable overview of tags used on the web.

## What is WebTags?

WebTags is a tool generating a JSON file describing all elements, attributes and predefined attribute values for multiple web browser specifications like HTML, SVG and MathML. The JSON is generated directly from spec data so it's always up to date.

You can use this data to build other tools from, like a DSL, validator or autocomplete scripts.

## How to use

You have multiple options:
- Use the hosted JSON files on https://webtags.dev (automatically updated every 6 hours)
- Generate the JSON file yourself by:
  - Running one of the [binary releases](https://github.com/nonstrict-hq/WebTags/releases).
  - Running from source: `swift run`

## Data sources

All data is pulled from https://w3c.github.io/webref/ which in turn parses most of the web specs published by W3C and WhatWG every 6 hours and published as JSON. This format is pretty good, but still not super easy to use. By default we parse the HTML, SVG2 and MathML Core spec and use the curated version of the webref data.

## Why not use alternative X?

Most of the sources online are not easily machine readable, are not generated from the spec or unclearly licensed.

The most notable exceptions are:
- [Webref](https://w3c.github.io/webref/) not super easy to use, but otherwise excellent. (WebTags uses this as its main data source.)
- [Caniuse](https://github.com/Fyrd/caniuse) contains a lot of info, but unclear how it is updated and a lot of noise.
- [MDN](https://github.com/mdn/content) very complete and high quality, but very hard to parse.

## License

WebTags is Open Source from [Nonstrict](https://nonstrict.eu) created by [Mathijs Kadijk](https://github.com/mac-cain13) and [Tom Lokhorst](https://github.com/tomlokhorst), released under [MIT License](LICENSE.md).

Generated content is under the license of the respective owners:
- WhatWG HTML spec is licensed under [CC BY 4.0](https://github.com/whatwg/html/blob/main/LICENSE)
- W3C specs (SVG and MathML) are licensed under [W3C Document License](https://www.w3.org/Consortium/Legal/2023/doc-license)
