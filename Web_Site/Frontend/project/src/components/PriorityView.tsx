import { AlertCircle, TrendingDown } from "lucide-react";

interface WeeklySlot {
  _id: string;
  Time: string;
  Bus_Capacity: number;
  Passengers: number;
}

interface PriorityViewProps {
  instances: WeeklySlot[];
}

const PriorityView = ({ instances }: PriorityViewProps) => {
  const calculateRatio = (instance: WeeklySlot): number => {
    return (instance.Passengers / instance.Bus_Capacity) * 100;
  };

  const overcrowded = instances
    .filter((inst) => calculateRatio(inst) > 80)
    .sort((a, b) => calculateRatio(b) - calculateRatio(a));

  const undercrowded = instances
    .filter((inst) => calculateRatio(inst) < 20)
    .sort((a, b) => calculateRatio(a) - calculateRatio(b));

  const SlotCard = ({
    instance,
    type,
  }: {
    instance: WeeklySlot;
    type: "over" | "under";
  }) => {
    const ratio = calculateRatio(instance);

    return (
      <div
        className={`p-4 rounded-lg border-2 ${
          type === "over"
            ? "border-red-200 bg-red-50"
            : "border-yellow-200 bg-yellow-50"
        }`}
      >
        <div className="font-semibold text-gray-900">
          Time: {instance.Time}
        </div>

        <div className="flex items-center justify-between mt-3">
          <div>
            <span className="text-2xl font-bold text-gray-900">
              {instance.Passengers}
            </span>
            <span className="text-gray-500">
              /{instance.Bus_Capacity}
            </span>
          </div>

          <div
            className={`px-3 py-1 rounded-full text-sm font-semibold ${
              type === "over"
                ? "bg-red-200 text-red-800"
                : "bg-yellow-200 text-yellow-800"
            }`}
          >
            {ratio.toFixed(1)}%
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Overcrowded */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-red-500 to-red-600 text-white">
          <div className="flex items-center gap-3">
            <AlertCircle size={28} />
            <div>
              <h3 className="text-xl font-bold">
                Overcrowded (Weekly Avg)
              </h3>
              <p className="text-sm mt-1">
                Occupancy &gt; 80%
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-4 max-h-[600px] overflow-y-auto">
          {overcrowded.length > 0 ? (
            overcrowded.map((slot) => (
              <SlotCard key={slot._id} instance={slot} type="over" />
            ))
          ) : (
            <div className="text-center py-8 text-gray-500">
              No overcrowded time slots this week
            </div>
          )}
        </div>
      </div>

      {/* Undercrowded */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="p-6 bg-gradient-to-r from-yellow-500 to-amber-500 text-white">
          <div className="flex items-center gap-3">
            <TrendingDown size={28} />
            <div>
              <h3 className="text-xl font-bold">
                Undercrowded (Weekly Avg)
              </h3>
              <p className="text-sm mt-1">
                Occupancy &lt; 20%
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-4 max-h-[600px] overflow-y-auto">
          {undercrowded.length > 0 ? (
            undercrowded.map((slot) => (
              <SlotCard key={slot._id} instance={slot} type="under" />
            ))
          ) : (
            <div className="text-center py-8 text-gray-500">
              No undercrowded time slots this week
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PriorityView;