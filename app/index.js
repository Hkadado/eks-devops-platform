const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

// Root route
app.get("/", (req, res) => {
  res.send("Hello from EKS DevOps Platform");
});

// Health check
app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

// Version endpoint
app.get("/version", (req, res) => {
  res.json({ version: "1.0.0" });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});