module hunt.http.codec.websocket.frame;

import hunt.http.codec.websocket.model.OpCode;
import hunt.http.utils.io.BufferUtils;

import hunt.container.ByteBuffer;
import java.util.Arrays;

/**
 * A Base Frame as seen in <a href="https://tools.ietf.org/html/rfc6455#section-5.2">RFC 6455. Sec 5.2</a>
 * <p>
 * <pre>
 *    0                   1                   2                   3
 *    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 *   +-+-+-+-+-------+-+-------------+-------------------------------+
 *   |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
 *   |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
 *   |N|V|V|V|       |S|             |   (if payload len==126/127)   |
 *   | |1|2|3|       |K|             |                               |
 *   +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
 *   |     Extended payload length continued, if payload len == 127  |
 *   + - - - - - - - - - - - - - - - +-------------------------------+
 *   |                               |Masking-key, if MASK set to 1  |
 *   +-------------------------------+-------------------------------+
 *   | Masking-key (continued)       |          Payload Data         |
 *   +-------------------------------- - - - - - - - - - - - - - - - +
 *   :                     Payload Data continued ...                :
 *   + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
 *   |                     Payload Data continued ...                |
 *   +---------------------------------------------------------------+
 * </pre>
 */
abstract class WebSocketFrame : Frame {
    static WebSocketFrame copy(Frame original) {
        WebSocketFrame copy;
        switch (original.getOpCode()) {
            case OpCode.BINARY:
                copy = new BinaryFrame();
                break;
            case OpCode.TEXT:
                copy = new TextFrame();
                break;
            case OpCode.CLOSE:
                copy = new CloseFrame();
                break;
            case OpCode.CONTINUATION:
                copy = new ContinuationFrame();
                break;
            case OpCode.PING:
                copy = new PingFrame();
                break;
            case OpCode.PONG:
                copy = new PongFrame();
                break;
            default:
                throw new IllegalArgumentException("Cannot copy frame with opcode " + original.getOpCode() + " - " + original);
        }

        copy.copyHeaders(original);
        ByteBuffer payload = original.getPayload();
        if (payload != null) {
            ByteBuffer payloadCopy = ByteBuffer.allocate(payload.remaining());
            payloadCopy.put(payload.slice()).flip();
            copy.setPayload(payloadCopy);
        }
        return copy;
    }

    /**
     * Combined FIN + RSV1 + RSV2 + RSV3 + OpCode byte.
     * <p>
     * <pre>
     *   1000_0000 (0x80) = fin
     *   0100_0000 (0x40) = rsv1
     *   0010_0000 (0x20) = rsv2
     *   0001_0000 (0x10) = rsv3
     *   0000_1111 (0x0F) = opcode
     * </pre>
     */
    protected byte finRsvOp;
    protected bool masked = false;

    protected byte mask[];
    /**
     * The payload data.
     * <p>
     * It is assumed to always be in FLUSH mode (ready to read) in this object.
     */
    protected ByteBuffer data;

    /**
     * Construct form opcode
     *
     * @param opcode the opcode the frame is based on
     */
    protected WebSocketFrame(byte opcode) {
        reset();
        setOpCode(opcode);
    }

    abstract void assertValid();

    protected void copyHeaders(Frame frame) {
        finRsvOp = 0x00;
        finRsvOp |= frame.isFin() ? 0x80 : 0x00;
        finRsvOp |= frame.isRsv1() ? 0x40 : 0x00;
        finRsvOp |= frame.isRsv2() ? 0x20 : 0x00;
        finRsvOp |= frame.isRsv3() ? 0x10 : 0x00;
        finRsvOp |= frame.getOpCode() & 0x0F;

        masked = frame.isMasked();
        if (masked) {
            mask = frame.getMask();
        } else {
            mask = null;
        }
    }

    protected void copyHeaders(WebSocketFrame copy) {
        finRsvOp = copy.finRsvOp;
        masked = copy.masked;
        mask = null;
        if (copy.mask != null)
            mask = Arrays.copyOf(copy.mask, copy.mask.length);
    }

