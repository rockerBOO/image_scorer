import { hashFile, trySyncMessage, getFilename } from "./main.js";

let imagesList = [];

const observer = new MutationObserver((changes) => {
  changes.forEach((e) => {
    if (e.attributeName === "src") {
      loadingAnimation();
    }
  });
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
    document.querySelector("#image-count").textContent =
      `${images.length} images. showing first 100`;

    const imagesElements = images.slice(0, 100).map((image) => {
      const ele = document.createElement("img");
      ele.onload = ele.src = image;
      observer.observe(ele, { attributes: true });

      const block = document.createElement("div");
      block.classList.add("block");

      block.appendChild(ele);

      const prediction = document.createElement("div");
      prediction.classList.add("prediction");
      prediction.textContent = "-";

      block.appendChild(prediction);

      const rating = document.createElement("div");
      rating.classList.add("rating");
      rating.textContent = "-";

      block.appendChild(rating);
      return block;
    });

    const imagesElement = document.querySelector("#images");
    imagesElement.classList.add("images-grid");
    imagesElement.classList.add("small-grid");

    imagesElement.append(...imagesElements);
    return images;
  })
  .then(async (images) => {
    imagesList = images;

    trySyncMessage({
      messageType: "get_images_score",
      image_hashes: await Promise.allSettled(images.map(hashFile)).then(
        (values) =>
          values.filter((v) => v.status == "fulfilled").map((v) => v.value),
      ),
    });

    updateScores();
  });

async function updateScores() {
  clearPrediction();
  clearRating();
  getScores(imagesList)
    .then(({ scores }) => {
      Object.entries(document.querySelector("#images").children).forEach(
        ([_, imageBlock], i) => {
          const rating = imageBlock.querySelector(".rating");

          if (!rating) {
            return;
          }

          if (!scores[i]) {
            return;
          }

          rating.textContent = scores[i].toPrecision(2);
          rating.classList.remove("predicting");
          rating.classList.add("predicted");
        },
      );
    })
    .catch((e) => {
      console.log("Could not process aesthetic score", e);
    });
  Promise.allSettled(imagesList.map((image) => getAestheticScore(image)))
    .then((results) => results.map((result) => result.value))
    .then((scores) => {
      console.log("scores", scores);
      scores.forEach(async (score, i) => {
        const tryElement = tryBlockElement(i);

        if (!tryElement) {
          return;
        }

        const blockElement = tryElement[1];

        const predictionEle = blockElement.querySelector(".prediction");
        predictionEle.classList.remove("predicting");
        predictionEle.classList.add("predicted");
        predictionEle.textContent = score.toPrecision(2);
      });
    })
    .catch((e) => {
      console.log("Could not process aesthetic score", e);
    });
}

function tryBlockElement(idx) {
  return Object.entries(document.querySelector("#images").children).find(
    (_, i) => i == idx,
  );
}

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

async function clearRating() {
  const ratingEles = document.querySelectorAll(".rating");

  ratingEles.forEach((rateEle) => {
    rateEle.textContent = "-";
    rateEle.classList.remove("predicted");
    rateEle.classList.add("predicting");
  });
}

async function clearPrediction() {
  const predictionEles = document.querySelectorAll(".prediction");

  predictionEles.forEach((predictedEle) => {
    predictedEle.textContent = "-";
    predictedEle.classList.remove("predicted");
    predictedEle.classList.add("predicting");
  });
}

async function getScores() {
  return trySyncMessage({
    messageType: "get_images_score",
    image_hashes: await Promise.all(imagesList.map(hashFile)),
  });
}
