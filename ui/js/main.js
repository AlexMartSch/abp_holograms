const DisplayRoot = document.getElementById("displayRoot");

const events = {}

window.addEventListener("message", function(ev) {
	const eventData = ev.data;
    const id = eventData.id
    const duiName = eventData.duiName
    const eventName = eventData.eventName
    const content = eventData.content
    emitEvent(duiName, eventName, id, content)
});

// function AddEventListener(duiName, eventName, callback){
//     setInterval(() => {
//         if(eventData !== null){
//             console.log(eventData.id, eventData.duiName, duiName, eventData.eventName, eventName, eventData.content);
//             if(eventData.duiName == duiName && eventData.eventName == eventName){
//                 callback(eventData.id, eventData.content)

//                 setTimeout(() => {
//                     eventData = null
//                 }, 50);
//             }
//         }
//     }, 100);
// }

// const events = {};

// Función para suscribirse a eventos
function AddEventListener(duiName, eventName, callback) {
    if (!events[duiName]) {
        events[duiName] = {};
    }

    if (!events[duiName][eventName]) {
        events[duiName][eventName] = [];
    }

    events[duiName][eventName].push(callback);
}

function emitEvent(duiName, eventName, id, data) {
    if (events[duiName] && events[duiName][eventName]) {
        events[duiName][eventName].forEach(callback => {
            callback(id, data);
        });
    }
}

function SendData(duiName, eventName, content) {
    fetch('https://' + document.location.host + '/sendData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            id: duiName,
            eventName,
            content
        })
    })
}

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