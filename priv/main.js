let imagesList = [];
let imageIdx = 0;
let clickRated;

const imageEle = document.querySelector("#image");
const scoreContainerEle = document.querySelector("#score-container");
const scoreValueEle = document.querySelector("#score-value");

function debounce(callback, delay) {
  let timeout;
  return function () {
    clearTimeout(timeout);
    timeout = setTimeout(callback, delay);
  };
}

function shuffle(array) {
  let currentIndex = array.length,
    randomIndex;

  // While there remain elements to shuffle.
  while (currentIndex > 0) {
    // Pick a remaining element.
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    // And swap it with the current element.
    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex],
      array[currentIndex],
    ];
  }

  return array;
}

const loadingAnimation = () => {
  if (imageLoadTimeout) {
    clearTimeout(imageLoadTimeout);
  }
  imageEle.style.animation = "";
  imageEle.style.animation = null;
  imageEle.classList.add("loading");
  imageLoadTimeout = setTimeout(() => {
    imageEle.classList.remove("loading");
  }, 1000);
};

observer = new MutationObserver((changes) => {
  changes.forEach((e) => {
    if (e.attributeName === "src") {
      loadingAnimation();
    }
  });
});
observer.observe(imageEle, { attributes: true });

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += 1;
    resolve();
  }).then(imageLoad);
}

async function decrement() {
  return new Promise((resolve, _reject) => {
    setTimeout(() => {
      imageIdx -= 1;
      // if (imagesList[imageIdx]) {
      // }
      resolve();
    }, 500);
  }).then(imageLoad);
}

let imageLoadTimeout;

async function imageLoad() {
  return new Promise(() => {
    imageEle.src = imagesList[imageIdx];
  });
}

// manage how fast we can click to score to limit double clicks and rapid clicking
function clickRate() {
  setTimeout(() => {
    clickRated = false;
  }, 1000);
}

function encode(message) {
  return new Blob([JSON.stringify(message, null, 2)], {
    type: "application/json",
  });
}

async function placeScore(image, score) {
	socket.send(encode({ messageType: "rating", image, rating: score }));
  return setScoreValue(score);
}

let scoreValueTimeout;

async function setScoreValue(score) {
  return new Promise((resolve, _reject) => {
    if (scoreValueTimeout) {
      clearTimeout(scoreValueTimeout);
    }
    scoreValueEle.textContent = score;
    scoreValueEle.style.animation = "";
    scoreValueEle.style.animation = null;
    scoreValueEle.classList.add("scored");
    scoreValueTimeout = setTimeout(() => {
      scoreValueEle.classList.remove("scored");
      resolve(score);
    }, 240);
  });
}

const socket = new WebSocket("ws://localhost:3030/ws");

socket.addEventListener("open", () => {
  socket.send("Hello Server!");
});

socket.addEventListener("message", (event) => {
  console.log("Message from server ", event.data);
});

fetch("/static/images.json")
  .then((resp) => {
    if (!resp.ok) {
      throw new Error("Could not load images.json");
    }

    return resp.json();
  })
  .then((images) => {
    console.log(images);
    imageIdx = 0;
    imagesList = shuffle(images);
    increment();
  })
  .catch((err) => {
    console.error(err);
  });

const rating = document.querySelector("#rating");
rating.addEventListener("submit", (e) => {
  e.preventDefault();

  // Limit double, and rapid scoring
  if (e.key in pressScoreList) {
    if (clickRated) {
      return;
    }
  }
  console.log(e.submitter.value);
  placeScore(imagesList[imageIdx], parseInt(e.submitter.value)).then(increment);
});

const skipEle = document.querySelector("#skip");
const skipFun = () => {
  setScoreValue("skipped").then(increment);
};
skipEle.addEventListener("click", skipFun);

const pressScoreList = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
window.addEventListener(
  "keypress",
  debounce((e) => {
    // Limit double, and rapid scoring
    if (e.key in pressScoreList) {
      if (clickRated) {
        return;
      }
    }

    if (e.key == "1") {
      placeScore(imagesList[imageIdx], 1).then(increment);
    } else if (e.key == "2") {
      placeScore(imagesList[imageIdx], 2).then(increment);
    } else if (e.key == "3") {
      placeScore(imagesList[imageIdx], 3).then(increment);
    } else if (e.key == "4") {
      placeScore(imagesList[imageIdx], 4).then(increment);
    } else if (e.key == "5") {
      placeScore(imagesList[imageIdx], 5).then(increment);
    } else if (e.key == "6") {
      placeScore(imagesList[imageIdx], 6).then(increment);
    } else if (e.key == "7") {
      placeScore(imagesList[imageIdx], 7).then(increment);
    } else if (e.key == "8") {
      placeScore(imagesList[imageIdx], 8).then(increment);
    } else if (e.key == "9") {
      placeScore(imagesList[imageIdx], 9).then(increment);
    } else if (e.key == "0") {
      placeScore(imagesList[imageIdx], 10).then(increment);
    } else if (e.key == "-") {
      decrement();
    } else if (e.key == "u") {
      skipFun();
    } else if (e.key == "d") {
      decrement();
    } else if (e.key == "j") {
      skipFun();
    } else if (e.key == "f") {
      decrement();
    } else if (e.key == "b") {
      decrement();
    } else if (e.key == "s") {
      skipFun();
    } else if (e.key == " ") {
      skipFun();
    }
    console.log(e.key);
  }, 300),
);