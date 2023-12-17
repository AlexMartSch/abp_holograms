const selectedRow = 0
const selectedColumn = 0
const items = [{title: 'test'}, {title: 'test 2'}, {title: 'test 3'}, {title: 'test 4'}, {title: 'test 5'}, {title: 'test 6'}]

let selectedIndex = 0

const numColumns = 3;
let numRows = Math.ceil(items.length / numColumns);
let cells = []

let btnTimeout = false

const grid = document.getElementById('grid');

AddEventListener("selectorexample", "makeAction", (id, action) => {
    cells = grid.getElementsByClassName('grid-cell');

    for (let index = 0; index < cells.length; index++) {
        const cell = cells[index];
        cell.classList.remove('selected')
    }

    if(selectedIndex === -1) selectedIndex = 0

    if (action === "up" && ((selectedIndex - numColumns) >= 0)) {
        selectedIndex -= numColumns;
    } else if (action === "down" && selectedIndex + numRows < cells.length) {
        selectedIndex += numColumns;
    
        if(selectedIndex >= cells.length) selectedIndex = cells.length - 1
    } else if (action === "left") {
        selectedIndex--;
        if (selectedIndex < 0) {
            selectedIndex = cells.length - 1;
        }
    } else if (action === "right") {
        selectedIndex++;

        if (selectedIndex >= cells.length) {
            selectedIndex = 0;
        }
    } else if (action === "select") {
        if(btnTimeout) return

        const item = items[selectedIndex]
        if (item) {
            console.log(`You selected ${item.title}`)
            SendData('testSelector', 'onItemSelected', item)
        }
        btnTimeout = true
        setTimeout(() => {
            btnTimeout = false
        }, 300);
    }

    cells[selectedIndex].focus();
    cells[selectedIndex].classList.add('selected');
})

// grid.addEventListener('keydown', (event) => {
//     cells = grid.getElementsByClassName('grid-cell');

//     for (let index = 0; index < cells.length; index++) {
//         const cell = cells[index];
//         cell.classList.remove('selected')
//     }

//     // let selectedIndex = Array.from(cells).findIndex((cell) => cell.classList.contains('selected'));
  
//     // console.log(">> SELECTED INDEX", selectedIndex);

//     if(selectedIndex === -1) selectedIndex = 0

//     if (event.key === 'ArrowRight') {
//       selectedIndex++;

//         if (selectedIndex >= cells.length) {
//             selectedIndex = 0;
//         }

//     } else if (event.key === 'ArrowLeft') {
//         selectedIndex--;
//         if (selectedIndex < 0) {
//             selectedIndex = cells.length - 1;
//         }
//     } else if (event.key === 'ArrowDown' && selectedIndex + numRows < cells.length) {
//         selectedIndex += numColumns;
    
//         if(selectedIndex >= cells.length) selectedIndex = cells.length - 1

//     } else if (event.key === 'ArrowUp' && ((selectedIndex - numColumns) >= 0)) {
//       selectedIndex -= numColumns;
//     } else if (event.key === 'Enter'){
//         console.log("ENTER PRESSED", items[selectedIndex]);
//     }
  
//     console.log("SELECTED INDEX", selectedIndex);
//     cells[selectedIndex].focus();
//     cells[selectedIndex].classList.add('selected');
// });

function refreshSelector(){
    items.forEach((item, index) => {
        const cell = document.createElement('div');
        cell.textContent = item.title;
        cell.classList.add('grid-cell');


        grid.appendChild(cell);

        if(index === 0) 
            setTimeout(() => {
                cell.classList.add('selected');
            }, 200);
    });

    grid.focus()
}

refreshSelector()

MarkDUIAsReady("selectorexample")
