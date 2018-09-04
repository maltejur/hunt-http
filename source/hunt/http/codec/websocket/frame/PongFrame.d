module hunt.http.codec.websocket.frame.PongFrame;

import hunt.http.codec.websocket.model.common;
import hunt.util.string;

import hunt.container.ByteBuffer;

class PongFrame : ControlFrame {
    this() {
        super(OpCode.PONG);
    }

    PongFrame setPayload(byte[] bytes) {
        setPayload(ByteBuffer.wrap(bytes));
        return this;
    }

    PongFrame setPayload(string payload) {
        setPayload(StringUtils.getUtf8Bytes(payload));
        return this;
    }

    override
    Type getType() {
        return Type.PONG;
    }
}
