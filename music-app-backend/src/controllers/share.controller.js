export const shareSong = async (req, res) => {
    const { songId } = req.params;
    const link = `myapp://song/${songId}`;
    res.json({ message: "Link chia sẻ bài hát", link });
  };
  
  export const sharePlaylist = async (req, res) => {
    const { playlistId } = req.params;
    const link = `myapp://playlist/${playlistId}`;
    res.json({ message: "Link chia sẻ playlist", link });
  };
  