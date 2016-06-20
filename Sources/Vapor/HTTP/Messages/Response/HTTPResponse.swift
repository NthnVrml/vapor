import S4

// So common we simplify it

public typealias Response = HTTPResponse

public final class HTTPResponse: HTTPMessage {
    public let version: Version
    public let status: Status

    // MARK: Post Serialization

    public var onComplete: ((Stream) throws -> Void)?

    public init(version: Version = Version(major: 1, minor: 1), status: Status = .ok, headers: Headers = [:], body: HTTPBody = .data([])) {
        self.version = version
        self.status = status


        let statusLine = "HTTP/\(version.major).\(version.minor) \(status.statusCode) \(status.reasonPhrase)"
        super.init(startLine: statusLine, headers: headers, body: body)

        self.data.append(self.json)
    }

    public convenience required init(startLineComponents: (BytesSlice, BytesSlice, BytesSlice), headers: Headers, body: HTTPBody) throws {
        let (httpVersionSlice, statusCodeSlice, reasonPhrase) = startLineComponents
        // TODO: Right now in Status, if you pass reason phrase, it automatically overrides status code. Try to use reason phrase
        // keeping weirdness here to help reminder and silence warnings
        _ = reasonPhrase

        let version = try Version(httpVersionSlice)
        guard let statusCode = Int(statusCodeSlice.string) else { fatalError("throw real error") }
        // TODO: If we pass status reason phrase, it overrides status, adjust so that's not a thing
        let status = Status(statusCode: statusCode)

        self.init(version: version, status: status, headers: headers, body: body)
    }
}

extension HTTPResponse {
    public convenience init(error: String) {
        self.init(status: .internalServerError, body: error)
    }
}

extension HTTPResponse {
    /**
         Send chunked data with the
         `Transfer-Encoding: Chunked` header.

         Chunked uses the Transfer-Encoding HTTP header in
         place of the Content-Length header.

         https://en.wikipedia.org/wiki/Chunked_transfer_encoding
    */
    public convenience init(status: Status = .ok, headers: Headers = [:], chunked closure: ((ChunkStream) throws -> Void)) {
        var headers = headers
        headers.setTransferEncodingChunked()
        self.init(status: status, headers: headers, body: .chunked(closure))
    }
}

extension HTTPResponse {
    /**
         Convenience Initializer

         - parameter status: the http status
         - parameter json: any value that will be attempted to be serialized as json.  Use 'Json' for more complex objects
     */
    public convenience init(status: Status, json: JSON) {
        let headers: Headers = [
            "Content-Type": "application/json; charset=utf-8"
        ]
        self.init(status: status, headers: headers, body: HTTPBody(json))
    }
}

extension HTTPResponse {
    /*
        Creates a redirect response with
        the 301 Status an `Location` header.
    */
    public convenience init(headers: Headers = [:], redirect location: String) {
        var headers = headers
        headers["Location"] = location
        self.init(status: .movedPermanently, headers: headers)
    }
}

extension HTTPResponse {
    /*
     Creates a redirect response with
     the 301 Status an `Location` header.
     */
    public convenience init<S: Sequence where S.Iterator.Element == Byte>(version: Version = Version(major: 1, minor: 1), status: Status = .ok, headers: Headers = [:], body: S) {
        let body = HTTPBody(body)
        self.init(version: version, status: status, headers: headers, body: body)
    }
}



extension HTTPResponse {
    /*
     Creates a redirect response with
     the 301 Status an `Location` header.
     */
    public convenience init(version: Version = Version(major: 1, minor: 1), status: Status = .ok, headers: Headers = [:], body: HTTPBodyConvertible) {
        let body = body.makeBody()
        self.init(version: version, status: status, headers: headers, body: body)
    }
}