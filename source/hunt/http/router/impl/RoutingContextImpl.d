module hunt.http.router.impl.RoutingContextImpl;

import hunt.http.router.impl.RouterImpl;

import hunt.http.router.handler;
import hunt.http.router.HttpSession;
import hunt.http.router.HttpRequestBody;
import hunt.http.router.RoutingHandler;
import hunt.http.router.RouterManager;
import hunt.http.router.RoutingContext;

import hunt.http.codec.http.model.MetaData;
import hunt.http.codec.http.stream.HttpOutputStream;
// import hunt.http.server.HttpRequest;
// import hunt.http.server.HttpResponse;

import hunt.http.server.HttpServerContext;

import hunt.collection;
import hunt.util.Common;
import hunt.Exceptions;
import hunt.Functions;
import hunt.logging;
import hunt.concurrency.Promise;

import std.container;

/**
 * 
 */
class RoutingContextImpl : RoutingContext {
    private HttpRequest request;
    private NavigableSet!(RouterMatchResult) routers;
    private RouterMatchResult current;
    private HttpRequestBody httpRequestBody;
    private HttpSessionHandlerSPI httpSessionHandlerSPI;
    // private TemplateHandlerSPI templateHandlerSPI = TemplateHandlerSPILoader.getInstance().getTemplateHandlerSPI();
    private  bool asynchronousRead = false;
    // private  ConcurrentLinkedDeque<Promise<?>> handlerPromiseQueue;
    private HttpServerContext _context;

    this(HttpServerContext context, NavigableSet!(RouterMatchResult) routers) {
        _context = context;
        request = _context.httpRequest();
        this.routers = routers;
    }

    // override
    // string getAttribute(string key) {
    //     return request.get(key);
    // }

    // override
    // string setAttribute(string key, string value) {
    //     return request.put(key, value);
    // }

    // override
    // string removeAttribute(string key) {
    //     return request.remove(key);
    // }

    // override
    // string[string] getAttributes() {
    //     return request.getAttributes();
    // }

    override
    HttpResponse getResponse() {
        // return request.getResponse();
        return _context.httpResponse();
    }

    // override
    // HttpResponse getAsyncResponse() {
    //     return request.getAsyncResponse();
    // }

    override
    HttpRequest getRequest() {
        return request;
    }

    override
    string getRouterParameter(string name) {
        return current.getParameters().get(name);
    }

    override
    RoutingContext onContent(Action1!ByteBuffer handler) {
        getRequest().onContent(handler);
        asynchronousRead = true;
        return this;
    }

    override
    RoutingContext onContentComplete(Action1!HttpRequest handler) {
        getRequest().onContentComplete(handler);
        asynchronousRead = true;
        return this;
    }

    override
    RoutingContext onMessageComplete(Action1!HttpRequest handler) {
        getRequest().onMessageComplete(handler);
        asynchronousRead = true;
        return this;
    }

    override
    bool isAsynchronousRead() {
        return asynchronousRead;
    }

    override
    bool next() {
        current = routers.pollFirst();
        if(current is null) 
            return false;

        RouterImpl r = cast(RouterImpl)current.getRouter();
        IRoutingHandler handler = r.getHandler();
        version(HUNT_HTTP_DEBUG) trace("current handler: ", typeid(cast(Object)handler));
        handler.handle(this);
        return true;
    }

    override
    bool hasNext() {
        return !routers.isEmpty();
    }

    // override
    // <T> RoutingContext complete(Promise<T> promise) {
    //     ConcurrentLinkedDeque<Promise<T>> queue = createHandlerPromiseQueueIfAbsent();
    //     queue.push(promise);
    //     return this;
    // }

    // override
    // <T> bool next(Promise<T> promise) {
    //     return complete(promise).next();
    // }

    
    // override
    // <T> void succeed(T t) {
    //     Optional.ofNullable(handlerPromiseQueue)
    //             .map(ConcurrentLinkedDeque::pop)
    //             .map(p -> (Promise<T>) p)
    //             .ifPresent(p -> p.succeeded(t));
    // }

    // override
    // void fail(Throwable x) {
    //     Optional.ofNullable(handlerPromiseQueue)
    //             .map(ConcurrentLinkedDeque::pop)
    //             .ifPresent(p -> p.failed(x));
    // }

    
    // private <T> ConcurrentLinkedDeque<Promise<T>> createHandlerPromiseQueueIfAbsent() {
    //     if (handlerPromiseQueue == null) {
    //         handlerPromiseQueue = new ConcurrentLinkedDeque<>();
    //     }
    //     return (ConcurrentLinkedDeque) handlerPromiseQueue;
    // }

    override int getConnectionId() {
        return _context.getConnectionId();
    }

    void close() {
        _context.end();
    }

    override
    string getParameter(string name) {
        if(httpRequestBody is null) {
            return null;
        } else {
            return httpRequestBody.getParameter(name);
        }
    }

    override
    List!string getParameterValues(string name) {
        if(httpRequestBody is null)
            return new EmptyList!string();
        else
            return httpRequestBody.getParameterValues(name);
    }

    override
    Map!(string, List!string) getParameterMap() {
        if(httpRequestBody is null)
            return null;
        else
            return httpRequestBody.getParameterMap();
    }

