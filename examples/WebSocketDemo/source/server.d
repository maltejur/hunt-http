
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream;
import hunt.http.codec.websocket.frame;
import hunt.http.codec.websocket.model;
import hunt.http.codec.websocket.stream.WebSocketConnection;

import hunt.http.server;
import hunt.collection.ByteBuffer;


import hunt.logging;

import std.file;
import std.path;
import std.stdio;


/**
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 365 -key ca.key -out ca.crt
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
*/

void main(string[] args)
{
    HttpServer server = new HttpServer("0.0.0.0", 8080, new HttpServerOptions(), 
        new class ServerHttpHandlerAdapter {

            override
            bool messageComplete(HttpRequest request, HttpResponse response,
                                           HttpOutputStream output,
                                           HttpConnection connection) {
                return true;
            }
        }, 

        new class WebSocketHandler {
            override
            void onConnect(WebSocketConnection webSocketConnection) {
                webSocketConnection.onClose((HttpConnection conn) {
                    warningf("Remote host shutdown: %s", 
                        webSocketConnection.getRemoteAddress().toString());
                });

                webSocketConnection.sendText("Say hello from Hunt.HTTP.").thenAccept( 
                    (r) { 
                        tracef("Server sends text frame success."); 
                    }
                );
            }

            override
            void onFrame(Frame frame, WebSocketConnection connection) {
                FrameType type = frame.getType();
                switch (type) {
                    case FrameType.TEXT: {
                        TextFrame textFrame = cast(TextFrame) frame;
                        string msg = textFrame.getPayloadAsUTF8();
                        tracef("Server received: " ~ textFrame.toString() ~ ", " ~ msg);
                        connection.sendText(msg); // echo back
                        break;
                    }

                    case FrameType.BINARY: {
                        BinaryFrame bf = cast(BinaryFrame)frame;
                        ByteBuffer buf = bf.getPayload;
                        byte[] data = buf.getRemaining();
                        tracef("%(%02X %)", data);
                        break;
                    }

                    case FrameType.CLOSE: {
                        infof("Client [%s] closed normally.", connection.getRemoteAddress().toString());
                        break;
                    }

                    default: 
                        warningf("Can't handle the frame of %s", type);
                        break;
                }

            }
        });
    
    server.start();
}

