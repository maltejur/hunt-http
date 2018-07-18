module test.codec.websocket;

import hunt.http.codec.websocket.exception.WebSocketException;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.frame.WebSocketFrame;
import hunt.http.codec.websocket.model.IncomingFrames;
import hunt.http.codec.websocket.model.OpCode;
import hunt.container.BufferUtils;
import hunt.util.Assert;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Queue;




public class IncomingFramesCapture : IncomingFrames {
    private static Logger LOG = LoggerFactory.getLogger("hunt-system");
    private EventQueue<WebSocketFrame> frames = new EventQueue<>();
    private EventQueue<Throwable> errors = new EventQueue<>();

    public void assertErrorCount(int expectedCount) {
        Assert.assertThat("Captured error count", errors.size(), is(expectedCount));
    }

    public void assertFrameCount(int expectedCount) {
        if (frames.size() != expectedCount) {
            // dump details
            System.err.printf("Expected %d frame(s)%n", expectedCount);
            System.err.printf("But actually captured %d frame(s)%n", frames.size());
            int i = 0;
            for (Frame frame : frames) {
                System.err.printf(" [%d] Frame[%s] - %s%n", i++,
                        OpCode.name(frame.getOpCode()),
                        BufferUtils.toDetailString(frame.getPayload()));
            }
        }
        Assert.assertThat("Captured frame count", frames.size(), is(expectedCount));
    }

    public void assertHasErrors(Class<? extends WebSocketException> errorType, int expectedCount) {
        Assert.assertThat(errorType.getSimpleName(), getErrorCount(errorType), is(expectedCount));
    }

    public void assertHasFrame(byte op) {
        Assert.assertThat(OpCode.name(op), getFrameCount(op), greaterThanOrEqualTo(1));
    }

    public void assertHasFrame(byte op, int expectedCount) {
        string msg = string.format("%s frame count", OpCode.name(op));
        Assert.assertThat(msg, getFrameCount(op), is(expectedCount));
    }

    public void assertHasNoFrames() {
        Assert.assertThat("Frame count", frames.size(), is(0));
    }

    public void assertNoErrors() {
        Assert.assertThat("Error count", errors.size(), is(0));
    }

    public void clear() {
        frames.clear();
    }

    public void dump() {
        System.err.printf("Captured %d incoming frames%n", frames.size());
        int i = 0;
        for (Frame frame : frames) {
            System.err.printf("[%3d] %s%n", i++, frame);
            System.err.printf("          payload: %s%n", BufferUtils.toDetailString(frame.getPayload()));
        }
    }

    public int getErrorCount(Class<? extends Throwable> errorType) {
        int count = 0;
        for (Throwable error : errors) {
            if (errorType.isInstance(error)) {
                count++;
            }
        }
        return count;
    }

    public Queue<Throwable> getErrors() {
        return errors;
    }

    public int getFrameCount(byte op) {
        int count = 0;
        for (WebSocketFrame frame : frames) {
            if (frame.getOpCode() == op) {
                count++;
            }
        }
        return count;
    }

    public Queue<WebSocketFrame> getFrames() {
        return frames;
    }

    override
    public void incomingError(Throwable e) {
        LOG.debug("incoming error", e);
        errors.add(e);
    }

    override
    public void incomingFrame(Frame frame) {
        WebSocketFrame copy = WebSocketFrame.copy(frame);
        // TODO: might need to make this optional (depending on use by client vs server tests)
        // Assert.assertThat("frame.masking must be set",frame.isMasked(),is(true));
        frames.add(copy);
    }

    public int size() {
        return frames.size();
    }
}