    // override
    // Collection!Part getParts() {
    //     // return Optional.ofNullable(httpRequestBody)
    //     //                .map(HttpRequestBody::getParts)
    //     //                .orElse(Collections.emptyList());
    //     if(httpRequestBody is null)
    //         return null;
    //     else
    //         return httpRequestBody.getParts();
    // }

    // override
    // Part getPart(string name) {
    //     // return Optional.ofNullable(httpRequestBody)
    //     //                .map(s -> s.getPart(name))
    //     //                .orElse(null);
    //     if(httpRequestBody is null)
    //         return null;
    //     else
    //         return httpRequestBody.getPart(name);
    // }

    // override
    // InputStream getInputStream() {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(HttpRequestBody::getInputStream)
    //                    .orElse(null);
    // }

    // override
    // BufferedReader getBufferedReader() {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(HttpRequestBody::getBufferedReader)
    //                    .orElse(null);
    // }

    override
    string getStringBody(string charset) {
        if(httpRequestBody is null)
            return request.getStringBody(charset);
        else
            return httpRequestBody.getStringBody(charset);
    }

    override
    string getStringBody() {
        if(httpRequestBody is null)
            return request.getStringBody();
        else
            return httpRequestBody.getStringBody();
    }

    // override
    // <T> T getJsonBody(Class<T> clazz) {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(s -> s.getJsonBody(clazz))
    //                    .orElseGet(() -> request.getJsonBody(clazz));
    // }

    // override
    // <T> T getJsonBody(GenericTypeReference<T> typeReference) {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(s -> s.getJsonBody(typeReference))
    //                    .orElseGet(() -> request.getJsonBody(typeReference));

    // }

    // override
    // JsonObject getJsonObjectBody() {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(HttpRequestBody::getJsonObjectBody)
    //                    .orElseGet(request::getJsonObjectBody);
    // }

    // override
    // JsonArray getJsonArrayBody() {
    //     return Optional.ofNullable(httpRequestBody)
    //                    .map(HttpRequestBody::getJsonArrayBody)
    //                    .orElseGet(request::getJsonArrayBody);
    // }
    
    override void setHttpBody(HttpRequestBody requestBody) {
        this.httpRequestBody = requestBody;
    }

    // override
    // CompletableFuture<HttpSession> getSessionById(string id) {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(s -> s.getSessionById(id)).orElse(null);
    // }

    // override
    // CompletableFuture<HttpSession> getSession() {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(HttpSessionHandlerSPI::getSession).orElse(null);
    // }

    // override
    // CompletableFuture<HttpSession> getSession(bool create) {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(s -> s.getSession(create)).orElse(null);
    // }

    // override
    // CompletableFuture<HttpSession> getAndCreateSession(int maxAge) {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(s -> s.getAndCreateSession(maxAge)).orElse(null);
    // }

    // override
    // CompletableFuture<Integer> getSessionSize() {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(HttpSessionHandlerSPI::getSessionSize).orElse(null);
    // }

    // override
    // CompletableFuture<bool> removeSessionById(string id) {
    //     return Optional.ofNullable(httpSessionHandlerSPI).map(s -> s.removeSessionById(id)).orElse(null);
    // }

    // override
    // CompletableFuture<bool> removeSession() {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(HttpSessionHandlerSPI::removeSession)
    //                    .orElse(null);
    // }

    // override
    // CompletableFuture<bool> updateSession(HttpSession httpSession) {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(s -> s.updateSession(httpSession))
    //                    .orElse(null);
    // }

    // override
    // bool isRequestedSessionIdFromURL() {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(HttpSessionHandlerSPI::isRequestedSessionIdFromURL)
    //                    .orElse(false);
    // }

    // override
    // bool isRequestedSessionIdFromCookie() {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(HttpSessionHandlerSPI::isRequestedSessionIdFromCookie)
    //                    .orElse(false);
    // }

    // override
    // string getRequestedSessionId() {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(HttpSessionHandlerSPI::getRequestedSessionId)
    //                    .orElse(null);
    // }

    // override
    // string getSessionIdParameterName() {
    //     return Optional.ofNullable(httpSessionHandlerSPI)
    //                    .map(HttpSessionHandlerSPI::getSessionIdParameterName)
    //                    .orElse(null);
    // }

    // void setHttpSessionHandlerSPI(HttpSessionHandlerSPI httpSessionHandlerSPI) {
    //     this.httpSessionHandlerSPI = httpSessionHandlerSPI;
    // }

    // override
    // void renderTemplate(string resourceName, Object scope) {
    //     templateHandlerSPI.renderTemplate(this, resourceName, scope);
    // }

    // override
    // void renderTemplate(string resourceName, Object[] scopes) {
    //     templateHandlerSPI.renderTemplate(this, resourceName, scopes);
    // }

    // override
    // void renderTemplate(string resourceName, List<Object> scopes) {
    //     templateHandlerSPI.renderTemplate(this, resourceName, scopes);
    // }


    override RoutingContext write(string value) {
        _context.write(value);
        return this;
    }
   
    override RoutingContext write(byte[] b, int off, int len) {
        _context.write(b, off, len);
        return this;
    }

    override RoutingContext end() {
        _context.end();
        return this;
    }
    
    override void flush() {
        _context.flush();
    }

    override bool isCommitted() {
        return _context.isCommitted();
    }
}
