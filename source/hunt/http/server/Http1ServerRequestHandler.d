module hunt.http.server.Http1ServerRequestHandler;


import hunt.http.server.Http1ServerConnection;
import hunt.http.server.Http2ServerHandler;
import hunt.http.server.HttpServerRequest;
import hunt.http.server.HttpServerResponse;
import hunt.http.server.ServerHttpHandler;

import hunt.http.codec.http.decode.HttpParser;
import hunt.http.codec.http.model;

import hunt.container.ByteBuffer;
import hunt.string;

import hunt.logging;

alias RequestHandler = HttpParser.RequestHandler;
alias Http1ServerResponseOutputStream = Http1ServerConnection.Http1ServerResponseOutputStream;

/**
*/
class Http1ServerRequestHandler : RequestHandler {
    package(hunt.http.server) MetaData.Request request;
    package(hunt.http.server) MetaData.Response response;
    package(hunt.http.server) Http1ServerConnection connection;
    package(hunt.http.server) Http1ServerResponseOutputStream outputStream;
    package(hunt.http.server) ServerHttpHandler serverHttpHandler;
    package(hunt.http.server) HttpFields trailer;

    this(ServerHttpHandler serverHttpHandler) {
        this.serverHttpHandler = serverHttpHandler;
    }

    override
    bool startRequest(string method, string uri, HttpVersion ver) {
        version(HUNT_DEBUG) {
            tracef("server received the request line, %s, %s, %s", method, uri, ver);
        }

        request = new HttpServerRequest(method, uri, ver);
        response = new HttpServerResponse();
        outputStream = new Http1ServerResponseOutputStream(response, connection);

        return HttpMethod.PRI.isSame(method) && connection.directUpgradeHttp2(request);
    }

    override
    void parsedHeader(HttpField field) {
        request.getFields().add(field);
    }

    override
    bool headerComplete() {
        if (HttpMethod.CONNECT.asString().equalsIgnoreCase(request.getMethod())) {
            return serverHttpHandler.acceptHttpTunnelConnection(request, response, outputStream, connection);
        } else {
            string expectedValue = request.getFields().get(HttpHeader.EXPECT);
            if ("100-continue".equalsIgnoreCase(expectedValue)) {
                bool skipNext = serverHttpHandler.accept100Continue(request, response, outputStream, connection);
                if (skipNext) {
                    return true;
                } else {
                    connection.response100Continue();
                    return serverHttpHandler.headerComplete(request, response, outputStream, connection);
                }
            } else {
                return serverHttpHandler.headerComplete(request, response, outputStream, connection);
            }
        }
    }

    override
    bool content(ByteBuffer item) {
        return serverHttpHandler.content(item, request, response, outputStream, connection);
    }

    override
    bool contentComplete() {
        return serverHttpHandler.contentComplete(request, response, outputStream, connection);
    }

    override
    void parsedTrailer(HttpField field) {
        if (trailer is null) {
            trailer = new HttpFields();
            request.setTrailerSupplier(() => trailer);
        }
        trailer.add(field);
    }

    override
    bool messageComplete() {
        try {
            if (connection.getUpgradeHttp2Complete() || connection.getUpgradeWebSocketComplete()) {
                return true;
            } else {
                bool success = connection.upgradeProtocol(request, response, outputStream, connection);
                return success || serverHttpHandler.messageComplete(request, response, outputStream, connection);
            }
        } finally {
            connection.getParser().reset();
        }
    }

    override
    void badMessage(int status, string reason) {
        serverHttpHandler.badMessage(status, reason, request, response, outputStream, connection);
    }


    void badMessage(BadMessageException failure)
    {
        badMessage(failure.getCode(), failure.getReason());
    }


    override
    void earlyEOF() {
        serverHttpHandler.earlyEOF(request, response, outputStream, connection);
    }

    override
    int getHeaderCacheSize() {
        return 1024;
    }

}
