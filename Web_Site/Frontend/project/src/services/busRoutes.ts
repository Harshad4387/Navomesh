import axiosInstance from '../config/axios';

export interface BusRoute {
  _id: string;
  Route_Number: string;
  Source: string;
  Destination: string;
  createdAt: string;
  updatedAt: string;
}

export interface BusRoutesResponse {
  success: boolean;
  count: number;
  data: BusRoute[];
}

export const getAllBusRoutes = async (search?: string): Promise<BusRoutesResponse> => {
  const params = search ? { search } : {};
  const response = await axiosInstance.get<BusRoutesResponse>('/api/bus-routes', { params });
  return response.data;
};

export const getBusRouteById = async (id: string): Promise<{ success: boolean; data: BusRoute }> => {
  const response = await axiosInstance.get(`/api/bus-routes/${id}`);
  return response.data;
};
