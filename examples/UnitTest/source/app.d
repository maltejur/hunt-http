import std.stdio;

import hunt.util.UnitTest;

import test.codec.http2.model.HttpFieldsTest;
import test.codec.http2.model.HttpURIParseTest;
import test.codec.http2.model.HttpURITest;
import test.codec.http2.model.QuotedCSVTest;
import test.codec.http2.model.TestHttpField;
import test.codec.http2.model.CookieTest;

import test.codec.http2.hpack.HpackContextTest;
import test.codec.http2.hpack.HpackDecoderTest;
import test.codec.http2.hpack.HpackEncoderTest;
import test.codec.http2.hpack.HpackTest;
import test.codec.http2.hpack.TestHuffman;

import test.codec.http2.frame.SettingsGenerateParseTest;

import test.codec.http2.encode.TestPredefinedHTTP1Response;

import test.codec.http2.decode.HttpParserTest;
import test.codec.http2.decode.HTTP2DecoderTest;

import test.codec.http2.encode.URLEncodedTest;

import hunt.util.exception;
import kiss.logger;
import hunt.http.codec.http.model.HttpHeader;

void main()
{

	// testHpackDecoder();
	// implementationMissing();

	// **********************
	// bug
	// **********************
	testUnits!URLEncodedTest();


	// **********************
	// test.codec.http2.model
	// **********************

	// testUnits!TestHttpField();
	// testUnits!HttpFieldsTest();
	// testUnits!QuotedCSVTest();
	// testUnits!HttpURIParseTest();
	// testUnits!HttpURITest();
	// testUnits!CookieTest(); 
	

	// **********************
	// test.codec.http2.hpack
	// **********************

	// testUnits!HpackContextTest(); 
	// testUnits!HpackEncoderTest(); 
	// testUnits!HpackDecoderTest(); 
	// testUnits!TestHuffman(); 
	// testUnits!HpackTest(); 

	// **********************
	// test.codec.http2.decode.*
	// **********************
	
	// testUnits!HttpParserTest(); 
	// testUnits!HTTP2DecoderTest();

	// **********************
	// test.codec.http2.encode.*
	// **********************

	// testUnits!TestPredefinedHTTP1Response();

	// **********************
	// test.codec.http2.frame.*
	// **********************
	// testUnits!SettingsGenerateParseTest();

}

void testHpackDecoder()
{
import hunt.http.codec.http.hpack.HpackDecoder;
import hunt.http.codec.http.model;
import hunt.util.TypeUtils;

import hunt.util.Assert;
import hunt.util.UnitTest;

import hunt.container.ByteBuffer;
import hunt.container.Iterator;
import hunt.http.codec.http.model.DateGenerator;
import std.datetime;
	
        // Response encoded by nghttpx
        string encoded = "886196C361Be940b6a65B6850400B8A00571972e080a62D1Bf5f87497cA589D34d1f9a0f0d0234327690Aa69D29aFcA954D3A5358980Ae112e0f7c880aE152A9A74a6bF3";
		encoded = "885f87497cA589D34d1f"; // ok 
        ByteBuffer buffer = ByteBuffer.wrap(TypeUtils.fromHexString(encoded));

		tracef("%(%02X %)", buffer.array());

        HpackDecoder decoder = new HpackDecoder(4096, 8192);
        MetaData.Response response = cast(MetaData.Response) decoder.decode(buffer);
		tracef("status: %d", response.getStatus());
		foreach(HttpField h; response)
		{
			tracef("%s", h.toString());
		}

		tracef(DateGenerator.formatDate(Clock.currTime));

		trace(Clock.currTime.toSimpleString());
}
