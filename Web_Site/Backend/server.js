require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const busRouteRoutes = require("./busRoute.routes");
const busInstanceRoutes = require("./busInstance.routes");

const app = express();

app.use(express.json());

app.use(cors({
  origin: "http://localhost:5173",
  credentials: true
}));

// ── Routes ──────────────────────────────────────────────────────────────────
app.use("/api/bus-routes", busRouteRoutes);
app.use("/api/bus-instances", busInstanceRoutes);

// Health check
app.get("/", (req, res) => {
  res.json({
    message: "PMPML Bus Optimization API is running 🚌",
    endpoints: {
      busRoutes: "/api/bus-routes",
      busInstances: "/api/bus-instances",
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: err.message || "Internal Server Error" });
});

// ── Database & Server ────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URL ;

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("✅  MongoDB connected:", MONGO_URI);
    app.listen(PORT, () => {
      console.log(`🚌  PMPML API running on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error("❌  MongoDB connection failed:", err.message);
    process.exit(1);
  });

module.exports = app;
