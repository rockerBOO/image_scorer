import { send, encode, decode, getWS } from "./main.js"

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
      return block;
    });

    const imagesElement = document.querySelector("#images");
    imagesElement.classList.add("images-grid");
    imagesElement.classList.add("small-grid");

    imagesElement.append(...imagesElements);
  })
  .then((images) => {
    setTimeout(async () => {
      // get ratings
      await send(encode({ messageType: "get_ratings", images: images }));

      // ws.send(encode({ messageType: "get_rating", image }));

      const listener = async (event) => {
        const { messageType, rating } = await decode(event.data);
        getWS().removeEventListener("message", listener);
      };

      getWS().addEventListener("message", listener);

      // Make sure we remove the listener if anything fails
      setTimeout(() => {
        getWS().removeEventListener("message", listener);
      }, 5000);
    }, 1000);
  });
