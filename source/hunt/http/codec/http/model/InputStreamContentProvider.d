module hunt.http.codec.http.model.InputStreamContentProvider;

// import hunt.util.functional;
// import hunt.container.BufferUtils;
// import hunt.io;
// import hunt.logging;


// import java.io.Closeable;
// import java.io.InputStream;
// import hunt.container.ByteBuffer;
// import java.util.Iterator;
// import java.util.NoSuchElementException;

/**
 * A {@link ContentProvider} for an {@link InputStream}.
 * <p>
 * The input stream is read once and therefore fully consumed.
 * Invocations to the {@link #iterator()} method after the first will return an "empty" iterator
 * because the stream has been consumed on the first invocation.
 * <p>
 * However, it is possible for subclasses to override {@link #onRead(byte[], int, int)} to copy
 * the content read from the stream to another location (for example a file), and be able to
 * support multiple invocations of {@link #iterator()}, returning the iterator provided by this
 * class on the first invocation, and an iterator on the bytes copied to the other location
 * for subsequent invocations.
 * <p>
 * It is possible to specify, at the constructor, a buffer size used to read content from the
 * stream, by default 4096 bytes.
 * <p>
 * The {@link InputStream} passed to the constructor is by default closed when is it fully
 * consumed (or when an exception is thrown while reading it), unless otherwise specified
 * to the {@link #InputStreamContentProvider(InputStream, int, bool) constructor}.
 */
// class InputStreamContentProvider : ContentProvider, Callback, Closeable {
    

//     private InputStreamContentProviderIterator iterator = new InputStreamContentProviderIterator();
//     private InputStream stream;
//     private int bufferSize;
//     private bool autoClose;

//     this(InputStream stream) {
//         this(stream, 4096);
//     }

//     this(InputStream stream, int bufferSize) {
//         this(stream, bufferSize, true);
//     }

//     this(InputStream stream, int bufferSize, bool autoClose) {
//         this.stream = stream;
//         this.bufferSize = bufferSize;
//         this.autoClose = autoClose;
//     }

//     override
//     long getLength() {
//         return -1;
//     }

//     /**
//      * Callback method invoked just after having read from the stream,
//      * but before returning the iteration element (a {@link ByteBuffer}
//      * to the caller.
//      * <p>
//      * Subclasses may override this method to copy the content read from
//      * the stream to another location (a file, or in memory if the content
//      * is known to fit).
//      *
//      * @param buffer the byte array containing the bytes read
//      * @param offset the offset from where bytes should be read
//      * @param length the length of the bytes read
//      * @return a {@link ByteBuffer} wrapping the byte array
//      */
//     protected ByteBuffer onRead(byte[] buffer, int offset, int length) {
//         if (length <= 0)
//             return BufferUtils.EMPTY_BUFFER;
//         return ByteBuffer.wrap(buffer, offset, length);
//     }

//     /**
//      * Callback method invoked when an exception is thrown while reading
//      * from the stream.
//      *
//      * @param failure the exception thrown while reading from the stream.
//      */
//     protected void onReadFailure(Exception failure) {
//     }

//     override
//     Iterator!ByteBuffer iterator() {
//         return iterator;
//     }

//     override
//     void close() {
//         if (autoClose) {
//             IO.close(stream);
//         }
//     }

//     override
//     void failed(Exception failure) {
//         // TODO: forward the failure to the iterator.
//         close();
//     }

//     /**
//      * Iterating over an {@link InputStream} is tricky, because {@link #hasNext()} must return false
//      * if the stream reads -1. However, we don't know what to return until we read the stream, which
//      * means that stream reading must be performed by {@link #hasNext()}, which introduces a side-effect
//      * on what is supposed to be a simple query method (with respect to the Query Command Separation
//      * Principle).
//      * <p>
//      * Alternatively, we could return {@code true} from {@link #hasNext()} even if we don't know that
//      * we will read -1, but then when {@link #next()} reads -1 it must return an empty buffer.
//      * However this is problematic, since GETs with no content indication would become GET with chunked
//      * content, and not understood by servers.
//      * <p>
//      * Therefore we need to make sure that {@link #hasNext()} does not perform any side effect (so that
//      * it can be called multiple times) until {@link #next()} is called.
//      */
//     private class InputStreamContentProviderIterator : Iterator!ByteBuffer, Closeable {
//         private Exception failure;
//         private ByteBuffer buffer;
//         private bool hasNext;

//         override
//         bool hasNext() {
//             try {
//                 if (hasNext != null)
//                     return hasNext;

//                 byte[] bytes = new byte[bufferSize];
//                 int read = stream.read(bytes);
//                 version(HuntDebugMode)
//                     tracef("Read %s bytes from %s", read, stream);
//                 if (read > 0) {
//                     hasNext = bool.TRUE;
//                     buffer = onRead(bytes, 0, read);
//                     return true;
//                 } else if (read < 0) {
//                     hasNext = bool.FALSE;
//                     buffer = null;
//                     close();
//                     return false;
//                 } else {
//                     hasNext = bool.TRUE;
//                     buffer = BufferUtils.EMPTY_BUFFER;
//                     return true;
//                 }
//             } catch (Exception x) {
//                 version(HuntDebugMode) {
//                     tracef("input stream exception", x);
//                 }
//                 if (failure == null) {
//                     failure = x;
//                     onReadFailure(x);
//                     // Signal we have more content to cause a call to
//                     // next() which will throw NoSuchElementException.
//                     hasNext = bool.TRUE;
//                     buffer = null;
//                     close();
//                     return true;
//                 }
//                 throw new IllegalStateException("");
//             }
//         }

//         override
//         ByteBuffer next() {
//             if (failure != null) {
//                 // Consume the failure so that calls to hasNext() will return false.
//                 hasNext = bool.FALSE;
//                 buffer = null;
//                 throw (NoSuchElementException) new NoSuchElementException().initCause(failure);
//             }
//             if (!hasNext())
//                 throw new NoSuchElementException();

//             ByteBuffer result = buffer;
//             if (result == null) {
//                 hasNext = bool.FALSE;
//                 buffer = null;
//                 throw new NoSuchElementException();
//             } else {
//                 hasNext = null;
//                 buffer = null;
//                 return result;
//             }
//         }

//         override
//         void remove() {
//             throw new UnsupportedOperationException();
//         }

//         override
//         void close() {
//             InputStreamContentProvider.this.close();
//         }
//     }
// }
