module test.codec.http2;

import hunt.http.client.http2.ClientHTTPHandler;
import hunt.http.client.http2.HTTP2Client;
import hunt.http.client.http2.HTTPClientConnection;
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream.HTTP2Configuration;
import hunt.http.utils.concurrent.FuturePromise;

import java.io.UnsupportedEncodingException;
import hunt.container.ByteBuffer;
import java.util.concurrent.ExecutionException;

import test.codec.http2.HTTPClientHandlerFactory.newHandler;

public class HTTP2ClientTLSDemo {

    public static void main(string[] args)
            throws InterruptedException, ExecutionException, UnsupportedEncodingException {
        final HTTP2Configuration http2Configuration = new HTTP2Configuration();
        http2Configuration.getTcpConfiguration().setTimeout(60 * 1000);
        http2Configuration.setSecureConnectionEnabled(true);
        HTTP2Client client = new HTTP2Client(http2Configuration);

        FuturePromise<HTTPClientConnection> promise = new FuturePromise<>();
        client.connect("127.0.0.1", 6677, promise);

        final HTTPClientConnection httpConnection = promise.get();

        final ByteBuffer[] buffers = new ByteBuffer[]{ByteBuffer.wrap("hello world!".getBytes("UTF-8")),
                ByteBuffer.wrap("big hello world!".getBytes("UTF-8"))};
        ClientHTTPHandler handler = newHandler(buffers);

        // test
        HttpFields fields = new HttpFields();
        fields.put(HttpHeader.USER_AGENT, "Hunt Client 1.0");
        MetaData.Request post = new MetaData.Request("POST", HttpScheme.HTTP, new HostPortHttpField("127.0.0.1:6677"),
                "/data", HttpVersion.HTTP_1_1, fields);
        httpConnection.sendRequestWithContinuation(post, handler);

        MetaData.Request get = new MetaData.Request("GET", HttpScheme.HTTP, new HostPortHttpField("127.0.0.1:6677"),
                "/test2", HttpVersion.HTTP_1_1, new HttpFields());
        httpConnection.send(get, handler);

        MetaData.Request post2 = new MetaData.Request("POST", HttpScheme.HTTP, new HostPortHttpField("127.0.0.1:6677"),
                "/data", HttpVersion.HTTP_1_1, fields);
        httpConnection.send(post2, new ByteBuffer[]{ByteBuffer.wrap("test data 2".getBytes("UTF-8")),
                ByteBuffer.wrap("finished test data 2".getBytes("UTF-8"))}, handler);
    }


}
