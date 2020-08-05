/**
 *  Server example.
 */
const fs = require("fs");
const express = require("express");
const https = require("https");

const NAME = process.env["NAME"];
const PORT = process.env["PORT"];
const SSL_CERT = process.env["SERVER_SSL_CERT"];
const SSL_KEY = process.env["SERVER_SSL_KEY"];
const app = express();

const credentials = {
  key: fs.readFileSync(SSL_KEY, "utf-8"),
  cert: fs.readFileSync(SSL_CERT, "utf-8"),
};
const server = https.createServer(credentials, app);
app.use((req, res) => {
  res.send(
    "Testing in " + NAME + " OK! URL Sent: " + req.originalUrl.toLowerCase()
  );
});
server.listen(PORT);
console.log("Listening to port " + PORT);
