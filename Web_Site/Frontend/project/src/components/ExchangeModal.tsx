import { X, ArrowRightLeft } from 'lucide-react';
import { BusInstance } from '../services/busInstances';

interface ExchangeModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  instance1: BusInstance | null;
  instance2: BusInstance | null;
}

const ExchangeModal = ({ isOpen, onClose, onConfirm, instance1, instance2 }: ExchangeModalProps) => {
  if (!isOpen || !instance1 || !instance2) return null;

  const ratio1 = ((instance1.Passengers / instance1.Bus_Capacity) * 100).toFixed(1);
  const ratio2 = ((instance2.Passengers / instance2.Bus_Capacity) * 100).toFixed(1);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl mx-4">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h3 className="text-xl font-bold text-gray-900">Exchange Bus Instances</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6">
          <p className="text-gray-600 mb-6">
            This will swap the passenger counts between these two bus instances:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-center">
            <div className="bg-gray-50 p-4 rounded-lg border-2 border-gray-200">
              <div className="text-sm text-gray-600 mb-2">Instance 1</div>
              <div className="font-bold text-lg text-gray-900 mb-1">{instance1.Time}</div>
              <div className="text-sm text-gray-600 mb-3">
                Route: {instance1.Bus_Route.Route_Number}
              </div>
              <div className="flex items-baseline gap-1">
                <span className="text-2xl font-bold text-gray-900">{instance1.Passengers}</span>
                <span className="text-gray-500">/{instance1.Bus_Capacity}</span>
              </div>
              <div className="mt-2 text-sm font-semibold text-orange-600">
                {ratio1}% occupancy
              </div>
            </div>

            <div className="flex justify-center">
              <div className="bg-orange-100 p-3 rounded-full">
                <ArrowRightLeft className="text-orange-600" size={24} />
              </div>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg border-2 border-gray-200">
              <div className="text-sm text-gray-600 mb-2">Instance 2</div>
              <div className="font-bold text-lg text-gray-900 mb-1">{instance2.Time}</div>
              <div className="text-sm text-gray-600 mb-3">
                Route: {instance2.Bus_Route.Route_Number}
              </div>
              <div className="flex items-baseline gap-1">
                <span className="text-2xl font-bold text-gray-900">{instance2.Passengers}</span>
                <span className="text-gray-500">/{instance2.Bus_Capacity}</span>
              </div>
              <div className="mt-2 text-sm font-semibold text-orange-600">
                {ratio2}% occupancy
              </div>
            </div>
          </div>

          <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="text-sm font-medium text-blue-900 mb-2">After Exchange:</div>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-blue-700">{instance1.Time}:</span>{' '}
                <span className="font-semibold">{instance2.Passengers}/{instance1.Bus_Capacity}</span>
              </div>
              <div>
                <span className="text-blue-700">{instance2.Time}:</span>{' '}
                <span className="font-semibold">{instance1.Passengers}/{instance2.Bus_Capacity}</span>
              </div>
            </div>
          </div>

          <div className="flex gap-3 mt-6">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-orange-500 to-amber-500 text-white rounded-lg hover:from-orange-600 hover:to-amber-600 transition-colors font-medium"
            >
              Confirm Exchange
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExchangeModal;
