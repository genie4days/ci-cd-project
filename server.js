const express = require("express");
require("dotenv").config();

const app = express();
const PORT = parseInt(process.env.PORT, 10); // Set server port

app.use(express.static("dist"));

app.listen(PORT, () => console.log(`Server listening on port: ${PORT}`));