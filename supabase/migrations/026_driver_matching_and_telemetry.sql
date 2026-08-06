-- 7s Delivery Platform — Additive Migration 026
-- Driver Matching, Realtime Telemetry, Rich Booking Lifecycle & Event Timeline

-- 1. Create Enums for Driver and Ride Status
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'driver_status_type') THEN
    CREATE TYPE driver_status_type AS ENUM (
      'AVAILABLE',
      'MATCHING',
      'ACCEPTED',
      'ARRIVING',
      'ON_TRIP',
      'OFFLINE'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ride_lifecycle_status_type') THEN
    CREATE TYPE ride_lifecycle_status_type AS ENUM (
      'REQUESTED',
      'MATCHING',
      'MATCHED',
      'ACCEPTED',
      'ARRIVING',
      'ARRIVED',
      'PASSENGER_ONBOARD',
      'IN_PROGRESS',
      'COMPLETED',
      'CANCELLED_BY_CUSTOMER',
      'CANCELLED_BY_DRIVER',
      'NO_DRIVER_FOUND',
      'EXPIRED'
    );
  END IF;
END $$;

-- 2. Drivers Table
CREATE TABLE IF NOT EXISTS public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  photo_url TEXT,
  vehicle_plate TEXT NOT NULL,
  vehicle_model TEXT NOT NULL DEFAULT 'Boda Boda Motorcycle',
  rating NUMERIC(3,2) NOT NULL DEFAULT 4.90,
  total_trips INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  status driver_status_type NOT NULL DEFAULT 'AVAILABLE',
  service_zone TEXT NOT NULL DEFAULT 'VOI',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Driver Locations Table (Telemetry)
CREATE TABLE IF NOT EXISTS public.driver_locations (
  driver_id UUID PRIMARY KEY REFERENCES public.drivers(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  heading DOUBLE PRECISION DEFAULT 0.0,
  speed_kmh DOUBLE PRECISION DEFAULT 0.0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Ride Requests Table
CREATE TABLE IF NOT EXISTS public.ride_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  pickup_name TEXT NOT NULL,
  pickup_lat DOUBLE PRECISION NOT NULL,
  pickup_lng DOUBLE PRECISION NOT NULL,
  dest_name TEXT NOT NULL,
  dest_lat DOUBLE PRECISION NOT NULL,
  dest_lng DOUBLE PRECISION NOT NULL,
  fare_amount NUMERIC(10,2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'Cash',
  status ride_lifecycle_status_type NOT NULL DEFAULT 'REQUESTED',
  distance_km DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  estimated_duration_mins INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Ride Event Logs (Event Timeline & Audit)
CREATE TABLE IF NOT EXISTS public.ride_event_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_request_id UUID NOT NULL REFERENCES public.ride_requests(id) ON DELETE CASCADE,
  event_type ride_lifecycle_status_type NOT NULL,
  note TEXT,
  payload_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Indexes for High Performance Queries
CREATE INDEX IF NOT EXISTS idx_drivers_status ON public.drivers(status);
CREATE INDEX IF NOT EXISTS idx_driver_locations_coords ON public.driver_locations(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_ride_requests_customer ON public.ride_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_ride_requests_status ON public.ride_requests(status);
CREATE INDEX IF NOT EXISTS idx_ride_event_logs_ride ON public.ride_event_logs(ride_request_id);

-- 7. Enable RLS
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_event_logs ENABLE ROW LEVEL SECURITY;

-- 8. Basic Permissive RLS Policies for Operational Access
CREATE POLICY "Public select drivers" ON public.drivers FOR SELECT USING (true);
CREATE POLICY "Public select driver_locations" ON public.driver_locations FOR SELECT USING (true);
CREATE POLICY "Customer manage own ride_requests" ON public.ride_requests FOR ALL USING (true);
CREATE POLICY "Public select ride_event_logs" ON public.ride_event_logs FOR ALL USING (true);

-- 9. Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.drivers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ride_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ride_event_logs;
