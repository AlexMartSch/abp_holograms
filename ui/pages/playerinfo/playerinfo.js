const num = document.getElementById("numberToChange");
var n = 0



if (num){
    setInterval(() => {
        n += 1
        num.innerHTML = "N:" + n;
    }, 1000);
}


MarkDUIAsReady("playerinfo")