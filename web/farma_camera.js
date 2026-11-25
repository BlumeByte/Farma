window.farmaCapturePhoto = async function () {
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: { ideal: "environment" } },
    audio: false,
  });

  try {
    return await new Promise((resolve, reject) => {
      const dialog = document.createElement("dialog");
      dialog.setAttribute("aria-label", "Take a photo");
      dialog.style.maxWidth = "min(90vw, 36rem)";
      const video = document.createElement("video");
      video.muted = true;
      video.playsInline = true;
      video.style.width = "100%";
      video.srcObject = stream;

      const capture = document.createElement("button");
      capture.textContent = "Capture photo";
      capture.disabled = true;
      const cancel = document.createElement("button");
      cancel.textContent = "Cancel";

      dialog.append(video, capture, cancel);
      dialog.addEventListener("close", () => {
        dialog.remove();
        resolve(null);
      }, { once: true });
      cancel.onclick = () => dialog.close();
      capture.onclick = async () => {
        capture.disabled = true;
        try {
          const canvas = document.createElement("canvas");
          const scale = Math.min(1, 960 / Math.max(video.videoWidth, video.videoHeight));
          canvas.width = Math.round(video.videoWidth * scale);
          canvas.height = Math.round(video.videoHeight * scale);
          canvas.getContext("2d").drawImage(video, 0, 0, canvas.width, canvas.height);
          const blob = await new Promise((done) => canvas.toBlob(done, "image/jpeg", 0.75));
          if (!blob) throw new Error("Photo capture failed");
          resolve(new Uint8Array(await blob.arrayBuffer()));
        } catch (error) {
          reject(error);
        } finally {
          dialog.close();
        }
      };

      document.body.append(dialog);
      dialog.showModal();
      cancel.focus();
      video.play().then(() => {
        capture.disabled = false;
      }).catch((error) => {
        reject(error);
        dialog.close();
      });
    });
  } finally {
    stream.getTracks().forEach((track) => track.stop());
  }
};
