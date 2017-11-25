/**
 * animation.js
 */


function addAnimations(element) {
	var highlightAnim = element.animation({
		style : { 'overlay-color' : '#f00', 'overlay-padding' : 10, 'overlay-opacity' : 0.3},
		duration : 500
	});
	var unhighlightAnim = element.animation({
		style : { 'overlay-color' : '#f00', 'overlay-padding' : 0, 'overlay-opacity' : 0},
		duration : 500
	});
	var scratch = element.scratch('_anims', {
		'highlightAnim': highlightAnim, 'unhighlightAnim': unhighlightAnim
	})
}

function highlightElements(eles) {
	eles.forEach(function(e) {
		e.scratch('_anims')['unhighlightAnim'].stop();
		e.scratch('_anims')['highlightAnim'].play();
	});
}
function unhighlightElements(eles) {
	eles.forEach(function(e) {
		e.scratch('_anims')['highlightAnim'].stop();
		e.scratch('_anims')['unhighlightAnim'].play();
	});
}

function zoomToElements(eles) {
	cy.animate({fit: {eles: eles, padding: 20}, duration: 500});
}

function centerOnElements(eles) {
	cy.animate({center: {eles: eles}, duration: 500});
}
