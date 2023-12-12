import { ws, encode, decode, connected, debounce, shuffle } from "./main.js";

let imagesList = [];
let imageIdx = 0;
let showImageCount = 4;
let clickRated;

let imagesElem = document.querySelector("#images");

const imageEles = [...Array(showImageCount).keys()].map(() => {
  const div = document.createElement("div");
  div.classList.add("image");
  const img = document.createElement("img");
  div.appendChild(img);

  imagesElem.appendChild(div);
  return img;
});

const scoreValueEle = document.querySelector("#score-value");

imageEles.forEach((imageEle) => {
  imageEle.addEventListener("click", (e) => {
    pickPreference(
      e.target.src,
      others(imagesList, imageIdx, e.target.dataset.id),
    );
    increment();
  });
});

function others(list, id, item) {
  const others = [];
  for (let i = id; i < id + showImageCount; i++) {
    if (i != item) {
      others.push(list[i]);
    }
  }

  return others;
}

function pickPreference(image, others) {
  // picked
  console.log("picked", image);
  console.log("others", others);
}

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += showImageCount;

    if (imageIdx >= imagesList.length - 1) {
      // imagesList = [];
    }
    // getScores(imagesList, imageIdx);
    // clearPrediction();
    // getAestheticScores(imagesList, imageIdx).then((score) => {
    //   const predictedEle = document.querySelector("#predicted");
    //   predictedEle.classList.remove("predicting");
    //   predictedEle.classList.add("predicted");
    //   predictedEle.textContent = score.toPrecision(2);
    // });
    resolve();
  }).then(imageLoad);
}

// function clearPrediction() {
//   const predictedEle = document.querySelector("#predicted");
//   predictedEle.textContent = "-";
//   predictedEle.classList.remove("predicted");
//   predictedEle.classList.add("predicting");
// }
//
// async function decrement() {
//   return new Promise((resolve, _reject) => {
//     setTimeout(() => {
//       imageIdx -= 1;
//       if (imageIdx == -1) {
//         imageIdx = imagesList.length - 1;
//       }
//       getScore(imagesList[imageIdx]);
//       clearPrediction();
//       getAestheticScore(imagesList[imageIdx]).then((score) => {
//         const predictedEle = document.querySelector("#predicted");
//         predictedEle.classList.remove("predicting");
//         predictedEle.classList.add("predicted");
//         predictedEle.textContent = score.toPrecision(2);
//       });
//       resolve();
//     }, 500);
//   }).then(imageLoad);
// }

const loadingAnimation = () => {
  if (imageLoadTimeout) {
    clearTimeout(imageLoadTimeout);
  }
  imageEles.forEach((imageEle) => {
    imageEle.style.animation = "";
    imageEle.style.animation = null;
    imageEle.classList.add("loading");
    imageLoadTimeout = setTimeout(() => {
      imageEle.classList.remove("loading");
    }, 1000);
  });
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
  return new Promise((resolve) => {
    imageEles.forEach((imageEle, i) => {
      imageEle.src = imagesList[imageIdx + i];
      imageEle.dataset.id = imageIdx + i;
      imageEle.dataset.file = imagesList[imageIdx + i];
    });
    resolve();
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
