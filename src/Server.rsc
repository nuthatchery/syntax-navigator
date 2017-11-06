module Server
import List;
import String;
import IO;
import Triples;
import util::Webserver;

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
	println("subPath: <subPath>");
	if(subPath == "") {
		return response(ok(), "application/json", (), toJson(g));
	}
	else {
		id = fromString(path);
		return response(ok(), "application/json", (), toJson(g[id]));
	}
}
