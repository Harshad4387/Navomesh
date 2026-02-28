/**
 * PMPML Seed Script
 * Populates BusRoute and BusInstance collections with mock data.
 *
 * Run: node src/seed/seed.js
 */

require("dotenv").config();
const mongoose = require("mongoose");
const BusRoute = require("./BusRoute.model");
const BusInstance = require("./BusInstance.model");

// ─────────────────────────────────────────────────────────────────────────────
// RAW ROUTES  (parsed from the PMPML dataset)
// ─────────────────────────────────────────────────────────────────────────────
const RAW_ROUTES = [
  { Route_Number: "2",      Source: "Katraj",                   Destination: "Shivajinagar" },
  { Route_Number: "2B",     Source: "Bhilarewadi",              Destination: "Shivajinagar" },
  { Route_Number: "2C",     Source: "Narhegaon",                Destination: "Shivajinagar" },
  { Route_Number: "3",      Source: "Swargate",                 Destination: "Pune Station" },
  { Route_Number: "5",      Source: "Swargate",                 Destination: "Pune Station" },
  { Route_Number: "5A",     Source: "Swargate",                 Destination: "Tadiwala Road" },
  { Route_Number: "7",      Source: "Swargate",                 Destination: "Uruli Kanchan" },
  { Route_Number: "7A",     Source: "Hadapsar",                 Destination: "Uruli Kanchan" },
  { Route_Number: "8",      Source: "Hadapsar",                 Destination: "Mhatobachi Alandi" },
  { Route_Number: "9",      Source: "Hadapsar",                 Destination: "Prayagdham Uruli Railway Station" },
  { Route_Number: "10",     Source: "Swargate",                 Destination: "Keshavnagar" },
  { Route_Number: "11",     Source: "Market Yard",              Destination: "Gurav Pimple" },
  { Route_Number: "11C",    Source: "Katraj",                   Destination: "Gurav Pimple" },
  { Route_Number: "12",     Source: "Upper Indiranagar",        Destination: "Nigdi" },
  { Route_Number: "13",     Source: "Upper Indiranagar",        Destination: "Shivajinagar" },
  { Route_Number: "13L",    Source: "Laketown",                 Destination: "Shivajinagar" },
  { Route_Number: "14",     Source: "Dhayari Maruti Mandir",    Destination: "Wagholi Kesanand Phata" },
  { Route_Number: "17",     Source: "Shaniwarwada",             Destination: "Narhe Ambegaon" },
  { Route_Number: "18",     Source: "Shaniwarwada",             Destination: "Tukainagar" },
  { Route_Number: "19",     Source: "Kondhwa Khurd Hospital",   Destination: "Shivajinagar" },
  { Route_Number: "20",     Source: "Sahakarnagar",             Destination: "Pune Station" },
  { Route_Number: "21",     Source: "Swargate",                 Destination: "Sangvi Gaon" },
  { Route_Number: "22",     Source: "Khandoba Mandir",          Destination: "Shivajinagar" },
  { Route_Number: "23",     Source: "Upper Indiranagar",        Destination: "Pune Station" },
  { Route_Number: "24",     Source: "Katraj",                   Destination: "Samtanagar MHB Board" },
  { Route_Number: "24B",    Source: "Katraj",                   Destination: "Lohegaon" },
  { Route_Number: "26",     Source: "Dhankawadi",               Destination: "Pune Station" },
  { Route_Number: "27",     Source: "Bharati Vidyapeeth",       Destination: "Shivajinagar Station" },
  { Route_Number: "28",     Source: "Katraj",                   Destination: "Shivajinagar Station" },
  { Route_Number: "29",     Source: "Swargate",                 Destination: "Alandi Devachi" },
  { Route_Number: "30",     Source: "Market Yard",              Destination: "Ghotawade Phata" },
  { Route_Number: "36",     Source: "Municipal Corporation Building", Destination: "Chinchwadgaon" },
  { Route_Number: "40",     Source: "Patwardhan Baug",          Destination: "M Phule Mandai Bus Stand" },
  { Route_Number: "42",     Source: "Katraj",                   Destination: "Nigdi Bhakti Shakti" },
  { Route_Number: "43",     Source: "Katraj",                   Destination: "Nigdi Bhakti Shakti" },
  { Route_Number: "46",     Source: "Swargate",                 Destination: "Lohegaon via Dhanori" },
  { Route_Number: "47",     Source: "Shaniwarwada",             Destination: "Sanaswadi" },
  { Route_Number: "48",     Source: "Pune Station",             Destination: "Venutai Chavan College" },
  { Route_Number: "50",     Source: "Shaniwarwada",             Destination: "Sinhagad Paytha" },
  { Route_Number: "51",     Source: "Shivajinagar Station",     Destination: "Dhayari Maruti Mandir" },
  { Route_Number: "55",     Source: "M Phule Mandai",           Destination: "Anandnagar Sun City" },
  { Route_Number: "57",     Source: "Pune Station",             Destination: "Wadgaon Budruk" },
  { Route_Number: "61",     Source: "Swargate",                 Destination: "Nasrapur" },
  { Route_Number: "63",     Source: "Swargate",                 Destination: "Kalyaninagar" },
  { Route_Number: "64",     Source: "Hadapsar",                 Destination: "Warje Malwadi" },
  { Route_Number: "67",     Source: "Swargate",                 Destination: "Kharadi" },
  { Route_Number: "70",     Source: "Deccan Gymkhana",          Destination: "Sheregaon via Paudgaon" },
  { Route_Number: "72",     Source: "Sukhsagar",                Destination: "Kondhwa Gate" },
  { Route_Number: "73",     Source: "Kothrud Depot",            Destination: "Hadapsar Gadital" },
  { Route_Number: "75",     Source: "Deccan Gymkhana",          Destination: "Vidyanagar" },
  { Route_Number: "77",     Source: "Warje Malwadi",            Destination: "Warje Malwadi (Circular)" },
  { Route_Number: "80",     Source: "PMC",                      Destination: "Cipla Center" },
  { Route_Number: "82",     Source: "Kondhwa Gate",             Destination: "Kondhwa Gate (Circular)" },
  { Route_Number: "84",     Source: "Deccan Gymkhana",          Destination: "Sangrun" },
  { Route_Number: "87",     Source: "Deccan Gymkhana",          Destination: "Abhinav College Girme Park" },
  { Route_Number: "90",     Source: "Swargate",                 Destination: "Gokhalenagar" },
  { Route_Number: "93",     Source: "Deccan Gymkhana",          Destination: "Pimple Nilakh" },
  { Route_Number: "94",     Source: "Kothrud Depot",            Destination: "Pune Station" },
  { Route_Number: "95",     Source: "Kothrud Depot",            Destination: "Pimple Gurav" },
  { Route_Number: "96",     Source: "Warje Gharkul Housing Colony", Destination: "Pimple Gurav" },
  { Route_Number: "98",     Source: "Katraj",                   Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "99",     Source: "Swargate",                 Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "100",    Source: "PMC Building",             Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "101",    Source: "Kothrud Depot",            Destination: "Kondhwa" },
  { Route_Number: "102",    Source: "Kothrud Depot",            Destination: "Lohegaon" },
  { Route_Number: "103",    Source: "Katraj",                   Destination: "Kothrud Depot" },
  { Route_Number: "104",    Source: "Deccan Gymkhana",          Destination: "Dhayari DSK Vishwa" },
  { Route_Number: "107",    Source: "Deccan Gymkhana",          Destination: "Pimple Gurav" },
  { Route_Number: "109",    Source: "PMC Building",             Destination: "PMC Building (Circular via Pashan)" },
  { Route_Number: "110",    Source: "PMC Building",             Destination: "PMC Building (Circular via Karve Road)" },
  { Route_Number: "115P",   Source: "Pune Station",             Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "117",    Source: "Swargate",                 Destination: "DSK Vishwa" },
  { Route_Number: "119",    Source: "PMC Building",             Destination: "Alandi Devachi" },
  { Route_Number: "120",    Source: "PMC Building",             Destination: "Chakan MIDC" },
  { Route_Number: "121",    Source: "PMC Building",             Destination: "Bhosari Telco" },
  { Route_Number: "122",    Source: "PMC Building",             Destination: "Chinchwadgaon" },
  { Route_Number: "123",    Source: "PMC Building",             Destination: "Nigdi Bhakti Shakti" },
  { Route_Number: "129",    Source: "Pune Station",             Destination: "Medi Point" },
  { Route_Number: "130",    Source: "Yewalewadi",               Destination: "Shivajinagar" },
  { Route_Number: "134",    Source: "Pune Station",             Destination: "Vidyanagar" },
  { Route_Number: "139",    Source: "Shewalwadi Hadapsar",      Destination: "Nigdi" },
  { Route_Number: "140",    Source: "Upper Indiranagar",        Destination: "Pune Station" },
  { Route_Number: "143",    Source: "Warje Naka",               Destination: "Pune Station" },
  { Route_Number: "144",    Source: "Kothrud Stand",            Destination: "Pune Station" },
  { Route_Number: "145",    Source: "Pune Station",             Destination: "NDA Gol Market" },
  { Route_Number: "151",    Source: "Pune Station",             Destination: "Alandi Devachi" },
  { Route_Number: "153",    Source: "Pune Station",             Destination: "Bopkhel" },
  { Route_Number: "155",    Source: "Pune Station",             Destination: "Dhanori" },
  { Route_Number: "158",    Source: "PMC Building",             Destination: "Lohegaon" },
  { Route_Number: "158A",   Source: "Deccan Gymkhana",          Destination: "Lohegaon Airport" },
  { Route_Number: "160",    Source: "PMC Building",             Destination: "Mundhwa" },
  { Route_Number: "161",    Source: "Deccan Gymkhana",          Destination: "Viman Nagar" },
  { Route_Number: "164",    Source: "Swargate",                 Destination: "Viman Nagar" },
  { Route_Number: "167",    Source: "Hadapsar",                 Destination: "Wagholi" },
  { Route_Number: "170",    Source: "Pune Station",             Destination: "Kondhwa Khurd" },
  { Route_Number: "176",    Source: "Sarasbaug",                Destination: "Mohammadwadi" },
  { Route_Number: "177",    Source: "Pune Station",             Destination: "Salunke Vihar" },
  { Route_Number: "180",    Source: "Natwadi",                  Destination: "Hadapsar" },
  { Route_Number: "184",    Source: "Swargate",                 Destination: "Bhekrai Nagar" },
  { Route_Number: "185",    Source: "Hadapsar",                 Destination: "Manjari Gaon" },
  { Route_Number: "187",    Source: "Bhekrai Nagar Hadapsar",   Destination: "Pune Station" },
  { Route_Number: "188",    Source: "Hadapsar",                 Destination: "Katraj" },
  { Route_Number: "192",    Source: "Hadapsar",                 Destination: "Undri Gaon" },
  { Route_Number: "197",    Source: "Hadapsar",                 Destination: "Kothrud Depot" },
  { Route_Number: "200",    Source: "Sadesatra Nali",           Destination: "Swargate" },
  { Route_Number: "201",    Source: "Hadapsar",                 Destination: "Alandi Darshan" },
  { Route_Number: "203",    Source: "Hadapsar",                 Destination: "Pune Station" },
  { Route_Number: "204",    Source: "Bhekrai Nagar",            Destination: "Chinchwad" },
  { Route_Number: "207",    Source: "Swargate",                 Destination: "Saswad" },
  { Route_Number: "208",    Source: "Hadapsar",                 Destination: "Hinjawadi Phase 3" },
  { Route_Number: "213",    Source: "Katraj",                   Destination: "Viman Nagar" },
  { Route_Number: "214",    Source: "Katraj",                   Destination: "Ambegaon Plateau" },
  { Route_Number: "218",    Source: "Katraj",                   Destination: "Balewadi" },
  { Route_Number: "226",    Source: "Pune Station",             Destination: "Wadgaon Dhayari" },
  { Route_Number: "230",    Source: "Bharati Vidyapeeth",       Destination: "Pune Station" },
  { Route_Number: "235",    Source: "Katraj",                   Destination: "Kharadi Gaon" },
  { Route_Number: "237",    Source: "Warje Malwadi",            Destination: "Kharadi" },
  { Route_Number: "276",    Source: "Warje Malwadi",            Destination: "Chinchwadgaon" },
  { Route_Number: "277",    Source: "Kondhwa Gate",             Destination: "Khadki Bazaar" },
  { Route_Number: "280",    Source: "PMC Building",             Destination: "Warje Hanuman Chowk" },
  { Route_Number: "281",    Source: "Warje Malwadi",            Destination: "Nigdi Bhakti Shakti" },
  { Route_Number: "282",    Source: "Warje Malwadi",            Destination: "Bhosari" },
  { Route_Number: "284",    Source: "Kothrud Depot",            Destination: "Nigdi Bhakti Shakti" },
  { Route_Number: "290",    Source: "Katraj Shaninagar",        Destination: "Shivajinagar" },
  { Route_Number: "291",    Source: "Katraj",                   Destination: "Hadapsar Gadital" },
  { Route_Number: "293",    Source: "Swargate",                 Destination: "Khed Shivapur" },
  { Route_Number: "294",    Source: "Katraj",                   Destination: "Khadakwasla" },
  { Route_Number: "296",    Source: "Jambhulwadi",              Destination: "Shivajinagar" },
  { Route_Number: "298",    Source: "Katraj",                   Destination: "Chinchwad Gaon Chintamani Chowk" },
  { Route_Number: "299",    Source: "Katraj",                   Destination: "Bhosari Gaon" },
  { Route_Number: "301",    Source: "Katraj",                   Destination: "Hadapsar BRT" },
  { Route_Number: "303",    Source: "Nigdi",                    Destination: "Akurdi Railway Station" },
  { Route_Number: "304",    Source: "Chinchwadgaon",            Destination: "Bhosari" },
  { Route_Number: "305",    Source: "Nigdi",                    Destination: "Wadgaon" },
  { Route_Number: "306",    Source: "Dange Chowk",              Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "309",    Source: "Alandi",                   Destination: "Dehugaon" },
  { Route_Number: "311",    Source: "Pimpri Gaon",              Destination: "Pune Station via Yerawada" },
  { Route_Number: "312",    Source: "Chinchwadgaon",            Destination: "Pune Station via Yerawada" },
  { Route_Number: "313",    Source: "Chinchwadgaon",            Destination: "Marunji" },
  { Route_Number: "315",    Source: "Bhosari",                  Destination: "Pune Station via Yerawada" },
  { Route_Number: "316",    Source: "Chinchwadgaon",            Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "317",    Source: "Sambhajinagar",            Destination: "Pune Station via Wakdewadi" },
  { Route_Number: "318",    Source: "Krishnanagar",             Destination: "Pune Station via Aundh" },
  { Route_Number: "321",    Source: "Sangvi",                   Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "322B",   Source: "Pune Station",             Destination: "Akurdi Railway Station" },
  { Route_Number: "324",    Source: "Bhosari",                  Destination: "Hinjawadi Phase 3" },
  { Route_Number: "327",    Source: "Alandi",                   Destination: "Hinjawadi" },
  { Route_Number: "329",    Source: "Pune Station",             Destination: "Dehugaon via Yerawada" },
  { Route_Number: "332",    Source: "Pune Station",             Destination: "Pimpri Municipal Corporation" },
  { Route_Number: "333",    Source: "Pune Station",             Destination: "Hinjawadi Man Phase 3" },
  { Route_Number: "336",    Source: "Wagholi",                  Destination: "Nigdi via Chandannagar Khadki" },
  { Route_Number: "337",    Source: "Dhayari Maruti Mandir",    Destination: "Nigdi Bhakti Shakti Depot" },
  { Route_Number: "338",    Source: "Kothrud Depot",            Destination: "Chinchwad Gaon" },
  { Route_Number: "341",    Source: "PMC",                      Destination: "Mohannagar" },
  { Route_Number: "345",    Source: "Pune Station",             Destination: "Thergaon via Aundh" },
  { Route_Number: "347",    Source: "Dapodi",                   Destination: "Alandi" },
  { Route_Number: "348",    Source: "Nigdi",                    Destination: "Pune Station via Aundh" },
  { Route_Number: "354",    Source: "Pimpri Gaon",              Destination: "Market Yard" },
  { Route_Number: "357",    Source: "Pune Station",             Destination: "Rajgurunagar" },
  { Route_Number: "358",    Source: "Bhosari",                  Destination: "Rajgurunagar" },
  { Route_Number: "360",    Source: "Alandi",                   Destination: "Balewadi" },
  { Route_Number: "361",    Source: "Bhosari",                  Destination: "Alandi" },
  { Route_Number: "363",    Source: "Nigdi",                    Destination: "Kiwale" },
  { Route_Number: "366",    Source: "Nigdi",                    Destination: "Pune Station" },
  { Route_Number: "367",    Source: "Nigdi",                    Destination: "Bhosari" },
  { Route_Number: "372",    Source: "Nigdi",                    Destination: "Hinjawadi" },
  { Route_Number: "373",    Source: "Wakad Bridge",             Destination: "Infosys Man Phase 3" },
  { Route_Number: "376",    Source: "Katraj",                   Destination: "Nigdi" },
  { Route_Number: "376B",   Source: "Nigdi",                    Destination: "Hadapsar via Garware Company" },
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/** Return "HH:MM" string from hour + minute */
function toTime(hour, minute = 0) {
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

/** Return UTC midnight Date for a given YYYY-MM-DD string */
function toDate(str) {
  return new Date(str + "T00:00:00.000Z");
}

/** Random integer in [min, max] */
function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

const DATES = [
  "2026-02-20",
  "2026-02-21",
  "2026-02-22",
  "2026-02-23",
  "2026-02-24",
  "2026-02-25",
  "2026-02-26",
];

// Busy routes get 10 trips/day, others get 6
const BUSY_ROUTE_NUMBERS = new Set([
  "2", "3", "5", "13", "20", "26", "28", "94", "99", "100",
  "115P", "129", "140", "143", "144", "151", "170", "203",
  "301", "311", "312", "315", "332", "333", "348", "366",
]);

// Bus capacities: bigger buses on busy routes
function getCapacity(routeNo) {
  if (BUSY_ROUTE_NUMBERS.has(routeNo)) return 60;
  const r = rand(0, 2);
  return r === 0 ? 35 : r === 1 ? 45 : 52;
}

/**
 * Generate departure times across 06:00–23:00.
 * busCount: number of trips per day.
 */
function generateTimes(busCount) {
  const times = [];
  const startHour = 6;
  const endHour = 23;
  const spanMinutes = (endHour - startHour) * 60;
  const interval = Math.floor(spanMinutes / (busCount - 1));

  for (let i = 0; i < busCount; i++) {
    const totalMin = startHour * 60 + i * interval;
    const h = Math.floor(totalMin / 60);
    const m = totalMin % 60;
    // Add slight randomness to make data realistic
    const jitter = rand(-5, 5);
    const adjMin = Math.max(0, Math.min(59, m + jitter));
    const adjHour = h > 23 ? 23 : h;
    times.push(toTime(adjHour, adjMin));
  }
  return times;
}

/**
 * Simulate realistic passenger load:
 *  - Morning peak 07:00–10:00 → 70–100% occupancy
 *  - Evening peak 17:00–20:00 → 70–100% occupancy
 *  - Midday        → 30–60%
 *  - Night/early   → 10–30%
 */
function getPassengers(capacity, timeStr) {
  const hour = parseInt(timeStr.split(":")[0], 10);
  let ratio;
  if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
    ratio = rand(70, 100) / 100;
  } else if (hour >= 10 && hour <= 16) {
    ratio = rand(30, 60) / 100;
  } else {
    ratio = rand(10, 30) / 100;
  }
  return Math.min(capacity, Math.round(capacity * ratio));
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SEED FUNCTION
// ─────────────────────────────────────────────────────────────────────────────
async function seed() {
  const MONGO_URI = process.env.MONGO_URL;

  await mongoose.connect(MONGO_URI);
  console.log("✅  Connected to MongoDB : ");
  console.log("Database Name:", mongoose.connection.name);

  // Clear existing data
  await BusRoute.deleteMany({});
  await BusInstance.deleteMany({});
  console.log("🗑️   Cleared existing BusRoute and BusInstance documents");

  // ── Insert BusRoutes ────────────────────────────────────────────────────────
  const insertedRoutes = await BusRoute.insertMany(RAW_ROUTES);
  console.log(`🚌  Inserted ${insertedRoutes.length} BusRoute documents`);

  // Build a map: Route_Number → ObjectId
  const routeMap = {};
  for (const r of insertedRoutes) {
    routeMap[r.Route_Number] = r._id;
  }

  // ── Build BusInstance documents ─────────────────────────────────────────────
  const instances = [];

  for (const route of insertedRoutes) {
    const busCount = BUSY_ROUTE_NUMBERS.has(route.Route_Number) ? 10 : 6;
    const capacity = getCapacity(route.Route_Number);
    const dailyTimes = generateTimes(busCount);

    for (const dateStr of DATES) {
      for (const time of dailyTimes) {
        instances.push({
          Bus_Route: routeMap[route.Route_Number],
          Time: time,
          Date: toDate(dateStr),
          Bus_Capacity: capacity,
          Passengers: getPassengers(capacity, time),
        });
      }
    }
  }

  // Insert in batches of 1000 to avoid memory issues
  const BATCH = 1000;
  let inserted = 0;
  for (let i = 0; i < instances.length; i += BATCH) {
    await BusInstance.insertMany(instances.slice(i, i + BATCH));
    inserted += Math.min(BATCH, instances.length - i);
    process.stdout.write(`\r⏳  Inserting bus instances... ${inserted}/${instances.length}`);
  }

  console.log(`\n✅  Inserted ${instances.length} BusInstance documents`);
  console.log("🎉  Seeding complete!");

  await mongoose.disconnect();
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌  Seed failed:", err);
  process.exit(1);
});
