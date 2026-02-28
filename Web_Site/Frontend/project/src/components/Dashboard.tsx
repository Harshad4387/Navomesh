import { useState, useEffect } from 'react';
import { Bus, Plus, Lock, Loader2, RefreshCw } from 'lucide-react';
import { BusRoute, getAllBusRoutes } from '../services/busRoutes';
import ScheduleView from "./ScheduleView";
import {
  BusInstance,
  getBusInstances,
  createBusInstance,
  deleteBusInstance,
  updateBusInstance,
  bulkDeleteBusInstances,
} from '../services/busInstances';
import { formatDate, getLastWeekDates, get7DaysAgoDate, getTomorrowDate } from '../utils/dateUtils';
import TimetableView from './TimetableView';
import PriorityView from './PriorityView';
import CreateInstanceModal from './CreateInstanceModal';
import ExchangeModal from './ExchangeModal';

const Dashboard = () => {
  const [routes, setRoutes] = useState<BusRoute[]>([]);
  const [selectedRoute, setSelectedRoute] = useState<string>('');
  const [lastWeekInstances, setLastWeekInstances] = useState<BusInstance[]>([]);
  // const [todayInstances, setTodayInstances] = useState<BusInstance[]>([]);
  const [loading, setLoading] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isExchangeModalOpen, setIsExchangeModalOpen] = useState(false);
  const [selectedForExchange, setSelectedForExchange] = useState<BusInstance[]>([]);
  const [suggestions, setSuggestions] = useState<string[]>([]);

  useEffect(() => {
    fetchRoutes();
  }, []);

  useEffect(() => {
  if (selectedRoute) {
    fetchInstances();
  }
}, [selectedRoute]);

