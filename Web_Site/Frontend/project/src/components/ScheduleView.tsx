import { AlertCircle, TrendingDown, CheckCircle } from "lucide-react";

interface ScheduleSlot {
  _id: string;
  Time: string;
  Bus_Capacity: number;
  Passengers: number;
  requiredBuses: number;
  difference: number; // + need more, - can remove
  allocated: number;  // buses actually reallocated
}

interface ScheduleViewProps {
  schedule: ScheduleSlot[];
}

const ScheduleView = ({ schedule }: ScheduleViewProps) => {
  const addList = schedule.filter((s) => s.allocated > 0);
  const removeList = schedule.filter((s) => s.difference < 0);

  const totalAdded = addList.reduce((sum, s) => sum + s.allocated, 0);
  const totalRemoved = Math.abs(
    removeList.reduce((sum, s) => sum + s.difference, 0)
  );

  const unfulfilledDemand = schedule
    .filter((s) => s.difference > s.allocated)
    .reduce((sum, s) => sum + (s.difference - s.allocated), 0);

  const SlotCard = ({
    time,
    buses,
    type,
  }: {
    time: string;
    buses: number;
    type: "add" | "remove";
  }) => (
    <div
      className={`p-4 rounded-lg border-2 ${
        type === "add"
          ? "border-red-200 bg-red-50"
          : "border-yellow-200 bg-yellow-50"
      }`}
    >
      <div className="font-semibold text-gray-900">
        {time}
      </div>

      <div
        className={`mt-2 text-lg font-bold ${
          type === "add" ? "text-red-700" : "text-yellow-700"
        }`}
      >
        {type === "add" ? `+${buses} Bus(es)` : `-${buses} Bus(es)`}
      </div>
    </div>
  );

  return (
    <div className="space-y-8">
      {/* ADD BUSES */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-red-500 to-red-600 text-white">
          <div className="flex items-center gap-3">
            <AlertCircle size={28} />
            <div>
              <h3 className="text-xl font-bold">Add Buses (High Demand)</h3>
              <p className="text-sm mt-1">
                Additional buses required during peak hours
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-4">
          {addList.length > 0 ? (
            addList.map((slot) => (
              <SlotCard
                key={slot._id}
                time={slot.Time}
                buses={slot.allocated}
                type="add"
              />
            ))
          ) : (
            <div className="text-center py-6 text-gray-500">
              No additional buses required
            </div>
          )}
        </div>
      </div>

      {/* REMOVE BUSES */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-yellow-500 to-amber-500 text-white">
          <div className="flex items-center gap-3">
            <TrendingDown size={28} />
            <div>
              <h3 className="text-xl font-bold">Remove Buses (Low Demand)</h3>
              <p className="text-sm mt-1">
                Buses that can be reallocated
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-4">
          {removeList.length > 0 ? (
            removeList.map((slot) => (
              <SlotCard
                key={slot._id}
                time={slot.Time}
                buses={Math.abs(slot.difference)}
                type="remove"
              />
            ))
          ) : (
            <div className="text-center py-6 text-gray-500">
              No removable buses
            </div>
          )}
        </div>
      </div>

      {/* SUMMARY */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-green-500 to-emerald-500 text-white">
          <div className="flex items-center gap-3">
            <CheckCircle size={28} />
            <div>
              <h3 className="text-xl font-bold">Reallocation Summary</h3>
              <p className="text-sm mt-1">
                Final optimized scheduling overview
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-3 text-gray-800">
          <div className="flex justify-between">
            <span>Total Buses Reallocated:</span>
            <span className="font-semibold">{totalAdded}</span>
          </div>

          <div className="flex justify-between">
            <span>Total Buses Available from Low Demand:</span>
            <span className="font-semibold">{totalRemoved}</span>
          </div>

          <div className="flex justify-between">
            <span>Unfulfilled Demand (if any):</span>
            <span className="font-semibold text-red-600">
              {unfulfilledDemand}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ScheduleView;