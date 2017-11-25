package library;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import io.usethesource.vallang.IInteger;
import io.usethesource.vallang.IList;
import io.usethesource.vallang.IListWriter;
import io.usethesource.vallang.IString;
import io.usethesource.vallang.IValue;
import io.usethesource.vallang.IValueFactory;
import sun.awt.CharsetString;

public class Triples {
	private IValueFactory values;

	public Triples() {

	}

	public Triples(IValueFactory values) {
		this.values = values;
	}

	public IList chars(IString s, IString charset) {
		Charset cs = Charset.forName(charset.getValue());

		ByteBuffer bytes = cs.encode(s.getValue());
		IListWriter lw = values.listWriter();
		while (bytes.hasRemaining()) {
			int b = bytes.get();
			if (b < 0)
				b += 256;
			lw.append(values.integer(b));
		}

		return lw.done();
	}

	public IString stringChars(IList list, IString charset) {
		Charset cs = Charset.forName(charset.getValue());

		byte[] bytes = new byte[list.length()];
		for (int i = 0; i < list.length(); i++) {
			if (list.get(i) instanceof IInteger) {
				bytes[i] = (byte) ((IInteger) list.get(i)).intValue();
			}
		}

		CharBuffer decoded = cs.decode(ByteBuffer.wrap(bytes));
		IString r = values.string("");
		while (decoded.hasRemaining()) {
			char c = decoded.get();
			if(Character.isSurrogate(c)) {
				char d = decoded.get();
				System.out.println(Character.toCodePoint(c, d));
				r = r.concat(values.string(Character.toCodePoint(c, d)));
			}
			else {
				r = r.concat(values.string(c));
			}
		}
		return r;
	}

	/**
	 * Percent-decodes a string.
	 * 
	 * Percent encoding (aka URL-encoding) replaces all reserved characters as well
	 * as all non-unreserved characters with the UTF-8 representation of the character as
	 * a sequence of %xx bytes.
	 * 
	 * Percent encoding is specified in <a href="https://tools.ietf.org/html/rfc3986#page-12">RFC 3986</a>:
	 * 
	 * @param s A %-encoded string
	 * @return A decoded version of the string
	 * @throws IllegalArgumentException if the string contains non-encoded unicode characters past code point 255.
	 * @see #percentEncodingProperty(IString)
	 */
	public IString percentDecode(IString s) {
		ByteBuffer bytes = ByteBuffer.allocate(s.length());
		for(int i = 0; i < s.length(); i++) {
			int c = s.charAt(i);
			if(c == '%') {
				System.out.println(Integer.valueOf(s.substring(i+1, i+3).getValue(), 16).byteValue());
				bytes.put(Integer.valueOf(s.substring(i+1, i+3).getValue(), 16).byteValue());
				i += 2;
			}
			else if (c < 256) {
				bytes.put((byte)c);
			}
			else {
				throw new IllegalArgumentException("Unencoded character in string: " + c);
			}
		}
		bytes.limit(bytes.position());
		bytes.rewind();
		int[] array = StandardCharsets.UTF_8.decode(bytes).codePoints().toArray();
		return values.string(array);
	}

	public  boolean percentEncodingProperty(IString s) {
		return percentDecode(percentEncode(s)).equals(s);
	}

	/**
	 * Percent-encodes a string.
	 * 
	 * Percent encoding (aka URL-encoding) replaces all reserved characters as well
	 * as all non-unreserved characters with the UTF-8 representation of the character as
	 * a sequence of %xx bytes.
	 * 
	 * Percent encoding is specified in <a href="https://tools.ietf.org/html/rfc3986#page-12">RFC 3986</a>:
	 * 
	 * This method will also handle multi-word characters correctly (i.e., Unicode characters beyond 65535).
	 * Example:
	 * 
	 * <li>percentEncode("føø") = "f%C3%B8%C3%B8"
	 * <li>percentEncode("\ud801\udc00") = "%F0%90%90%80"
	 * 
	 * @param s A string
	 * @return A %-encoded version of the string
	 * @see #percentEncodingProperty(String)
	 */
	public IString percentEncode(IString s) {
		byte[] bytes = s.getValue().getBytes(StandardCharsets.UTF_8);
		StringBuilder result = new StringBuilder(s.length());
		for (byte b : bytes) {
			switch (b) {
			case 'A':case 'B':case 'C':case 'D':case 'E':case 'F':case 'G':case 'H':case 'I':case 'J':case 'K':case 'L':case 'M':case 'N':case 'O':case 'P':case 'Q':case 'R':case 'S':case 'T':case 'U':case 'V':case 'W':case 'X':case 'Y':case 'Z':case 'a':case 'b':case 'c':case 'd':case 'e':case 'f':case 'g':case 'h':case 'i':case 'j':case 'k':case 'l':case 'm':case 'n':case 'o':case 'p':case 'q':case 'r':case 's':case 't':case 'u':case 'v':case 'w':case 'x':case 'y':case 'z':case '0':case '1':case '2':case '3':case '4':case '5':case '6':case '7':case '8':case '9':
			case '-':
			case '_':
			case '~':
			case '.':
				result.append((char)b);
				break;
			default:
				result.append("%");
				result.append(String.format("%02X", b));
			}

		}
		return values.string(result.toString());
	}
}
