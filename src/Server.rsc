module Server
import List;
import String;
import IO;
import Triples;
import util::Webserver;
import ParseTree;
import Grammars;
import ParseTrees;

public loc serverLog = |tmp:///server.log|;

public str reqToStr(get(str p)) = "GET <p>";
public str reqToStr(put(p,_)) = "PUT <p>";
public str reqToStr(post(p,_)) = "POST <p>";
public str reqToStr(delete(str p)) = "DELETE <p>";
public str reqToStr(head(p)) = "HEAD <p>";
public default str reqToStr(Request r) = "<r>";

public str dumpReq(Request req) {
	str s = reqToStr(req);
	if((req.parameters["NanoHttpd.QUERY_STRING"]?"") != "") {
		s = "<s>?<req.parameters["NanoHttpd.QUERY_STRING"]>";
	}
	s = "<s>\n";
	s = "<s>  Parameters:\n";
	for(k <- req.parameters, k != "NanoHttpd.QUERY_STRING") {
		s = "<s>    <k>=<req.parameters[k]>\n";
	}
	s = "<s>  Headers:\n";
	for(k <- req.headers) {
		s = "<s>    <k>: <req.headers[k]>\n";
	}
	s = "<s>  Uploads:\n";
	for(k <- req.uploads) {
		s = "<s>    DATA <k> <size(req.uploads[k])> chars\n";
	}
	return s;
}

public str dumpRes(Response res) {
	str s = "";
	if(fileResponse(_,_,_) := res)
		s = "x00 ??? <res.mimeType> <res.file>\n";
	else if(jsonResponse(_,_,_) := res)
		s = "x00 <res.status> <res.mimeType> (Rascal value)\n";
	else
		s = "x00 <res.status> <res.mimeType> <size(res.content)> chars\n";
	
	s = "<s>  Headers:\n";
	for(k <- res.header) {
		s = "<s>    <k>: <res.header[k]>\n";
	}
	s = "<s>  Content:\n";
	content = res.content[..640] ? "";
	for(c <- split("/", content)) {
		s = "<s>    |<c>|\n";
	}
	return s;
}

Request currentRequest;
bool hasLogged = false;

public void logStart(Request req) {
	currentRequest = req;
	hasLogged = false;
	appendToFileEnc(serverLog, "UTF-8", "<dumpReq(req)>\n");
}
public void log(str msg) {
	if(!hasLogged) {
		appendToFileEnc(serverLog, "UTF-8", "100 / <reqToStr(currentRequest)>\n");
		hasLogged = true;
	}
	appendToFileEnc(serverLog, "UTF-8", "100 | <msg>\n");
}
public void logWrite(str msg) {
	appendToFileEnc(serverLog, "UTF-8", "<msg>\n");
}
public void logEnd(Request req, Response res) {
	s = hasLogged ? "\\" : " ";
	if(fileResponse(_,_,_) := res)
		appendToFileEnc(serverLog, "UTF-8", "ok() <s> <reqToStr(currentRequest)> =\> <res.mimeType> <res.file>\n");
	else if(jsonResponse(_,_,_) := res)
		appendToFileEnc(serverLog, "UTF-8", "<res.status> <s> <reqToStr(currentRequest)> =\> <res.mimeType> Rascal value\n");
	else
		appendToFileEnc(serverLog, "UTF-8", "<res.status> <s> <reqToStr(currentRequest)> =\> <res.mimeType> <size(res.content)> chars\n");
	appendToFileEnc(serverLog, "UTF-8", "<dumpRes(res)>\n");
	currentRequest = get("/");

}

public Graph loadedGrammar;
public ProdTable loadedProdTable;

