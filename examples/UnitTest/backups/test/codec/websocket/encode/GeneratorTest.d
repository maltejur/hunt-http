module test.codec.websocket.encode;

import hunt.http.codec.websocket.decode.Parser;
import hunt.http.codec.websocket.encode.Generator;
import hunt.http.codec.websocket.frame;
import hunt.http.codec.websocket.model.CloseInfo;
import hunt.http.codec.websocket.model.OpCode;
import hunt.http.codec.websocket.model.StatusCode;
import hunt.http.codec.websocket.stream.WebSocketPolicy;
import test.codec.websocket.utils.Hex;
import hunt.http.utils.StringUtils;
import hunt.container.BufferUtils;
import hunt.util.Assert;
import hunt.util.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import test.codec.websocket.IncomingFramesCapture;
import test.codec.websocket.UnitGenerator;
import test.codec.websocket.UnitParser;

import hunt.container.ByteBuffer;
import java.util.Arrays;



public class GeneratorTest {
    private static Logger LOG = LoggerFactory.getLogger("hunt-system");

    public static class WindowHelper {
        final int windowSize;
        int totalParts;
        int totalBytes;

        public WindowHelper(int windowSize) {
            this.windowSize = windowSize;
            this.totalParts = 0;
            this.totalBytes = 0;
        }

        public ByteBuffer generateWindowed(Frame... frames) {
            // Create Buffer to hold all generated frames in a single buffer
            int completeBufSize = 0;
            for (Frame f : frames) {
                completeBufSize += Generator.MAX_HEADER_LENGTH + f.getPayloadLength();
            }

            ByteBuffer completeBuf = ByteBuffer.allocate(completeBufSize);
            BufferUtils.clearToFill(completeBuf);

            // Generate from all frames
            Generator generator = new UnitGenerator();

            for (Frame f : frames) {
                ByteBuffer header = generator.generateHeaderBytes(f);
                totalBytes += BufferUtils.put(header, completeBuf);

                if (f.hasPayload()) {
                    ByteBuffer payload = f.getPayload();
                    totalBytes += payload.remaining();
                    totalParts++;
                    completeBuf.put(payload.slice());
                }
            }

            // Return results
            BufferUtils.flipToFlush(completeBuf, 0);
            return completeBuf;
        }

        public void assertTotalParts(int expectedParts) {
            Assert.assertThat("Generated Parts", totalParts, is(expectedParts));
        }

        public void assertTotalBytes(int expectedBytes) {
            Assert.assertThat("Generated Bytes", totalBytes, is(expectedBytes));
        }
    }

    private void assertGeneratedBytes(CharSequence expectedBytes, Frame... frames) {
        // collect up all frames as single ByteBuffer
        ByteBuffer allframes = UnitGenerator.generate(frames);
        // Get hex string form of all frames bytebuffer.
        string actual = Hex.asHex(allframes);
        // Validate
        Assert.assertThat("Buffer", actual, is(expectedBytes.toString()));
    }

    private string asMaskedHex(string str, byte[] maskingKey) {
        byte utf[] = StringUtils.getUtf8Bytes(str);
        mask(utf, maskingKey);
        return Hex.asHex(utf);
    }

    private void mask(byte[] buf, byte[] maskingKey) {
        int size = buf.length;
        for (int i = 0; i < size; i++) {
            buf[i] ^= maskingKey[i % 4];
        }
    }

    
    public void testClose_Empty() {
        // 0 byte payload (no status code)
        assertGeneratedBytes("8800", new CloseFrame());
    }

    
    public void testClose_CodeNoReason() {
        CloseInfo close = new CloseInfo(StatusCode.NORMAL);
        // 2 byte payload (2 bytes for status code)
        assertGeneratedBytes("880203E8", close.asFrame());
    }

    
    public void testClose_CodeOkReason() {
        CloseInfo close = new CloseInfo(StatusCode.NORMAL, "OK");
        // 4 byte payload (2 bytes for status code, 2 more for "OK")
        assertGeneratedBytes("880403E84F4B", close.asFrame());
    }

    
    public void testText_Hello() {
        WebSocketFrame frame = new TextFrame().setPayload("Hello");
        byte utf[] = StringUtils.getUtf8Bytes("Hello");
        assertGeneratedBytes("8105" ~ Hex.asHex(utf), frame);
    }

    
    public void testText_Masked() {
        WebSocketFrame frame = new TextFrame().setPayload("Hello");
        byte maskingKey[] = Hex.asByteArray("11223344");
        frame.setMask(maskingKey);

        // what is expected
        StringBuilder expected = new StringBuilder();
        expected.append("8185").append("11223344");
        expected.append(asMaskedHex("Hello", maskingKey));

        // validate
        assertGeneratedBytes(expected, frame);
    }

    
    public void testText_Masked_OffsetSourceByteBuffer() {
        ByteBuffer payload = ByteBuffer.allocate(100);
        payload.position(5);
        payload.put(StringUtils.getUtf8Bytes("Hello"));
        payload.flip();
        payload.position(5);
        // at this point, we have a ByteBuffer of 100 bytes.
        // but only a few bytes in the middle are made available for the payload.
        // we are testing that masking works as intended, even if the provided
        // payload does not start at position 0.
        LOG.debug("Payload = {}", BufferUtils.toDetailString(payload));
        WebSocketFrame frame = new TextFrame().setPayload(payload);
        byte maskingKey[] = Hex.asByteArray("11223344");
        frame.setMask(maskingKey);

        // what is expected
        StringBuilder expected = new StringBuilder();
        expected.append("8185").append("11223344");
        expected.append(asMaskedHex("Hello", maskingKey));

        // validate
        assertGeneratedBytes(expected, frame);
    }

