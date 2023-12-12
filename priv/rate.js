import { ws, encode, decode, connected, debounce, shuffle } from "./main.js";

let imagesList = [];
let imageIdx = 0;
let clickRated;

const imageEle = document.querySelector("#image");
const scoreContainerEle = document.querySelector("#score-container");
const scoreValueEle = document.querySelector("#score-value");

async function placeScore(image, score) {
  if (!connected()) {
    return;
  }

  if (!image) {
    console.error("image wtf");
  }

  ws().send(encode({ messageType: "rate", image, rating: score }));
  return setScoreValue(score);
}

async function getScore(image) {
  if (!connected()) {
    return;
  }
  ws().send(encode({ messageType: "get_rating", image }));

  const listener = async (event) => {
    const { messageType, rating } = await decode(event.data);
    ws().removeEventListener("message", listener);
  };

  ws().addEventListener("message", listener);

  // Make sure we remove the listener if anything fails
  setTimeout(() => {
    ws().removeEventListener("message", listener);
  }, 5000);
}

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += 1;

    if (imageIdx >= imagesList.length - 1) {
      imagesList = 0;
    }
    getScore(imagesList[imageIdx]);
    clearPrediction();
    getAestheticScore(imagesList[imageIdx]).then((score) => {
      const predictedEle = document.querySelector("#predicted");
      predictedEle.classList.remove("predicting");
      predictedEle.classList.add("predicted");
      predictedEle.textContent = score.toPrecision(2);
    });
    resolve();
  }).then(imageLoad);
}

function clearPrediction() {
  const predictedEle = document.querySelector("#predicted");
  predictedEle.textContent = "-";
  predictedEle.classList.remove("predicted");
  predictedEle.classList.add("predicting");
}

async function decrement() {
  return new Promise((resolve, _reject) => {
    setTimeout(() => {
      imageIdx -= 1;
      if (imageIdx == -1) {
        imageIdx = imagesList.length - 1;
      }
      getScore(imagesList[imageIdx]);
      clearPrediction();
      getAestheticScore(imagesList[imageIdx]).then((score) => {
        const predictedEle = document.querySelector("#predicted");
        predictedEle.classList.remove("predicting");
        predictedEle.classList.add("predicted");
        predictedEle.textContent = score.toPrecision(2);
      });
      resolve();
    }, 500);
  }).then(imageLoad);
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

// observer = new MutationObserver((changes) => {
//   changes.forEach((e) => {
//     if (e.attributeName === "src") {
//       loadingAnimation();
//     }
//   });
// });
// observer.observe(imageEle, { attributes: true });

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

async function getAestheticScore(image) {
  return fetch(
    `http://localhost:3031/aesthetic_score?image_file=${encodeURI(
      "/home/rockerboo/code/image_scorer/" + image,
    )}`,
  )
    .then((resp) => {
      if (!resp.ok) {
        throw new Error("Could not load images.json");
      }

      return resp.json();
    })
    .then(({ aesthetic_score }) => aesthetic_score);
}

const skipEle = document.querySelector("#skip");
const backEle = document.querySelector("#back");
const skipFun = () => {
  setScoreValue("skipped").then(increment);
};
const backFun = () => {
  decrement();
};
skipEle.addEventListener("click", skipFun);
backEle.addEventListener("click", backFun);

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

// const rating = document.querySelector("#rate");
// rating.addEventListener("submit", (e) => {
//   e.preventDefault();
//
//   // Limit double, and rapid scoring
//   if (e.key in pressScoreList) {
//     if (clickRated) {
//       return;
//     }
//   }
//   // console.log('submit rating', e.submitter.value);
//   placeScore(imagesList[imageIdx], parseInt(e.submitter.value)).then(increment);
// });

let scoreValueTimeout = undefined;

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