@doc{
  Serve on http://localhost:8088/.
}
public void serveIt() {
	<loadedGrammar,loadedProdTable> = loadGrammar(|project://syntax-navigator/src/ParseTrees.rsc|);
	pt = ptToGraph((Expr)`a+b+c`, "TestExpr", loadedProdTable);
	shutdown(|http://localhost:8088/|)?;
	serve(|http://localhost:8088/|, graphServer(metaGrammar, metaParseTree, loadedGrammar, pt));
}

public Response (Request) graphServer(Graph gs...) {
	map[str,Graph] graphs = ();
	mainGraph = newGraph("");
	logWrite("Starting server");
	
	for(g <- gs) {
		id = getOne(g, this(), IDENTITY);
		mainGraph += <this(), HAS, id>;
		name = toString(id);
		logWrite("  ... serving graph <name>");
		g = qualifyGraph(g);
		graphs[name] = g;
	}
	mainGraph = qualifyGraph(mainGraph);
	Response serve(Request req) {
		switch(req) {
		case get("/"): return response(ok(), "application/json", (), toJson(mainGraph));
		case get(/^\/api\/v1<p:\/.*>$/): {
			subPath = "";
			path = p;
			while(/^<prefix:.*><suffix:\/[^\/]*>$/ := p) {
				if(p in graphs)
					return serveGraph(req, path, subPath, graphs[p]);
				p = prefix;
				subPath = "<suffix><subPath>";
			}
			return response(notFound(), "Graph not found: <path>");
		}
		case get(path:/^\/js\/<file:[a-zA-Z0-9_][a-zA-Z0-9\._\-]*>$/): {
			for(dir <- ["libs", "js"]) {
				f = |project://syntax-navigator/<dir>/<file>|;
				if(exists(f))
					return response(f);
			}
			return response(notFound(), "File not found: <path>");
		} 
		case get(/^\/<file:([a-zA-Z0-9][a-zA-Z0-9\.]*\/)*[a-zA-Z0-9][a-zA-Z0-9\.]*>$/):
			return response(|project://syntax-navigator/html/<file>|); 
		case get(p): return response(notFound(), "not found: <p>"); 
		}
		
		return response(internalError(), "not implemented");
	};
	
	return Response(Request req) {
		Response res;
		logStart(req);
		try {
			res = serve(req);
		}
		catch ex: res = response(internalError(), "Server threw exception: <ex>");
		
		logEnd(req, res);
		return res;
	};
}

public Response serveGraph(Request req, str path, str subPath, Graph g) {
	if("filter" in req.parameters) {
		fExpr = parse(#TripleQuery, req.parameters["filter"]);
		f = makeFilter(fExpr);
		g = {x | x <- g, f(x)};
	}
	//log("<g[ident(ident(root(), "TestExpr"), "0.4.0")]>");
	//log("<g[ident("0.4.0")]>");
	
	//for(uri(u) <- g<0>+g<1>+g<2>) {
	//	if(u.begin? || u.end? || u.offset? || u.length?) {
	//		g += <uri(u), PART_OF, uri(toLocation(u.uri))>;
	//	}
	//}
	
	str format = "text/plain";
	str(Graph) formatter = str(Graph gg) { return "<gg>"; };
	
	switch(req.parameters["format"] ? "json") {
	case "cyto": {format = "application/json"; formatter = str(Graph gg) { return toCyto(gg, unlink={/*NAME,CONFORMS_TO*/}); };}
	case "json": {format = "application/json"; formatter = str(Graph gg) { return toJson(gg); };}
	default: throw "Unknown data format: <req.parameters["format"]>";
	}
	
	if(subPath == "") {
		return response(ok(), "application/json", (), formatter(g));
	}
	else {
		id = fromString(path);
		return response(ok(), "application/json", (), toJson(g[id]));
	}
}

public bool(tuple[Id,Id,Id]) makeFilter((TripleQuery)`and(<{TripleQuery ","}* qs>)`) {
	fs = [makeFilter(q) | q <- qs];
	return bool(tuple[Id,Id,Id] t) {
		for(f <- fs)
			if(!f(t)) return false;
		return true;
	};
}
public bool(tuple[Id,Id,Id]) makeFilter((TripleQuery)`or(<{TripleQuery ","}* qs>)`) {
	fs = [makeFilter(q) | q <- qs];
	if(fs == []) {
		return bool(tuple[Id,Id,Id] t) { return true; };
	}
	else {
		return bool(tuple[Id,Id,Id] t) {
			for(f <- fs)
				if(f(t)) return true;
			return false;
		};
	}
}

public bool(tuple[Id,Id,Id]) makeFilter((TripleQuery)`not(<TripleQuery q>)`) {
	f = makeFilter(q);
	return bool(tuple[Id,Id,Id] t) { return !f(t); };
}

public bool(tuple[Id,Id,Id]) makeFilter((TripleQuery)`label(<TripleId id>)`) {
	bool(Id) f = makeFilter(id);
	return bool(<Id _, Id l, Id _>) { return f(l); };
}
public bool(Id) makeFilter((TripleId)`<TripleIdNameChar+ n>:*`) {
	name = unparse(n);
	return bool(Id x) { return cardinal(name,_) := x; };
}
public bool(Id) makeFilter((TripleId)`<TripleIdNameChar+ n>#*`) {
	name = unparse(n);
	return bool(Id x) { return ordinal(name,_) := x; };
}

public bool(Id) makeFilter(TripleId idTree) {
	idStr = unparse(idTree);
	Id id = fromString(idStr);
	return bool(Id x) { return matchId(x,id); };
}

public bool matchId(Id _, ident("*")) = true;
public bool matchId(ident(x,_), ident(y, "*")) = matchId(x, y);
public bool matchId(ident(x1,x2), ident(y1, y2)) = x2 == y2 && matchId(x1, y1);
public default bool matchId(Id x, Id y) = x == y;