    /**
     * Prevent regression of masking of many packets.
     */
    
    public void testManyMasked() {
        int pingCount = 2;

        // Prepare frames
        WebSocketFrame[] frames = new WebSocketFrame[pingCount + 1];
        for (int i = 0; i < pingCount; i++) {
            frames[i] = new PingFrame().setPayload(string.format("ping-%d", i));
        }
        frames[pingCount] = new CloseInfo(StatusCode.NORMAL).asFrame();

        // Mask All Frames
        byte maskingKey[] = Hex.asByteArray("11223344");
        for (WebSocketFrame f : frames) {
            f.setMask(maskingKey);
        }

        // Validate result of generation
        StringBuilder expected = new StringBuilder();
        expected.append("8986").append("11223344");
        expected.append(asMaskedHex("ping-0", maskingKey)); // ping 0
        expected.append("8986").append("11223344");
        expected.append(asMaskedHex("ping-1", maskingKey)); // ping 1
        expected.append("8882").append("11223344");
        byte closure[] = Hex.asByteArray("03E8");
        mask(closure, maskingKey);
        expected.append(Hex.asHex(closure)); // normal closure

        assertGeneratedBytes(expected, frames);
    }

    /**
     * Test the windowed generate of a frame that has no masking.
     */
    
    public void testWindowedGenerate() {
        // A decent sized frame, no masking
        byte payload[] = new byte[10240];
        Arrays.fill(payload, cast(byte) 0x44);

        WebSocketFrame frame = new BinaryFrame().setPayload(payload);

        // Generate
        int windowSize = 1024;
        WindowHelper helper = new WindowHelper(windowSize);
        ByteBuffer completeBuffer = helper.generateWindowed(frame);

        // Validate
        int expectedHeaderSize = 4;
        int expectedSize = payload.length + expectedHeaderSize;
        int expectedParts = 1;

        helper.assertTotalParts(expectedParts);
        helper.assertTotalBytes(payload.length + expectedHeaderSize);

        Assert.assertThat("Generated Buffer", completeBuffer.remaining(), is(expectedSize));
    }

    
    public void testWindowedGenerateWithMasking() {
        // A decent sized frame, with masking
        byte payload[] = new byte[10240];
        Arrays.fill(payload, cast(byte) 0x55);

        byte mask[] = new byte[]
                {0x2A, cast(byte) 0xF0, 0x0F, 0x00};

        WebSocketFrame frame = new BinaryFrame().setPayload(payload);
        frame.setMask(mask); // masking!

        // Generate
        int windowSize = 2929;
        WindowHelper helper = new WindowHelper(windowSize);
        ByteBuffer completeBuffer = helper.generateWindowed(frame);

        // Validate
        int expectedHeaderSize = 8;
        int expectedSize = payload.length + expectedHeaderSize;
        int expectedParts = 1;

        helper.assertTotalParts(expectedParts);
        helper.assertTotalBytes(payload.length + expectedHeaderSize);

        Assert.assertThat("Generated Buffer", completeBuffer.remaining(), is(expectedSize));

        // Parse complete buffer.
        WebSocketPolicy policy = WebSocketPolicy.newServerPolicy();
        Parser parser = new UnitParser(policy);
        IncomingFramesCapture capture = new IncomingFramesCapture();
        parser.setIncomingFramesHandler(capture);

        parser.parse(completeBuffer);

        // Assert validity of frame
        WebSocketFrame actual = capture.getFrames().poll();
        Assert.assertThat("Frame.opcode", actual.getOpCode(), is(OpCode.BINARY));
        Assert.assertThat("Frame.payloadLength", actual.getPayloadLength(), is(payload.length));

        // Validate payload contents for proper masking
        ByteBuffer actualData = actual.getPayload().slice();
        Assert.assertThat("Frame.payload.remaining", actualData.remaining(), is(payload.length));
        while (actualData.remaining() > 0) {
            Assert.assertThat("Actual.payload[" ~ actualData.position() ~ "]", actualData.get(), is(cast(byte) 0x55));
        }
    }
}
