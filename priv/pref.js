import { syncMessage, hashFile, shuffle, trySyncMessage } from "./main.js";

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

  const prediction = document.createElement("div");
  prediction.classList.add("prediction");
  prediction.textContent = "7.8";

  div.appendChild(prediction);

  imagesElem.appendChild(div);
  return img;
});

const scoreValueEle = document.querySelector("#score-value");

imageEles.forEach((imageEle) => {
  imageEle.addEventListener("click", async (e) => {
    pickPreference(
      await hashFile(e.target.src),
      await Promise.all(others(imagesList, imageIdx, e.target.dataset.id).map(hashFile)),
    );
    increment();
  });
});

function getImages() {
  return imagesList.slice(imageIdx, imageIdx + showImageCount);
}

function others(list, id, item) {
  const others = [];
  for (let i = id; i < id + showImageCount; i++) {
    if (i != item) {
      others.push(list[i]);
    }
  }

  return others;
}

async function pickPreference(image, others) {
  // picked
  console.log("picked", image);
  console.log("others", others);
	return trySyncMessage({ messageType: "pick_preference", image_hash: image, others });
}

async function increment() {
  return new Promise((resolve, _reject) => {
    imageIdx += showImageCount;
    resolve(updateScores());
  }).then(imageLoad);
}

async function updateScores() {
  return Promise.all([
    getScores(imagesList, imageIdx)
      .then(({ scores }) => {
        console.log("scores", scores);
      })
      .catch((e) => {
        console.log("Could not process aesthetic score", e);
      }),
    clearPrediction(),
    getAestheticScores(imagesList, imageIdx)
      .then((scores) => {
        scores.forEach(async (score, i) => {
          const predictionEle = getBlockElement(i).querySelector(".prediction");
          predictionEle.classList.remove("predicting");
          predictionEle.classList.add("predicted");
          predictionEle.textContent = score.toPrecision(2);
        });
      })
      .catch((e) => {
        console.log("Could not process aesthetic score", e);
      }),
  ]);
}

async function clearPrediction() {
  const predictionEles = document.querySelectorAll(".prediction");

  predictionEles.forEach((predictedEle) => {
    predictedEle.textContent = "-";
    predictedEle.classList.remove("predicted");
    predictedEle.classList.add("predicting");
  });
}

function getBlockElement(idx) {
  return Object.entries(document.querySelector("#images").children).find(
    (_, i) => i == idx,
  )[1];
}

async function decrement() {
  return new Promise((resolve, _reject) => {
    setTimeout(() => {
      imageIdx -= showImageCount;
      if (imageIdx == -1) {
        imageIdx = imagesList.length - 1;
      }
      resolve(updateScores());
    }, 500);
  }).then(imageLoad);
}

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
    loadingAnimation();
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

async function getAestheticScores(list, id) {
  return Promise.all(
    [...Array(showImageCount)].map((_, i) => {
      return getAestheticScore(list[id + i]);
    }),
  );
}

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

async function getScores() {
  return syncMessage({
    messageType: "get_images_score",
    image_hashes: await Promise.all(getImages().map(hashFile)),
  });
}
