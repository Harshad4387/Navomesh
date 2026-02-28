import { BusInstance } from '../services/busInstances';
import { getLastWeekDates, getDateLabel } from '../utils/dateUtils';

interface TimetableViewProps {
  instances: BusInstance[];
}

const TimetableView = ({ instances }: TimetableViewProps) => {
  const lastWeekDates = getLastWeekDates();

  const groupedByTime = instances.reduce((acc, instance) => {
    const time = instance.Time;
    if (!acc[time]) {
      acc[time] = {};
    }
    const date = instance.Date.split('T')[0];
    acc[time][date] = instance;
    return acc;
  }, {} as Record<string, Record<string, BusInstance>>);

  const times = Object.keys(groupedByTime).sort();

  const calculateAverage = (time: string): number => {
    const timeInstances = Object.values(groupedByTime[time]);
    if (timeInstances.length === 0) return 0;
    const sum = timeInstances.reduce((acc, inst) => acc + (inst.Passengers / inst.Bus_Capacity) * 100, 0);
    return sum / timeInstances.length;
  };

  const getStatusTag = (avg: number): { label: string; color: string } => {
    if (avg > 100) return { label: 'Overcrowded', color: 'bg-red-100 text-red-700' };
    if (avg < 20) return { label: 'Undercrowded', color: 'bg-yellow-100 text-yellow-700' };
    return { label: 'Normal', color: 'bg-green-100 text-green-700' };
  };

  const getCellColor = (ratio: number): string => {
    if (ratio > 100) return 'bg-red-50 text-red-900';
    if (ratio > 80) return 'bg-orange-50 text-orange-900';
    if (ratio >= 20) return 'bg-green-50 text-green-900';
    return 'bg-yellow-50 text-yellow-900';
  };

  return (
    <div className="bg-white rounded-lg shadow-lg overflow-hidden">
      <div className="p-6 bg-gradient-to-r from-orange-500 to-amber-500">
        <h2 className="text-2xl font-bold text-white">Last Week Timetable</h2>
        <p className="text-orange-50 mt-1">Passenger/Capacity ratios for the past 7 days</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b-2 border-gray-200">
            <tr>
              <th className="px-4 py-3 text-left text-sm font-semibold text-gray-700 sticky left-0 bg-gray-50 z-10">
                Time
              </th>
              {lastWeekDates.map((date) => (
                <th key={date} className="px-4 py-3 text-center text-sm font-semibold text-gray-700 min-w-[120px]">
                  <div>{getDateLabel(date)}</div>
                  <div className="text-xs font-normal text-gray-500 mt-1">
                    {new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </div>
                </th>
              ))}
              <th className="px-4 py-3 text-center text-sm font-semibold text-gray-700 min-w-[150px]">
                Average
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {times.map((time) => {
              const avg = calculateAverage(time);
              const status = getStatusTag(avg);

              return (
                <tr key={time} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3 text-sm font-medium text-gray-900 sticky left-0 bg-white z-10">
                    {time}
                  </td>
                  {lastWeekDates.map((date) => {
                    const instance = groupedByTime[time][date];
                    if (!instance) {
                      return (
                        <td key={date} className="px-4 py-3 text-center text-sm text-gray-400">
                          -
                        </td>
                      );
                    }
                    const ratio = (instance.Passengers / instance.Bus_Capacity) * 100;
                    return (
                      <td key={date} className={`px-4 py-3 text-center text-sm font-medium ${getCellColor(ratio)}`}>
                        <div>{instance.Passengers}/{instance.Bus_Capacity}</div>
                        <div className="text-xs mt-1">{ratio.toFixed(1)}%</div>
                      </td>
                    );
                  })}
                  <td className="px-4 py-3">
                    <div className="flex flex-col items-center gap-2">
                      <span className="text-sm font-semibold text-gray-900">{avg.toFixed(1)}%</span>
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${status.color}`}>
                        {status.label}
                      </span>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {times.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            No bus instances found for the last week
          </div>
        )}
      </div>
    </div>
  );
};

export default TimetableView;
