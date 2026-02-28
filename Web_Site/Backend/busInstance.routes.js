const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const BusInstance = require("./BusInstance.model");
const BusRoute = require("./BusRoute.model");

// ─────────────────────────────────────────────────────────────────────────────
// 1. GET /api/bus-instances
//    Query params:
//      - routeId   : BusRoute ObjectId  (filter by route)
//      - routeNo   : Route_Number string (alternative to routeId)
//      - time      : "HH:MM" exact match
//      - date      : "YYYY-MM-DD" (filters by date regardless of time)
//      - startTime : "HH:MM" lower bound (inclusive)
//      - endTime   : "HH:MM" upper bound (inclusive)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const { routeId, routeNo, time, date, startTime, endTime } = req.query;

    const filter = {};

    // ── Resolve Bus_Route ───────────────────────────────────────────────────
    if (routeId) {
      if (!mongoose.Types.ObjectId.isValid(routeId)) {
        return res.status(400).json({ success: false, message: "Invalid routeId" });
      }
      filter.Bus_Route = routeId;
    } else if (routeNo) {
      const route = await BusRoute.findOne({ Route_Number: routeNo });
      if (!route) {
        return res.status(404).json({ success: false, message: `No route found with Route_Number: ${routeNo}` });
      }
      filter.Bus_Route = route._id;
    }

    // ── Date filter ─────────────────────────────────────────────────────────
    if (date) {
      const start = new Date(date);
      start.setUTCHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setUTCHours(23, 59, 59, 999);
      filter.Date = { $gte: start, $lte: end };
    }

    // ── Time filter ─────────────────────────────────────────────────────────
    if (time) {
      filter.Time = time;
    } else if (startTime || endTime) {
      filter.Time = {};
      if (startTime) filter.Time.$gte = startTime;
      if (endTime) filter.Time.$lte = endTime;
    }

    const instances = await BusInstance.find(filter)
      .populate("Bus_Route", "Route_Number Source Destination")
      .sort({ Date: 1, Time: 1 });

    res.json({
      success: true,
      count: instances.length,
      data: instances,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/bus-instances/:id  — single instance
// ─────────────────────────────────────────────────────────────────────────────
router.get("/:id", async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: "Invalid id" });
    }
    const instance = await BusInstance.findById(req.params.id).populate(
      "Bus_Route",
      "Route_Number Source Destination"
    );
    if (!instance) return res.status(404).json({ success: false, message: "Bus instance not found" });
    res.json({ success: true, data: instance });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. POST /api/bus-instances  — Create new bus instance
//    Body: { Bus_Route, Time, Date, Bus_Capacity, Passengers }
//    Bus_Route can be ObjectId OR Route_Number string
// ─────────────────────────────────────────────────────────────────────────────
router.post("/", async (req, res) => {
  try {
    let { Bus_Route, Time, Date: instanceDate, Bus_Capacity, Passengers } = req.body;

    // Validate required fields
    if (!Bus_Route || !Time || !instanceDate || !Bus_Capacity) {
      return res.status(400).json({
        success: false,
        message: "Bus_Route, Time, Date, and Bus_Capacity are required",
      });
    }

    // Resolve Bus_Route: accept either ObjectId or Route_Number string
    if (!mongoose.Types.ObjectId.isValid(Bus_Route)) {
      const route = await BusRoute.findOne({ Route_Number: Bus_Route });
      if (!route) {
        return res.status(404).json({
          success: false,
          message: `No route found with Route_Number: ${Bus_Route}`,
        });
      }
      Bus_Route = route._id;
    }

    // Validate time format
    if (!/^\d{2}:\d{2}$/.test(Time)) {
      return res.status(400).json({ success: false, message: "Time must be in HH:MM format" });
    }

    const passengers = Passengers !== undefined ? Passengers : 0;

    if (passengers > Bus_Capacity) {
      return res.status(400).json({
        success: false,
        message: "Passengers cannot exceed Bus_Capacity",
      });
    }

    const newInstance = await BusInstance.create({
      Bus_Route,
      Time,
      Date: new Date(instanceDate),
      Bus_Capacity,
      Passengers: passengers,
    });

    const populated = await newInstance.populate("Bus_Route", "Route_Number Source Destination");

    res.status(201).json({
      success: true,
      message: "Bus instance created successfully",
      data: populated,
    });
  } catch (err) {
    if (err.name === "ValidationError") {
      return res.status(400).json({ success: false, message: err.message });
    }
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/bus-instances/:id — Update bus instance (e.g., update Passengers)
// ─────────────────────────────────────────────────────────────────────────────
router.patch("/:id", async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: "Invalid id" });
    }

    const allowedUpdates = ["Time", "Date", "Bus_Capacity", "Passengers"];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }

    const updated = await BusInstance.findByIdAndUpdate(req.params.id, updates, {
      new: true,
      runValidators: true,
    }).populate("Bus_Route", "Route_Number Source Destination");

    if (!updated) return res.status(404).json({ success: false, message: "Bus instance not found" });

    res.json({ success: true, message: "Bus instance updated", data: updated });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. DELETE /api/bus-instances/:id  — Remove bus instance
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/:id", async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: "Invalid id" });
    }

    const deleted = await BusInstance.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ success: false, message: "Bus instance not found" });

    res.json({
      success: true,
      message: "Bus instance removed successfully",
      data: { id: req.params.id },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/bus-instances  — Bulk remove by routeId + date (optional)
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/", async (req, res) => {
  try {
    const { routeId, date } = req.query;
    if (!routeId) {
      return res.status(400).json({ success: false, message: "routeId query param is required for bulk delete" });
    }

    const filter = { Bus_Route: routeId };
    if (date) {
      const start = new Date(date);
      start.setUTCHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setUTCHours(23, 59, 59, 999);
      filter.Date = { $gte: start, $lte: end };
    }

    const result = await BusInstance.deleteMany(filter);
    res.json({
      success: true,
      message: `${result.deletedCount} bus instance(s) removed`,
      deletedCount: result.deletedCount,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