useEffect(() => {
  generateSuggestions();
}, [lastWeekInstances]);

  const fetchRoutes = async () => {
    try {
      const response = await getAllBusRoutes();
      setRoutes(response.data);
    } catch (error) {
      console.error('Failed to fetch routes:', error);
    }
  };

  const fetchInstances = async () => {
  if (!selectedRoute) return;

  setLoading(true);
  try {
    const lastWeekDates = getLastWeekDates();

    const allInstances = await Promise.all(
      lastWeekDates.map((date) =>
        getBusInstances({ routeId: selectedRoute, date })
      )
    );

    const lastWeekData = allInstances.flatMap((res) => res.data);
    setLastWeekInstances(lastWeekData);

  } catch (error) {
    console.error('Failed to fetch instances:', error);
  } finally {
    setLoading(false);
  }
};

  const generateSuggestions = () => {
  if (!lastWeekInstances.length) {
    setSuggestions([]);
    return;
  }

  // Group by time
  const timeMap: Record<string, { totalLoad: number; count: number }> = {};

  lastWeekInstances.forEach((inst) => {
    const load = inst.Passengers / inst.Bus_Capacity;

    if (!timeMap[inst.Time]) {
      timeMap[inst.Time] = { totalLoad: 0, count: 0 };
    }

    timeMap[inst.Time].totalLoad += load;
    timeMap[inst.Time].count += 1;
  });

  const overcrowdedTimes: string[] = [];
  const undercrowdedTimes: string[] = [];

  Object.entries(timeMap).forEach(([time, data]) => {
    const avgLoad = data.totalLoad / data.count;

    if (avgLoad > 0.8) {
      overcrowdedTimes.push(time);
    } else if (avgLoad < 0.3) {
      undercrowdedTimes.push(time);
    }
  });

  const newSuggestions: string[] = [];

  if (overcrowdedTimes.length > 0) {
    newSuggestions.push(
      `High demand consistently at: ${overcrowdedTimes.join(
        ", "
      )}. Consider adding buses during these peak hours.`
    );
  }

  if (undercrowdedTimes.length > 0) {
    newSuggestions.push(
      `Low demand consistently at: ${undercrowdedTimes.join(
        ", "
      )}. Consider reducing frequency during these slots.`
    );
  }

  setSuggestions(newSuggestions);
};

  const handleCreateInstance = async (data: { time: string; capacity: number; passengers: number }) => {
    try {
      const today = formatDate(new Date());
      await createBusInstance({
        Bus_Route: selectedRoute,
        Time: data.time,
        Date: today,
        Bus_Capacity: data.capacity,
        Passengers: data.passengers,
      });
      setIsCreateModalOpen(false);
      fetchInstances();
    } catch (error) {
      console.error('Failed to create instance:', error);
    }
  };

  const handleDeleteInstance = async (id: string) => {
    if (!confirm('Are you sure you want to delete this bus instance?')) return;

    try {
      await deleteBusInstance(id);
      fetchInstances();
    } catch (error) {
      console.error('Failed to delete instance:', error);
    }
  };

  const handleSelectForExchange = (instance: BusInstance) => {
    setSelectedForExchange((prev) => {
      const exists = prev.find((i) => i._id === instance._id);
      if (exists) {
        return prev.filter((i) => i._id !== instance._id);
      }
      if (prev.length >= 2) {
        return [prev[1], instance];
      }
      return [...prev, instance];
    });

    if (selectedForExchange.length === 1 && selectedForExchange[0]._id !== instance._id) {
      setIsExchangeModalOpen(true);
    }
  };

  const handleExchange = async () => {
    if (selectedForExchange.length !== 2) return;

    try {
      const [inst1, inst2] = selectedForExchange;
      await Promise.all([
        updateBusInstance(inst1._id, { Passengers: inst2.Passengers }),
        updateBusInstance(inst2._id, { Passengers: inst1.Passengers }),
      ]);
      setIsExchangeModalOpen(false);
      setSelectedForExchange([]);
      fetchInstances();
    } catch (error) {
      console.error('Failed to exchange instances:', error);
    }
  };

  const handleLockAllocations = async () => {
    if (!confirm(
      'This will delete bus instances from 7 days ago and create new instances for tomorrow with 0 passengers. Continue?'
    )) return;

    try {
      setLoading(true);
      const sevenDaysAgo = get7DaysAgoDate();
      const tomorrow = getTomorrowDate();

      await bulkDeleteBusInstances(selectedRoute, sevenDaysAgo);

      const uniqueTimes = [...new Set(lastWeekInstances.map((inst) => inst.Time))];
      await Promise.all(
        uniqueTimes.map((time) => {
          const refInstance = lastWeekInstances.find((inst) => inst.Time === time);
          if (refInstance) {
            return createBusInstance({
              Bus_Route: selectedRoute,
              Time: time,
              Date: tomorrow,
              Bus_Capacity: refInstance.Bus_Capacity,
              Passengers: 0,
            });
          }
        })
      );

      alert('Allocations locked successfully! Old data removed and new instances created.');
      fetchInstances();
    } catch (error) {
      console.error('Failed to lock allocations:', error);
      alert('Failed to lock allocations. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const selectedRouteData = routes.find((r) => r._id === selectedRoute);

  const weeklyAverages = Object.values(
  lastWeekInstances.reduce((acc: any, inst) => {
    if (!acc[inst.Time]) {
      acc[inst.Time] = {
        Time: inst.Time,
        totalPassengers: 0,
        totalCapacity: 0,
        count: 0,
      };
    }

    acc[inst.Time].totalPassengers += inst.Passengers;
    acc[inst.Time].totalCapacity += inst.Bus_Capacity;
    acc[inst.Time].count += 1;

    return acc;
  }, {})
).map((slot: any) => ({
  _id: slot.Time,
  Time: slot.Time,
  Bus_Capacity: Math.round(slot.totalCapacity / slot.count),
  Passengers: Math.round(slot.totalPassengers / slot.count),
}));

const IDEAL_LOAD = 0.8;
const BUS_CAPACITY = 50;

const schedulingPlan = weeklyAverages.map((slot) => {
  const avgLoad = slot.Passengers / slot.Bus_Capacity;

  let difference = 0;

  if (avgLoad > 0.8) {
    difference = 1; // add 1 bus
  } else if (avgLoad < 0.25) {
    difference = -1; // remove 1 bus
  }

  return {
    ...slot,
    requiredBuses: 1 + difference,
    difference,
  };
});

const needMore = schedulingPlan.filter((s) => s.difference > 0);
const canRemove = schedulingPlan.filter((s) => s.difference < 0);

let availableBuses = Math.abs(
  canRemove.reduce((sum, s) => sum + s.difference, 0)
);

const finalSchedule = schedulingPlan.map((slot) => {
  let allocated = 0;

  if (slot.difference > 0 && availableBuses > 0) {
    allocated = Math.min(slot.difference, availableBuses);
    availableBuses -= allocated;
  }

  return {
    ...slot,
    allocated,
  };
});



  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <header className="bg-gradient-to-r from-orange-600 to-amber-500 shadow-lg">
        <div className="container mx-auto px-6 py-6">
          <div className="flex items-center gap-4">
            <div className="bg-white p-3 rounded-lg shadow-md">
              <Bus className="text-orange-600" size={32} />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-white">PMPML Bus Optimization</h1>
              <p className="text-orange-50 mt-1">Route Planning & Capacity Management</p>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-6 py-8">
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <label className="block text-sm font-semibold text-gray-700 mb-3">
            Select Bus Route
          </label>
          <div className="flex gap-4 items-end">
            <select
              value={selectedRoute}
              onChange={(e) => setSelectedRoute(e.target.value)}
              className="flex-1 px-4 py-3 border-2 border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 outline-none text-lg"
            >
              <option value="">-- Select a route --</option>
              {routes.map((route) => (
                <option key={route._id} value={route._id}>
                  {route.Route_Number} - {route.Source} to {route.Destination}
                </option>
              ))}
            </select>
            {selectedRoute && (
              <button
                onClick={fetchInstances}
                disabled={loading}
                className="px-4 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-medium flex items-center gap-2"
              >
                <RefreshCw size={20} className={loading ? 'animate-spin' : ''} />
                Refresh
              </button>
            )}
          </div>

          {selectedRouteData && (
            <div className="mt-4 p-4 bg-orange-50 rounded-lg border border-orange-200">
              <div className="text-sm text-gray-600">Selected Route:</div>
              <div className="text-lg font-semibold text-gray-900 mt-1">
                {selectedRouteData.Route_Number}: {selectedRouteData.Source} → {selectedRouteData.Destination}
              </div>
            </div>
          )}
        </div>

        {selectedRoute && !loading && (
          <>
            {suggestions.length > 0 && (
              <div className="bg-blue-50 border-l-4 border-blue-500 p-6 mb-8 rounded-lg">
                <h3 className="font-semibold text-blue-900 mb-3">💡 Optimization Suggestions</h3>
                <ul className="space-y-2">
                  {suggestions.map((suggestion, idx) => (
                    <li key={idx} className="text-blue-800 text-sm">
                      • {suggestion}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="flex gap-4 mb-8">
              <button
                onClick={() => setIsCreateModalOpen(true)}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-lg hover:from-green-600 hover:to-green-700 transition-colors font-medium shadow-md"
              >
                <Plus size={20} />
                Create New Instance
              </button>

              <button
                onClick={handleLockAllocations}
                disabled={loading || lastWeekInstances.length === 0}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-orange-500 to-amber-500 text-white rounded-lg hover:from-orange-600 hover:to-amber-600 transition-colors font-medium shadow-md disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Lock size={20} />
                Lock Allocations
              </button>

              {selectedForExchange.length > 0 && (
                <div className="flex items-center gap-2 px-4 py-3 bg-orange-100 border-2 border-orange-300 rounded-lg text-orange-800 font-medium">
                  {selectedForExchange.length} selected for exchange
                </div>
              )}
            </div>

           <h2 className="text-2xl font-bold text-gray-900 mb-4">
  Weekly Average Priority Buses
</h2>
<ScheduleView schedule={finalSchedule} />

            <div>
              <TimetableView instances={lastWeekInstances} />
            </div>
          </>
        )}

        {selectedRoute && loading && (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="animate-spin text-orange-500" size={48} />
          </div>
        )}

        {!selectedRoute && (
          <div className="text-center py-20">
            <Bus className="mx-auto text-gray-300 mb-4" size={64} />
            <p className="text-gray-500 text-lg">Select a bus route to view optimization data</p>
          </div>
        )}
      </main>

      <CreateInstanceModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        onSubmit={handleCreateInstance}
        routeId={selectedRoute}
      />

      <ExchangeModal
        isOpen={isExchangeModalOpen}
        onClose={() => {
          setIsExchangeModalOpen(false);
          setSelectedForExchange([]);
        }}
        onConfirm={handleExchange}
        instance1={selectedForExchange[0] || null}
        instance2={selectedForExchange[1] || null}
      />
    </div>
  );
};

export default Dashboard;
