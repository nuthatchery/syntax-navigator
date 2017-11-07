module DownloadDeps
import IO;
import String;

loc libraryPath = |project://syntax-navigator/libs|;

map[str,loc] dependencies =
	("cytoscape.js" : |https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.2.5/cytoscape.js|,
	"cytoscape.min.js" : |https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.2.5/cytoscape.min.js|,
	"cola.v3.js" : |http://marvl.infotech.monash.edu/webcola/cola.v3.js|,
	"cola.v3.min.js" : |http://marvl.infotech.monash.edu/webcola/cola.v3.min.js|,
	"cytoscape-cola.js" : |https://raw.githubusercontent.com/cytoscape/cytoscape.js-cola/master/cytoscape-cola.js|,
	"vivagraph.js" : |https://raw.githubusercontent.com/anvaka/VivaGraphJS/master/dist/vivagraph.js|,
	"vivagraph.min.js" : |https://raw.githubusercontent.com/anvaka/VivaGraphJS/master/dist/vivagraph.min.js|
	);
	
public void loadDeps(bool force = false) {
	for(n <- dependencies) {
		path = libraryPath + n;
		if(force || !exists(path)) {
			print("Downloading <n> from <dependencies[n]>...");
			s = readFileEnc(dependencies[n], "UTF-8");
			writeFileEnc(path, "UTF-8", s);
			println("<size(s)> characters, ok");
		}
	}
}

