module hunt.http.codec.CommonDecoder;

import hunt.collection.ByteBuffer;
import hunt.Exceptions;
import hunt.logging;

import hunt.http.AbstractHttpConnection;
import hunt.http.HttpConnection;
import hunt.http.HttpConnectionType;
import hunt.net.codec.Decoder;
import hunt.net.Connection;
import hunt.net.secure.SecureSession;

/**
 * 
 */
class CommonDecoder : DecoderChain {

    this(DecoderChain next) {
        super(next);
    }

    override void decode(ByteBuffer buf, Connection session) {
        version(HUNT_METRIC) {
            import core.time;
            MonoTime startTime = MonoTime.currTime;
            debug infof("start decoding ...");
        }
        DecoderChain next = getNext();

        ConnectionState connState = session.getState();
        AbstractHttpConnection httpConnection = cast(AbstractHttpConnection) session.getAttribute(HttpConnection.NAME);

        version(HUNT_HTTP_DEBUG) {
            if(httpConnection !is null) {
                tracef("http connection: %s", typeid(httpConnection).name);
            }
        }

        SecureSession secureSession = cast(SecureSession) session.getAttribute(SecureSession.NAME);
        
        version(HUNT_HTTP_DEBUG) infof("State: %s, isSecured: %s, SecureSession: %s, http connection: %s", 
            connState, session.isSecured(), secureSession is null, httpConnection is null);

        if(connState == ConnectionState.Securing) {
            // TLS handshake
            ByteBuffer plaintext = secureSession.read(buf);

            if (plaintext !is null && plaintext.hasRemaining()) {
                version(HUNT_DEBUG) {
                    tracef("The session %s handshake finished and received cleartext size %s",
                            session.getId(), plaintext.remaining());
                }

                httpConnection = cast(AbstractHttpConnection) session.getAttribute(HttpConnection.NAME);
                warningf("HTTP_CONNECTION is null: ", httpConnection is null);

                if (httpConnection !is null) {
                    if (next !is null) 
                        next.decode(plaintext, session);
                    else 
                        warning("The next decoder is null.");
                } else {
                    warningf("httpConnection is null");
                    throw new IllegalStateException("the http connection has not been created");
                }
            } else {
                version(HUNT_DEBUG) {
                    if (secureSession.isHandshakeFinished()) {
                        tracef("The ssl session %s need more data", session.getId());
                    } else {
                        tracef("The ssl session %s is shaking hand", session.getId());
                    }
                }
            }
        } else if(connState == ConnectionState.Secured) {
            // try {
            //     return secureSession.read(buffer);
            // } catch (IOException e) {
            //     throw new SecureNetException("decrypt exception", e);
            // }            
            ByteBuffer plaintext = secureSession.read(buf); // httpConnection.decrypt(buf);
            if (plaintext !is null && plaintext.hasRemaining() && next !is null) {
                next.decode(plaintext, session);
            } else {
                warning("The next decoder is null.");
            }
        } else {
            if (next !is null) {
                next.decode(buf, session);
            } else {
                warning("The next decoder is null.");
            }
        }

        version(HUNT_METRIC) {
            Duration timeElapsed = MonoTime.currTime - startTime;
            warningf("decoding done for session %d in: %d microseconds",
                session.getId, timeElapsed.total!(TimeUnit.Microsecond)());
        }
    }
}
