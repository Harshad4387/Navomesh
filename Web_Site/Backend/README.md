# 🚌 PMPML Bus Frequency Optimization — Backend API

Node.js + Express + MongoDB backend to model PMPML bus routes and instances,
enabling frequency optimization analysis to tackle overcrowding and under-utilization.

---

## 📁 Project Structure

```
pmpml-backend/
├── server.js                        ← Express app entry point
├── .env                             ← Environment variables
├── .env.example
├── package.json
└── src/
    ├── models/
    │   ├── BusRoute.model.js        ← BusRoute schema
    │   └── BusInstance.model.js     ← BusInstance schema
    ├── routes/
    │   ├── busRoute.routes.js       ← GET /api/bus-routes
    │   └── busInstance.routes.js    ← GET / POST / DELETE /api/bus-instances
    └── seed/
        └── seed.js                  ← Populates DB with mock data
```

---

## ⚡ Quick Start

### 1. Install dependencies
```bash
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env if your MongoDB URI is different
```

### 3. Seed the database
```bash
npm run seed
```
This inserts **~150 bus routes** and **~10,000+ bus instances** covering
**20 Feb 2026 – 26 Feb 2026** with realistic passenger load patterns.

### 4. Start the server
```bash
npm start          # production
npm run dev        # development (nodemon)
```

Server runs at: `http://localhost:3000`

---

## 🗄️ MongoDB Schemas

### BusRoute
```json
{
  "_id":          "ObjectId",
  "Route_Number": "2",
  "Source":       "Katraj",
  "Destination":  "Shivajinagar",
  "createdAt":    "ISODate",
  "updatedAt":    "ISODate"
}
```

### BusInstance
```json
{
  "_id":          "ObjectId",
  "Bus_Route":    "ObjectId (ref: BusRoute)",
  "Time":         "06:00",          // HH:MM 24-hr
  "Date":         "ISODate",
  "Bus_Capacity": 60,
  "Passengers":   48,
  "createdAt":    "ISODate",
  "updatedAt":    "ISODate"
}
```
A virtual field `Occupancy_Percent` is also computed: `"80.0%"`

---

## 📡 API Reference

### BusRoute APIs

| Method | Endpoint               | Description            |
|--------|------------------------|------------------------|
| GET    | `/api/bus-routes`      | List all routes        |
| GET    | `/api/bus-routes/:id`  | Get single route by ID |

**Query params for list:**
- `search` — filter by Route_Number, Source, or Destination (case-insensitive)

---

### BusInstance APIs

#### 1. 🔍 GET all bus instances by route and/or time

```
GET /api/bus-instances
```

| Query Param  | Type   | Description                                   |
|-------------|--------|-----------------------------------------------|
| `routeNo`   | string | Filter by Route_Number (e.g. `routeNo=2`)     |
| `routeId`   | string | Filter by BusRoute ObjectId                   |
| `date`      | string | Filter by date `YYYY-MM-DD` (e.g. `2026-02-20`) |
| `time`      | string | Exact time match `HH:MM` (e.g. `time=08:00`) |
| `startTime` | string | Start of time window `HH:MM`                  |
| `endTime`   | string | End of time window `HH:MM`                    |

**Examples:**
```bash
# All instances for route 2 on 20 Feb
GET /api/bus-instances?routeNo=2&date=2026-02-20

# All morning rush instances (7am–10am) for route 94
GET /api/bus-instances?routeNo=94&startTime=07:00&endTime=10:00

# All instances on a specific date
GET /api/bus-instances?date=2026-02-23

# All instances for a route across all dates
GET /api/bus-instances?routeNo=99
```

**Response:**
```json
{
  "success": true,
  "count": 10,
  "data": [
    {
      "_id": "...",
      "Bus_Route": {
        "_id": "...",
        "Route_Number": "2",
        "Source": "Katraj",
        "Destination": "Shivajinagar"
      },
      "Time": "07:15",
      "Date": "2026-02-20T00:00:00.000Z",
      "Bus_Capacity": 60,
      "Passengers": 54,
      "Occupancy_Percent": "90.0%"
    }
  ]
}
```

---

#### 2. ➕ POST — Create new bus instance

```
POST /api/bus-instances
Content-Type: application/json
```

**Body:**
```json
{
  "Bus_Route": "2",          // Route_Number string  OR  ObjectId
  "Time": "08:30",           // HH:MM format
  "Date": "2026-02-28",      // YYYY-MM-DD
  "Bus_Capacity": 60,
  "Passengers": 0            // optional, defaults to 0
}
```

**Response `201`:**
```json
{
  "success": true,
  "message": "Bus instance created successfully",
  "data": { ... }
}
```

---

#### 3. 🗑️ DELETE — Remove bus instance

**Single instance by ID:**
```
DELETE /api/bus-instances/:id
```

**Response:**
```json
{
  "success": true,
  "message": "Bus instance removed successfully",
  "data": { "id": "..." }
}
```

**Bulk delete by route + optional date:**
```
DELETE /api/bus-instances?routeId=<ObjectId>&date=2026-02-20
```

---

#### 4. ✏️ PATCH — Update a bus instance

```
PATCH /api/bus-instances/:id
Content-Type: application/json
```

**Body (any subset):**
```json
{
  "Passengers": 45,
  "Bus_Capacity": 60,
  "Time": "09:00",
  "Date": "2026-02-21"
}
```

---

## 🧠 Optimization Use Cases

With this data foundation you can:

- **Identify overcrowded slots**: query instances where `Passengers / Bus_Capacity > 0.85`
- **Spot underutilized trips**: query instances where `Passengers / Bus_Capacity < 0.30`
- **Frequency rebalancing**: aggregate per route per hour across all 7 days
- **Peak vs. off-peak analysis**: filter by `startTime` / `endTime`
- **Route comparison**: compare occupancy across routes serving same corridor

---

## 🔧 Tech Stack

| Layer     | Technology         |
|-----------|--------------------|
| Runtime   | Node.js            |
| Framework | Express 4.x        |
| Database  | MongoDB            |
| ODM       | Mongoose 8.x       |
| Config    | dotenv             |
| Dev Tool  | nodemon            |
