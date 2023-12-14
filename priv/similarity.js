import { showModal } from "./image_modal.js";
import { getFilename } from "./main.js";

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

function getImages() {
  const images = sessionStorage.getItem("images");
  if (images) {
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
      sessionStorage.setItem("images", images);
    })
    .catch((err) => {
      console.error(err);
    });
}

getImages();
getSimilarity(
  "/images/00306-3900798205.png",
  "/images/00112-4246239745.png",
).then((similarity) => {
  const imagesEle = document.querySelector("#images");
  for (let blockId in imagesEle.children) {
    const imgEle = imagesEle.children.item(blockId).querySelector("img");

    attachImageModal(imgEle);
  }

  const simElement = document.querySelector("#similarity");
  simElement.textContent = similarity.toPrecision(4);
});

function attachImageModal(imageElement) {
  if (!imageElement) {
    console.log("image element does not exist for modal");

    return;
  }

  const modalContentEle = document.createElement("div");
  modalContentEle.appendChild(imageElement.cloneNode());

  imageElement.addEventListener(
    "click",
    showModal(() => modalContentEle),
  );
}
