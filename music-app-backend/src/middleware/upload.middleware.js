// import multer from "multer";
// import { CloudinaryStorage } from "multer-storage-cloudinary";
// import cloudinary from "../config/cloudinary.js";

// // Storage ảnh
// const imageStorage = new CloudinaryStorage({
//   cloudinary,
//   params: {
//     folder: "music-player-images",
//     resource_type: "image",
//     allowed_formats: ["jpg", "png", "jpeg"],
//   },
// });

// // Storage audio
// const audioStorage = new CloudinaryStorage({
//   cloudinary,
//   params: {
//     folder: "music-player-audio",
//     resource_type: "video", // mp3/wav/m4a phải là video
//     allowed_formats: ["mp3", "wav", "m4a"],
//   },
// });

// const upload = multer({
//   storage: (req, file) => {
//     if (file.fieldname === "image") return imageStorage;
//     if (file.fieldname === "audio") return audioStorage;
//   }
// });

// /**
//  * Upload cả image + audio
//  */
// export const uploadFiles = upload.fields([
//   { name: "image", maxCount: 1 },
//   { name: "audio", maxCount: 1 },
// ]);


import multer from "multer";

const storage = multer.memoryStorage();

export const uploadFiles = multer({
  storage,
}).fields([
  { name: "image", maxCount: 1 },
  { name: "audio", maxCount: 1 }
]);
