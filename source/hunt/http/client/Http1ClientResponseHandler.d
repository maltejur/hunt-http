module hunt.http.client.Http1ClientResponseHandler;

import hunt.http.client.ClientHttpHandler;
import hunt.http.client.Http1ClientConnection;
import hunt.http.client.HttpClientResponse;

import hunt.http.codec.http.decode.HttpParser;
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream.HttpOutputStream;

import hunt.collection.ByteBuffer;
import hunt.io;
import hunt.logging;
import hunt.text.Common;

import std.string : icmp;
import std.conv;


/**
*/
class Http1ClientResponseHandler : HttpResponseHandler {
    package(hunt.http.client)  Http1ClientConnection connection;
    package(hunt.http.client)  HttpResponse response;
    package(hunt.http.client)  HttpRequest request;
    package(hunt.http.client) HttpOutputStream outputStream;
    protected ClientHttpHandler clientHttpHandler;
    protected HttpFields trailer;

    this(ClientHttpHandler clientHttpHandler) {
        this.clientHttpHandler = clientHttpHandler;

    }

    package(hunt.http.client) void onReady() {

    }

    override
    final bool startResponse(HttpVersion ver, int status, string reason) {
        version(HUNT_HTTP_DEBUG) {
            tracef("client received the response line, %s, %s, %s", ver, status, reason);
        }

        if (status == HttpStatus.CONTINUE_100 && HttpStatus.Code.CONTINUE.getMessage().equalsIgnoreCase(reason)) {
            clientHttpHandler.continueToSendData(request, response, outputStream, connection);
            version(HUNT_HTTP_DEBUG) {
                tracef("client received 100 continue, current parser state is %s", connection.getParser().getState());
            }
            return true;
        } else {
            response = new HttpClientResponse(ver, status, reason);
            return false;
        }
    }

    override
    final void parsedHeader(HttpField field) {
        response.getFields().add(field);
    }

    override
    final int getHeaderCacheSize() {
        return 1024;
    }

    override
    final bool headerComplete() {
        version(HUNT_HTTP_DEBUG_MORE) trace("handle response");
        return clientHttpHandler.headerComplete(request, response, outputStream, connection);
    }

    override
    final bool content(ByteBuffer item) {
        version(HUNT_HTTP_DEBUG_MORE) trace("handle response");
        return clientHttpHandler.content(item, request, response, outputStream, connection);
    }

    override
    bool contentComplete() {
        version(HUNT_HTTP_DEBUG_MORE) trace("handle response");
        return clientHttpHandler.contentComplete(request, response, outputStream, connection);
    }

    override
    void parsedTrailer(HttpField field) {
        if (trailer is null) {
            trailer = new HttpFields();
            response.setTrailerSupplier(() => trailer);
        }
        trailer.add(field);
    }

    protected bool http1MessageComplete() {
        version(HUNT_HTTP_DEBUG_MORE) trace("handle response");
        try {
            // version(WITH_HUNT_TRACE) endTraceSpan("");
            
            return clientHttpHandler.messageComplete(request, response, outputStream, connection);
        } finally {
            string requestConnectionValue = request.getFields().get(HttpHeader.CONNECTION);
            string responseConnectionValue = response.getFields().get(HttpHeader.CONNECTION);

            connection.getParser().reset();

            HttpVersion httpVersion = response.getHttpVersion();

            if(httpVersion == HttpVersion.HTTP_1_0) {
                if (icmp("keep-alive", requestConnectionValue)
                        && icmp("keep-alive", responseConnectionValue)) {
                    tracef("the client %s connection is persistent", response.getHttpVersion());
                } else {
                    IOUtils.close(connection);
                } 
            } else if (httpVersion == HttpVersion.HTTP_1_1){ // the persistent connection is default in HTTP 1.1
                if (icmp("close", requestConnectionValue)
                        || icmp("close", responseConnectionValue)) {
                    IOUtils.close(connection);
                } else {
                    tracef("the client %s connection is persistent", response.getHttpVersion());
                }
            }

        }
    }

    override
    final bool messageComplete() {
        bool success = connection.upgradeProtocolComplete(request, response);
        if (success) {
            tracef("client upgraded protocol successfully");
        }
        return http1MessageComplete();
    }

    
    void badMessage(BadMessageException failure) {
        badMessage(failure.getCode(), failure.getReason());
    }

    override
    final void badMessage(int status, string reason) {
        clientHttpHandler.badMessage(status, reason, request, response, outputStream, connection);
    }

    override
    void earlyEOF() {
        clientHttpHandler.earlyEOF(request, response, outputStream, connection);
    }

}
