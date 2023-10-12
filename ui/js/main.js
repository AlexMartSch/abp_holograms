const DisplayRoot = document.getElementById("displayRoot");


const canvas = document.getElementById("videocall-canvas");

setTimeout(() => {
    
    if(canvas) {
       MainRender().renderToTarget(canvas);
    }
}, 1500);


window.addEventListener("message", function(ev) {
	const data = ev.data;

	//if (data.display != undefined) DisplayRoot.classList.toggle("hidden", !data.display);
});




// Due to loading order, we need to let the resource side know when *we* are ready.
// Just having the browser "loaded" isn't enough.


function MarkDUIAsReady(duiName){
    fetch(`https://${document.location.host}/duiIsReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({duiName})
    })
}