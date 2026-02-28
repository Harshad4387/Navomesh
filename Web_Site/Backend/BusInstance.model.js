const mongoose = require("mongoose");

const busInstanceSchema = new mongoose.Schema(
  {
    Bus_Route: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "BusRoute",
      required: true,
    },
    Time: {
      // Stored as "HH:MM" 24-hr format  e.g. "06:00"
      type: String,
      required: true,
      match: [/^\d{2}:\d{2}$/, "Time must be in HH:MM format"],
    },
    Date: {
      type: Date,
      required: true,
    },
    Bus_Capacity: {
      type: Number,
      required: true,
      min: 1,
    },
    Passengers: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
      validate: {
        validator: function (v) {
          return v <= this.Bus_Capacity;
        },
        message: "Passengers cannot exceed Bus_Capacity",
      },
    },
  },
  { timestamps: true }
);

// Compound index: efficient query by route + date + time
busInstanceSchema.index({ Bus_Route: 1, Date: 1, Time: 1 });

// Virtual: occupancy percentage
busInstanceSchema.virtual("Occupancy_Percent").get(function () {
  return ((this.Passengers / this.Bus_Capacity) * 100).toFixed(1) + "%";
});

busInstanceSchema.set("toJSON", { virtuals: true });
busInstanceSchema.set("toObject", { virtuals: true });

module.exports = mongoose.model("BusInstance", busInstanceSchema);
