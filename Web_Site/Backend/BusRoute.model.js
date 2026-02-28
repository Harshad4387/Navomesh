const mongoose = require("mongoose");

const busRouteSchema = new mongoose.Schema(
  {
    Route_Number: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    Source: {
      type: String,
      required: true,
      trim: true,
    },
    Destination: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

// Index for fast lookups
busRouteSchema.index({ Route_Number: 1 });

module.exports = mongoose.model("BusRoute", busRouteSchema);
