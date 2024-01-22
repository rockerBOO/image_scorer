import {
  getFilename,
  trySyncMessage,
  hashFile,
  shuffle,
  attachLoadAnimation,
} from "/static/main.js";

import { showModal } from "/static/image_modal.js";

let imagesList = [];
let imageIdx = 0;
let clickRated;
let currentScore;

const imageEle = document.querySelector("#image");
const scoreContainerEle = document.querySelector("#score-container");
const scoreValueEle = document.querySelector("#score-value");

async function placeScore(imageFile, score) {
  return trySyncMessage({
    messageType: "place_score",
    image_hash: await hashFile(imageFile),
    score,
  });
}

async function getScore(image) {
  return trySyncMessage({
    messageType: "get_image_score",
    image_hash: await hashFile(image),
  }).then(({ score }) => {
    console.log("curent score", score, currentScore);
    currentScore = score ?? 0.0;
    console.log("current score AFTER", currentScore);
    return score ?? 0.0;
  });
}

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += 1;

    if (imageIdx >= imagesList.length - 1) {
      imagesList = 0;
    }

    clearPrediction();
    clearRating();
    getScore(imagesList[imageIdx]).then(updateRating);
    getAestheticScore(imagesList[imageIdx]).then((score) => {
      const predictedEle = document.querySelector("#predicted");
      predictedEle.classList.remove("predicting");
      predictedEle.classList.add("predicted");
      predictedEle.textContent = score.toPrecision(2);
    });
    resolve();
  }).then(imageLoad);
}

async function onLoad() {
  clearPrediction();
  clearRating();
  getScore(imagesList[imageIdx]).then(updateRating);
  getAestheticScore(imagesList[imageIdx]).then((score) => {
    const predictedEle = document.querySelector("#predicted");
    predictedEle.classList.remove("predicting");
    predictedEle.classList.add("predicted");
    predictedEle.textContent = score.toPrecision(2);
  });
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
      clearPrediction();
      clearRating();
      getScore(imagesList[imageIdx]).then(updateRating);
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

async function imageLoad() {
  return new Promise(() => {
    imageEle.src = imagesList[imageIdx];
    attachModal(imageEle);
    attachLoadAnimation(imageEle);
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
  const imageBlob = await fetch(image).then((resp) => {
    if (!resp.ok) {
      throw new Error("Could not load images.json");
    }

    return resp.blob();
  });

  const file = new File([imageBlob], getFilename(image), {
    type: "image/png",
  });

  const formData = new FormData();
  formData.append("file", file);

  return fetch(`http://localhost:3031/aesthetic_score`, {
    method: "POST",
    body: formData,
  })
    .then((resp) => {
      if (!resp.ok) {
        throw new Error("Could not load aesthetic sacore");
      }

      return resp.json();
    })
    .then(({ aesthetic_score }) => aesthetic_score);
}

const skipEle = document.querySelector("#skip");
const backEle = document.querySelector("#back");
const skipFun = () => {
  increment();
};
const backFun = () => {
  decrement();
};
skipEle.addEventListener("click", skipFun);
backEle.addEventListener("click", backFun);

function handleUpdateRating({ score, error }) {
  if (error) {
    console.error(error);
    return;
  }

  currentScore = score ?? 0.0;
  updateRating(score);
}

function attachControls() {
  const minusMinus = document.querySelector("#minus-minus");
  const minus = document.querySelector("#minus");
  const plus = document.querySelector("#plus");
  const plusPlus = document.querySelector("#plus-plus");

  minusMinus.addEventListener("click", (e) => {
    // decrement by 1
    e.preventDefault();
    placeScore(imagesList[imageIdx], currentScore - 1.0).then(handleUpdateRating);
  });
  minus.addEventListener("click", (e) => {
    // decrement by 0.1
    e.preventDefault();
    placeScore(imagesList[imageIdx], currentScore - 0.1).then(handleUpdateRating);
  });
  plus.addEventListener("click", async (e) => {
    // increment by 0.1
    e.preventDefault();
    placeScore(imagesList[imageIdx], currentScore + 0.1).then(handleUpdateRating);
  });
  plusPlus.addEventListener("click", (e) => {
    // increment by 1.0
    e.preventDefault();
    placeScore(imagesList[imageIdx], currentScore + 1.0).then(handleUpdateRating);
  });
}

attachControls();

async function clearRating() {
  const rateEle = document.querySelector("#rating");

  rateEle.textContent = "-";
  rateEle.classList.remove("predicted");
  rateEle.classList.add("predicting");
}

function updateRating(score) {
  const rating = document.querySelector("#rating");

  if (!rating) {
    return;
  }

  if (!score) {
    return;
  }

  rating.textContent = score.toPrecision(2);
  rating.classList.remove("predicting");
  rating.classList.add("predicted");
}

function attachModal(element) {
  element.addEventListener(
    "click",
    showModal(() => {
      if (!element) {
        console.log("image element does not exist for modal");
        return;
      }
      console.log(element);
      const modalContentEle = document.createElement("div");
      const deep = true;
      modalContentEle.appendChild(element.cloneNode(deep));

      return modalContentEle;
    }),
  );
}
