const express = require("express");
const router = express.Router();
const BusRoute = require("./BusRoute.model");

// GET /api/bus-routes  — list all routes (with optional search)
router.get("/", async (req, res) => {
  try {
    const { search } = req.query;
    const filter = search
      ? {
          $or: [
            { Route_Number: { $regex: search, $options: "i" } },
            { Source: { $regex: search, $options: "i" } },
            { Destination: { $regex: search, $options: "i" } },
          ],
        }
      : {};

    const routes = await BusRoute.find(filter).sort({ Route_Number: 1 });
    res.json({ success: true, count: routes.length, data: routes });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bus-routes/:id
router.get("/:id", async (req, res) => {
  try {
    const route = await BusRoute.findById(req.params.id);
    if (!route) return res.status(404).json({ success: false, message: "Bus route not found" });
    res.json({ success: true, data: route });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// router.get("/all", async (req, res) => {
//   try {
//     const routes = await BusRoute.find({})
//       .sort({ Route_Number: 1 }); // sort by route number

//     return res.status(200).json({
//       success: true,
//       count: routes.length,
//       data: routes,
//     });

//   } catch (error) {
//     console.error("Error fetching routes:", error);

//     return res.status(500).json({
//       success: false,
//       message: "Failed to fetch bus routes",
//       error: error.message,
//     });
//   }
// });



module.exports = router;
