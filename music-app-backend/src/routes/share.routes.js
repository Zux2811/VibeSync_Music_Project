import express from "express";
import { shareSong, sharePlaylist } from "../controllers/share.controller.js";

const router = express.Router();

router.get("/song/:songId", shareSong);
router.get("/playlist/:playlistId", sharePlaylist);

export default router;