    override
    bool equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        WebSocketFrame other = (WebSocketFrame) obj;
        if (data == null) {
            if (other.data != null) {
                return false;
            }
        } else if (!data.equals(other.data)) {
            return false;
        }
        if (finRsvOp != other.finRsvOp) {
            return false;
        }
        if (!Arrays.equals(mask, other.mask)) {
            return false;
        }
        if (masked != other.masked) {
            return false;
        }
        return true;
    }

    override
    byte[] getMask() {
        return mask;
    }

    override
    final byte getOpCode() {
        return (byte) (finRsvOp & 0x0F);
    }

    /**
     * Get the payload ByteBuffer. possible null.
     */
    override
    ByteBuffer getPayload() {
        return data;
    }

    string getPayloadAsUTF8() {
        return BufferUtils.toUTF8String(getPayload());
    }

    override
    int getPayloadLength() {
        if (data == null) {
            return 0;
        }
        return data.remaining();
    }

    override
    Type getType() {
        return Type.from(getOpCode());
    }

    override
    int hashCode() {
        final int prime = 31;
        int result = 1;
        result = (prime * result) + ((data == null) ? 0 : data.hashCode());
        result = (prime * result) + finRsvOp;
        result = (prime * result) + Arrays.hashCode(mask);
        return result;
    }

    override
    bool hasPayload() {
        return ((data != null) && data.hasRemaining());
    }

    abstract bool isControlFrame();

    abstract bool isDataFrame();

    override
    bool isFin() {
        return (byte) (finRsvOp & 0x80) != 0;
    }

    override
    bool isMasked() {
        return masked;
    }

    override
    bool isRsv1() {
        return (byte) (finRsvOp & 0x40) != 0;
    }

    override
    bool isRsv2() {
        return (byte) (finRsvOp & 0x20) != 0;
    }

    override
    bool isRsv3() {
        return (byte) (finRsvOp & 0x10) != 0;
    }

    void reset() {
        finRsvOp = (byte) 0x80; // FIN (!RSV, opcode 0)
        masked = false;
        data = null;
        mask = null;
    }

    WebSocketFrame setFin(bool fin) {
        // set bit 1
        this.finRsvOp = (byte) ((finRsvOp & 0x7F) | (fin ? 0x80 : 0x00));
        return this;
    }

    Frame setMask(byte[] maskingKey) {
        this.mask = maskingKey;
        this.masked = (mask != null);
        return this;
    }

    Frame setMasked(bool mask) {
        this.masked = mask;
        return this;
    }

    protected WebSocketFrame setOpCode(byte op) {
        this.finRsvOp = (byte) ((finRsvOp & 0xF0) | (op & 0x0F));
        return this;
    }

    /**
     * Set the data payload.
     * <p>
     * The provided buffer will be used as is, no copying of bytes performed.
     * <p>
     * The provided buffer should be flipped and ready to READ from.
     *
     * @param buf the bytebuffer to set
     * @return the frame itself
     */
    WebSocketFrame setPayload(ByteBuffer buf) {
        data = buf;
        return this;
    }

    WebSocketFrame setRsv1(bool rsv1) {
        // set bit 2
        this.finRsvOp = (byte) ((finRsvOp & 0xBF) | (rsv1 ? 0x40 : 0x00));
        return this;
    }

    WebSocketFrame setRsv2(bool rsv2) {
        // set bit 3
        this.finRsvOp = (byte) ((finRsvOp & 0xDF) | (rsv2 ? 0x20 : 0x00));
        return this;
    }

    WebSocketFrame setRsv3(bool rsv3) {
        // set bit 4
        this.finRsvOp = (byte) ((finRsvOp & 0xEF) | (rsv3 ? 0x10 : 0x00));
        return this;
    }

    override
    string toString() {
        StringBuilder b = new StringBuilder();
        b.append(OpCode.name((byte) (finRsvOp & 0x0F)));
        b.append('[');
        b.append("len=").append(getPayloadLength());
        b.append(",fin=").append((finRsvOp & 0x80) != 0);
        b.append(",rsv=");
        b.append(((finRsvOp & 0x40) != 0) ? '1' : '.');
        b.append(((finRsvOp & 0x20) != 0) ? '1' : '.');
        b.append(((finRsvOp & 0x10) != 0) ? '1' : '.');
        b.append(",masked=").append(masked);
        b.append(']');
        return b.toString();
    }
}
