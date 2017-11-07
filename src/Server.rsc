module Server
import List;
import String;
import IO;
import Triples;
import util::Webserver;
import ParseTree;

public Response (Request) graphServer(Graph gs...) {
	map[str,Graph] graphs = ();
	mainGraph = newGraph("");
	
	for(g <- gs) {
		id = getOne(g, this(), IDENTITY);
		mainGraph += <this(), HAS, id>;
		name = toString(id);
		println(name);
		g = qualifyGraph(g);
		graphs[name] = g;
	}
	mainGraph = qualifyGraph(mainGraph);
	
	return Response (Request req) {
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
			fail;
		}
		case get(/^\/js\/<file:[a-zA-Z0-9][a-zA-Z0-9\.]*>$/):
			return response(|project://syntax-navigator/libs/<file>|); 
		case get(/^\/<file:([a-zA-Z0-9][a-zA-Z0-9\.]*\/)*[a-zA-Z0-9][a-zA-Z0-9\.]*>$/):
			return response(|project://syntax-navigator/html/<file>|); 
		case get(p): return response(notFound(), "not found: <p>"); 
		}
		
		return response(internalError(), "not implemented");
	};
}

public Response serveGraph(Request req, str path, str subPath, Graph g) {
	println("request: <req>");
	if(req has parameters) {
		if("filter" in req.parameters) {
			fExpr = parse(#TripleQuery, req.parameters["filter"]);
			f = makeFilter(fExpr);
			g = {x | x <- g, f(x)};
		}
	}
	if(subPath == "") {
		return response(ok(), "application/json", (), toJson(g));
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
	return bool(tuple[Id,Id,Id] t) {
		for(f <- fs)
			if(f(t)) return true;
		return false;
	};
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
	println(id);
	return bool(Id x) { return matchId(x,id); };
}

public bool matchId(_, ident("*")) = true;
public bool matchId(ident(x,_), ident(y, "*")) = matchId(x, y);
public bool matchId(ident(x1,x2), ident(y1, y2)) = x2 == y2 && matchId(x1, y1);
public default bool matchId(Id x, Id y) = x == y;
