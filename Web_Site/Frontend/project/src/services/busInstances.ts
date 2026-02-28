import axiosInstance from '../config/axios';
import { BusRoute } from './busRoutes';

export interface BusInstance {
  _id: string;
  Bus_Route: BusRoute;
  Time: string;
  Date: string;
  Bus_Capacity: number;
  Passengers: number;
  Occupancy_Percent: string;
  createdAt: string;
  updatedAt: string;
}

export interface BusInstancesResponse {
  success: boolean;
  count: number;
  data: BusInstance[];
}

export interface CreateBusInstanceData {
  Bus_Route: string;
  Time: string;
  Date: string;
  Bus_Capacity: number;
  Passengers?: number;
}

export const getBusInstances = async (params?: {
  routeId?: string;
  routeNo?: string;
  time?: string;
  date?: string;
  startTime?: string;
  endTime?: string;
}): Promise<BusInstancesResponse> => {
  const response = await axiosInstance.get<BusInstancesResponse>('/api/bus-instances', { params });
  return response.data;
};

export const getBusInstanceById = async (id: string): Promise<{ success: boolean; data: BusInstance }> => {
  const response = await axiosInstance.get(`/api/bus-instances/${id}`);
  return response.data;
};

export const createBusInstance = async (data: CreateBusInstanceData): Promise<{ success: boolean; data: BusInstance }> => {
  const response = await axiosInstance.post('/api/bus-instances', data);
  return response.data;
};

export const updateBusInstance = async (
  id: string,
  data: Partial<CreateBusInstanceData>
): Promise<{ success: boolean; data: BusInstance }> => {
  const response = await axiosInstance.patch(`/api/bus-instances/${id}`, data);
  return response.data;
};

export const deleteBusInstance = async (id: string): Promise<{ success: boolean; message: string }> => {
  const response = await axiosInstance.delete(`/api/bus-instances/${id}`);
  return response.data;
};

export const bulkDeleteBusInstances = async (
  routeId: string,
  date?: string
): Promise<{ success: boolean; deletedCount: number }> => {
  const params = { routeId, ...(date && { date }) };
  const response = await axiosInstance.delete('/api/bus-instances', { params });
  return response.data;
};
