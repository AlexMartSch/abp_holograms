const itemList = document.getElementById("itemList");
let serverItems = {}

AddEventListener("3dinventory", "refreshItems", (id, items) => {
    if (serverItems[id] === items) return

    serverItems[id] = items
    refreshItemList(id)
})

function refreshItemList(id){
    if (itemList){
        itemList.innerHTML = "";

        const maxItems = 5
        let i = 0

        const items = serverItems[id];
        if(!items) return

        items.forEach((item) => {

            if (!item) return
            if (i >= maxItems) return

            let itemElement = document.createElement("div")
            itemElement.classList.add("item")
            itemElement.innerHTML = `
                <div class="itemImage">
                    <img src="nui://ox_inventory/web/images/${item.name}.png" />
                </div>
                <div class="itemInfo">
                    <div class="itemName">${item.label} <br> (${item.count})</div>
                </div>
            `
            itemList.appendChild(itemElement)

            i += 1
        })
    }
}

MarkDUIAsReady("3dinventory")