function clearModal() {
  const modalOverlay = document.querySelector("#modal-overlay");

  // already isn't there
  if (!modalOverlay) {
    return;
  }

  document.body.removeChild(modalOverlay);
}

export function showModal(getModalContentEle) {
  return function (_e) {
    clearModal();
    const modalElement = document.createElement("div");

    modalElement.id = "modal-overlay";
    modalElement.classList.add("show-modal");

    // const imageElement = document.createElement("img");
    // imageElement.src = image;
    // modalElement.appendChild(imageElement);
    modalElement.appendChild(getModalContentEle());

    // // Eat the click events before the modal
    // imageElement.addEventListener("click", (e) => {
    // 	e.preventDefault();
    // });

    modalElement.addEventListener("click", clearModal);

    document.body.appendChild(modalElement);
  };
}
