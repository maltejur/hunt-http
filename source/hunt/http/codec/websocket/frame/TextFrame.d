module hunt.http.codec.websocket.frame.TextFrame;

import hunt.http.codec.websocket.frame.DataFrame;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.frame.WebSocketFrame;
import hunt.http.codec.websocket.model.common;
import hunt.util.string;

import hunt.container.ByteBuffer;
import hunt.container.BufferUtils;

class TextFrame : DataFrame {
    this() {
        super(OpCode.TEXT);
    }

    override
    Type getType() {
        return getOpCode() == OpCode.CONTINUATION ? Type.CONTINUATION : Type.TEXT;
    }

    TextFrame setPayload(string str) {
        setPayload(ByteBuffer.wrap(cast(byte[])(str)));
        return this;
    }

    alias setPayload = WebSocketFrame.setPayload;

    override string getPayloadAsUTF8() {
        if (data is null) {
            return null;
        }
        return BufferUtils.toString(data);
    }
}