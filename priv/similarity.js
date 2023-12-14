import { showModal } from "./image_modal.js";
import { getFilename, attachLoadAnimation } from "./main.js";

let imagesList = [];
let imageIdx = 0;

async function getSimilarity(url1, url2) {
  const [file1, file2] = await Promise.allSettled([
    getUploadFromUrl(url1),
    getUploadFromUrl(url2),
  ]).then((files) => {
    console.log(files);
    return [files[0].value, files[1].value];
  });

  const formData = new FormData();
  formData.append("file", file1);
  formData.append("file2", file2);

  return fetch(`http://localhost:3031/similarity`, {
    method: "POST",
    body: formData,
  })
    .then((resp) => {
      if (!resp.ok) {
        throw new Error("Could not load similarity");
      }

      return resp.json();
    })
    .then(({ similarity }) => similarity);
}

function guessContentType(filename) {
  const ext = filename.split(".").pop().toLowerCase();
  if (ext === "png") {
    return "image/png";
  } else if (ext === "jpg" || ext === "jpeg") {
    return "image/jpeg";
  } else {
    throw new Error("Invalid content type to guess. " + ext);
  }
}

async function getUploadFromUrl(url) {
  const blob = await fetch(url).then((resp) => {
    if (!resp.ok) {
      throw new Error("Could not load images.json");
    }

    return resp.blob();
  });

  const filename = getFilename(url);
  const file = new File([blob], filename, {
    type: guessContentType(filename),
  });

  return file;
}

async function getAestheticScore(image) {
  const file = await getUploadFromUrl(image);

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
function onLoad() {
  const imgEle1 = document.querySelector("#image1");
  const imgEle2 = document.querySelector("#image2");

  attachImageModal(imgEle1);
  attachLoadAnimation(imgEle1);

  attachImageModal(imgEle2);
  attachLoadAnimation(imgEle2);

  randomSimilarityTest();
}

function getImages() {
  const images = sessionStorage.getItem("images");
  if (images) {
    imageIdx = 0;
    imagesList = JSON.parse(images);

    onLoad();
    return images;
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
      imagesList = images;
      sessionStorage.setItem("images", JSON.stringify(images));

      onLoad();
    })
    .catch((err) => {
      console.error(err);
    });
}

getImages();

function randomImage(list, max) {
  console.log("max", max);
  console.log(Math.floor(Math.random() * max));
  return list[Math.floor(Math.random() * max)];
}

function randomSimilarityTest() {
  console.log(imagesList);
  const image1 = randomImage(imagesList, imagesList.length - 1);
  const image2 = randomImage(imagesList, imagesList.length - 1);
  console.log("image1", image1, "image2", image2);
  getSimilarity(image1, image2).then((similarity) => {
    console.log(similarity);

    const imgEle1 = document.querySelector("#image1");
    const imgEle2 = document.querySelector("#image2");
    imgEle1.src = image1;
    console.log("image1", image1);
    imgEle2.src = image2;
    console.log("image2", image2);

    const simElement = document.querySelector("#similarity");
    simElement.textContent = similarity.toPrecision(4);
  });
}

function attachImageModal(imageElement) {
  imageElement.addEventListener(
    "click",
    showModal(() => {
      if (!imageElement) {
        console.log("image element does not exist for modal");

        return;
      }

      const modalContentEle = document.createElement("div");
      modalContentEle.appendChild(imageElement.cloneNode());

      return modalContentEle;
    }),
  );
}

document.querySelector("#random").addEventListener("click", (e) => {
  e.preventDefault();
  randomSimilarityTest();
});

const uploadForm = document.querySelector("#upload");
const fileUploadEle = document.querySelector("#file-upload");

uploadForm.addEventListener("submit", (e) => {
  e.preventDefault();
});

fileUploadEle.addEventListener("change", (e) => {
  e.preventDefault();
});
