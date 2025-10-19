--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: update_staff_daily_stats(uuid, character varying, numeric, integer); Type: FUNCTION; Schema: public; Owner: ivan
--

CREATE FUNCTION public.update_staff_daily_stats(p_staff_id uuid, p_transaction_type character varying, p_amount numeric, p_quantity integer DEFAULT 1) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    seat_income DECIMAL(10,2) := 0.00;
    day_pass_income DECIMAL(10,2) := 0.00;
    seat_count INTEGER := 0;
    day_pass_count INTEGER := 0;
BEGIN
    -- Calculate income based on transaction type
    IF p_transaction_type = 'SEAT_BOOKING' THEN
        seat_income := p_amount;
        seat_count := p_quantity;
    ELSIF p_transaction_type = 'DAY_PASS_SALE' THEN
        day_pass_income := p_amount;
        day_pass_count := p_quantity;
    END IF;

    -- Insert or update staff daily statistics
    INSERT INTO staff_daily_statistics (
        staff_id, date, total_seats_booked, total_seat_income,
        total_day_passes_sold, total_day_pass_income, total_income, total_transactions
    ) VALUES (
        p_staff_id, current_date, seat_count, seat_income,
        day_pass_count, day_pass_income, seat_income + day_pass_income, 1
    )
    ON CONFLICT (staff_id, date) DO UPDATE SET
        total_seats_booked = staff_daily_statistics.total_seats_booked + seat_count,
        total_seat_income = staff_daily_statistics.total_seat_income + seat_income,
        total_day_passes_sold = staff_daily_statistics.total_day_passes_sold + day_pass_count,
        total_day_pass_income = staff_daily_statistics.total_day_pass_income + day_pass_income,
        total_income = staff_daily_statistics.total_income + seat_income + day_pass_income,
        total_transactions = staff_daily_statistics.total_transactions + 1,
        updated_at = NOW();
END;
$$;


ALTER FUNCTION public.update_staff_daily_stats(p_staff_id uuid, p_transaction_type character varying, p_amount numeric, p_quantity integer) OWNER TO ivan;

--
-- Name: update_station_daily_stats(uuid, character varying, numeric, integer); Type: FUNCTION; Schema: public; Owner: ivan
--

CREATE FUNCTION public.update_station_daily_stats(p_station_id uuid, p_transaction_type character varying, p_amount numeric, p_quantity integer DEFAULT 1) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_date DATE := CURRENT_DATE;
    seat_income DECIMAL(10,2) := 0.00;
    day_pass_income DECIMAL(10,2) := 0.00;
    seat_count INTEGER := 0;
    day_pass_count INTEGER := 0;
BEGIN
    -- Calculate income based on transaction type
    IF p_transaction_type = 'SEAT_BOOKING' THEN
        seat_income := p_amount;
        seat_count := p_quantity;
    ELSIF p_transaction_type = 'DAY_PASS_SALE' THEN
        day_pass_income := p_amount;
        day_pass_count := p_quantity;
    END IF;

    -- Insert or update station daily statistics
    INSERT INTO station_daily_statistics (
        station_id, date, total_seats_booked, total_seat_income,
        total_day_passes_sold, total_day_pass_income, total_income, total_transactions
    ) VALUES (
        p_station_id, current_date, seat_count, seat_income,
        day_pass_count, day_pass_income, seat_income + day_pass_income, 1
    )
    ON CONFLICT (station_id, date) DO UPDATE SET
        total_seats_booked = station_daily_statistics.total_seats_booked + seat_count,
        total_seat_income = station_daily_statistics.total_seat_income + seat_income,
        total_day_passes_sold = station_daily_statistics.total_day_passes_sold + day_pass_count,
        total_day_pass_income = station_daily_statistics.total_day_pass_income + day_pass_income,
        total_income = station_daily_statistics.total_income + seat_income + day_pass_income,
        total_transactions = station_daily_statistics.total_transactions + 1,
        updated_at = NOW();
END;
$$;


ALTER FUNCTION public.update_station_daily_stats(p_station_id uuid, p_transaction_type character varying, p_amount numeric, p_quantity integer) OWNER TO ivan;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO ivan;

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.bookings (
    id text NOT NULL,
    queue_id text,
    seats_booked integer NOT NULL,
    total_amount double precision NOT NULL,
    booking_source text DEFAULT 'CASH_STATION'::text NOT NULL,
    booking_type text DEFAULT 'CASH'::text NOT NULL,
    sub_route text,
    sub_route_name text,
    booking_status text DEFAULT 'ACTIVE'::text NOT NULL,
    payment_status text DEFAULT 'PAID'::text NOT NULL,
    payment_method text DEFAULT 'CASH'::text NOT NULL,
    payment_processed_at timestamp(3) without time zone,
    verification_code text NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    verified_at timestamp(3) without time zone,
    verified_by_id text,
    cancelled_at timestamp(3) without time zone,
    cancelled_by text,
    cancellation_reason text,
    refund_amount double precision,
    created_offline boolean DEFAULT false NOT NULL,
    local_id text,
    created_by text,
    created_at timestamp(3) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT now() NOT NULL,
    seat_number integer DEFAULT 1,
    created_by_name character varying(200)
);


ALTER TABLE public.bookings OWNER TO ivan;

--
-- Name: day_passes; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.day_passes (
    id text NOT NULL,
    vehicle_id text NOT NULL,
    license_plate text NOT NULL,
    price double precision DEFAULT 2.0 NOT NULL,
    purchase_date timestamp(3) without time zone NOT NULL,
    valid_from timestamp(3) without time zone NOT NULL,
    valid_until timestamp(3) without time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_expired boolean DEFAULT false NOT NULL,
    created_by text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.day_passes OWNER TO ivan;

--
-- Name: exit_passes; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.exit_passes (
    id text NOT NULL,
    queue_id text,
    vehicle_id text NOT NULL,
    license_plate text NOT NULL,
    destination_id text NOT NULL,
    destination_name text NOT NULL,
    current_exit_time timestamp(3) without time zone NOT NULL,
    created_by text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_price numeric(10,2) DEFAULT 0.00 NOT NULL
);


ALTER TABLE public.exit_passes OWNER TO ivan;

--
-- Name: offline_customers; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.offline_customers (
    id integer NOT NULL,
    name text NOT NULL,
    phone text,
    cin text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.offline_customers OWNER TO ivan;

--
-- Name: offline_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: ivan
--

CREATE SEQUENCE public.offline_customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.offline_customers_id_seq OWNER TO ivan;

--
-- Name: offline_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ivan
--

ALTER SEQUENCE public.offline_customers_id_seq OWNED BY public.offline_customers.id;


--
-- Name: operation_logs; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.operation_logs (
    id integer NOT NULL,
    staff_id text,
    operation text NOT NULL,
    details text,
    success boolean DEFAULT true NOT NULL,
    error text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.operation_logs OWNER TO ivan;

--
-- Name: operation_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: ivan
--

CREATE SEQUENCE public.operation_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.operation_logs_id_seq OWNER TO ivan;

--
-- Name: operation_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ivan
--

ALTER SEQUENCE public.operation_logs_id_seq OWNED BY public.operation_logs.id;


--
-- Name: print_queue; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.print_queue (
    id character varying(255) NOT NULL,
    job_type character varying(50) NOT NULL,
    content text NOT NULL,
    staff_name character varying(255),
    priority integer DEFAULT 0,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    completed_at timestamp without time zone,
    failed_at timestamp without time zone,
    retry_count integer DEFAULT 0
);


ALTER TABLE public.print_queue OWNER TO ivan;

--
-- Name: printers; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.printers (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    ip_address character varying(45) NOT NULL,
    port integer DEFAULT 9100 NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    is_online boolean DEFAULT false NOT NULL,
    station_id character varying(255) NOT NULL,
    last_seen timestamp without time zone,
    last_error text,
    error_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.printers OWNER TO ivan;

--
-- Name: routes; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.routes (
    id text NOT NULL,
    station_id text NOT NULL,
    station_name text NOT NULL,
    base_price double precision NOT NULL,
    governorate text,
    governorate_ar text,
    delegation text,
    delegation_ar text,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.routes OWNER TO ivan;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    staff_id text NOT NULL,
    token text NOT NULL,
    staff_data text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_activity timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp(3) without time zone NOT NULL,
    created_offline boolean DEFAULT false NOT NULL,
    last_offline_at timestamp(3) without time zone,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sessions OWNER TO ivan;

--
-- Name: staff; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.staff (
    id text NOT NULL,
    cin text NOT NULL,
    phone_number text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    role text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp(3) without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.staff OWNER TO ivan;

--
-- Name: station_config; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.station_config (
    id text NOT NULL,
    station_id text NOT NULL,
    station_name text NOT NULL,
    governorate text NOT NULL,
    delegation text NOT NULL,
    address text,
    opening_time text DEFAULT '06:00'::text NOT NULL,
    closing_time text DEFAULT '22:00'::text NOT NULL,
    is_operational boolean DEFAULT true NOT NULL,
    service_fee numeric(10,3) DEFAULT 0.200 NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.station_config OWNER TO ivan;

--
-- Name: station_daily_statistics; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.station_daily_statistics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id uuid NOT NULL,
    date date NOT NULL,
    total_seats_booked integer DEFAULT 0,
    total_seat_income numeric(10,2) DEFAULT 0.00,
    total_day_passes_sold integer DEFAULT 0,
    total_day_pass_income numeric(10,2) DEFAULT 0.00,
    total_income numeric(10,2) DEFAULT 0.00,
    total_transactions integer DEFAULT 0,
    active_staff_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.station_daily_statistics OWNER TO ivan;

--
-- Name: stations; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.stations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    station_id character varying(50) NOT NULL,
    station_name character varying(100) NOT NULL,
    governorate character varying(100),
    delegation character varying(100),
    address text,
    opening_time character varying(10) DEFAULT '06:00'::character varying,
    closing_time character varying(10) DEFAULT '22:00'::character varying,
    is_operational boolean DEFAULT true,
    service_fee numeric(10,3) DEFAULT 0.200,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.stations OWNER TO ivan;

--
-- Name: trips; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.trips (
    id text NOT NULL,
    vehicle_id text NOT NULL,
    license_plate text NOT NULL,
    destination_id text NOT NULL,
    destination_name text NOT NULL,
    queue_id text,
    seats_booked integer NOT NULL,
    start_time timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    vehicle_capacity integer,
    base_price numeric(10,2)
);


ALTER TABLE public.trips OWNER TO ivan;

--
-- Name: vehicle_authorized_stations; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.vehicle_authorized_stations (
    id text NOT NULL,
    vehicle_id text NOT NULL,
    station_id text NOT NULL,
    station_name text,
    priority integer DEFAULT 1 NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.vehicle_authorized_stations OWNER TO ivan;

--
-- Name: vehicle_queue; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.vehicle_queue (
    id text NOT NULL,
    vehicle_id text NOT NULL,
    destination_id text NOT NULL,
    destination_name text NOT NULL,
    sub_route text,
    sub_route_name text,
    "queueType" text DEFAULT 'REGULAR'::text NOT NULL,
    queue_position integer NOT NULL,
    status text DEFAULT 'WAITING'::text NOT NULL,
    entered_at timestamp(3) without time zone NOT NULL,
    available_seats integer NOT NULL,
    total_seats integer NOT NULL,
    base_price double precision NOT NULL,
    estimated_departure timestamp(3) without time zone,
    actual_departure timestamp(3) without time zone,
    queue_type text DEFAULT 'REGULAR'::text
);


ALTER TABLE public.vehicle_queue OWNER TO ivan;

--
-- Name: vehicle_schedules; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.vehicle_schedules (
    id text NOT NULL,
    vehicle_id text NOT NULL,
    route_id text NOT NULL,
    departure_time timestamp(3) without time zone NOT NULL,
    available_seats integer NOT NULL,
    total_seats integer NOT NULL,
    status text DEFAULT 'SCHEDULED'::text NOT NULL,
    actual_departure timestamp(3) without time zone
);


ALTER TABLE public.vehicle_schedules OWNER TO ivan;

--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: ivan
--

CREATE TABLE public.vehicles (
    id text NOT NULL,
    license_plate text NOT NULL,
    capacity integer DEFAULT 8 NOT NULL,
    phone_number text,
    is_active boolean DEFAULT true NOT NULL,
    is_available boolean DEFAULT true NOT NULL,
    is_banned boolean DEFAULT false NOT NULL,
    default_destination_id text,
    default_destination_name text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT now() NOT NULL,
    available_seats integer DEFAULT 8,
    total_seats integer DEFAULT 8,
    base_price numeric(10,2) DEFAULT 2.00,
    destination_id text,
    destination_name text
);


ALTER TABLE public.vehicles OWNER TO ivan;

--
-- Name: offline_customers id; Type: DEFAULT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.offline_customers ALTER COLUMN id SET DEFAULT nextval('public.offline_customers_id_seq'::regclass);


--
-- Name: operation_logs id; Type: DEFAULT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.operation_logs ALTER COLUMN id SET DEFAULT nextval('public.operation_logs_id_seq'::regclass);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
e5f6ce22-41e3-4762-a384-0d25715aabca	46f4680b70914f874c8471a4d9188c02754e856a4645a88522d1ab4885006266	2025-10-13 06:05:03.349055+01	20251013050502_initial_with_sub_routes	\N	\N	2025-10-13 06:05:02.826863+01	1
3d318a7d-2a8f-4449-9ae3-6894db032373	3fc46ccee2d1705c4d556597cdf1c5942b3e7e9817ce7b647915ebcce2fbfaa6	2025-10-13 13:29:02.037683+01	20251013122901_set_null_bookings_on_queue_delete	\N	\N	2025-10-13 13:29:02.008927+01	1
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.bookings (id, queue_id, seats_booked, total_amount, booking_source, booking_type, sub_route, sub_route_name, booking_status, payment_status, payment_method, payment_processed_at, verification_code, is_verified, verified_at, verified_by_id, cancelled_at, cancelled_by, cancellation_reason, refund_amount, created_offline, local_id, created_by, created_at, updated_at, seat_number, created_by_name) FROM stdin;
405d8bedead357660eaa0b4f	\N	8	16	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	319774	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:21:16.593	2025-10-19 00:21:16.593	1	\N
3137e97021056b217d1d4f0d	\N	2	4	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	733546	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 23:52:29.784	2025-10-16 23:52:29.784	1	\N
6bb93a105dfea8df71646a00	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	567484	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:26:01.94	2025-10-17 00:26:01.94	1	\N
3848012bad1ff75c34327402	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	419766	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:26:01.94	2025-10-17 00:26:01.94	1	\N
4d6bd214-a692-4754-a541-42806492a5e5	\N	2	3.9	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	059d2bac-82fc-4c2c-99bd-719af12d1bbd	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 10:26:19.751	2025-10-13 10:26:19.751	1	\N
9440ac08-1b0b-4f81-af09-9f3b6a355d3c	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	4e39284f-6468-463b-82fa-8fa56e153374	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:43:51.584	2025-10-13 22:43:51.584	1	\N
ba58963f-67ae-4af1-9290-614fdae2f8b9	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	e0704d42-24a5-4252-a4ac-ad9224a0e001	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:46:50.934	2025-10-13 22:46:50.934	1	\N
422707fe-c1e8-418b-9df2-9f6ff25cf6d0	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	e4c4cf4e-9623-4382-8ade-030f14e125ad	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:46:54.767	2025-10-13 22:46:54.767	1	\N
c023fb7c-0b7d-4bdf-95ac-e5be88133fae	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	76f9e914-22d4-4c48-a81f-af574675f45d	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:46:56.384	2025-10-13 22:46:56.384	1	\N
f6ed19b1-6951-4e8f-91b1-4b0c32506f96	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	1bc121bd-a14c-497d-abea-6c9cbe25484f	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:48:40.532	2025-10-13 22:48:40.532	1	\N
3af2d5b0-d76b-42c8-a1ee-10caf46f7b7d	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	b840ffd8-7355-4a89-b997-4786acb6a9f0	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:51:57.158	2025-10-13 22:51:57.158	1	\N
51c305d2-080e-498a-a65c-e11abc09d728	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	d252130c-0505-4efe-a498-2909c246d64f	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 09:59:56.613	2025-10-13 09:59:56.613	1	\N
dfdfe426-d36b-43a5-a644-448007f951c9	\N	2	3.9	CASH_STATION	CASH	SAYADA	SAYADA	ACTIVE	PAID	CASH	\N	2061ac79-a167-4311-babc-3ebde92ec07d	f	\N	\N	\N	\N	\N	\N	f	\N	\N	2025-10-13 06:39:55.585	2025-10-13 06:39:55.585	1	\N
87861282-d104-4129-9238-f7336013e418	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	f6876194-3660-499c-9aa8-cf4467d853c1	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:43:35.87	2025-10-13 22:43:35.87	1	\N
50fcaf3f-dcae-4be2-8315-3169736f1083	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	25c70cf4-7444-4c6b-82d8-ff69c41ec60b	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:51:57.16	2025-10-13 22:51:57.16	1	\N
82c4ca04-2931-4aaf-b000-b2df9d7cabfe	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	74c679d6-e223-47c9-ae7c-a2132192a07b	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:52:11.455	2025-10-13 22:52:11.455	1	\N
7d164dff-ccd2-414f-a881-73ba2ae46831	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	7134d4df-1680-434a-999f-5a4c75f467df	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:52:11.457	2025-10-13 22:52:11.457	1	\N
9269ac47-acce-4b8a-800c-f19891d1e0a7	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	6a39064e-980a-40b3-8266-50bc9ad36792	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:52:26.463	2025-10-13 22:52:26.463	1	\N
124b0f39-da7d-45a6-b316-8f8e444ffbb5	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	99cf0f7b-87fb-4956-965e-4901283cd233	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:54:40.234	2025-10-13 22:54:40.234	1	\N
81c54ace-e81f-4cd2-a7cb-f323efa67242	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	fa1495a1-41b9-4c72-8782-fcabd9b11f6b	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:54:40.235	2025-10-13 22:54:40.235	1	\N
9eec706a-3477-4077-864c-4d6a676b1879	\N	5	9.75	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	1ab657ff-0547-476b-bdc6-9c5123bce65d	f	\N	\N	\N	\N	\N	1.95	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:54:53.568	2025-10-13 22:54:53.568	1	\N
b48230e9-2d98-4613-96b0-372acc5928b6	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	b153fb0b-6598-49a3-bc04-378aadac495f	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:55:15.785	2025-10-13 22:55:15.785	1	\N
8c8a4aac-30b7-4b7a-b896-fd7e78dd4414	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	fe5c352b-52bf-4e9a-943a-5cdf2c06e1cd	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:07.408	2025-10-13 22:57:07.408	1	\N
8d06b218-e4b3-40d5-a5a4-f3c6136d9ad1	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	da555dde-2d2e-4b41-ae02-0d2458d4b805	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:17.983	2025-10-13 22:57:17.983	1	\N
b464b102-1a26-4eed-8876-0e3e89aed1b0	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	caf0cdaf-d63d-4417-964b-6304910917cf	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:32.17	2025-10-13 22:57:32.17	1	\N
59ffa264-6e67-4081-a917-3773e8c84abb	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	d09ace5b-9fa2-46a5-992f-7f80b94fd7be	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:50.206	2025-10-13 22:57:50.206	1	\N
160a94f3-56d2-4745-af88-efeea0341de6	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	e8d0ab60-a8da-44ca-822f-8081fb3d824b	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:54.884	2025-10-13 22:57:54.884	1	\N
895d9206-6c56-4e8a-8572-26be1089e3ad	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	50641854-28fc-49b4-9888-443b568fa6c2	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:57:57.859	2025-10-13 22:57:57.859	1	\N
739e1838-3521-495c-adf0-21a373e586eb	\N	2	3.9	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	7402897f-9fb6-4af0-865a-6dd4d0235159	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:58:15.647	2025-10-13 22:58:15.647	1	\N
fd675cdd-0a7f-48fe-84e1-786a18678a58	\N	6	11.7	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	51cceb00-2122-4a66-99e1-e30a54e3dcac	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:56:27.954	2025-10-13 22:56:27.954	1	\N
c16a0fdd-adca-4b45-bacf-ea7f634bf9b0	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	ceaba529-2c79-4827-b737-64e6a0c9e637	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:56:26.483	2025-10-13 22:56:26.483	1	\N
b5167d6a-716b-4fe5-a64c-9d0927ceace1	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	d864c703-0526-4d75-a9bf-d417691d4f02	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 22:56:26.485	2025-10-13 22:56:26.485	1	\N
9c144232-cadd-41da-8b07-42ff4fe19218	\N	1	2.25	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	64e9e5d1-7b6e-486e-a155-c9482eb141da	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 10:47:01.993	2025-10-13 10:47:01.993	1	\N
d3021d5b-fcad-427d-918e-8cc9f9895da8	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	5d6e187d-0c99-4fa3-b59c-c2f0c2117d6e	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:03:52.63	2025-10-13 23:03:52.63	1	\N
114d4b84-7fef-4b7d-bfbb-5210e44f95f3	\N	5	9.75	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	37afb90b-9e03-4587-963f-ff37da8d42de	f	\N	\N	\N	\N	\N	1.95	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:04:00.675	2025-10-13 23:04:00.675	1	\N
2b7066b8-8d83-4c0d-8d31-268c2ee888c1	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	fdcedba8-0e0b-4822-93dd-3089f4312c29	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:24:21.63	2025-10-13 23:24:21.63	1	\N
dfa3ef2b-2ef3-431c-bc97-f10054e73902	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	b7fe0d37-5757-4129-b473-a11223684eca	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:24:23.574	2025-10-13 23:24:23.574	1	\N
33b06532d2fd66cbfabeee59	\N	7	14	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	646908	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:51:01.088	2025-10-19 00:51:01.088	1	\N
7ef0d5a5-f8ee-40cd-8fcc-da48af796eaa	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	aa559d4c-07b2-46f7-9d66-000b06a7d0dc	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:31:21.145	2025-10-13 23:31:21.145	1	\N
84c1777f-a19e-4d9f-9c02-fe014f9cdc2e	\N	6	12	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	e0e8f4ac-9c66-416d-908b-cc4785af5884	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:31:22.091	2025-10-13 23:31:22.091	1	\N
b13a71de-d3b7-4bec-b3cd-c054eee8c3e2	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	b9596b33-f33e-4843-a4d4-04c0dbe0c7c3	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:31:40.132	2025-10-13 23:31:40.132	1	\N
a6b421f19e90fb4d482fa8f6	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	424624	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:25:22.735	2025-10-17 00:25:22.735	1	\N
578c00d1446a5d24b24c3ff6	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	329773	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:25:22.735	2025-10-17 00:25:22.735	1	\N
1df63eaad6187a983b67cc5c	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	158108	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:18:27.427	2025-10-17 00:18:27.427	1	\N
2450ffc5-e4e7-4bf7-b1b5-d5de7dca48c3	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	e25dac5a-3c61-4230-93b7-490199c44be4	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:38:37.867	2025-10-13 23:38:37.867	1	\N
65a5b2da-8763-4984-a343-01f208e96671	\N	6	12	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	76eaa447-5f69-4245-a098-ccc464fe80ac	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:38:39.013	2025-10-13 23:38:39.013	1	\N
4a077954-8433-47d7-91f7-71b68699a1c0	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	c0fae802-1332-4e1f-8f82-ed52d3aca35e	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-13 23:39:05.531	2025-10-13 23:39:05.531	1	\N
b7669a6071c89987e69d233a	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	952364	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:26:01.94	2025-10-17 00:26:01.94	1	\N
34b19ff541f936c75743a700	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	754290	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:18:50.739	2025-10-17 00:18:50.739	1	\N
c445888edfc5048331208167	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	610557	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
57ba03756838562836d28eed	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	809518	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
5ee5d04e1061fb0a5ab83d85	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	694225	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
ab19499449bfa7380c1cd756	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	914203	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
bee916d3c455461801a03caa	\N	2	3.6	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	254692	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:45:02.484	2025-10-16 05:45:02.484	1	\N
e9d55c47d3e8c5acdd2eb421	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	761402	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:22:57.749	2025-10-15 16:22:57.749	1	\N
2fbcc435a845bf36999ef298	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	813499	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:37:02.509	2025-10-15 16:37:02.509	1	\N
e4cdec479eca223e478cdcf3	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	787142	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:41:48.886	2025-10-15 16:41:48.886	1	\N
9514279b16e73b23862ff552	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	554541	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:47:59.606	2025-10-15 16:47:59.606	1	\N
0db177c7cb01ff2b608f6e6b	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	226840	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:47:59.622	2025-10-15 16:47:59.622	1	\N
be40898c3ac4cc89bafe59ef	\N	1	1.8	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	909028	f	\N	\N	2025-10-15 17:00:49.024	staff_1758995428363_2nhfegsve	test cancel	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:47:59.659	2025-10-15 16:47:59.659	1	\N
082748d8be254ae7146cb6e8	\N	1	1.8	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	040528	f	\N	\N	2025-10-16 17:08:29.491	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:47:59.647	2025-10-15 16:47:59.647	1	\N
9d45ca8bb63cc5d3760aafae	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	925678	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:59:52.854	2025-10-16 05:59:52.854	1	\N
05df5adb77363ab2cabd5346	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	182827	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:59:55.688	2025-10-16 05:59:55.688	1	\N
fb159acd2cbedcdf8ed897e9	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	328595	f	\N	\N	\N	\N	\N	\N	f	\N	staff-001	2025-10-15 15:58:56.722	2025-10-15 15:58:56.722	1	\N
f12ceb602df2e738a60cf03e	\N	2	3.6	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	636077	f	\N	\N	\N	\N	\N	\N	f	\N	staff-001	2025-10-15 15:51:29.911	2025-10-15 15:51:29.911	1	\N
961c60c129ed81c24be45f78	\N	3	5.4	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	577992	f	\N	\N	\N	\N	\N	\N	f	\N	staff-001	2025-10-15 15:53:13.068	2025-10-15 15:53:13.068	1	\N
d06611f6c4882728ba0644ae	\N	1	1.8	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	763057	f	\N	\N	2025-10-15 15:53:13.202	staff-001	test cancel	\N	f	\N	staff-001	2025-10-15 15:53:13.107	2025-10-15 15:53:13.107	1	\N
dea0f60b2eea96d651497090	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	037639	f	\N	\N	\N	\N	\N	\N	f	\N	staff-001	2025-10-15 16:03:36.251	2025-10-15 16:03:36.251	1	\N
b1cfda88d8711dbbd531ad29	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	963791	f	\N	\N	\N	\N	\N	\N	f	\N	staff-001	2025-10-15 16:09:38.536	2025-10-15 16:09:38.536	1	\N
639d5e69e2ccb8239f9efe7d	\N	1	1.8	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	508895	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:13:44.249	2025-10-15 16:13:44.249	1	\N
676a7521581146ad35b8471b	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	180891	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:48:30.442	2025-10-16 05:48:30.442	1	\N
dbb46efd3d38d5fec90e6e5e	\N	1	1.95	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	499869	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:51:01.24	2025-10-16 05:51:01.24	1	\N
817dfc13bb110686926c5df3	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	088715	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:13:05.263	2025-10-16 05:13:05.263	1	\N
aa2cba2b9c6fbd347314deaf	\N	2	4	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	264704	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 05:13:17.129	2025-10-16 05:13:17.129	1	\N
5649993cedc00233db5d5dad	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	869086	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:22:56.218	2025-10-16 06:22:56.218	1	\N
790f059ac652571b840db3e7	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	486567	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:51:33.477	2025-10-19 00:51:33.477	1	\N
3229aabff95c241a9b56d5b4	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	985429	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:46:26.481	2025-10-17 00:46:26.481	1	\N
3ee8ec07316386fec86ed7d7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	023358	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:19:16.911	2025-10-17 00:19:16.911	1	\N
26e7abf22173b26b8b268c28	\N	2	4	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	411155	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 07:40:47.586	2025-10-17 07:40:47.586	1	\N
6d11008960c55ea98682c700	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	613820	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:22:59.198	2025-10-16 06:22:59.198	1	\N
085b60b72153dea889a1cadd	\N	2	4.4	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	438648	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:23:05.752	2025-10-16 06:23:05.752	1	\N
864edcedb8c7fee9429440ab	\N	1	2.2	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	866437	f	\N	\N	2025-10-16 17:12:00.428	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:23:35.276	2025-10-16 06:23:35.276	1	\N
e138209de61c2367f5134b95	\N	1	2.25	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	712931	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:35:35.914	2025-10-16 06:35:35.914	1	\N
7893efb1eb8c38bd83bb84bc	\N	1	2.25	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	889775	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:35:36.592	2025-10-16 06:35:36.592	1	\N
b9c8cc88c26485f334fbb5fc	\N	1	2.25	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	328566	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:35:36.993	2025-10-16 06:35:36.993	1	\N
9f7840b56ab000c7bb82198b	\N	1	2.25	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	370329	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:35:37.206	2025-10-16 06:35:37.206	1	\N
d0f7446b9fab6e890c362a59	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	277506	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:03:32.712	2025-10-18 20:03:32.712	1	\N
be9c0951c0565091ee97ad06	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	890640	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
489ed64b745bfd9968d70cf5	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	329266	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
356016e0b92f8a8c838b1ba5	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	405187	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
fa2faa07a1fec897c37d91ab	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	787428	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
dc09c2f9760deb5d47605f61	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	119985	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
29a7456c22fdcf215b936ff8	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	121671	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
0348b04980206f922981c1bc	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	844776	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
7df196807a1ab7072540d012	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	245336	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	2025-10-18 20:07:44.576	1	\N
25a40b8b5a11edf3014deffd	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	114830	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
93dccc1bf27ba9d7b8e929e7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	344886	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
622db00024231c1927fba7c7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	026311	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
2bbedf42d1835e41d903b989	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	553238	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
324be9404ae9eeae8458b4e9	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	212494	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:03:05.957	2025-10-18 20:03:05.957	1	\N
f7cf0d1dba50581d31d5a9d7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	850792	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
f0a068f74b3f9f6d12307816	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	310306	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
dbbd0b5865a1398d47069709	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	211891	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 21:26:47.661	2025-10-18 21:26:47.661	1	\N
3b994ffc10ba4ddeb65ff363	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	452124	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:04:22.781	2025-10-18 22:04:22.781	1	\N
4769125769e3ff3c54f4d371	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	342821	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:27:56.133	2025-10-18 22:27:56.133	1	\N
fb2882ee629deb0b6b83921b	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	137484	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:36:52.673	2025-10-18 22:36:52.673	1	\N
96ea5079b5a4c49a03770625	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	899117	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:45:16.772	2025-10-18 22:45:16.772	1	\N
36e537a7578971440423a84c	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	520700	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:45:31.695	2025-10-18 22:45:31.695	1	\N
2e8e174de88b84fa2092f687	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	546821	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:11:44.872	2025-10-18 23:11:44.872	1	\N
40d0fa331154f083a911044f	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	127311	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:25:43.213	2025-10-18 23:25:43.213	1	\N
f4f08ed53a583e76092fe711	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	545338	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:45:23.062	2025-10-18 22:45:23.062	1	\N
371eb39683a64754863c6776	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	059843	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:33:52.098	2025-10-18 23:33:52.098	1	\N
d8299da9d8cf7a8bc0b39a68	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	532066	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
8778223d54b24df23179f569	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	681551	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:24:44.033	2025-10-17 00:24:44.033	1	\N
f9a85c22950e01ca4ba6bd41	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	907803	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:24:50.647	2025-10-17 00:24:50.647	1	\N
5fca0a495943112579fab023	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	740235	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 00:49:46.984	2025-10-17 00:49:46.984	1	\N
ec647e4cac824025b8a7d7bf	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	573697	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
87a31af3a09c277bcb55e5b4	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	944860	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	2025-10-18 20:13:18.292	1	\N
b7ae9ab68c530d4f3588d170	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	228127	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-17 08:45:31.263	2025-10-17 08:45:31.263	1	\N
b2d7e5d57765171b90a746b9	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	520755	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
d2b9315fbc6adcb5070a5cfd	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	878583	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	2025-10-18 20:16:46.906	1	\N
d982ef849575952e68f99777	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	523269	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:30:07.034	2025-10-16 06:30:07.034	1	\N
6d55c13b14b5a8949a315ee7	\N	1	1.8	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	444555	f	\N	\N	2025-10-16 17:08:31.496	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-15 16:47:59.636	2025-10-15 16:47:59.636	1	\N
d8daf4938009e022aa670ce0	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	161776	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 06:28:20.733	2025-10-16 06:28:20.733	1	\N
85f2e119ef3326afb23ff08f	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	737920	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 17:12:06.312	2025-10-16 17:12:06.312	1	\N
85b2d8be0359391375699c87	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	627411	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 15:15:04.784	2025-10-16 15:15:04.784	1	\N
f36ea44e0299507cb7b70bf7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	787592	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 15:15:06.087	2025-10-16 15:15:06.087	1	\N
d89d19ddbb579d5de7192ca5	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	359896	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 15:16:11.53	2025-10-16 15:16:11.53	1	\N
baece6d17eff8269852f0208	\N	7	12.25	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	397191	f	\N	\N	2025-10-16 17:11:38.599	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 16:42:58.184	2025-10-16 16:42:58.184	1	\N
f42fa4f5e680976e149a7f9a	\N	1	1.95	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	218081	f	\N	\N	2025-10-16 21:34:57.5	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 17:11:48.754	2025-10-16 17:11:48.754	1	\N
2aadd850038716860f97650b	\N	1	1.95	CASH_STATION	CASH	\N	\N	CANCELLED	PAID	CASH	\N	512258	f	\N	\N	2025-10-16 21:34:58.414	staff_1758995428363_2nhfegsve	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-16 15:12:36.571	2025-10-16 15:12:36.571	1	\N
fc296f5eb33f16107de8bcd5	\N	8	16	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	810669	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 20:20:42.289	2025-10-18 20:20:42.289	1	\N
5b4bbe3b1843a6ef3d82cc36	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	676694	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 21:58:38.35	2025-10-18 21:58:38.35	1	\N
bd95c0e6a84c82d18ac39d3e	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	775945	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:09:20.378	2025-10-18 22:09:20.378	1	\N
9bb30f0dc3b27519e34677e3	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	123989	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:28:38.902	2025-10-18 22:28:38.902	1	\N
14a7e1a6fee8495cb0537aa2	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	030683	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:44:55.753	2025-10-18 22:44:55.753	1	\N
551c7e2209122c2faec42ac1	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	315023	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:54:08.222	2025-10-18 22:54:08.222	1	\N
ea677e130d1f6ccb721e2730	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	997429	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 22:54:35.679	2025-10-18 22:54:35.679	1	\N
c01ecd70cd4e734762d52730	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	870783	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:23:13.12	2025-10-18 23:23:13.12	1	\N
40c711fd55c8d277c5341005	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	037854	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:25:57.077	2025-10-18 23:25:57.077	1	\N
82535f62c64c385b6103f2eb	\N	1	2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	131791	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-18 23:26:05.956	2025-10-18 23:26:05.956	1	\N
80a2ec689f48911da447ae01	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	437658	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:11.94	2025-10-19 00:02:11.94	1	\N
863af36875e14c96c73250fc	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	498897	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:11.94	2025-10-19 00:02:11.94	1	\N
ffce270717352be59a60e3af	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	812771	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:11.94	2025-10-19 00:02:11.94	1	\N
ff7bf61b357a79f058325f43	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	794970	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:11.94	2025-10-19 00:02:11.94	1	\N
85566067b0680111c85f7e64	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	265230	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:11.94	2025-10-19 00:02:11.94	1	\N
6179d814972c375bdbf3615b	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	595400	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:02:40.09	2025-10-19 00:02:40.09	1	\N
e09ddd65558e99601c6d97be	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	346616	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
56d7111eb5bfc77cd7686c8a	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	325514	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
28d00b4d8a653842425d1215	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	619931	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
1ad15d767a8ecc12a16d76a9	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	835824	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
e755b5e1dc4b400b12ff6d2d	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	713592	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
a7a48140b0687c55fbe2358c	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	256807	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:18.695	2025-10-19 00:06:18.695	1	\N
32a298dff237603d2e7e9de7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	162353	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:06:39.123	2025-10-19 00:06:39.123	1	\N
1bfa8664b525b71567b63b87	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	133949	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
534020f255fe5ced79d4dfb7	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	529907	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
f69eca55ca95502ccfda1f69	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	385290	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
54a09f8d2f3a768cc04d4682	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	360203	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
5e9d606b9541387dfcfe2d35	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	509808	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
895dc659a41e1cf50d7480c6	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	116280	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
3d010349507c89c6a95c5ddb	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	476344	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
4cad92fcdf3a03d46865ea42	\N	1	2.2	CASH_STATION	CASH	\N	\N	ACTIVE	PAID	CASH	\N	909466	f	\N	\N	\N	\N	\N	\N	f	\N	staff_1758995428363_2nhfegsve	2025-10-19 00:16:33.737	2025-10-19 00:16:33.737	1	\N
\.


--
-- Data for Name: day_passes; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.day_passes (id, vehicle_id, license_plate, price, purchase_date, valid_from, valid_until, is_active, is_expired, created_by, created_at, updated_at) FROM stdin;
5f316b8e-97ce-42dc-bddd-c9cfd77b6c95	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	2	2025-10-11 18:53:29.716	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 18:53:29.716	2025-10-12 04:48:33.074
bb1e59c1-ada1-4a26-9a76-0f9bfa358180	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	2	2025-10-11 19:04:49.342	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:04:49.342	2025-10-12 04:48:33.074
630b6833-f543-46ee-8d07-e4a0a817f588	c84ba5d0-0ac4-4b61-ba37-e8973889a6b6	121 TUN 9450	2	2025-10-11 19:06:12.498	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:06:12.498	2025-10-12 04:48:33.074
68d6d7a2-0b41-4e30-a907-c9c873a526da	d6257331-1a01-4a8b-9a66-c70addf18f7b	221 TUN 5867	2	2025-10-11 19:21:56.147	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:21:56.147	2025-10-12 04:48:33.074
93cb022e-db28-4f65-a7d9-2f2727e3cf3b	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	2	2025-10-09 18:50:39.623	2025-10-09 00:00:00	2025-10-09 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-09 18:50:39.623	2025-10-10 23:00:00.036
50984530-3628-4b74-8629-9cc17b56bdbe	0ed253e9-6c76-464a-9cc9-6369fa3f119b	184 TUN 1376	2	2025-10-09 18:50:59.099	2025-10-09 00:00:00	2025-10-09 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-09 18:50:59.099	2025-10-10 23:00:00.036
d0d30ae1-7a4c-4613-99dc-9cf495924c81	d6257331-1a01-4a8b-9a66-c70addf18f7b	221 TUN 5867	2	2025-10-09 19:11:29.931	2025-10-09 00:00:00	2025-10-09 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-09 19:11:29.931	2025-10-10 23:00:00.036
26517afc-af26-4a1c-86cf-9c9c9721c52d	c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	2	2025-10-11 19:25:06.261	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:25:06.261	2025-10-12 04:48:33.074
21cc364f-4193-49a2-8e3d-714c283524cb	570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	2	2025-10-11 19:48:47.162	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:48:47.162	2025-10-12 04:48:33.074
7829d909-3683-49e9-9def-74c1792b668f	ab273830-0eae-4c6d-940c-34745e0494c7	218 TUN 1158	2	2025-10-11 19:57:17.008	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 19:57:17.008	2025-10-12 04:48:33.074
5046cc83-bd23-43fe-86c0-dc38c0d35a3f	20568779-4dd7-4dde-8961-356fa6bfbadc	166 TUN 8519	2	2025-10-11 20:05:46.895	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 20:05:46.895	2025-10-12 04:48:33.074
e47a39d5-be7d-4eb3-92f5-22a6f41fe6b2	veh_3135332054554e2031303634	153 TUN 1064	2	2025-10-11 18:26:46.795	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 18:26:46.795	2025-10-12 04:48:33.074
8e9221a0-3cc7-40a1-b106-bc4a283d7595	veh_3132312054554e2039333033	121 TUN 9303	2	2025-10-11 18:42:57.181	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 18:42:57.181	2025-10-12 04:48:33.074
70715c27-9a38-41df-bca7-0e0516d63d60	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	2	2025-10-11 18:48:47.453	2025-10-11 00:00:00	2025-10-11 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-11 18:48:47.453	2025-10-12 04:48:33.074
aad1ef02-7b59-4da0-9b19-a005fc88f271	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	2	2025-10-13 06:55:13.556	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 06:55:13.556	2025-10-13 06:55:13.556
b0c3cd4a-5ce2-43d1-a170-a90ecb033a5b	vehicle_1760251707403_45c6e9gdt	124TUN237	2	2025-10-13 07:34:36.202	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 07:34:36.202	2025-10-13 07:34:36.202
978c5e16-c3c1-4175-93f7-2dac3fc75024	veh_3133302054554e2033313438	130 TUN 3148	2	2025-10-13 22:52:26.473	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 22:52:26.473	2025-10-13 22:52:26.473
dp_1760423328599_uqoabd8td	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	2	2025-10-14 07:28:48.602	2025-10-14 00:00:00	2025-10-14 23:59:59.999	t	f	staff_1758995428363_2nhfegsve	2025-10-14 07:28:48.602	2025-10-14 07:28:48.602
2b284f1f37bca66ed504d81d	a3822825-4ecc-4d6a-892b-ae13706767a3	222 TUN 2222	2	2025-10-15 16:30:08.218	2025-10-15 00:00:00	2025-10-15 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-15 16:30:08.218	2025-10-15 16:30:08.218
c2b1a251faa2f10c97e9c631	veh_3233352054554e2032323238	235 TUN 2228	2	2025-10-16 01:27:02.574	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 01:27:02.574	2025-10-16 01:27:02.574
c4b090a2c995970df0cf8903	veh_3133302054554e2032313636	130 TUN 2166	2	2025-10-16 01:27:16.643	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 01:27:16.643	2025-10-16 01:27:16.643
1bd3ff5e1c0dd10dddf8139f	a01d1105-9e36-4eba-b164-34e2bba4adf8	111 TUN 1111	2	2025-10-16 18:07:33.941	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 18:07:33.941	2025-10-16 18:07:33.941
ca5221829127ab74d440ad97	vehicle_1760251707403_45c6e9gdt	124TUN237	2	2025-10-16 22:36:06.054	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 22:36:06.054	2025-10-16 22:36:06.054
c89e48d9450fe4170eecf710	vehicle_1760251516726_v3xdgeaou	178TUN3446	2	2025-10-16 23:39:30.713	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 23:39:30.713	2025-10-16 23:39:30.713
4a01d438c9ae531707a4a03e	40718af1-8404-4fdd-8914-111d8e393e9c	999 TUN 9999	2	2025-10-16 23:48:22.936	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff-001	2025-10-16 23:48:22.936	2025-10-16 23:48:22.936
737bce4f49757532f37fe088	veh_3134322054554e2032323736	142 TUN 2276	2	2025-10-17 00:01:01.803	2025-10-17 00:00:00	2025-10-17 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-17 00:01:01.803	2025-10-17 00:01:01.803
c844bd3c173e82c096d6e305	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	2	2025-10-17 00:01:26.391	2025-10-17 00:00:00	2025-10-17 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-17 00:01:26.391	2025-10-17 00:01:26.391
d6fe8c018ec9fe456fdb5284	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	2	2025-10-18 00:19:08.622	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 00:19:08.622	2025-10-18 00:19:08.622
6022b298cd6bf313450fff50	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	2	2025-10-18 20:16:17.917	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 20:16:17.917	2025-10-18 20:16:17.917
4484ef427dcac4b731246461	veh_3132362054554e2035303734	126 TUN 5074	2	2025-10-19 00:50:45.227	2025-10-19 00:00:00	2025-10-19 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-19 00:50:45.227	2025-10-19 00:50:45.227
30fef91f-43b8-4eb8-848e-ee4a69e71768	ccb80a37-fc0c-4f3a-8354-8e6e91a11e48	187 TUN 1357	2	2025-10-13 06:59:57.42	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 06:59:57.42	2025-10-13 06:59:57.42
17f986b1-bdc7-453e-b271-aaef4aeac5e7	vehicle_1760249233865_2rdyukkkq	121TUN7184	2	2025-10-13 07:57:53.823	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 07:57:53.823	2025-10-13 07:57:53.823
ad4347c0-7b68-4d61-8470-1d8c7058d3de	10440f4d-acde-4772-8237-0a646d4fd650	252 TUN 5925	2	2025-10-13 23:25:49.302	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 23:25:49.302	2025-10-13 23:25:49.302
dp_1760423328602_pdeo5xd1w	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	2	2025-10-14 07:28:48.604	2025-10-14 00:00:00	2025-10-14 23:59:59.999	t	f	staff_1758995428363_2nhfegsve	2025-10-14 07:28:48.604	2025-10-14 07:28:48.604
1543c4329c1196c9e70fa567	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	2	2025-10-16 18:11:04.494	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 18:11:04.494	2025-10-16 18:11:04.494
9d935fca731473a6f5662339	veh_3132362054554e2035303734	126 TUN 5074	2	2025-10-16 22:48:18.181	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 22:48:18.181	2025-10-16 22:48:18.181
e97c2da53b5406d935963097	8fdf3bef-a3d1-4baf-8ca4-c99b380e4458	888 TUN 8888	2	2025-10-16 23:50:19.38	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff-001	2025-10-16 23:50:19.38	2025-10-16 23:50:19.38
a44f47a6092bf47937292453	veh_3234372054554e2038353536	247 TUN 8556	2	2025-10-17 00:13:19.084	2025-10-17 00:00:00	2025-10-17 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-17 00:13:19.084	2025-10-17 00:13:19.084
24d67318af72531214c09873	a01d1105-9e36-4eba-b164-34e2bba4adf8	111 TUN 1111	2	2025-10-18 00:08:35.504	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff-001	2025-10-18 00:08:35.504	2025-10-18 00:08:35.504
772b0155063a3cb69910d072	veh_3232342054554e2035333333	224 TUN 5333	2	2025-10-18 14:24:31.281	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 14:24:31.281	2025-10-18 14:24:31.281
34cc52ac05175422ee4f64f2	f76e78fc-fd60-4b26-ae9d-a119459aa2a6	243 TUN 3852	2	2025-10-18 14:30:00.731	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 14:30:00.731	2025-10-18 14:30:00.731
91be6870562067381e4ab371	veh_3234342054554e2031333431	244 TUN 1341	2	2025-10-18 20:16:27.014	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 20:16:27.014	2025-10-18 20:16:27.014
2900b8e1dc2062a241b04b35	veh_3132392054554e2032373735	129 TUN 2775	2	2025-10-18 23:46:23.504	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 23:46:23.504	2025-10-18 23:46:23.504
28b6d31f-2d54-4f9a-a53c-9696d000d180	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	2	2025-10-13 07:07:55.417	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 07:07:55.417	2025-10-13 07:07:55.417
b107cae3-001f-431b-b5cc-d077e8a8e0bf	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	2	2025-10-13 10:26:11.223	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 10:26:11.223	2025-10-13 10:26:11.223
bc0290e6-5b4e-4630-94c8-15838def437e	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	2	2025-10-13 23:32:05.82	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 23:32:05.82	2025-10-13 23:32:05.82
dp_1760423478850_iqwwtabiz	a7938b81-2018-4dcf-8456-4d51e8e1aef4	249 TUN 9077	2	2025-10-14 07:31:18.851	2025-10-14 00:00:00	2025-10-14 23:59:59.999	t	f	staff_1758995428363_2nhfegsve	2025-10-14 07:31:18.851	2025-10-14 07:31:18.851
dp_1760423506294_foi2r33ii	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	2	2025-10-14 07:31:46.297	2025-10-14 00:00:00	2025-10-14 23:59:59.999	t	f	staff_1758995428363_2nhfegsve	2025-10-14 07:31:46.297	2025-10-14 07:31:46.297
4287607212209554c2474a1d	veh_3234372054554e2038353536	247 TUN 8556	2	2025-10-16 23:03:23.108	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 23:03:23.108	2025-10-16 23:03:23.108
8b6d673551f21dae7e04759f	eaccda73-0cd4-46f6-9d0e-ad4a3961e453	777 TUN 7777	2	2025-10-17 00:00:12.977	2025-10-17 00:00:00	2025-10-17 23:59:59	t	f	staff-001	2025-10-17 00:00:12.977	2025-10-17 00:00:12.977
be3afe2531525498e9d607fb	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	2	2025-10-18 00:09:21.773	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 00:09:21.773	2025-10-18 00:09:21.773
a26634a32c710cc016b49cde	veh_3230342054554e2037373131	204 TUN 7711	2	2025-10-18 00:09:56.19	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 00:09:56.19	2025-10-18 00:09:56.19
e339c1eb56d518ba0a6c7511	veh_3139312054554e2035323537	191 TUN 5257	2	2025-10-18 20:07:13.103	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 20:07:13.103	2025-10-18 20:07:13.103
d84c9f1fe7027fc833241c72	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	2	2025-10-18 21:26:39.173	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 21:26:39.173	2025-10-18 21:26:39.173
200e7ff4496bfc5b649cb0a5	vehicle_1760418874312_yfjec858a	853TUN5522	2	2025-10-18 21:36:11.179	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 21:36:11.179	2025-10-18 21:36:11.179
5f13e82e82d63162465b52c2	veh_3134352054554e2031303634	145 TUN 1064	2	2025-10-18 21:40:15.965	2025-10-18 00:00:00	2025-10-18 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-18 21:40:15.965	2025-10-18 21:40:15.965
738315e6483b155c664f552a	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	2	2025-10-19 00:21:01.252	2025-10-19 00:00:00	2025-10-19 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-19 00:21:01.252	2025-10-19 00:21:01.252
21e877a5-d330-40c0-a39a-f220c77bc28d	vehicle_1760247734626_cuorwq86x	210TUN4130	2	2025-10-12 06:42:42.624	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 06:42:42.624	2025-10-13 05:18:02.306
fa5b9720-26da-4c35-a26e-69dbad0d33d2	veh_3133322054554e2037323139	132 TUN 7219	2	2025-10-12 06:48:32.234	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 06:48:32.234	2025-10-13 05:18:02.306
ecece58c-cadf-4516-acab-26aea2b3f8b5	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	2	2025-10-12 06:54:59.968	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 06:54:59.968	2025-10-13 05:18:02.306
b14ac43e-20a7-4676-9a51-b4236677eb1b	vehicle_1760249095699_7h62u6flc	193TUN6376	2	2025-10-12 07:05:54.85	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:05:54.85	2025-10-13 05:18:02.306
f4da1916-eea6-4d52-8477-7fde78cbfd39	veh_3134352054554e2031303634	145 TUN 1064	2	2025-10-12 07:06:28.077	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:06:28.077	2025-10-13 05:18:02.306
9243dd76-72ba-4176-b176-04f05a3b5a98	vehicle_1760249233865_2rdyukkkq	121TUN7184	2	2025-10-12 07:07:34.064	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:07:34.064	2025-10-13 05:18:02.306
36006284-1c3e-4562-971b-7a00b23b2b69	veh_3137392054554e2034323934	179 TUN 4294	2	2025-10-12 07:07:48.175	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:07:48.175	2025-10-13 05:18:02.306
925790b6-d756-453c-a11c-350798b14875	vehicle_1760248901989_kkpdqpdp0	247TUN5381	2	2025-10-12 07:08:02.163	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:08:02.163	2025-10-13 05:18:02.306
6b6e2253-34af-4a83-bccb-3f5e4adc17ff	veh_3234342054554e2031333431	244 TUN 1341	2	2025-10-12 07:09:43.4	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:09:43.4	2025-10-13 05:18:02.306
a1d528a7-ea72-43a0-9778-2e55ee19a40d	vehicle_1760249655820_o2w7zbb4b	127TUN2956	2	2025-10-12 07:14:30.06	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:14:30.06	2025-10-13 05:18:02.306
40952c58-e4a9-4bd7-8f3a-1d33fcec13ad	vehicle_1760249733257_lk9zxkckf	224TUN2800	2	2025-10-12 07:16:42.985	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:16:42.985	2025-10-13 05:18:02.306
ff46ed47-e555-43ea-be61-eaeb727346d7	veh_3233392054554e2034373831	239 TUN 4781	2	2025-10-12 07:17:15.436	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:17:15.436	2025-10-13 05:18:02.306
27041b8e-181d-4381-837e-1a91def473d4	veh_3233382054554e2034333232	238 TUN 4322	2	2025-10-12 07:22:39.221	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:22:39.221	2025-10-13 05:18:02.306
90be2c6d-0a78-49e6-bca1-ef83d0a70b42	4ca4bc71-ccb7-4b02-9e30-7a6e74aa5696	255 TUN 4893	2	2025-10-12 07:27:50.739	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:27:50.739	2025-10-13 05:18:02.306
a2ae1a7f-fd84-4995-a3ac-c306c1f709d9	vehicle_1760250959358_yucrp9a2g	166TUN7598	2	2025-10-12 07:36:47.493	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:36:47.493	2025-10-13 05:18:02.306
e59663c1-4e32-4b56-9fee-c9c31d3ca2f9	veh_3233352054554e2033313138	235 TUN 3118	2	2025-10-12 07:37:20.248	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:37:20.248	2025-10-13 05:18:02.306
d08f961d-2b7d-4fc6-9c11-4936fba85d39	vehicle_1760251516726_v3xdgeaou	178TUN3446	2	2025-10-12 07:45:30.5	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:45:30.5	2025-10-13 05:18:02.306
46b3b171-8e6e-46d4-bee8-b710990914b1	vehicle_1760251707403_45c6e9gdt	124TUN0237	2	2025-10-12 07:49:02.738	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:49:02.738	2025-10-13 05:18:02.306
efadb89a-111f-435a-8589-99f659264bef	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	2	2025-10-12 07:53:12.455	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:53:12.455	2025-10-13 05:18:02.306
848db43a-4a4e-40cf-ae4b-b5e2f3ff73a9	veh_3138312054554e2038373936	181 TUN 8796	2	2025-10-12 07:53:21.952	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:53:21.952	2025-10-13 05:18:02.306
e1bb8782-99ee-4c09-ae64-01b2fdc8b695	vehicle_1760251602175_4y0a2r1fm	178TUN1173	2	2025-10-12 07:53:28.566	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 07:53:28.566	2025-10-13 05:18:02.306
347c2503-00c8-4cd1-aee1-10ca9c86bd11	veh_3132362054554e2035303734	126 TUN 5074	2	2025-10-12 08:02:32.893	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:02:32.893	2025-10-13 05:18:02.306
ebf67fea-1620-4ebc-8175-0f25f8c1f916	vehicle_1760252593027_xjlilyx8e	141TUN5692	2	2025-10-12 08:03:35.728	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:03:35.728	2025-10-13 05:18:02.306
3439b016-3ae8-412f-b607-dd7968b7a2ee	veh_3135332054554e2031303634	153 TUN 1064	2	2025-10-12 08:04:40.175	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:04:40.175	2025-10-13 05:18:02.306
86522018-6326-4e83-ad97-f3ab2f77d183	veh_3234392054554e2034303332	249 TUN 4032	2	2025-10-12 08:06:43.506	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:06:43.506	2025-10-13 05:18:02.306
0d211246-ab46-4b50-8282-d1202f0f2484	veh_3234372054554e2038393531	247 TUN 8951	2	2025-10-12 08:14:06.017	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:14:06.017	2025-10-13 05:18:02.306
0a47be64-c305-4430-a900-2d6798ea51d6	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	2	2025-10-12 08:19:09.698	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:19:09.698	2025-10-13 05:18:02.306
8f224b73-6041-44d9-bea8-95784099709d	e31a2351-1d6e-4b4c-b1f4-ae81a9167981	181 TUN 5476	2	2025-10-12 08:24:15.287	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:24:15.287	2025-10-13 05:18:02.306
a77866b7-e1e0-4aa2-8a08-e3602e1ab7dd	14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	2	2025-10-12 08:30:22.754	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:30:22.754	2025-10-13 05:18:02.306
acd00e00-e43d-40a0-b7ff-0e1604ddc9ec	vehicle_1760252392573_ilt6t9ei2	253TUN2817	2	2025-10-12 08:34:29.152	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:34:29.152	2025-10-13 05:18:02.306
3181ed03-f6e9-4613-9489-7bfc809284e9	ab273830-0eae-4c6d-940c-34745e0494c7	218 TUN 1158	2	2025-10-12 08:50:08.182	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:50:08.182	2025-10-13 05:18:02.306
87e18122-5b80-4288-94a5-ce44c851113a	veh_3234392054554e2039373736	249 TUN 9776	2	2025-10-12 08:50:43.498	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:50:43.498	2025-10-13 05:18:02.306
d8bf94b7-6bc5-4c90-895a-9236366e7941	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	2	2025-10-12 08:51:43.824	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:51:43.824	2025-10-13 05:18:02.306
47a778a9-b28b-4ef4-ada6-e45046f1b503	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	2	2025-10-12 08:51:54.593	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:51:54.593	2025-10-13 05:18:02.306
498cdbf7-0a59-4b07-8b6a-83b1e58ad475	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	2	2025-10-12 08:54:29.003	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:54:29.003	2025-10-13 05:18:02.306
f7e96911-5008-4149-88ff-013551989185	veh_3234372054554e2038353536	247 TUN 8556	2	2025-10-12 08:55:09.67	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:55:09.67	2025-10-13 05:18:02.306
c0286db5-b66c-4cf5-b287-b6780b73e811	3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	2	2025-10-12 08:58:59.546	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 08:58:59.546	2025-10-13 05:18:02.306
432c970d-02e1-4401-a303-7d5dfe19d237	vehicle_1760251707403_45c6e9gdt	124TUN237	2	2025-10-12 09:05:15.105	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:05:15.105	2025-10-13 05:18:02.306
d9f805af-2329-4faa-8950-b475b02e9cf6	veh_3136392054554e2037393937	169 TUN 7997	2	2025-10-12 09:07:40.532	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:07:40.532	2025-10-13 05:18:02.306
aa484b98-aa23-4ebf-940a-b050857b5f78	veh_3132392054554e2032373735	129 TUN 2775	2	2025-10-12 09:40:12.527	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:40:12.527	2025-10-13 05:18:02.306
fd0dbfea-046f-430b-8dba-77afdb7a4894	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	2	2025-10-12 09:46:30.187	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:46:30.187	2025-10-13 05:18:02.306
a68bf29c-7c2c-4eec-ba6d-abcc1469839b	veh_3132312054554e2039333033	121 TUN 9303	2	2025-10-12 09:54:59.395	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:54:59.395	2025-10-13 05:18:02.306
56e53b91-45e0-47d4-ad3d-d0766ffb9d35	veh_3234302054554e2037373131	240 TUN 7711	2	2025-10-12 09:56:04.339	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 09:56:04.339	2025-10-13 05:18:02.306
95332183-ddbd-4682-a1bb-4f1435515bc4	veh_3235332054554e2039343138	253 TUN 9418	2	2025-10-12 10:01:57.147	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:01:57.147	2025-10-13 05:18:02.306
e52f7b4c-dacd-4324-b9a0-14175dd504c7	veh_3134302054554e2032363731	140 TUN 2671	2	2025-10-12 10:13:44.24	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:13:44.24	2025-10-13 05:18:02.306
3c53529a-7ee4-45e4-b0c4-ded5ad819e7b	22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	2	2025-10-12 10:13:52.382	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:13:52.382	2025-10-13 05:18:02.306
5da1b329-d42e-455a-b219-958f3728abc7	vehicle_1760260625377_plz85u34c	250TUN7082	2	2025-10-12 10:17:25.741	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:17:25.741	2025-10-13 05:18:02.306
fe6b76b1-cb1c-48cc-94d8-bec563e7742e	veh_3132372054554e2034333739	127 TUN 4379	2	2025-10-12 10:36:07.836	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:36:07.836	2025-10-13 05:18:02.306
71a98bc2-e1ea-4082-bee4-08af021bf43a	5a487488-41bf-4863-9b46-14b51ed931fc	242 TUN 1417	2	2025-10-12 10:41:50.118	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 10:41:50.118	2025-10-13 05:18:02.306
20f1ab98-f70a-4a6a-8ffa-96bdc88c72f7	f76e78fc-fd60-4b26-ae9d-a119459aa2a6	243 TUN 3852	2	2025-10-12 11:01:10.499	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:01:10.499	2025-10-13 05:18:02.306
acbd61e0-2df8-4089-9ed0-b29e732f8f89	b9e3efb0-32f2-4e68-8fbf-c7f032fc7c90	127 TUN 5147	2	2025-10-12 11:05:07.387	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:05:07.387	2025-10-13 05:18:02.306
e20ba342-43b3-4f30-ada7-86b80203d290	veh_3133382054554e2031303234	138 TUN 1024	2	2025-10-12 11:06:44.456	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:06:44.456	2025-10-13 05:18:02.306
839aef26-dd1e-4aad-aa88-3626917f5d9e	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	2	2025-10-12 11:09:06.235	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:09:06.235	2025-10-13 05:18:02.306
674cb0cd-78d9-4a28-b6fb-baa01517998f	veh_3137352054554e2033363732	175 TUN 3672	2	2025-10-12 11:09:17.143	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:09:17.143	2025-10-13 05:18:02.306
32927933-56cf-487d-b634-3aba321f2880	c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	2	2025-10-12 11:14:38.104	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:14:38.104	2025-10-13 05:18:02.306
cf368330-2f98-4517-a775-de034d3daf0a	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	2	2025-10-12 11:17:14.247	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:17:14.247	2025-10-13 05:18:02.306
575319c2-5b59-47bc-a92f-a6aa5d1cff2a	veh_3134322054554e2032323736	142 TUN 2276	2	2025-10-12 11:20:00.789	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:20:00.789	2025-10-13 05:18:02.306
73b69259-9197-4760-adcc-f54f1386a1f7	veh_3235302054554e20363739	250 TUN 679	2	2025-10-12 11:23:09.546	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:23:09.546	2025-10-13 05:18:02.306
cc885f64-3ec4-4244-ab50-567fcc91db0f	b339ef18-7892-48ff-96c8-82df56271eae	251 TUN 7611	2	2025-10-12 11:31:52.503	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:31:52.503	2025-10-13 05:18:02.306
282dd4ad-38ed-41b8-b867-31983ce4d0b3	866ffcfd-be45-46fe-894e-104ac2bd71df	170 TUN 2905	2	2025-10-12 11:49:48.339	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:49:48.339	2025-10-13 05:18:02.306
1df0d04b-1f1f-4206-8422-53463ea52b09	veh_3139342054554e2039333031	194 TUN 9301	2	2025-10-12 11:52:13.328	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:52:13.328	2025-10-13 05:18:02.306
8d9e3558-f5ce-4e43-8e31-3343168b2b52	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	2	2025-10-12 11:58:33.988	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:58:33.988	2025-10-13 05:18:02.306
b23ee394-809c-45d7-8ed0-d4fcb88f1624	428de0a6-be2e-436b-918d-7887419291c0	247 TUN 6296	2	2025-10-12 11:59:22.737	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:59:22.737	2025-10-13 05:18:02.306
d22c03e9-07fb-4588-8db3-ff0826bb883c	0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	2	2025-10-12 11:59:39.303	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:59:39.303	2025-10-13 05:18:02.306
b7e02a01-a4ed-4d03-b3f7-ddf142388a0c	veh_3133302054554e2033313438	130 TUN 3148	2	2025-10-12 11:59:53.234	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 11:59:53.234	2025-10-13 05:18:02.306
0c1450de-4951-4353-a0f7-3aa62721cb1a	570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	2	2025-10-12 12:11:35.229	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:11:35.229	2025-10-13 05:18:02.306
66cca883-6538-413d-8e10-cfbd208b26e3	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	2	2025-10-12 12:16:17.346	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:16:17.346	2025-10-13 05:18:02.306
899f9eac-a44c-4c2a-a9b7-e2e31c03f862	96b8a5b6-6676-45a0-8888-12c6bb9d2910	146 TUN 3509	2	2025-10-12 12:22:41.525	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:22:41.525	2025-10-13 05:18:02.306
ba01b5da-6419-43e0-9c1b-d08df57da6c1	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	2	2025-10-12 12:35:04.953	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:35:04.953	2025-10-13 05:18:02.306
b8a9d81e-6d04-483c-ab6a-e2c5294f1c0a	veh_3133382054554e2035373738	138 TUN 5778	2	2025-10-12 12:39:40.175	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:39:40.175	2025-10-13 05:18:02.306
1687fd36-47be-41b0-b2b1-9a34c01c6edc	veh_3233332054554e2036363831	233 TUN 6681	2	2025-10-12 12:50:11.149	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:50:11.149	2025-10-13 05:18:02.306
7902b5c4-c561-4fe5-a815-7d4efe2e346d	veh_3232342054554e2035333333	224 TUN 5333	2	2025-10-12 12:50:33.622	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:50:33.622	2025-10-13 05:18:02.306
62f07073-8e86-4fa7-8c3c-b134e68bb460	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	2	2025-10-12 12:53:44.089	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 12:53:44.089	2025-10-13 05:18:02.306
574b3b8d-5aae-4d64-b4b7-12b585264dcc	veh_3230342054554e2037373131	204 TUN 7711	2	2025-10-12 13:09:18.978	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:09:18.978	2025-10-13 05:18:02.306
b3e82104-6743-4538-9a2c-66ad9fd8320c	4bb4a12b-8571-4cc4-aa9b-c460a878cada	242 TUN 7358	2	2025-10-12 13:11:28.63	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:11:28.63	2025-10-13 05:18:02.306
18dd8a52-25dd-464b-b8a9-d6aed3a68fbc	20568779-4dd7-4dde-8961-356fa6bfbadc	166 TUN 8519	2	2025-10-12 13:19:40.706	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:19:40.706	2025-10-13 05:18:02.306
c9639bba-3206-47e5-b7af-e4ada39e4bce	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	2	2025-10-12 13:20:25.865	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:20:25.865	2025-10-13 05:18:02.306
772b33b8-c7d7-4558-938f-90ccc5b25835	veh_3139332054554e2035333736	193 TUN 5376	2	2025-10-12 13:33:16.609	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:33:16.609	2025-10-13 05:18:02.306
5bbea20e-b9cc-480d-b841-0c8adb7b75fb	a827ab5f-fffd-4e01-b50d-378c4f61f615	180 TUN 3276	2	2025-10-12 13:51:48.508	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 13:51:48.508	2025-10-13 05:18:02.306
6b3d0277-9ab5-4fb0-9c5f-070261888d8b	456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	2	2025-10-12 14:17:38.699	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 14:17:38.699	2025-10-13 05:18:02.306
04f8e703-4f19-42a8-b90b-35c4c23a473f	00784611-53e2-498b-b30b-778e5376efac	225 TUN 458	2	2025-10-12 14:20:22.662	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 14:20:22.662	2025-10-13 05:18:02.306
cf155cf9-673e-49f4-9194-e9a83fdeb28e	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	210 TUN 4130	2	2025-10-12 15:00:40.342	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:00:40.342	2025-10-13 05:18:02.306
fc74416f-cbeb-473f-bc14-4f30934cb49d	128f10f5-5bdc-4cac-b165-96c2fefeca6c	243 TUN 4358	2	2025-10-12 15:09:01.848	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:09:01.848	2025-10-13 05:18:02.306
4cc100da-d0eb-4a06-b9cd-178bb6ab6213	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	2	2025-10-12 15:09:35.721	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:09:35.721	2025-10-13 05:18:02.306
8f5c2c2d-9438-4ce8-8960-7028820cd276	24bd242e-9ed7-41dd-91e4-e91290118db6	253 TUN 6900	2	2025-10-12 15:20:28.518	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:20:28.518	2025-10-13 05:18:02.306
edb99a28-ec68-4cb4-9d86-f72518e8dff5	ccb80a37-fc0c-4f3a-8354-8e6e91a11e48	187 TUN 1357	2	2025-10-12 15:21:06.783	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:21:06.783	2025-10-13 05:18:02.306
015cfb2b-3885-4a4e-85c1-46c59b7fb317	d084e91a-df8b-4f8d-a3a9-f09b74395a85	233 TUN 7278	2	2025-10-12 15:42:00.182	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:42:00.182	2025-10-13 05:18:02.306
6e8050c7-106e-436e-82da-c7f6f5784b39	veh_3233372054554e2038333430	237 TUN 8340	2	2025-10-12 15:46:48.595	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:46:48.595	2025-10-13 05:18:02.306
20298f22-8bd1-4f16-9a89-f9efc00dfb81	1e792121-0a50-429a-bfe8-7e1a0e8c1ab6	225 TUN 5376	2	2025-10-12 15:50:22.766	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:50:22.766	2025-10-13 05:18:02.306
79758b66-ae51-482e-86a9-f4d6b7564bfe	a7938b81-2018-4dcf-8456-4d51e8e1aef4	249 TUN 9077	2	2025-10-12 15:56:37.683	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:56:37.683	2025-10-13 05:18:02.306
d74b61a8-7473-4f39-a927-faf1ccb76593	e7795446-726f-43f7-bb34-aba040be0bde	182 TUN 7866	2	2025-10-12 15:58:45.067	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 15:58:45.067	2025-10-13 05:18:02.306
97587c84-44d2-41ed-a594-aa9a10012edb	4d000425-8615-4b20-9648-2052e3776b49	178 TUN 7005	2	2025-10-12 16:48:12.377	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 16:48:12.377	2025-10-13 05:18:02.306
d8edac86-5d0c-4491-b6fe-fbfd0c06fdc9	015afe3a-3526-42fc-a9ae-4d963be711c0	130 TUN 2221	2	2025-10-12 17:12:57.722	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 17:12:57.722	2025-10-13 05:18:02.306
3fda0292-2ff7-4d15-850b-0b66a03d1e1e	068fea9c-279a-4df3-a497-2dde7cc6e9d0	203 TUN 2938	2	2025-10-12 17:13:54.788	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 17:13:54.788	2025-10-13 05:18:02.306
9f034cae-06fa-4ebf-a3f8-60969e21b7be	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	2	2025-10-12 17:15:21.562	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 17:15:21.562	2025-10-13 05:18:02.306
8a7cac02-5a0b-4747-9d35-99083fd3f5a1	veh_3232372054554e2034333739	227 TUN 4379	2	2025-10-12 17:44:02.135	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 17:44:02.135	2025-10-13 05:18:02.306
c0ccb46c-3f5a-4775-94a1-1d6c51fd846c	10440f4d-acde-4772-8237-0a646d4fd650	252 TUN 5925	2	2025-10-12 17:57:40.44	2025-10-12 00:00:00	2025-10-12 23:59:59	f	t	staff_1758995428363_2nhfegsve	2025-10-12 17:57:40.44	2025-10-13 05:18:02.306
589378a6-bce9-4d4b-9312-4e05b891e023	d084e91a-df8b-4f8d-a3a9-f09b74395a85	233 TUN 7278	2	2025-10-13 07:25:11.461	2025-10-13 00:00:00	2025-10-13 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-13 07:25:11.461	2025-10-13 07:25:11.461
73f927561ca73291ec378a6c	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	2	2025-10-16 23:15:45.299	2025-10-16 00:00:00	2025-10-16 23:59:59	t	f	staff_1758995428363_2nhfegsve	2025-10-16 23:15:45.299	2025-10-16 23:15:45.299
\.


--
-- Data for Name: exit_passes; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.exit_passes (id, queue_id, vehicle_id, license_plate, destination_id, destination_name, current_exit_time, created_by, created_at, total_price) FROM stdin;
c931626b-fa83-46e9-b005-87791479bcb9	\N	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	station-bekalta	BEKALTA	2025-10-09 17:39:27.344	staff_1759175419713_ib5c2pncz	2025-10-09 17:39:27.344	0.00
2448fb52-e7ec-463b-bb3b-3077ed9e2fb2	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-09 17:46:22.363	staff_1759175419713_ib5c2pncz	2025-10-09 17:46:22.363	0.00
dad56a86-f1cd-4108-a008-de827b4736f3	\N	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	station-jemmal	JEMMAL	2025-10-09 17:49:20.493	staff_1759175419713_ib5c2pncz	2025-10-09 17:49:20.493	0.00
05fa80c0-fc87-4c82-99c4-28b0a1d1c45c	\N	veh_3138322054554e2035303133	182 TUN 5013	station-ksar-hlel	KSAR HLEL	2025-10-09 18:18:59.447	staff_1758995428363_2nhfegsve	2025-10-09 18:18:59.447	0.00
d5fe0a02-5bed-4e69-b2e2-f93c5232e458	\N	veh_3133302054554e2033313438	130 TUN 3148	station-ksar-hlel	KSAR HLEL	2025-10-09 18:21:19.983	staff_1758995428363_2nhfegsve	2025-10-09 18:21:19.983	0.00
71746d40-5d5e-48e6-994d-897a98883330	\N	veh_3132312054554e2039333033	121 TUN 9303	station-ksar-hlel	KSAR HLEL	2025-10-07 18:18:23.304	staff_1759175419713_ib5c2pncz	2025-10-07 18:18:23.304	0.00
a5ac4a09-1193-49e6-9f15-82a465270422	\N	def04ebe-4c4a-4af4-8db1-b16b26c38331	252 TUN 471	station-jemmal	JEMMAL	2025-10-07 18:19:10.222	staff_1759175419713_ib5c2pncz	2025-10-07 18:19:10.222	0.00
ece2772a-4931-4722-9a30-cd73abf8b9c1	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-07 18:24:19.833	staff_1759175419713_ib5c2pncz	2025-10-07 18:24:19.833	0.00
6d13c838-b476-4277-82f1-a758e1088236	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-07 19:45:45.639	staff_1759175419713_ib5c2pncz	2025-10-07 19:45:45.639	0.00
aec5b60a-706d-40c9-80bb-32ffbc2c0da8	\N	d6257331-1a01-4a8b-9a66-c70addf18f7b	221 TUN 5867	station-bekalta	BEKALTA	2025-10-09 17:22:49.2	staff_1759175419713_ib5c2pncz	2025-10-09 17:22:49.2	0.00
30a39df4-48e6-41f3-a200-81b119aec8ca	\N	20568779-4dd7-4dde-8961-356fa6bfbadc	166 TUN 8519	station-bekalta	BEKALTA	2025-10-09 17:33:15.893	staff_1759175419713_ib5c2pncz	2025-10-09 17:33:15.893	0.00
74ca1a72-c57c-4f1b-b512-49f5bbe4627b	\N	0ed253e9-6c76-464a-9cc9-6369fa3f119b	184 TUN 1376	station-jemmal	JEMMAL	2025-10-09 17:37:44.738	staff_1759175419713_ib5c2pncz	2025-10-09 17:37:44.738	0.00
68cf6aa8-299b-4b48-9e0c-fa07f941d6d0	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-09 18:28:27.391	staff_1758995428363_2nhfegsve	2025-10-09 18:28:27.391	0.00
c6c753d5-793d-42ba-b1e8-18047143ede0	\N	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	station-jemmal	JEMMAL	2025-10-11 18:27:12.935	staff_1758995428363_2nhfegsve	2025-10-11 18:27:12.935	0.00
e7fde266-a10e-4bcd-b187-5c0dcff27db9	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-11 18:39:28.123	staff_1758995428363_2nhfegsve	2025-10-11 18:39:28.123	0.00
dab43f84-1abf-46e6-aecb-af08b24815b2	\N	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	station-jemmal	JEMMAL	2025-10-11 18:44:07.878	staff_1758995428363_2nhfegsve	2025-10-11 18:44:07.878	0.00
6bbf133d-9eaa-44d0-8f15-d92c70c69ec5	\N	veh_3132312054554e2039333033	121 TUN 9303	station-ksar-hlel	KSAR HLEL	2025-10-11 18:44:11.263	staff_1758995428363_2nhfegsve	2025-10-11 18:44:11.263	0.00
84b6f190-08af-47e1-909e-54b67bcda634	\N	veh_3134352054554e2031303634	145 TUN 1064	station-moknin	MOKNIN	2025-10-11 18:44:53.619	staff_1758995428363_2nhfegsve	2025-10-11 18:44:53.619	0.00
065b4e93-a194-4008-9af8-6d9a00672bcb	\N	veh_3132372054554e2034333739	127 TUN 4379	station-teboulba	TEBOULBA	2025-10-11 18:45:01.419	staff_1758995428363_2nhfegsve	2025-10-11 18:45:01.419	0.00
38f1fc17-37b3-4f11-b73a-1d15e26714e8	\N	c84ba5d0-0ac4-4b61-ba37-e8973889a6b6	121 TUN 9450	station-jemmal	JEMMAL	2025-10-11 19:09:43.334	staff_1758995428363_2nhfegsve	2025-10-11 19:09:43.334	0.00
44b49015-03bf-45db-bf93-1a06169cf9b1	\N	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	station-jemmal	JEMMAL	2025-10-11 19:20:50.083	staff_1759175419713_ib5c2pncz	2025-10-11 19:20:50.083	0.00
10a0b4a8-7ab8-4793-924e-82d2f11fc6ab	\N	veh_3133322054554e2037323139	132 TUN 7219	station-moknin	MOKNIN	2025-10-12 06:50:20.448	staff_1760247642213_in7dp0fty	2025-10-12 06:50:20.448	0.00
4a4fa0cb-d091-430a-81bb-55bba6b21efc	\N	vehicle_1760247734626_cuorwq86x	210TUN4130	station-teboulba	TEBOULBA	2025-10-12 06:58:37.726	staff_1760247605348_8h4p63gzo	2025-10-12 06:58:37.726	0.00
1fde5308-e2dc-4c9f-8d53-0e5538b957d4	\N	veh_3133322054554e2037323139	132 TUN 7219	station-moknin	MOKNIN	2025-10-12 07:03:58.664	staff_1760209249802_llckjlapc	2025-10-12 07:03:58.664	0.00
f42d27a1-0255-4619-8bb7-182a84e72365	\N	vehicle_1760249095699_7h62u6flc	193TUN6376	station-ksar-hlel	KSAR HLEL	2025-10-12 07:26:31.26	staff_1760209249802_llckjlapc	2025-10-12 07:26:31.26	0.00
b3815c11-6e4b-4f8e-89f6-35d71faf02a2	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 07:29:34.465	staff_1760247642213_in7dp0fty	2025-10-12 07:29:34.465	0.00
2098ed4c-7bd6-433c-bbc3-0a998d80380d	\N	vehicle_1760249655820_o2w7zbb4b	127TUN2956	station-jemmal	JEMMAL	2025-10-12 07:39:32.852	staff_1760247642213_in7dp0fty	2025-10-12 07:39:32.852	0.00
6168da13-23a9-4201-bfef-e6926356b8f2	\N	veh_3134352054554e2031303634	145 TUN 1064	station-moknin	MOKNIN	2025-10-12 07:41:32.847	staff_1760209249802_llckjlapc	2025-10-12 07:41:32.847	0.00
39e3a886-cd4e-465f-81da-b055b230150a	\N	vehicle_1760249233865_2rdyukkkq	121TUN7184	station-ksar-hlel	KSAR HLEL	2025-10-12 07:50:51.432	staff_1760209249802_llckjlapc	2025-10-12 07:50:51.432	0.00
cec85d4f-6ef0-4ab6-a18f-1b3ab9913e79	\N	vehicle_1760249733257_lk9zxkckf	224TUN2800	station-jemmal	JEMMAL	2025-10-12 07:56:15.84	staff_1760247642213_in7dp0fty	2025-10-12 07:56:15.84	0.00
d23fcbb7-9f6c-4a7c-b6a4-6abb63981b49	\N	veh_3233382054554e2034333232	238 TUN 4322	station-jemmal	JEMMAL	2025-10-12 08:10:06.703	staff_1760247642213_in7dp0fty	2025-10-12 08:10:06.703	0.00
e312b544-3444-4c9b-924d-8ee04a9a3be2	\N	vehicle_1760251516726_v3xdgeaou	178TUN3446	station-teboulba	TEBOULBA	2025-10-12 08:11:25.791	staff_1760247605348_8h4p63gzo	2025-10-12 08:11:25.791	0.00
1f7f2eb8-5974-4530-a804-c4e999cbc068	\N	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	station-jemmal	JEMMAL	2025-10-12 08:16:13.598	staff_1760247642213_in7dp0fty	2025-10-12 08:16:13.598	0.00
c2c7bc1a-e640-49d6-a38d-d2374dd3a3af	\N	veh_3137392054554e2034323934	179 TUN 4294	station-ksar-hlel	KSAR HLEL	2025-10-12 08:17:29.486	staff_1760209249802_llckjlapc	2025-10-12 08:17:29.486	0.00
0b1e0322-1286-4c8d-915b-8d6a61a0d310	\N	vehicle_1760248901989_kkpdqpdp0	247TUN5381	station-ksar-hlel	KSAR HLEL	2025-10-12 08:20:12.564	staff_1760209249802_llckjlapc	2025-10-12 08:20:12.564	0.00
553ba49a-a5dd-485c-9d87-ec61dfff4963	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-moknin	MOKNIN	2025-10-12 08:20:23.373	staff_1760209249802_llckjlapc	2025-10-12 08:20:23.373	0.00
3d53c256-a273-4b8f-8708-1dc09e87dfb1	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 08:24:17.036	staff_1760209249802_llckjlapc	2025-10-12 08:24:17.036	0.00
72fe23f4-b109-41b1-9c70-fde38adb3abd	\N	veh_3138312054554e2038373936	181 TUN 8796	station-jemmal	JEMMAL	2025-10-12 08:30:02.975	staff_1760247642213_in7dp0fty	2025-10-12 08:30:02.975	0.00
c6f5ce2b-e78e-42be-bee9-6b6a61749379	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 08:47:54.318	staff_1760209249802_llckjlapc	2025-10-12 08:47:54.318	0.00
3e67162a-8d7d-419a-86b2-6c2cb92d1df3	\N	vehicle_1760252392573_ilt6t9ei2	253TUN2817	station-jemmal	JEMMAL	2025-10-12 08:54:39.737	staff_1760247642213_in7dp0fty	2025-10-12 08:54:39.737	0.00
ea29717f-fd1c-4a55-afdd-c190538adc19	\N	veh_3233352054554e2033313138	235 TUN 3118	station-ksar-hlel	KSAR HLEL	2025-10-12 08:58:40.823	staff_1760209249802_llckjlapc	2025-10-12 08:58:40.823	0.00
aaaa5c6c-a474-4132-aafc-e297fc9ba9cb	\N	vehicle_1760251707403_45c6e9gdt	124TUN237	station-ksar-hlel	KSAR HLEL	2025-10-12 08:58:44.893	staff_1760209249802_llckjlapc	2025-10-12 08:58:44.893	0.00
0f3c0aa3-f4ff-457d-98e5-47666d77b0bb	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 08:58:47.71	staff_1760209249802_llckjlapc	2025-10-12 08:58:47.71	0.00
b284d52b-c6df-4135-8eea-28e34b310a80	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 09:07:13.382	staff_1760247642213_in7dp0fty	2025-10-12 09:07:13.382	0.00
a09ae924-1df1-4ac6-bbf2-ab7db430fe84	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 09:10:30.612	staff_1760209249802_llckjlapc	2025-10-12 09:10:30.612	0.00
44517de3-28b4-499b-b17e-75f0cd31ea94	\N	vehicle_1760251707403_45c6e9gdt	124TUN237	station-ksar-hlel	KSAR HLEL	2025-10-12 09:10:50.545	staff_1760209249802_llckjlapc	2025-10-12 09:10:50.545	0.00
1a6f60de-3f83-4a8d-b032-15413f24f425	\N	veh_3234392054554e2039373736	249 TUN 9776	station-moknin	MOKNIN	2025-10-12 09:17:48.701	staff_1760209249802_llckjlapc	2025-10-12 09:17:48.701	0.00
41255bcf-f712-413f-be1a-1b4634b848e1	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 09:20:55.317	staff_1760247642213_in7dp0fty	2025-10-12 09:20:55.317	0.00
2df9162b-9501-4c66-a4b6-bd9b6ddae574	\N	14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	station-moknin	MOKNIN	2025-10-12 09:21:32.557	staff_1760209249802_llckjlapc	2025-10-12 09:21:32.557	0.00
60896563-a947-49e6-936f-6ce876b63b73	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 09:22:36.287	staff_1760247642213_in7dp0fty	2025-10-12 09:22:36.287	0.00
31583307-f1fc-456b-9ae6-898ec753f4ea	\N	veh_3234372054554e2038393531	247 TUN 8951	station-jemmal	JEMMAL	2025-10-12 09:27:33.681	staff_1760247642213_in7dp0fty	2025-10-12 09:27:33.681	0.00
3297bec9-6864-4dbc-82bc-b7db9436aedc	\N	veh_3234372054554e2038353536	247 TUN 8556	station-moknin	MOKNIN	2025-10-12 09:32:44.904	staff_1760209249802_llckjlapc	2025-10-12 09:32:44.904	0.00
684b46a6-5859-45cb-98fa-51547e6db3bf	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 09:33:08.459	staff_1760247642213_in7dp0fty	2025-10-12 09:33:08.459	0.00
58e0360d-ada7-4857-b02d-5e24b9316553	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-ksar-hlel	KSAR HLEL	2025-10-12 09:42:40.424	staff_1760209249802_llckjlapc	2025-10-12 09:42:40.424	0.00
1c8ba5fe-896f-462e-89a8-04e0ea058c80	\N	4ca4bc71-ccb7-4b02-9e30-7a6e74aa5696	255 TUN 4893	station-moknin	MOKNIN	2025-10-12 09:48:25.904	staff_1760209249802_llckjlapc	2025-10-12 09:48:25.904	0.00
3bae77e9-753e-40b5-805a-cbfd86a75662	\N	veh_3136392054554e2037393937	169 TUN 7997	station-teboulba	TEBOULBA	2025-10-12 09:48:46.722	staff_1760247605348_8h4p63gzo	2025-10-12 09:48:46.722	0.00
5a667123-39ed-4fab-a2c2-5b075db1650f	\N	ab273830-0eae-4c6d-940c-34745e0494c7	218 TUN 1158	station-jemmal	JEMMAL	2025-10-12 09:49:17.605	staff_1760247642213_in7dp0fty	2025-10-12 09:49:17.605	0.00
951009bd-8453-4965-8cb6-e5edcb3b45f1	\N	vehicle_1760249095699_7h62u6flc	193TUN6376	station-moknin	MOKNIN	2025-10-12 09:52:41.313	staff_1760209249802_llckjlapc	2025-10-12 09:52:41.313	0.00
44aa117b-4ed0-4784-a711-96da1e07dcc5	\N	veh_3133322054554e2037323139	132 TUN 7219	station-moknin	MOKNIN	2025-10-12 09:52:45.704	staff_1760209249802_llckjlapc	2025-10-12 09:52:45.704	0.00
45d99873-9704-4c4a-bf46-946a3ece649d	\N	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	station-jemmal	JEMMAL	2025-10-12 09:56:20.886	staff_1760247642213_in7dp0fty	2025-10-12 09:56:20.886	0.00
ee7b108b-1550-4ff6-9f0c-88676c9acc8a	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 09:59:28.214	staff_1760247642213_in7dp0fty	2025-10-12 09:59:28.214	0.00
a33baf74-482a-4069-8db1-01997474f120	\N	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	station-jemmal	JEMMAL	2025-10-12 10:11:36.246	staff_1760247642213_in7dp0fty	2025-10-12 10:11:36.246	0.00
322c4196-0311-4f1d-94da-1a01a38a4e94	\N	veh_3132312054554e2039333033	121 TUN 9303	station-ksar-hlel	KSAR HLEL	2025-10-12 10:12:20.434	staff_1760209249802_llckjlapc	2025-10-12 10:12:20.434	0.00
d39dc7b6-c4c0-43d0-8679-c31d4190faa1	\N	vehicle_1760252593027_xjlilyx8e	141TUN5692	station-ksar-hlel	KSAR HLEL	2025-10-12 10:12:45.432	staff_1760209249802_llckjlapc	2025-10-12 10:12:45.432	0.00
961b78e0-7221-4787-a649-a3b4bc852ea4	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 10:18:36.442	staff_1760247642213_in7dp0fty	2025-10-12 10:18:36.442	0.00
93b088b7-5001-4c25-8a19-d4c15d70e7d8	\N	vehicle_1760249655820_o2w7zbb4b	127TUN2956	station-jemmal	JEMMAL	2025-10-12 10:22:54.856	staff_1760247642213_in7dp0fty	2025-10-12 10:22:54.856	0.00
f9dbba0d-a548-40c9-9086-036e8110ff0a	\N	3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	station-jemmal	JEMMAL	2025-10-12 10:27:07.006	staff_1760247642213_in7dp0fty	2025-10-12 10:27:07.006	0.00
37d8bdad-2c5b-49fe-9ed7-7ded7730a3fe	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 10:28:32.651	staff_1760209249802_llckjlapc	2025-10-12 10:28:32.651	0.00
afad8efb-7085-4de1-878f-af7330d48382	\N	22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	station-ksar-hlel	KSAR HLEL	2025-10-12 10:30:13.028	staff_1760209249802_llckjlapc	2025-10-12 10:30:13.028	0.00
0d429959-0e32-40d3-b26a-5698b3eade5a	\N	veh_3233382054554e2034333232	238 TUN 4322	station-jemmal	JEMMAL	2025-10-12 10:30:25.253	staff_1760247642213_in7dp0fty	2025-10-12 10:30:25.253	0.00
32f1c651-bc84-45cc-ab21-7dc324715001	\N	veh_3132392054554e2032373735	129 TUN 2775	station-jemmal	JEMMAL	2025-10-12 10:36:18.652	staff_1760247642213_in7dp0fty	2025-10-12 10:36:18.652	0.00
cd15f7e3-da8e-46a7-9bd0-577ce6e6a640	\N	veh_3133322054554e2037323139	132 TUN 7219	station-moknin	MOKNIN	2025-10-12 10:39:21.308	staff_1760209249802_llckjlapc	2025-10-12 10:39:21.308	0.00
515efd26-f562-4c62-b37e-9c7eb79ea32b	\N	veh_3137392054554e2034323934	179 TUN 4294	station-ksar-hlel	KSAR HLEL	2025-10-12 10:41:46.498	staff_1760209249802_llckjlapc	2025-10-12 10:41:46.498	0.00
e60a061f-14bb-4075-b9d1-2727ba6b3762	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-moknin	MOKNIN	2025-10-12 10:43:57.657	staff_1760209249802_llckjlapc	2025-10-12 10:43:57.657	0.00
51c526f4-89ae-4c31-9110-17d818772fbb	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 10:44:56.097	staff_1760209249802_llckjlapc	2025-10-12 10:44:56.097	0.00
e7cc65bc-3c79-45de-8528-472e1f261c80	\N	vehicle_1760248901989_kkpdqpdp0	247TUN5381	station-ksar-hlel	KSAR HLEL	2025-10-12 10:45:00.294	staff_1760209249802_llckjlapc	2025-10-12 10:45:00.294	0.00
ab699b70-3edd-4b8a-a1b1-024b99dbb654	\N	vehicle_1760249233865_2rdyukkkq	121TUN7184	station-ksar-hlel	KSAR HLEL	2025-10-12 10:45:04.174	staff_1760209249802_llckjlapc	2025-10-12 10:45:04.174	0.00
3292343f-19ae-4606-93a8-fe80abb09305	\N	veh_3234302054554e2037373131	240 TUN 7711	station-teboulba	TEBOULBA	2025-10-12 10:49:02.939	staff_1760247605348_8h4p63gzo	2025-10-12 10:49:02.939	0.00
e1f0c66b-ce96-4507-aafe-bd830a1bfa1e	\N	veh_3138312054554e2038373936	181 TUN 8796	station-jemmal	JEMMAL	2025-10-12 10:52:29.866	staff_1760247642213_in7dp0fty	2025-10-12 10:52:29.866	0.00
43e383f6-4ab1-428e-8ffe-cb230bcfc055	\N	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	station-jemmal	JEMMAL	2025-10-12 10:56:16.136	staff_1760247642213_in7dp0fty	2025-10-12 10:56:16.136	0.00
5e2aa034-21b9-4d8a-b115-df7b5c9d81dd	\N	veh_3233352054554e2033313138	235 TUN 3118	station-ksar-hlel	KSAR HLEL	2025-10-12 11:00:31.49	staff_1760209249802_llckjlapc	2025-10-12 11:00:31.49	0.00
91354cc2-31ba-4ca8-b847-43e0d0faa777	\N	vehicle_1760252392573_ilt6t9ei2	253TUN2817	station-jemmal	JEMMAL	2025-10-12 11:02:00.695	staff_1760247642213_in7dp0fty	2025-10-12 11:02:00.695	0.00
4fc35711-716c-4205-b010-843602d4d712	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 11:02:16.218	staff_1760209249802_llckjlapc	2025-10-12 11:02:16.218	0.00
494aaf0d-7d38-4503-93d1-f41dcb7c2ba5	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 11:06:11.687	staff_1760209249802_llckjlapc	2025-10-12 11:06:11.687	0.00
54d7c738-8e26-4ce7-aa47-a955d874b0b8	\N	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	station-jemmal	JEMMAL	2025-10-12 11:07:47.182	staff_1760247642213_in7dp0fty	2025-10-12 11:07:47.182	0.00
598e4d74-30af-4129-922e-8c22c13b9cc3	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 11:12:30.098	staff_1760247642213_in7dp0fty	2025-10-12 11:12:30.098	0.00
35230a85-a516-4667-80b7-43ede8b772b7	\N	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	station-ksar-hlel	KSAR HLEL	2025-10-12 11:13:33.89	staff_1760209249802_llckjlapc	2025-10-12 11:13:33.89	0.00
726cafcc-2c88-4e48-a4e1-bfd14c251fd6	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 11:15:54.437	staff_1760209249802_llckjlapc	2025-10-12 11:15:54.437	0.00
e396617e-148a-448e-ab39-37689561c8eb	\N	b9e3efb0-32f2-4e68-8fbf-c7f032fc7c90	127 TUN 5147	station-moknin	MOKNIN	2025-10-12 11:21:01.352	staff_1760209249802_llckjlapc	2025-10-12 11:21:01.352	0.00
71271923-ee37-4475-843c-bebba4db822a	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 11:21:16.665	staff_1760247642213_in7dp0fty	2025-10-12 11:21:16.665	0.00
de91f666-0eac-4a2c-9f0c-e465532810f5	\N	5a487488-41bf-4863-9b46-14b51ed931fc	242 TUN 1417	station-jemmal	JEMMAL	2025-10-12 11:25:27.636	staff_1760247642213_in7dp0fty	2025-10-12 11:25:27.636	0.00
87811d77-764e-493c-8500-ab1daf9e85a4	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-ksar-hlel	KSAR HLEL	2025-10-12 11:27:05.69	staff_1760209249802_llckjlapc	2025-10-12 11:27:05.69	0.00
fbb58607-3088-46fd-9d24-0a19b48b094f	\N	veh_3132372054554e2034333739	127 TUN 4379	station-teboulba	TEBOULBA	2025-10-12 11:28:57.115	staff_1758995428363_2nhfegsve	2025-10-12 11:28:57.115	0.00
edf75f6e-ed72-4626-afce-5f96dc528cc6	\N	veh_3234372054554e2038393531	247 TUN 8951	station-jemmal	JEMMAL	2025-10-12 11:36:12.991	staff_1760247642213_in7dp0fty	2025-10-12 11:36:12.991	0.00
240133a1-dcda-469c-b137-b143162173ff	\N	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	station-jemmal	JEMMAL	2025-10-12 11:37:18.99	staff_1760247642213_in7dp0fty	2025-10-12 11:37:18.99	0.00
4128c7b3-e790-4d46-af04-037c00cf46c4	\N	f76e78fc-fd60-4b26-ae9d-a119459aa2a6	243 TUN 3852	station-jemmal	JEMMAL	2025-10-12 11:38:34.342	staff_1760247642213_in7dp0fty	2025-10-12 11:38:34.342	0.00
afa83902-4409-4dbc-b01a-aa79db3af9fb	\N	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	station-jemmal	JEMMAL	2025-10-12 11:41:32.959	staff_1760247642213_in7dp0fty	2025-10-12 11:41:32.959	0.00
260bc86a-ecb1-4be7-98f6-76c8e11c7c76	\N	veh_3137352054554e2033363732	175 TUN 3672	station-jemmal	JEMMAL	2025-10-12 11:46:12.797	staff_1760247642213_in7dp0fty	2025-10-12 11:46:12.797	0.00
2282c810-22c6-4689-9af1-2aee024bed1b	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-ksar-hlel	KSAR HLEL	2025-10-12 11:47:14.83	staff_1760209249802_llckjlapc	2025-10-12 11:47:14.83	0.00
cc20be74-d2a2-4817-ae54-24f3ffce5f05	\N	veh_3137352054554e2033363732	175 TUN 3672	station-jemmal	JEMMAL	2025-10-12 11:51:05.331	staff_1760247642213_in7dp0fty	2025-10-12 11:51:05.331	0.00
ce4f969b-7d14-4a2c-9271-505cb2f339bf	\N	veh_3235302054554e20363739	250 TUN 679	station-ksar-hlel	KSAR HLEL	2025-10-12 11:54:50.313	staff_1760209249802_llckjlapc	2025-10-12 11:54:50.313	0.00
f03941c8-a7cf-41c0-857c-791a53fa5e2c	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 11:54:56.079	staff_1760209249802_llckjlapc	2025-10-12 11:54:56.079	0.00
52dc8892-b9e1-4bc0-8d57-f5ee57dd559c	\N	c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	station-jemmal	JEMMAL	2025-10-12 11:55:26.508	staff_1760247642213_in7dp0fty	2025-10-12 11:55:26.508	0.00
fc5b3891-5c8e-409e-b422-c8a1a8a602d3	\N	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	station-moknin	MOKNIN	2025-10-12 12:03:44.559	staff_1760209249802_llckjlapc	2025-10-12 12:03:44.559	0.00
22bddba2-d78d-4343-ba3b-c4c1571ee388	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 12:03:49.933	staff_1758995428363_2nhfegsve	2025-10-12 12:03:49.933	0.00
0427ef53-23e8-40ad-a374-ce7304abce93	\N	b339ef18-7892-48ff-96c8-82df56271eae	251 TUN 7611	station-teboulba	TEBOULBA	2025-10-12 12:06:48.218	staff_1758995428363_2nhfegsve	2025-10-12 12:06:48.218	0.00
59828b39-2977-49fb-b3ce-9536cdf23109	\N	ab273830-0eae-4c6d-940c-34745e0494c7	218 TUN 1158	station-jemmal	JEMMAL	2025-10-12 12:10:27.224	staff_1760247642213_in7dp0fty	2025-10-12 12:10:27.224	0.00
5823f00a-bc77-4dea-ade3-5a994ef03c59	\N	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	station-jemmal	JEMMAL	2025-10-12 12:14:37.801	staff_1760247642213_in7dp0fty	2025-10-12 12:14:37.801	0.00
5a06dfb8-0eee-470c-a689-f1daf3e086ac	\N	veh_3133302054554e2033313438	130 TUN 3148	station-ksar-hlel	KSAR HLEL	2025-10-12 12:14:49.142	staff_1758995428363_2nhfegsve	2025-10-12 12:14:49.142	0.00
d690e17f-0ab5-42a1-a00e-c55291b8376f	\N	vehicle_1760251516726_v3xdgeaou	178TUN3446	station-teboulba	TEBOULBA	2025-10-12 12:20:27.028	staff_1758995428363_2nhfegsve	2025-10-12 12:20:27.028	0.00
3aa6f5f5-6399-4344-b88a-35ba6d0662d0	\N	0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	station-jemmal	JEMMAL	2025-10-12 12:21:40.343	staff_1760247642213_in7dp0fty	2025-10-12 12:21:40.343	0.00
ac297ba4-74c9-4947-85c5-ce1acb04fd3c	\N	96b8a5b6-6676-45a0-8888-12c6bb9d2910	146 TUN 3509	station-ksar-hlel	KSAR HLEL	2025-10-12 12:24:19.016	staff_1760209249802_llckjlapc	2025-10-12 12:24:19.016	0.00
dfef1361-233a-49b3-b8e3-f27c1dcb97ee	\N	4ca4bc71-ccb7-4b02-9e30-7a6e74aa5696	255 TUN 4893	station-moknin	MOKNIN	2025-10-12 12:26:05.588	staff_1760209249802_llckjlapc	2025-10-12 12:26:05.588	0.00
50997dc6-4e57-4317-9155-d14f56b36339	\N	866ffcfd-be45-46fe-894e-104ac2bd71df	170 TUN 2905	station-jemmal	JEMMAL	2025-10-12 12:28:00.607	staff_1760247642213_in7dp0fty	2025-10-12 12:28:00.607	0.00
79b821ef-2848-447c-a1a0-a853fee0da31	\N	veh_3133322054554e2037323139	132 TUN 7219	station-moknin	MOKNIN	2025-10-12 12:30:38.191	staff_1760209249802_llckjlapc	2025-10-12 12:30:38.191	0.00
9ff657f7-d074-4d6d-84b3-69017113dce8	\N	veh_3139342054554e2039333031	194 TUN 9301	station-jemmal	JEMMAL	2025-10-12 12:33:18.699	staff_1760247642213_in7dp0fty	2025-10-12 12:33:18.699	0.00
e87569e3-2c1a-4b12-8d98-7ccec47d7fe0	\N	22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	station-ksar-hlel	KSAR HLEL	2025-10-12 12:39:04.327	staff_1760209249802_llckjlapc	2025-10-12 12:39:04.327	0.00
580d47fb-22e5-409b-bdb6-95685e3beba6	\N	428de0a6-be2e-436b-918d-7887419291c0	247 TUN 6296	station-jemmal	JEMMAL	2025-10-12 12:41:49.759	staff_1760247642213_in7dp0fty	2025-10-12 12:41:49.759	0.00
bcaf7bcd-626d-4aa2-bf9c-b32681193eab	\N	vehicle_1760249655820_o2w7zbb4b	127TUN2956	station-jemmal	JEMMAL	2025-10-12 12:45:54.686	staff_1760247642213_in7dp0fty	2025-10-12 12:45:54.686	0.00
67bb4184-3a06-4b06-badf-0a39a90077e8	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-teboulba	TEBOULBA	2025-10-12 12:46:00.349	staff_1758995428363_2nhfegsve	2025-10-12 12:46:00.349	0.00
0601c579-d220-4193-a143-96c615a93b97	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 12:48:13.007	staff_1760247642213_in7dp0fty	2025-10-12 12:48:13.007	0.00
f69b7307-95d0-45f1-a005-613379f61ed8	\N	3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	station-jemmal	JEMMAL	2025-10-12 12:52:38.662	staff_1760247642213_in7dp0fty	2025-10-12 12:52:38.662	0.00
613ada86-86ed-43c0-8c7f-a4e5139a9d3e	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 12:56:50.271	staff_1760247642213_in7dp0fty	2025-10-12 12:56:50.271	0.00
d4508d72-f61f-477e-85eb-26a6f2a3ac82	\N	veh_3132392054554e2032373735	129 TUN 2775	station-jemmal	JEMMAL	2025-10-12 12:59:12.649	staff_1760247642213_in7dp0fty	2025-10-12 12:59:12.649	0.00
c338f969-ddde-4311-a6ce-daa6d6e9d41c	\N	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	station-jemmal	JEMMAL	2025-10-12 13:00:14.405	staff_1760247642213_in7dp0fty	2025-10-12 13:00:14.405	0.00
724e33bf-0e20-4635-acaa-047aa8c64f12	\N	vehicle_1760252392573_ilt6t9ei2	253TUN2817	station-jemmal	JEMMAL	2025-10-12 13:05:15.252	staff_1760247642213_in7dp0fty	2025-10-12 13:05:15.252	0.00
6b10e8ea-2971-435a-91a9-3e9025e879aa	\N	veh_3233392054554e2034373831	239 TUN 4781	station-moknin	MOKNIN	2025-10-12 13:05:23.988	staff_1758995428363_2nhfegsve	2025-10-12 13:05:23.988	0.00
5cfa0cc2-6ea9-4436-a7ad-b75b25147d9a	\N	veh_3133382054554e2031303234	138 TUN 1024	station-moknin	MOKNIN	2025-10-12 13:06:01.517	staff_1758995428363_2nhfegsve	2025-10-12 13:06:01.517	0.00
4e01b597-ff9b-48e5-aa95-0db1382e6ecd	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 13:08:34.834	staff_1760247642213_in7dp0fty	2025-10-12 13:08:34.834	0.00
657b68a9-60b7-4392-bcb1-19ff5744cf73	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 13:12:58.699	staff_1758995428363_2nhfegsve	2025-10-12 13:12:58.699	0.00
9acbea20-1dc2-433d-9e7e-f38dbeb1ed4c	\N	570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	station-ksar-hlel	KSAR HLEL	2025-10-12 13:13:01.891	staff_1758995428363_2nhfegsve	2025-10-12 13:13:01.891	0.00
8261f4da-b237-4ff0-b744-2a14f04fd2fc	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 13:13:04.571	staff_1758995428363_2nhfegsve	2025-10-12 13:13:04.571	0.00
0bec183c-5033-4ef8-b5ec-e3189b0d9e06	\N	vehicle_1760251707403_45c6e9gdt	124TUN237	station-ksar-hlel	KSAR HLEL	2025-10-12 13:13:08.804	staff_1758995428363_2nhfegsve	2025-10-12 13:13:08.804	0.00
dfb26125-c0ec-46da-82cc-db8cb56118d0	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 13:13:11.834	staff_1758995428363_2nhfegsve	2025-10-12 13:13:11.834	0.00
a6db7a1b-a781-4f36-82e2-ca6f4cf4a637	\N	vehicle_1760248901989_kkpdqpdp0	247TUN5381	station-ksar-hlel	KSAR HLEL	2025-10-12 13:13:14.476	staff_1758995428363_2nhfegsve	2025-10-12 13:13:14.476	0.00
26cdf9c5-a2d0-4ca6-a2d2-a50389e72b69	\N	vehicle_1760249733257_lk9zxkckf	224TUN2800	station-jemmal	JEMMAL	2025-10-12 13:15:42.874	staff_1760247642213_in7dp0fty	2025-10-12 13:15:42.874	0.00
aa504c7c-2662-47be-a175-93c65641f1bc	\N	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	station-jemmal	JEMMAL	2025-10-12 13:18:34.346	staff_1760247642213_in7dp0fty	2025-10-12 13:18:34.346	0.00
76875253-e13a-47bb-90d0-f1ceed0f27b0	\N	b9e3efb0-32f2-4e68-8fbf-c7f032fc7c90	127 TUN 5147	station-moknin	MOKNIN	2025-10-12 13:18:56.95	staff_1758995428363_2nhfegsve	2025-10-12 13:18:56.95	0.00
4956e62c-332f-47e0-84eb-ecd2cceb2158	\N	vehicle_1760248901989_kkpdqpdp0	247TUN5381	station-ksar-hlel	KSAR HLEL	2025-10-12 13:21:04.833	staff_1760209249802_llckjlapc	2025-10-12 13:21:04.833	0.00
34bfd3cf-400e-40db-a575-ec86df927d7f	\N	veh_3133382054554e2031303234	138 TUN 1024	station-moknin	MOKNIN	2025-10-12 13:21:19.65	staff_1758995428363_2nhfegsve	2025-10-12 13:21:19.65	0.00
6347c4eb-78ac-4c2a-8ab2-a7519c258711	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 13:22:08.604	staff_1760247642213_in7dp0fty	2025-10-12 13:22:08.604	0.00
b77d04ab-b8c0-4db4-9473-516a508540e2	\N	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	station-jemmal	JEMMAL	2025-10-12 13:23:38.261	staff_1760247642213_in7dp0fty	2025-10-12 13:23:38.261	0.00
53e1d8ad-ed4e-4b0d-8196-e023692a42ab	\N	veh_3133382054554e2035373738	138 TUN 5778	station-teboulba	TEBOULBA	2025-10-12 13:25:46.543	staff_1758995428363_2nhfegsve	2025-10-12 13:25:46.543	0.00
25e1ef0d-6ad8-4f0a-9310-094aa960274e	\N	veh_3233332054554e2036363831	233 TUN 6681	station-jemmal	JEMMAL	2025-10-12 13:25:47.774	staff_1760209249802_llckjlapc	2025-10-12 13:25:47.774	0.00
1fb23777-6353-44d4-81d0-de02e81c6eca	\N	veh_3232342054554e2035333333	224 TUN 5333	station-jemmal	JEMMAL	2025-10-12 13:28:59.249	staff_1760209249802_llckjlapc	2025-10-12 13:28:59.249	0.00
4d158856-a215-4453-8de5-9faff2891998	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 13:31:21.864	staff_1760209249802_llckjlapc	2025-10-12 13:31:21.864	0.00
28cd9d4a-d24b-45c1-a031-8cb92860d3ce	\N	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	station-jemmal	JEMMAL	2025-10-12 13:32:06.075	staff_1760209249802_llckjlapc	2025-10-12 13:32:06.075	0.00
80d2d686-415d-4315-ba9f-d93cdec35418	\N	vehicle_1760249233865_2rdyukkkq	121TUN7184	station-ksar-hlel	KSAR HLEL	2025-10-12 13:33:32.355	staff_1760209249802_llckjlapc	2025-10-12 13:33:32.355	0.00
567832a4-825c-4b65-855a-96b65a8b228d	\N	veh_3234372054554e2038393531	247 TUN 8951	station-jemmal	JEMMAL	2025-10-12 13:37:16.426	staff_1760247642213_in7dp0fty	2025-10-12 13:37:16.426	0.00
381bfdd0-bd81-4b7f-8bf1-9fd81edeb2d4	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 13:37:36.501	staff_1760209249802_llckjlapc	2025-10-12 13:37:36.501	0.00
eb0e062d-5edd-4220-b8cc-050ded1d539f	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 13:39:30.193	staff_1758995428363_2nhfegsve	2025-10-12 13:39:30.193	0.00
8a8abd04-9959-4e21-a642-e18d5efa37e0	\N	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	station-jemmal	JEMMAL	2025-10-12 13:42:51.684	staff_1760247642213_in7dp0fty	2025-10-12 13:42:51.684	0.00
cf313efd-36ed-4a0d-a6ad-946700077ca8	\N	4bb4a12b-8571-4cc4-aa9b-c460a878cada	242 TUN 7358	station-jemmal	JEMMAL	2025-10-12 13:46:03.892	staff_1760247642213_in7dp0fty	2025-10-12 13:46:03.892	0.00
9d1a9397-b91a-4b06-ac40-fb6af8625847	\N	veh_3235302054554e20363739	250 TUN 679	station-ksar-hlel	KSAR HLEL	2025-10-12 13:46:16.421	staff_1760209249802_llckjlapc	2025-10-12 13:46:16.421	0.00
42f43501-a280-46fb-90c0-ab2984833dcb	\N	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	station-ksar-hlel	KSAR HLEL	2025-10-12 13:47:04.843	staff_1760209249802_llckjlapc	2025-10-12 13:47:04.843	0.00
347deddb-5edb-42d7-a6c2-c94a28a7da7f	\N	c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	station-jemmal	JEMMAL	2025-10-12 13:50:51.259	staff_1760247642213_in7dp0fty	2025-10-12 13:50:51.259	0.00
3a26511c-d6db-4816-9689-e8ed9629ee2a	\N	veh_3134352054554e2031303634	145 TUN 1064	station-moknin	MOKNIN	2025-10-12 13:52:10.367	staff_1758995428363_2nhfegsve	2025-10-12 13:52:10.367	0.00
26aeaba3-8722-426d-9c6c-17dc465f3768	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-ksar-hlel	KSAR HLEL	2025-10-12 13:53:58.121	staff_1760209249802_llckjlapc	2025-10-12 13:53:58.121	0.00
dc5f4458-95d6-4b24-8b7a-72057b425058	\N	20568779-4dd7-4dde-8961-356fa6bfbadc	166 TUN 8519	station-jemmal	JEMMAL	2025-10-12 13:58:21.178	staff_1760247642213_in7dp0fty	2025-10-12 13:58:21.178	0.00
15b4ccaa-e389-4074-9f9c-33718e1df6e9	\N	e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	station-jemmal	JEMMAL	2025-10-12 13:58:34.451	staff_1760247642213_in7dp0fty	2025-10-12 13:58:34.451	0.00
cc0eea2d-ad0e-422a-be68-1c695bdb1411	\N	veh_3134322054554e2032323736	142 TUN 2276	station-moknin	MOKNIN	2025-10-12 14:01:46.934	staff_1758995428363_2nhfegsve	2025-10-12 14:01:46.934	0.00
8db0ebac-bc11-480a-b46d-da40fc31ee84	\N	veh_3139332054554e2035333736	193 TUN 5376	station-jemmal	JEMMAL	2025-10-12 14:04:06.841	staff_1760247642213_in7dp0fty	2025-10-12 14:04:06.841	0.00
59c51fc7-e498-46e4-a91c-1db9b7cadcab	\N	a827ab5f-fffd-4e01-b50d-378c4f61f615	180 TUN 3276	station-ksar-hlel	KSAR HLEL	2025-10-12 14:05:01.245	staff_1760209249802_llckjlapc	2025-10-12 14:05:01.245	0.00
356f8a2a-432c-4db9-ade0-eb1c08bcad1f	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 14:06:46.471	staff_1760209249802_llckjlapc	2025-10-12 14:06:46.471	0.00
1bec8cba-3512-4a9f-9de6-93300daa8446	\N	866ffcfd-be45-46fe-894e-104ac2bd71df	170 TUN 2905	station-jemmal	JEMMAL	2025-10-12 14:07:12.395	staff_1760247642213_in7dp0fty	2025-10-12 14:07:12.395	0.00
20be001b-ba6c-4343-94fa-56a7e3fb2782	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 14:08:19.653	staff_1760247642213_in7dp0fty	2025-10-12 14:08:19.653	0.00
111f54d9-b65b-486f-a68c-9e0aebdfb46b	\N	veh_3235332054554e2039343138	253 TUN 9418	station-moknin	MOKNIN	2025-10-12 14:09:06.123	staff_1758995428363_2nhfegsve	2025-10-12 14:09:06.123	0.00
b0dadbf7-c093-4493-9de2-23e7973f038d	\N	veh_3132392054554e2032373735	129 TUN 2775	station-jemmal	JEMMAL	2025-10-12 14:16:03.144	staff_1760247642213_in7dp0fty	2025-10-12 14:16:03.144	0.00
5c185c52-7e56-4145-8af1-05cbe1a59b9a	\N	veh_3230342054554e2037373131	204 TUN 7711	station-teboulba	TEBOULBA	2025-10-12 14:16:42.348	staff_1758995428363_2nhfegsve	2025-10-12 14:16:42.348	0.00
95f0768e-0cc8-4c71-95a7-4ce8ca583b79	\N	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	station-jemmal	JEMMAL	2025-10-12 14:19:55.137	staff_1760247642213_in7dp0fty	2025-10-12 14:19:55.137	0.00
ec0dcc02-6f15-4201-ae70-71717816c20d	\N	veh_3137352054554e2033363732	175 TUN 3672	station-jemmal	JEMMAL	2025-10-12 14:22:10.241	staff_1760247642213_in7dp0fty	2025-10-12 14:22:10.241	0.00
7d2471ad-0e8b-4484-946f-b81baf4beb34	\N	00784611-53e2-498b-b30b-778e5376efac	225 TUN 458	station-jemmal	JEMMAL	2025-10-12 14:27:16.537	staff_1760247642213_in7dp0fty	2025-10-12 14:27:16.537	0.00
abddc16a-cb8b-45b1-b1a5-1b79c7a69307	\N	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	station-moknin	MOKNIN	2025-10-12 14:27:48.982	staff_1758995428363_2nhfegsve	2025-10-12 14:27:48.982	0.00
e6b4fe9e-af68-4615-9374-75d0e3518611	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 14:28:56.65	staff_1760247642213_in7dp0fty	2025-10-12 14:28:56.65	0.00
8aa47355-2e76-4590-8b59-0b4fb8646d4f	\N	570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	station-ksar-hlel	KSAR HLEL	2025-10-12 14:30:49.279	staff_1760209249802_llckjlapc	2025-10-12 14:30:49.279	0.00
4c3cccf1-227f-45ca-9639-8ba0f0692c33	\N	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	station-jemmal	JEMMAL	2025-10-12 14:32:18.113	staff_1760247642213_in7dp0fty	2025-10-12 14:32:18.113	0.00
11765fd0-7d93-4f9f-95b2-383b831bae7c	\N	22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	station-ksar-hlel	KSAR HLEL	2025-10-12 14:35:24.826	staff_1758995428363_2nhfegsve	2025-10-12 14:35:24.826	0.00
5fbb349c-d741-493e-a8da-5a2d485108ed	\N	veh_3234392054554e2039373736	249 TUN 9776	station-moknin	MOKNIN	2025-10-12 14:44:39.935	staff_1758995428363_2nhfegsve	2025-10-12 14:44:39.935	0.00
c83b66a6-91cc-4c8f-88e5-9af86b843adb	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 14:44:43.562	staff_1760247642213_in7dp0fty	2025-10-12 14:44:43.562	0.00
08cd7a69-3c13-4434-b9a2-c1617089dad1	\N	vehicle_1760249733257_lk9zxkckf	224TUN2800	station-jemmal	JEMMAL	2025-10-12 14:44:47.331	staff_1760247642213_in7dp0fty	2025-10-12 14:44:47.331	0.00
787834fd-c0e7-414c-8361-fb53b8e493a6	\N	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	station-jemmal	JEMMAL	2025-10-12 14:45:29.581	staff_1760247642213_in7dp0fty	2025-10-12 14:45:29.581	0.00
6685bbad-fa3c-467a-85bf-3ce50a124350	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 14:46:37.504	staff_1760247642213_in7dp0fty	2025-10-12 14:46:37.504	0.00
15833fac-1128-4477-80d0-307d043d3580	\N	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	station-jemmal	JEMMAL	2025-10-12 14:49:27.75	staff_1760247642213_in7dp0fty	2025-10-12 14:49:27.75	0.00
b4db8c32-dcef-41bc-87a2-2a4d34610c29	\N	veh_3233332054554e2036363831	233 TUN 6681	station-jemmal	JEMMAL	2025-10-12 14:51:16.26	staff_1760247642213_in7dp0fty	2025-10-12 14:51:16.26	0.00
c58a72bf-d92b-40f4-8070-02ba9ea02f27	\N	veh_3233332054554e2036363831	233 TUN 6681	station-jemmal	JEMMAL	2025-10-12 14:56:26.604	staff_1760247642213_in7dp0fty	2025-10-12 14:56:26.604	0.00
daee111c-34ec-4735-85a7-f1903faf92db	\N	veh_3233352054554e2033313138	235 TUN 3118	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:36.691	staff_1760209249802_llckjlapc	2025-10-12 14:56:36.691	0.00
d481a02f-8575-44ac-919a-4a67ef0dafee	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:40.288	staff_1760209249802_llckjlapc	2025-10-12 14:56:40.288	0.00
87ed29de-5fb2-4434-a1b9-7e3ec1e01fd9	\N	456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:42.491	staff_1760209249802_llckjlapc	2025-10-12 14:56:42.491	0.00
e8fb1a1b-8a09-4021-a3d5-396477b8d98e	\N	veh_3133302054554e2033313438	130 TUN 3148	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:44.539	staff_1760209249802_llckjlapc	2025-10-12 14:56:44.539	0.00
ccf9bb03-898f-4252-a2bc-10b430f3c63d	\N	veh_3132312054554e2039333033	121 TUN 9303	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:46.624	staff_1760209249802_llckjlapc	2025-10-12 14:56:46.624	0.00
76167bc2-e2e9-449a-8b38-89eb7bdb5fa8	\N	vehicle_1760251707403_45c6e9gdt	124TUN237	station-ksar-hlel	KSAR HLEL	2025-10-12 14:56:48.72	staff_1760209249802_llckjlapc	2025-10-12 14:56:48.72	0.00
27b4da21-eadd-4a9e-976f-51f5d81c266b	\N	veh_3232342054554e2035333333	224 TUN 5333	station-jemmal	JEMMAL	2025-10-12 15:02:55.642	staff_1760247642213_in7dp0fty	2025-10-12 15:02:55.642	0.00
4d41971c-214e-447b-82ed-91469e088ca0	\N	428de0a6-be2e-436b-918d-7887419291c0	247 TUN 6296	station-jemmal	JEMMAL	2025-10-12 15:03:15.898	staff_1760247642213_in7dp0fty	2025-10-12 15:03:15.898	0.00
ffafe8e4-18e7-4e8c-abf3-a54a839c331e	\N	14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	station-moknin	MOKNIN	2025-10-12 15:04:21.778	staff_1758995428363_2nhfegsve	2025-10-12 15:04:21.778	0.00
3d80d9c3-9820-4a65-9bda-a74fa582865a	\N	veh_3132372054554e2034333739	127 TUN 4379	station-teboulba	TEBOULBA	2025-10-12 15:05:00.465	staff_1758995428363_2nhfegsve	2025-10-12 15:05:00.465	0.00
812c1c6f-641f-40ed-bfbf-6da5a0bccd7e	\N	0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	station-jemmal	JEMMAL	2025-10-12 15:05:55.228	staff_1760247642213_in7dp0fty	2025-10-12 15:05:55.228	0.00
10122f3d-ae76-48a0-80c3-ca14ebe809ba	\N	vehicle_1760249655820_o2w7zbb4b	127TUN2956	station-jemmal	JEMMAL	2025-10-12 15:07:34.351	staff_1760247642213_in7dp0fty	2025-10-12 15:07:34.351	0.00
85fb0886-8075-4ada-8d62-11cf3bb02740	\N	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	station-jemmal	JEMMAL	2025-10-12 15:14:45.765	staff_1760247642213_in7dp0fty	2025-10-12 15:14:45.765	0.00
47fceff8-6021-4279-a153-b39c8d6a77fc	\N	b339ef18-7892-48ff-96c8-82df56271eae	251 TUN 7611	station-teboulba	TEBOULBA	2025-10-12 15:15:10.33	staff_1758995428363_2nhfegsve	2025-10-12 15:15:10.33	0.00
72a87757-ed19-41e0-9c70-60f56ee4950e	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-jemmal	JEMMAL	2025-10-12 15:16:34.389	staff_1760247642213_in7dp0fty	2025-10-12 15:16:34.389	0.00
4cd2a258-85d7-4ac6-994d-f1d26a1ec05d	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-jemmal	JEMMAL	2025-10-12 15:19:17.23	staff_1760247642213_in7dp0fty	2025-10-12 15:19:17.23	0.00
ffdace02-c1c2-4fc0-b6ae-e143b1c753ab	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 15:20:51.766	staff_1760209249802_llckjlapc	2025-10-12 15:20:51.766	0.00
fd51c1aa-1e06-4e08-9a8c-ffad8b608ec2	\N	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	210 TUN 4130	station-ksar-hlel	KSAR HLEL	2025-10-12 15:20:54.997	staff_1760209249802_llckjlapc	2025-10-12 15:20:54.997	0.00
69a7ea8c-326f-4e84-9f6e-9f8962860eb8	\N	veh_3137392054554e2034323934	179 TUN 4294	station-ksar-hlel	KSAR HLEL	2025-10-12 15:20:57.46	staff_1760209249802_llckjlapc	2025-10-12 15:20:57.46	0.00
e3955e8e-ab57-4051-834c-5d1377486909	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 15:20:59.829	staff_1760209249802_llckjlapc	2025-10-12 15:20:59.829	0.00
37a27b93-4347-49b7-8e27-718752603ee4	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 15:21:02.659	staff_1760209249802_llckjlapc	2025-10-12 15:21:02.659	0.00
25778ae9-87ce-4c36-b3a6-8a074615d6cf	\N	128f10f5-5bdc-4cac-b165-96c2fefeca6c	243 TUN 4358	station-jemmal	JEMMAL	2025-10-12 15:24:57.801	staff_1760247642213_in7dp0fty	2025-10-12 15:24:57.801	0.00
8d2366b0-22e2-4b45-ade2-12bcdfd5e252	\N	veh_3133382054554e2031303234	138 TUN 1024	station-moknin	MOKNIN	2025-10-12 15:27:07.739	staff_1758995428363_2nhfegsve	2025-10-12 15:27:07.739	0.00
238d988c-3a43-4d6e-9a2c-029d9e191d64	\N	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	station-jemmal	JEMMAL	2025-10-12 15:27:24.62	staff_1760247642213_in7dp0fty	2025-10-12 15:27:24.62	0.00
3c386db5-72d2-4654-8296-8486def330fc	\N	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	station-jemmal	JEMMAL	2025-10-12 15:28:27.372	staff_1760247642213_in7dp0fty	2025-10-12 15:28:27.372	0.00
5114a517-7bf1-4f97-9041-0dfcd2bbf317	\N	veh_3234372054554e2038393531	247 TUN 8951	station-jemmal	JEMMAL	2025-10-12 15:31:52.947	staff_1760247642213_in7dp0fty	2025-10-12 15:31:52.947	0.00
47bb4cac-f6a8-487b-a49a-a261bb557587	\N	24bd242e-9ed7-41dd-91e4-e91290118db6	253 TUN 6900	station-jemmal	JEMMAL	2025-10-12 15:32:16.377	staff_1760247642213_in7dp0fty	2025-10-12 15:32:16.377	0.00
7c3e0cc3-8db8-4ee8-94bf-e5b91d9d69e5	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:28.674	staff_1760209249802_llckjlapc	2025-10-12 15:33:28.674	0.00
c80b53c1-8ab8-4122-a2a7-b5f63949a7d3	\N	veh_3137392054554e2034323934	179 TUN 4294	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:31.936	staff_1760209249802_llckjlapc	2025-10-12 15:33:31.936	0.00
d5bb3700-b628-4886-a550-5bc2fff5c229	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:34.327	staff_1760209249802_llckjlapc	2025-10-12 15:33:34.327	0.00
3b9a8cca-c2b9-43b8-ac4c-5e36301b2503	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:36.655	staff_1760209249802_llckjlapc	2025-10-12 15:33:36.655	0.00
e2c3ea24-06db-42ad-b936-07f8e7c82e55	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:38.831	staff_1760209249802_llckjlapc	2025-10-12 15:33:38.831	0.00
84250cea-6eb8-42d5-a8ed-1e7a4ee834ed	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:41.862	staff_1760209249802_llckjlapc	2025-10-12 15:33:41.862	0.00
e331ad90-1030-40eb-8e1f-0093078ed9fb	\N	456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	station-ksar-hlel	KSAR HLEL	2025-10-12 15:33:43.846	staff_1760209249802_llckjlapc	2025-10-12 15:33:43.846	0.00
42224247-617c-43a2-9a73-c9a0d980ca4a	\N	3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	station-jemmal	JEMMAL	2025-10-12 15:39:49.753	staff_1760247642213_in7dp0fty	2025-10-12 15:39:49.753	0.00
c56648cf-7b28-4406-9394-a40b3452a343	\N	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	station-moknin	MOKNIN	2025-10-12 15:43:19.66	staff_1758995428363_2nhfegsve	2025-10-12 15:43:19.66	0.00
f05e6244-ef6f-41c8-8d8e-97ce41b714c8	\N	veh_3139332054554e2035333736	193 TUN 5376	station-jemmal	JEMMAL	2025-10-12 15:45:08.463	staff_1760247642213_in7dp0fty	2025-10-12 15:45:08.463	0.00
b2872467-6bae-4f22-93e1-1a28381aadca	\N	570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	station-moknin	MOKNIN	2025-10-12 15:51:21.793	staff_1758995428363_2nhfegsve	2025-10-12 15:51:21.793	0.00
7dcbf0b1-7aa4-4473-a1fe-e905180364dd	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-12 15:54:47.905	staff_1760209249802_llckjlapc	2025-10-12 15:54:47.905	0.00
e98a2ceb-20ec-4793-bcf9-3607ac71ca26	\N	456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	station-ksar-hlel	KSAR HLEL	2025-10-12 15:54:49.931	staff_1760209249802_llckjlapc	2025-10-12 15:54:49.931	0.00
d14a9f02-2d74-4854-b07f-6e641440e7f0	\N	veh_3235302054554e20363739	250 TUN 679	station-ksar-hlel	KSAR HLEL	2025-10-12 15:54:53.017	staff_1760209249802_llckjlapc	2025-10-12 15:54:53.017	0.00
136b7b2e-fd7e-4bac-aaa2-2f3e4faf7879	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 15:54:55.396	staff_1760209249802_llckjlapc	2025-10-12 15:54:55.396	0.00
1529e544-dd42-4a2c-b3c1-6c95a137b7a5	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 15:54:58.929	staff_1760209249802_llckjlapc	2025-10-12 15:54:58.929	0.00
8d6d6305-4727-421d-8e5a-56d115985780	\N	veh_3234372054554e2038353536	247 TUN 8556	station-moknin	MOKNIN	2025-10-12 16:00:54.423	staff_1758995428363_2nhfegsve	2025-10-12 16:00:54.423	0.00
deabb213-9f13-47a5-8462-dc752380ec86	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 16:13:41.667	staff_1758995428363_2nhfegsve	2025-10-12 16:13:41.667	0.00
e2438c4b-d1d6-4318-9063-27dbe632ff0e	\N	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	station-jemmal	JEMMAL	2025-10-12 16:13:59.471	staff_1760247642213_in7dp0fty	2025-10-12 16:13:59.471	0.00
30fbe112-3189-49d7-bf4b-dfa8fe084a79	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 16:17:04.465	staff_1760247642213_in7dp0fty	2025-10-12 16:17:04.465	0.00
f09a5e67-eab7-4ad4-81c5-a24495816403	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 16:19:33.298	staff_1760247642213_in7dp0fty	2025-10-12 16:19:33.298	0.00
9ddf1354-7ac1-4949-95b9-44937ec62028	\N	d084e91a-df8b-4f8d-a3a9-f09b74395a85	233 TUN 7278	station-teboulba	TEBOULBA	2025-10-12 16:21:19.285	staff_1758995428363_2nhfegsve	2025-10-12 16:21:19.285	0.00
2ab36133-cc6c-4f5e-bfe7-28f6547015b2	\N	veh_3233382054554e2034333232	238 TUN 4322	station-jemmal	JEMMAL	2025-10-12 16:23:06.504	staff_1760247642213_in7dp0fty	2025-10-12 16:23:06.504	0.00
8d297848-88e5-44d5-a243-f372de59556d	\N	veh_3139342054554e2039333031	194 TUN 9301	station-jemmal	JEMMAL	2025-10-12 16:23:08.775	staff_1760247642213_in7dp0fty	2025-10-12 16:23:08.775	0.00
f9504e74-61ed-4693-be26-3accc0c1cc10	\N	c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	station-jemmal	JEMMAL	2025-10-12 16:23:09.71	staff_1760247642213_in7dp0fty	2025-10-12 16:23:09.71	0.00
a6fbe184-008f-4bf8-afdd-7306d4417166	\N	866ffcfd-be45-46fe-894e-104ac2bd71df	170 TUN 2905	station-jemmal	JEMMAL	2025-10-12 16:23:11.201	staff_1760247642213_in7dp0fty	2025-10-12 16:23:11.201	0.00
fc6206be-ac4c-484a-b2b0-874cfe85c57d	\N	veh_3233372054554e2038333430	237 TUN 8340	station-jemmal	JEMMAL	2025-10-12 16:23:13.853	staff_1760247642213_in7dp0fty	2025-10-12 16:23:13.853	0.00
52c49e96-5640-47ed-98f8-aeeefdfc477c	\N	veh_3137352054554e2033363732	175 TUN 3672	station-jemmal	JEMMAL	2025-10-12 16:23:20.701	staff_1760247642213_in7dp0fty	2025-10-12 16:23:20.701	0.00
33d45ba2-1ad2-4b51-a4fc-172bcf87c52f	\N	a7938b81-2018-4dcf-8456-4d51e8e1aef4	249 TUN 9077	station-jemmal	JEMMAL	2025-10-12 16:23:23.323	staff_1760247642213_in7dp0fty	2025-10-12 16:23:23.323	0.00
481c874b-627d-4182-bcae-a4aed3cd0155	\N	veh_3135332054554e2031303634	153 TUN 1064	station-jemmal	JEMMAL	2025-10-12 16:25:15.737	staff_1760247642213_in7dp0fty	2025-10-12 16:25:15.737	0.00
2c43cf27-74ca-4984-8292-31a9893184ab	\N	14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	station-moknin	MOKNIN	2025-10-12 16:26:20.152	staff_1758995428363_2nhfegsve	2025-10-12 16:26:20.152	0.00
1c2f9c81-6250-4975-a028-158a732ae722	\N	vehicle_1760252392573_ilt6t9ei2	253TUN2817	station-jemmal	JEMMAL	2025-10-12 16:30:26.442	staff_1760247642213_in7dp0fty	2025-10-12 16:30:26.442	0.00
6109bc85-5514-4316-8bc4-23d08a861c58	\N	veh_3139332054554e2035333736	193 TUN 5376	station-jemmal	JEMMAL	2025-10-12 16:30:30.635	staff_1760247642213_in7dp0fty	2025-10-12 16:30:30.635	0.00
158e1d87-1ba6-4073-82d4-df74baf9e803	\N	1e792121-0a50-429a-bfe8-7e1a0e8c1ab6	225 TUN 5376	station-jemmal	JEMMAL	2025-10-12 16:30:32.049	staff_1760247642213_in7dp0fty	2025-10-12 16:30:32.049	0.00
710ebd5f-d9f4-4e6b-ae47-1e4c6978feb8	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 16:30:33.204	staff_1760247642213_in7dp0fty	2025-10-12 16:30:33.204	0.00
acf5aa4e-3927-445c-b854-dc2adff5ded0	\N	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	station-jemmal	JEMMAL	2025-10-12 16:30:34.328	staff_1760247642213_in7dp0fty	2025-10-12 16:30:34.328	0.00
34095f50-e0b8-42e3-ab30-3010441b99b1	\N	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	station-jemmal	JEMMAL	2025-10-12 16:30:37.764	staff_1760247642213_in7dp0fty	2025-10-12 16:30:37.764	0.00
b6b6bceb-fd0c-4f45-9d8c-8f6931e35666	\N	14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	station-moknin	MOKNIN	2025-10-12 16:32:16.654	staff_1758995428363_2nhfegsve	2025-10-12 16:32:16.654	0.00
e3035bba-bfdd-4760-8f55-d44fffffb6cb	\N	vehicle_1760249233865_2rdyukkkq	121TUN7184	station-moknin	MOKNIN	2025-10-12 16:37:56.33	staff_1758995428363_2nhfegsve	2025-10-12 16:37:56.33	0.00
e4a680b2-7573-44fe-b470-6e28526a86a1	\N	vehicle_1760247734626_cuorwq86x	210TUN4130	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:05.089	staff_1760209249802_llckjlapc	2025-10-12 16:38:05.089	0.00
839979a9-e4e6-4fd8-9dbd-574217014ace	\N	e7795446-726f-43f7-bb34-aba040be0bde	182 TUN 7866	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:08.714	staff_1760209249802_llckjlapc	2025-10-12 16:38:08.714	0.00
bf57c27e-3a5f-4681-968e-e4089c2bece6	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:10.905	staff_1760209249802_llckjlapc	2025-10-12 16:38:10.905	0.00
f7cef423-0383-494f-bd28-1e5f3abe3f72	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:12.865	staff_1760209249802_llckjlapc	2025-10-12 16:38:12.865	0.00
d2780299-f19c-4803-b606-cbe932c663b8	\N	veh_3133302054554e2033313438	130 TUN 3148	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:14.938	staff_1760209249802_llckjlapc	2025-10-12 16:38:14.938	0.00
0d98c3f8-3be2-4e78-94e3-0704281e5a1b	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:17.673	staff_1760209249802_llckjlapc	2025-10-12 16:38:17.673	0.00
57ba4390-782f-4b1c-ac83-30f82cc79384	\N	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	station-ksar-hlel	KSAR HLEL	2025-10-12 16:38:20.521	staff_1760209249802_llckjlapc	2025-10-12 16:38:20.521	0.00
8a020c6b-bd10-49d4-928e-da9fdc105cd7	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 16:38:42.093	staff_1760247642213_in7dp0fty	2025-10-12 16:38:42.093	0.00
170fc8f2-52ea-44c6-b5d0-36f29d43035e	\N	veh_3234392054554e2034303332	249 TUN 4032	station-jemmal	JEMMAL	2025-10-12 16:40:58.843	staff_1760247642213_in7dp0fty	2025-10-12 16:40:58.843	0.00
0ccc582a-2868-4375-953d-cc629f82aaa2	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 16:41:37.772	staff_1760209249802_llckjlapc	2025-10-12 16:41:37.772	0.00
662e3a9b-e84b-4d89-bacd-91e8e747b462	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-jemmal	JEMMAL	2025-10-12 16:45:16.64	staff_1760247642213_in7dp0fty	2025-10-12 16:45:16.64	0.00
48c10bb3-389e-41ae-bfc9-54ed4fbaefb0	\N	0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	station-jemmal	JEMMAL	2025-10-12 16:46:13.079	staff_1760247642213_in7dp0fty	2025-10-12 16:46:13.079	0.00
e1de9c90-3474-41b2-a09b-766702509070	\N	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	station-moknin	MOKNIN	2025-10-12 16:46:59.952	staff_1758995428363_2nhfegsve	2025-10-12 16:46:59.952	0.00
a3b341d8-4afb-48d8-b60f-fbd958561985	\N	128f10f5-5bdc-4cac-b165-96c2fefeca6c	243 TUN 4358	station-jemmal	JEMMAL	2025-10-12 16:49:20.869	staff_1760247642213_in7dp0fty	2025-10-12 16:49:20.869	0.00
1dad425d-b862-49d0-ba19-e292caaa0ff5	\N	428de0a6-be2e-436b-918d-7887419291c0	247 TUN 6296	station-jemmal	JEMMAL	2025-10-12 16:51:02.685	staff_1760247642213_in7dp0fty	2025-10-12 16:51:02.685	0.00
25dc99fb-c5de-4121-be57-cee4bdd4abae	\N	97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	station-jemmal	JEMMAL	2025-10-12 16:53:25.468	staff_1760247642213_in7dp0fty	2025-10-12 16:53:25.468	0.00
f98e5c23-16e5-4e77-be28-95d219fb6201	\N	veh_3137392054554e2034323934	179 TUN 4294	station-ksar-hlel	KSAR HLEL	2025-10-12 16:55:11.019	staff_1760209249802_llckjlapc	2025-10-12 16:55:11.019	0.00
a60bc2ae-c914-4aa5-89dc-602e1a9c3808	\N	veh_3233372054554e2038333430	237 TUN 8340	station-jemmal	JEMMAL	2025-10-12 16:58:15.424	staff_1760247642213_in7dp0fty	2025-10-12 16:58:15.424	0.00
8c8c92b8-214a-4f7d-ab26-9decc5dc80eb	\N	24bd242e-9ed7-41dd-91e4-e91290118db6	253 TUN 6900	station-jemmal	JEMMAL	2025-10-12 17:00:05.137	staff_1760247642213_in7dp0fty	2025-10-12 17:00:05.137	0.00
fa6550a3-6c73-4910-8247-8627ff04e0cd	\N	vehicle_1760249655820_o2w7zbb4b	127TUN2956	station-jemmal	JEMMAL	2025-10-12 17:01:57.464	staff_1760247642213_in7dp0fty	2025-10-12 17:01:57.464	0.00
eb0c57a1-a46c-4f00-b7ef-5faf923dd49c	\N	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:29.402	staff_1760209249802_llckjlapc	2025-10-12 17:03:29.402	0.00
e689b85b-28a0-4795-82c6-479c1b948643	\N	vehicle_1760247734626_cuorwq86x	210TUN4130	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:31.639	staff_1760209249802_llckjlapc	2025-10-12 17:03:31.639	0.00
58aa670e-bb1d-4899-823a-aed5ab361f2e	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:34.647	staff_1760209249802_llckjlapc	2025-10-12 17:03:34.647	0.00
86b21b50-bd40-4366-92a3-8d2f65549576	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:36.512	staff_1760209249802_llckjlapc	2025-10-12 17:03:36.512	0.00
c23bd8d9-3203-454e-8fc7-c7ecd1a8b2a4	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:38.503	staff_1760209249802_llckjlapc	2025-10-12 17:03:38.503	0.00
0e41b662-a1cc-4715-982e-0c3464a6925c	\N	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	210 TUN 4130	station-ksar-hlel	KSAR HLEL	2025-10-12 17:03:42.864	staff_1760209249802_llckjlapc	2025-10-12 17:03:42.864	0.00
239202de-8b2b-4a18-b53a-4bb664076805	\N	veh_3233382054554e2034333232	238 TUN 4322	station-jemmal	JEMMAL	2025-10-12 17:04:04.219	staff_1760247642213_in7dp0fty	2025-10-12 17:04:04.219	0.00
6d3da8b0-231f-4353-ba67-fe75d403ac26	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 17:04:55.242	staff_1760247642213_in7dp0fty	2025-10-12 17:04:55.242	0.00
baf7e5f8-641e-4db4-a67b-03e2f2849f2d	\N	00784611-53e2-498b-b30b-778e5376efac	225 TUN 458	station-jemmal	JEMMAL	2025-10-12 17:09:35.365	staff_1760247642213_in7dp0fty	2025-10-12 17:09:35.365	0.00
2abafa72-2821-4af4-83ef-7a8a67ba2efb	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 17:10:04.823	staff_1760209249802_llckjlapc	2025-10-12 17:10:04.823	0.00
4c38d4d9-2c8e-4f2c-abdc-7a473d9b0e7f	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 17:12:31.549	staff_1760209249802_llckjlapc	2025-10-12 17:12:31.549	0.00
723a940d-3cb9-47de-91f0-8054b89b6e29	\N	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	station-jemmal	JEMMAL	2025-10-12 17:16:11.867	staff_1760247642213_in7dp0fty	2025-10-12 17:16:11.867	0.00
1e3ae961-28a0-4438-a6c2-aab29b0fa2a2	\N	vehicle_1760247734626_cuorwq86x	210TUN4130	station-ksar-hlel	KSAR HLEL	2025-10-12 17:17:58.859	staff_1760209249802_llckjlapc	2025-10-12 17:17:58.859	0.00
fee5c56c-c34c-45dc-840c-42cfcf2f01aa	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 17:20:25.088	staff_1760209249802_llckjlapc	2025-10-12 17:20:25.088	0.00
95b26f72-f843-48f3-af50-ce973f0ba9c2	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 17:42:49.944	staff_1760209249802_llckjlapc	2025-10-12 17:42:49.944	0.00
671b8833-5045-4654-8496-e933d451e87a	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 17:20:28.061	staff_1760209249802_llckjlapc	2025-10-12 17:20:28.061	0.00
55954201-daec-4550-865b-5e1c6d377e55	\N	9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	station-ksar-hlel	KSAR HLEL	2025-10-12 17:28:22.069	staff_1760209249802_llckjlapc	2025-10-12 17:28:22.069	0.00
52a99438-5307-4719-ae31-a70457031c5d	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 17:28:26.354	staff_1760209249802_llckjlapc	2025-10-12 17:28:26.354	0.00
5cff4a9f-4d49-448d-9a2d-6316b464f3f0	\N	vehicle_1760252392573_ilt6t9ei2	253TUN2817	station-jemmal	JEMMAL	2025-10-12 17:27:48.991	staff_1760247642213_in7dp0fty	2025-10-12 17:27:48.991	0.00
545952e7-b65b-4610-9aab-6f776ab7cab0	\N	veh_3136392054554e2037393937	169 TUN 7997	station-ksar-hlel	KSAR HLEL	2025-10-12 17:28:24.234	staff_1760209249802_llckjlapc	2025-10-12 17:28:24.234	0.00
229a44ec-3cdd-4d41-bba4-c24981160505	\N	veh_3235332054554e2039343138	253 TUN 9418	station-moknin	MOKNIN	2025-10-12 17:29:32.128	staff_1758995428363_2nhfegsve	2025-10-12 17:29:32.128	0.00
34ab53de-cee9-410e-94d0-ff48650b6047	\N	veh_3234392054554e2039373736	249 TUN 9776	station-moknin	MOKNIN	2025-10-12 17:29:35.896	staff_1758995428363_2nhfegsve	2025-10-12 17:29:35.896	0.00
ac1444b0-861f-4869-b8bf-32414bc2f910	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-moknin	MOKNIN	2025-10-12 17:29:37.531	staff_1758995428363_2nhfegsve	2025-10-12 17:29:37.531	0.00
420c3eb1-062e-4f51-a37b-562b32d86491	\N	ccb80a37-fc0c-4f3a-8354-8e6e91a11e48	187 TUN 1357	station-moknin	MOKNIN	2025-10-12 17:29:39.128	staff_1758995428363_2nhfegsve	2025-10-12 17:29:39.128	0.00
64b82369-65d9-4606-9e1d-daa442729799	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-moknin	MOKNIN	2025-10-12 17:29:40.679	staff_1758995428363_2nhfegsve	2025-10-12 17:29:40.679	0.00
17d9195d-9c4d-4d60-b4c1-41c923898771	\N	d084e91a-df8b-4f8d-a3a9-f09b74395a85	233 TUN 7278	station-moknin	MOKNIN	2025-10-12 17:29:41.864	staff_1758995428363_2nhfegsve	2025-10-12 17:29:41.864	0.00
9e3ff1e8-098c-46f9-85f8-19659e99d00c	\N	vehicle_1760251516726_v3xdgeaou	178TUN3446	station-teboulba	TEBOULBA	2025-10-12 17:30:15.691	staff_1758995428363_2nhfegsve	2025-10-12 17:30:15.691	0.00
eb186df6-38c7-4f48-9233-956654346579	\N	veh_3133382054554e2035373738	138 TUN 5778	station-teboulba	TEBOULBA	2025-10-12 17:30:20.049	staff_1758995428363_2nhfegsve	2025-10-12 17:30:20.049	0.00
33f6ad01-68bd-45aa-8c12-30caf2ffce9c	\N	veh_3230342054554e2037373131	204 TUN 7711	station-teboulba	TEBOULBA	2025-10-12 17:30:23.977	staff_1758995428363_2nhfegsve	2025-10-12 17:30:23.977	0.00
887a5f92-a01a-4f14-a6bf-11185d9b8607	\N	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	station-jemmal	JEMMAL	2025-10-12 17:31:35.129	staff_1760247642213_in7dp0fty	2025-10-12 17:31:35.129	0.00
f328dc04-5699-4e12-84d3-779dde053f11	\N	bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	station-jemmal	JEMMAL	2025-10-12 17:32:16.991	staff_1760247642213_in7dp0fty	2025-10-12 17:32:16.991	0.00
c90b9e67-3dcc-4814-bc58-ead646ac85ea	\N	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	station-jemmal	JEMMAL	2025-10-12 17:33:55.197	staff_1760247642213_in7dp0fty	2025-10-12 17:33:55.197	0.00
ba2e9fc5-5bbd-450b-8986-ee258e2510a7	\N	3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	station-jemmal	JEMMAL	2025-10-12 17:37:33.924	staff_1760247642213_in7dp0fty	2025-10-12 17:37:33.924	0.00
04ad8671-f99a-49d4-bdb6-d89d60f84ff8	\N	068fea9c-279a-4df3-a497-2dde7cc6e9d0	203 TUN 2938	station-teboulba	TEBOULBA	2025-10-12 17:38:04.4	staff_1758995428363_2nhfegsve	2025-10-12 17:38:04.4	0.00
19d47565-d460-4496-80f7-06a39928c222	\N	015afe3a-3526-42fc-a9ae-4d963be711c0	130 TUN 2221	station-jemmal	JEMMAL	2025-10-12 17:38:51.028	staff_1760247642213_in7dp0fty	2025-10-12 17:38:51.028	0.00
98fd90f2-84b4-46de-b420-836dab877354	\N	1e792121-0a50-429a-bfe8-7e1a0e8c1ab6	225 TUN 5376	station-jemmal	JEMMAL	2025-10-12 17:40:33.202	staff_1760247642213_in7dp0fty	2025-10-12 17:40:33.202	0.00
4532804b-8ce5-4db8-a688-8a527ba0d1d1	\N	vehicle_1760251707403_45c6e9gdt	124TUN237	station-ksar-hlel	KSAR HLEL	2025-10-12 17:49:01.515	staff_1760209249802_llckjlapc	2025-10-12 17:49:01.515	0.00
6507396a-8e15-4ae6-a635-b9ff4b697aed	\N	veh_3139342054554e2039333031	194 TUN 9301	station-jemmal	JEMMAL	2025-10-12 17:38:54.885	staff_1760247642213_in7dp0fty	2025-10-12 17:38:54.885	0.00
b54a8d49-4f42-4323-8e5d-9eb08b7a04ae	\N	veh_3233352054554e2033313138	235 TUN 3118	station-jemmal	JEMMAL	2025-10-12 17:38:56.273	staff_1760247642213_in7dp0fty	2025-10-12 17:38:56.273	0.00
8e4ddd32-bafe-4e6a-99e3-959ab0f4e758	\N	veh_3234372054554e2038393531	247 TUN 8951	station-jemmal	JEMMAL	2025-10-12 17:38:58.5	staff_1760247642213_in7dp0fty	2025-10-12 17:38:58.5	0.00
09535bbc-9cc9-40f7-b4fc-9745d2531f38	\N	6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	station-jemmal	JEMMAL	2025-10-12 17:41:27.65	staff_1760247642213_in7dp0fty	2025-10-12 17:41:27.65	0.00
b9a07ea9-97c4-4cb5-9d73-ca78c9539efc	\N	vehicle_1760249095699_7h62u6flc	193TUN6376	station-ksar-hlel	KSAR HLEL	2025-10-12 17:42:52.551	staff_1760209249802_llckjlapc	2025-10-12 17:42:52.551	0.00
50c50640-06d8-463c-8ff2-3a0f62355097	\N	a7938b81-2018-4dcf-8456-4d51e8e1aef4	249 TUN 9077	station-jemmal	JEMMAL	2025-10-12 17:45:11.376	staff_1760247642213_in7dp0fty	2025-10-12 17:45:11.376	0.00
55089743-ec31-4c1e-876f-f6c98c48d74f	\N	0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	station-ksar-hlel	KSAR HLEL	2025-10-12 17:50:56.743	staff_1760209249802_llckjlapc	2025-10-12 17:50:56.743	0.00
0ff2f0cd-30c0-46a1-9943-87ad81f267ec	\N	007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	station-jemmal	JEMMAL	2025-10-12 17:58:07.941	staff_1760247642213_in7dp0fty	2025-10-12 17:58:07.941	0.00
f53557e6-7e9f-472e-af45-91d135721621	\N	veh_3133382054554e2031303234	138 TUN 1024	station-ksar-hlel	KSAR HLEL	2025-10-12 18:00:14.395	staff_1760209249802_llckjlapc	2025-10-12 18:00:14.395	0.00
e0d91b2a-b31e-4c02-81db-7410a960156c	\N	veh_3232342054554e2035333333	224 TUN 5333	station-jemmal	JEMMAL	2025-10-12 18:00:18.972	staff_1760247642213_in7dp0fty	2025-10-12 18:00:18.972	0.00
cb6d337a-9560-4d0a-adc0-7d13749d186f	\N	4bb4a12b-8571-4cc4-aa9b-c460a878cada	242 TUN 7358	station-jemmal	JEMMAL	2025-10-12 18:01:10.445	staff_1760247642213_in7dp0fty	2025-10-12 18:01:10.445	0.00
d215028f-456b-425c-b33d-6229420d359e	\N	10440f4d-acde-4772-8237-0a646d4fd650	252 TUN 5925	station-jemmal	JEMMAL	2025-10-12 18:01:13.984	staff_1760247642213_in7dp0fty	2025-10-12 18:01:13.984	0.00
72978073-b2d0-43de-bf7a-9d839a4abea8	\N	e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	station-jemmal	JEMMAL	2025-10-12 18:05:45.747	staff_1760247642213_in7dp0fty	2025-10-12 18:05:45.747	0.00
347281e5-0d94-4256-a122-47491f53ba3b	\N	0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	station-jemmal	JEMMAL	2025-10-12 18:08:33.513	staff_1760247642213_in7dp0fty	2025-10-12 18:08:33.513	0.00
6fb783eb-4801-49ae-aac5-32a2dab28e30	\N	128f10f5-5bdc-4cac-b165-96c2fefeca6c	243 TUN 4358	station-jemmal	JEMMAL	2025-10-12 18:10:17.521	staff_1760247642213_in7dp0fty	2025-10-12 18:10:17.521	0.00
ef41bcfe-0be9-441c-b96c-fbd011492407	\N	vehicle_1760247734626_cuorwq86x	210TUN4130	station-ksar-hlel	KSAR HLEL	2025-10-12 18:12:07.801	staff_1760247642213_in7dp0fty	2025-10-12 18:12:07.801	0.00
865b5de9-6f1b-4be1-a020-f41d7f9674d2	\N	veh_3134302054554e2032363731	140 TUN 2671	station-ksar-hlel	KSAR HLEL	2025-10-12 18:12:11.29	staff_1760247642213_in7dp0fty	2025-10-12 18:12:11.29	0.00
2fe5b375-4dd8-4447-b281-68d5aa3b97f1	\N	22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	station-ksar-hlel	KSAR HLEL	2025-10-12 18:12:12.937	staff_1760247642213_in7dp0fty	2025-10-12 18:12:12.937	0.00
3f24f7f3-8c49-4b69-8b41-20fd4a3cd9a4	\N	vehicle_1760260625377_plz85u34c	250TUN7082	station-ksar-hlel	KSAR HLEL	2025-10-12 18:12:14.545	staff_1760247642213_in7dp0fty	2025-10-12 18:12:14.545	0.00
ba0e085a-df11-4782-b0f3-dcefe8d4f55f	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-ksar-hlel	KSAR HLEL	2025-10-12 18:12:15.721	staff_1760247642213_in7dp0fty	2025-10-12 18:12:15.721	0.00
d6448d3a-1f3a-4477-8179-ea857f718770	\N	c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	station-ksar-hlel	KSAR HLEL	2025-10-12 18:17:24.454	staff_1760209249802_llckjlapc	2025-10-12 18:17:24.454	0.00
5d6595e3-90da-44f8-8a89-fc666f7eac48	\N	veh_3233372054554e2038333430	237 TUN 8340	station-jemmal	JEMMAL	2025-10-12 18:29:42.627	staff_1759175419713_ib5c2pncz	2025-10-12 18:29:42.627	0.00
34a8c854-d1ff-4c31-abe4-ec2426a35d97	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 18:29:56.274	staff_1759175419713_ib5c2pncz	2025-10-12 18:29:56.274	0.00
4ad1f2c5-82b0-480c-8d0f-ab09457a35b4	\N	veh_3232372054554e2034333739	227 TUN 4379	station-teboulba	TEBOULBA	2025-10-12 18:32:49.442	staff_1759175419713_ib5c2pncz	2025-10-12 18:32:49.442	0.00
97af927b-4864-4793-bdff-d739779a7265	\N	00784611-53e2-498b-b30b-778e5376efac	225 TUN 458	station-jemmal	JEMMAL	2025-10-12 18:35:37.631	staff_1759175419713_ib5c2pncz	2025-10-12 18:35:37.631	0.00
5e69b103-6222-4daa-8123-d5a2947ae65c	\N	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	2025-10-12 18:35:40.254	staff_1759175419713_ib5c2pncz	2025-10-12 18:35:40.254	0.00
8648994e-4118-4246-ab0a-7258c49bac36	\N	vehicle_1760249233865_2rdyukkkq	121TUN7184	station-jemmal	JEMMAL	2025-10-12 18:44:31.283	staff_1759175419713_ib5c2pncz	2025-10-12 18:44:31.283	0.00
3b614d73-527f-4295-b0ec-14386ef1672d	\N	456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	station-ksar-hlel	KSAR HLEL	2025-10-12 18:44:50.643	staff_1759175419713_ib5c2pncz	2025-10-12 18:44:50.643	0.00
86291763-16b6-4fe4-9547-dd92bd032ee1	\N	29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	station-jemmal	JEMMAL	2025-10-12 18:50:20.196	staff_1759175419713_ib5c2pncz	2025-10-12 18:50:20.196	0.00
1d8d30cd-dee1-4989-8199-1b9d67c87215	\N	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	station-jemmal	JEMMAL	2025-10-12 18:52:09.39	staff_1760209249802_llckjlapc	2025-10-12 18:52:09.39	0.00
9b539ab9-1570-4d2d-80fa-b36eac91a2ee	\N	21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	station-jemmal	JEMMAL	2025-10-12 18:52:11.836	staff_1760209249802_llckjlapc	2025-10-12 18:52:11.836	0.00
d902eb5c-fe5e-40b2-b790-defd5fd526eb	\N	vehicle_1760250959358_yucrp9a2g	166TUN7598	station-ksar-hlel	KSAR HLEL	2025-10-12 18:52:14.021	staff_1760209249802_llckjlapc	2025-10-12 18:52:14.021	0.00
c53a0c90-b6a5-4449-9aab-97d35ac0c0d6	\N	vehicle_1760252593027_xjlilyx8e	141TUN5692	station-ksar-hlel	KSAR HLEL	2025-10-12 18:52:16.421	staff_1760209249802_llckjlapc	2025-10-12 18:52:16.421	0.00
0bdeb64d-5aeb-4a41-ac41-67ab64cd51b4	\N	veh_3132372054554e2034333739	127 TUN 4379	station-teboulba	TEBOULBA	2025-10-12 18:52:19.502	staff_1760209249802_llckjlapc	2025-10-12 18:52:19.502	0.00
6e7b57d4-c052-49cd-b2de-bb0326d622a7	\N	vehicle_1760251516726_v3xdgeaou	178TUN3446	station-teboulba	TEBOULBA	2025-10-12 18:52:24.061	staff_1760209249802_llckjlapc	2025-10-12 18:52:24.061	0.00
b0a1d929-04a3-4af7-8bc5-45344edcd8a4	\N	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	station-ksar-hlel	KSAR HLEL	2025-10-13 22:51:57.158	staff_1758995428363_2nhfegsve	2025-10-13 22:51:57.158	0.00
d7b93d5d-1d78-4a99-8d2d-f6a1cc749894	\N	veh_3133302054554e2033313438	130 TUN 3148	station-ksar-hlel	KSAR HLEL	2025-10-13 22:53:34.565	staff_1758995428363_2nhfegsve	2025-10-13 22:53:34.565	0.00
1924939a-76c6-4c10-930a-875810ceab2c	\N	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	station-ksar-hlel	KSAR HLEL	2025-10-13 23:03:18.93	staff_1758995428363_2nhfegsve	2025-10-13 23:03:18.93	0.00
bec2b58f-8895-43c4-9ce7-e63181246338	\N	ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	station-ksar-hlel	KSAR HLEL	2025-10-13 23:24:23.574	staff_1758995428363_2nhfegsve	2025-10-13 23:24:23.574	0.00
fc0d0b1a-3953-4974-a081-e48aa58dbd61	\N	10440f4d-acde-4772-8237-0a646d4fd650	252 TUN 5925	station-jemmal	JEMMAL	2025-10-13 23:31:40.132	staff_1758995428363_2nhfegsve	2025-10-13 23:31:40.132	0.00
47d95151-6435-4f50-b89f-174bd1c2cd7b	\N	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	station-jemmal	JEMMAL	2025-10-13 23:39:05.531	staff_1758995428363_2nhfegsve	2025-10-13 23:39:05.531	0.00
exit_pass_1760814212722653852	\N	a01d1105-9e36-4eba-b164-34e2bba4adf8	111 TUN 1111	station-moknin	Station Moknin	2025-10-18 20:03:32.712	staff_1758995428363_2nhfegsve	2025-10-18 20:03:32.712	0.00
exit_pass_1760814464579063584	\N	veh_3139312054554e2035323537	191 TUN 5257	station-ksar-hlel	KSAR HLEL	2025-10-18 20:07:44.576	staff_1758995428363_2nhfegsve	2025-10-18 20:07:44.576	0.00
exit_pass_1760814798293942552	\N	vehicle_1760251516726_v3xdgeaou	178TUN3446	station-teboulba	TEBOULBA	2025-10-18 20:13:18.292	staff_1758995428363_2nhfegsve	2025-10-18 20:13:18.292	0.00
exit_pass_1760815006911657701	\N	veh_3234342054554e2031333431	244 TUN 1341	station-ksar-hlel	KSAR HLEL	2025-10-18 20:16:46.906	staff_1758995428363_2nhfegsve	2025-10-18 20:16:46.906	0.00
exit_pass_1760823916776357644	\N	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	station-jemmal	JEMMAL	2025-10-18 22:45:16.772	staff_1758995428363_2nhfegsve	2025-10-18 22:45:16.772	0.00
\.


--
-- Data for Name: offline_customers; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.offline_customers (id, name, phone, cin, created_at) FROM stdin;
\.


--
-- Data for Name: operation_logs; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.operation_logs (id, staff_id, operation, details, success, error, created_at) FROM stdin;
14	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":2,"timestamp":"2025-09-30T15:54:50.854Z"}	t	\N	2025-09-30 15:54:50.855
15	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-01T08:32:10.841Z"}	t	\N	2025-10-01 08:32:10.841
16	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-01T14:05:38.626Z"}	t	\N	2025-10-01 14:05:38.627
17	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-03T07:47:29.190Z"}	t	\N	2025-10-03 07:47:29.191
18	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-03T23:00:00.027Z"}	t	\N	2025-10-03 23:00:00.028
19	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-04T10:11:12.321Z"}	t	\N	2025-10-04 10:11:12.321
20	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":1,"timestamp":"2025-10-05T14:53:22.524Z"}	t	\N	2025-10-05 14:53:22.524
21	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-05T15:34:52.804Z"}	t	\N	2025-10-05 15:34:52.804
22	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-05T23:00:00.022Z"}	t	\N	2025-10-05 23:00:00.022
23	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-06T23:00:00.037Z"}	t	\N	2025-10-06 23:00:00.037
24	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-07T07:03:10.868Z"}	t	\N	2025-10-07 07:03:10.869
25	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-07T23:00:00.031Z"}	t	\N	2025-10-07 23:00:00.031
26	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":4,"timestamp":"2025-10-08T09:18:39.867Z"}	t	\N	2025-10-08 09:18:39.867
27	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-08T23:00:00.034Z"}	t	\N	2025-10-08 23:00:00.034
28	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":8,"timestamp":"2025-10-09T13:59:20.574Z"}	t	\N	2025-10-09 13:59:20.574
29	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-09T14:07:55.853Z"}	t	\N	2025-10-09 14:07:55.853
30	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-09T17:30:01.561Z"}	t	\N	2025-10-09 17:30:01.561
31	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-09T23:00:00.034Z"}	t	\N	2025-10-09 23:00:00.034
32	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":3,"timestamp":"2025-10-10T23:00:00.046Z"}	t	\N	2025-10-10 23:00:00.046
33	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-11T13:27:01.323Z"}	t	\N	2025-10-11 13:27:01.324
34	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-11T23:00:00.037Z"}	t	\N	2025-10-11 23:00:00.037
35	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":12,"timestamp":"2025-10-12T04:48:33.083Z"}	t	\N	2025-10-12 04:48:33.084
36	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T09:02:42.749Z"}	t	\N	2025-10-12 09:02:42.749
37	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T09:29:51.785Z"}	t	\N	2025-10-12 09:29:51.785
38	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T09:30:50.270Z"}	t	\N	2025-10-12 09:30:50.27
39	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T09:33:30.554Z"}	t	\N	2025-10-12 09:33:30.555
40	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T11:45:47.582Z"}	t	\N	2025-10-12 11:45:47.582
41	\N	CRON_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-12T23:00:00.028Z"}	t	\N	2025-10-12 23:00:00.028
42	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":97,"timestamp":"2025-10-13T05:18:02.323Z"}	t	\N	2025-10-13 05:18:02.325
43	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T09:09:20.163Z"}	t	\N	2025-10-13 09:09:20.164
44	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T09:40:57.853Z"}	t	\N	2025-10-13 09:40:57.854
45	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T12:53:05.943Z"}	t	\N	2025-10-13 12:53:05.944
46	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T12:53:39.058Z"}	t	\N	2025-10-13 12:53:39.058
47	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T12:54:10.695Z"}	t	\N	2025-10-13 12:54:10.695
48	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T13:38:48.741Z"}	t	\N	2025-10-13 13:38:48.742
49	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T13:39:32.946Z"}	t	\N	2025-10-13 13:39:32.948
50	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T13:39:52.645Z"}	t	\N	2025-10-13 13:39:52.646
51	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T14:40:05.956Z"}	t	\N	2025-10-13 14:40:05.957
52	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T14:44:27.630Z"}	t	\N	2025-10-13 14:44:27.631
53	\N	MANUAL_DAY_PASS_EXPIRATION	{"expiredCount":0,"timestamp":"2025-10-13T19:00:03.269Z"}	t	\N	2025-10-13 19:00:03.269
54	staff_1759175419713_ib5c2pncz	LOGIN	{"timestamp":"2025-10-14T05:28:26.164Z"}	t	\N	2025-10-14 06:28:26.167
\.


--
-- Data for Name: print_queue; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.print_queue (id, job_type, content, staff_name, priority, status, created_at, completed_at, failed_at, retry_count) FROM stdin;
\.


--
-- Data for Name: printers; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.printers (id, name, ip_address, port, is_enabled, is_online, station_id, last_seen, last_error, error_count, created_at, updated_at) FROM stdin;
tm-t20x-default	TM-T20X Default	192.168.192.11	9100	t	f	default-station	\N	\N	0	2025-10-16 21:42:52.193283	2025-10-16 21:42:52.193283
\.


--
-- Data for Name: routes; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.routes (id, station_id, station_name, base_price, governorate, governorate_ar, delegation, delegation_ar, is_active, updated_at) FROM stdin;
route_1759022113843_1g055mpvx	station-ksar-hlel	KSAR HLEL	1.75	Monastir	\N	ksar hlel	\N	t	2025-09-28 01:15:13.845
route_1759022367969_hh3lxici0	station-jemmal	JEMMAL	1.8	Monastir	\N	JEMMAL	\N	t	2025-09-28 01:19:27.97
route_1759022381472_lsv51xtz9	station-moknin	MOKNIN	2.05	Monastir	\N	MOKNIN	\N	t	2025-09-28 01:19:41.473
route_1759022418090_8ddnbc47e	station-teboulba	TEBOULBA	2.4	Monastir	\N	TEBOULBA	\N	t	2025-09-28 01:20:18.091
935f73a2-f436-47b7-88b5-b728f357453e	station-sahline	SAHLINE	1.9	Monastir	\N	SAHLINE	\N	t	2025-10-15 10:35:05.183
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.sessions (id, staff_id, token, staff_data, is_active, last_activity, expires_at, created_offline, last_offline_at, created_at) FROM stdin;
cmgnjezkm00094ahqf7we2798	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjYzNDYxLCJleHAiOjE3NjI4NTU0NjF9.et0zT3LyY7EnVNyCy1Xe_Oxn4Noy0Eopfxb3wNyPNDk	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T10:04:21.519Z","loginTime":"2025-10-12T10:04:21.519Z"}	f	2025-10-12 10:04:21.525	2025-11-11 10:04:21	f	\N	2025-10-12 10:04:21.526
cmgjmaq9e00034a5j29sgk6dj	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAwMjY0MzYsImV4cCI6MTc2MjYxODQzNn0.Oqu5x-NdnClDsqpwYdekcogR2o_L09tEXQIfS_r-2tY	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-09T16:13:56.966Z","loginTime":"2025-10-09T16:13:56.966Z"}	f	2025-10-09 16:13:56.977	2025-11-08 16:13:56	f	\N	2025-10-09 16:13:56.978
cmgjmh07u00054a5j41htmohg	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDI2NzI5LCJleHAiOjE3NjI2MTg3Mjl9.OTyUu7GHOOoldZRFzrnhNG--OwgNqc_O_Evgl96z2HA	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T16:18:49.809Z","loginTime":"2025-10-09T16:18:49.809Z"}	f	2025-10-09 16:18:49.818	2025-11-08 16:18:49	f	\N	2025-10-09 16:18:49.819
cmgmk0i7i00014a80a1ok3vhj	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyMDM5OTksImV4cCI6MTc2Mjc5NTk5OX0.uQP6NfHaH8ecd_AQHkx7mntKlPLjTG1bygjSTRWlWaA	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-11T17:33:19.267Z","loginTime":"2025-10-11T17:33:19.267Z"}	f	2025-10-11 17:33:19.278	2025-11-10 17:33:19	f	\N	2025-10-11 17:33:19.279
cmgmk1v3i00034a805o8y7zdy	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyMDQwNjIsImV4cCI6MTc2Mjc5NjA2Mn0.ZDhv1NG8opIEGcGAxBMNBs-GPQ9svenN2H_I7pZt29Y	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-11T17:34:22.630Z","loginTime":"2025-10-11T17:34:22.630Z"}	f	2025-10-11 17:34:22.638	2025-11-10 17:34:22	f	\N	2025-10-11 17:34:22.639
cmgnekenx001v4a8cdnkxlkow	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjU1MzE2LCJleHAiOjE3NjI4NDczMTZ9.ArE2Qz1FQpIlWBjBGp6Z2tVqyGJY_MwU-GYFIAxrJdE	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T07:48:36.278Z","loginTime":"2025-10-12T07:48:36.278Z"}	f	2025-10-12 07:48:36.285	2025-11-11 07:48:36	f	\N	2025-10-12 07:48:36.286
cmgnenmwh001x4a8csh9gwggf	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjU1NDY2LCJleHAiOjE3NjI4NDc0NjZ9.3Sh0a_54VgEPw7gZQJ0p5cii17gTNzcXQnFjcKSSbx8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T07:51:06.921Z","loginTime":"2025-10-12T07:51:06.921Z"}	f	2025-10-12 07:51:06.929	2025-11-11 07:51:06	f	\N	2025-10-12 07:51:06.929
cmgniqnt100014ahqe7uzczsz	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjYyMzI2LCJleHAiOjE3NjI4NTQzMjZ9.Fmgj976cXeB0fsNpJpY3YWD7W84ucx5YN1ExzjVgQJE	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T09:45:26.516Z","loginTime":"2025-10-12T09:45:26.516Z"}	f	2025-10-12 09:45:26.533	2025-11-11 09:45:26	f	\N	2025-10-12 09:45:26.534
cmgnjs10d000b4ahqmpa9dd0r	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjY0MDY5LCJleHAiOjE3NjI4NTYwNjl9.AV_xP2mrkDEfSHFy_urm7hNYA_cKmK5pJEcjGb_Pi_8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T10:14:29.907Z","loginTime":"2025-10-12T10:14:29.907Z"}	f	2025-10-12 10:14:29.916	2025-11-11 10:14:29	f	\N	2025-10-12 10:14:29.917
cmgjuphjy000l4a5j7ethpkgv	staff_1759571310147_i6fil8b2b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTU3MTMxMDE0N19pNmZpbDhiMmIiLCJjaW4iOiIwNjc4MDkyMiIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDQwNTYyLCJleHAiOjE3NjI2MzI1NjJ9.vC0ZoPNotf1dgCIhYhIfpBxzMcBy1coxGD4A1zXkQLk	{"id":"staff_1759571310147_i6fil8b2b","cin":"06780922","firstName":"salah","lastName":"gassouma","role":"ADMIN","phoneNumber":"06780922","lastLogin":"2025-10-09T20:09:22.449Z","loginTime":"2025-10-09T20:09:22.449Z"}	f	2025-10-12 21:18:40.907	2025-11-08 20:09:22	f	\N	2025-10-09 20:09:22.462
cmgnjty3k000d4ahqwpy4ih67	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjY0MTU5LCJleHAiOjE3NjI4NTYxNTl9.VtpF6m4Iz45L0k3cNmAIger2UGWI5OE1LaLWZrQhX_k	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T10:15:59.447Z","loginTime":"2025-10-12T10:15:59.447Z"}	f	2025-10-12 11:23:35.279	2025-11-11 10:15:59	f	\N	2025-10-12 10:15:59.457
cmgjmhakx00074a5j3nthgybf	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAwMjY3NDMsImV4cCI6MTc2MjYxODc0M30.Sy17SczM1n_MxP--jxNIQXkAN9ecInzEwYq1Imq5oy0	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-09T16:19:03.239Z","loginTime":"2025-10-09T16:19:03.239Z"}	f	2025-10-09 17:22:13.745	2025-11-08 16:19:03	f	\N	2025-10-09 16:19:03.249
cmgmkomfs00054a8022v5xetk	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjA1MTI0LCJleHAiOjE3NjI3OTcxMjR9.7ioE7T6YsRA0-b-Iq5KCop-mKHLuWNwO_I7rnrBSITE	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-11T17:52:04.494Z","loginTime":"2025-10-11T17:52:04.494Z"}	f	2025-10-11 17:52:04.504	2025-11-10 17:52:04	f	\N	2025-10-11 17:52:04.505
cmgnnufl100014a9zs7ytob7w	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjcwOTAwLCJleHAiOjE3NjI4NjI5MDB9.8wlOBijfEoG18hcFKloNw3NEN40lGgHWXxc9eLybNA0	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T12:08:20.571Z","loginTime":"2025-10-12T12:08:20.571Z"}	f	2025-10-12 13:08:20.621	2025-11-11 12:08:20	f	\N	2025-10-12 12:08:20.581
cmgna0tfb00034a8crznihi5v	staff_1760247605348_8h4p63gzo	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzYwNTM0OF84aDRwNjNnem8iLCJjaW4iOiIwNjkxOTkyMCIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI0NzY4MywiZXhwIjoxNzYyODM5NjgzfQ.j0ciML6ekb7utLakzmirFZlSxj-77L1BxRY0boEwDws	{"id":"staff_1760247605348_8h4p63gzo","cin":"06919920","firstName":"wael","lastName":"boussaid","role":"WORKER","phoneNumber":"58991429","lastLogin":"2025-10-12T05:41:23.824Z","loginTime":"2025-10-12T05:41:23.824Z"}	f	2025-10-12 06:41:43.825	2025-11-11 05:41:23	f	\N	2025-10-12 05:41:23.831
cmgneu8y6001z4a8c3xbexx7y	staff_1760247605348_8h4p63gzo	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzYwNTM0OF84aDRwNjNnem8iLCJjaW4iOiIwNjkxOTkyMCIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI1NTc3NSwiZXhwIjoxNzYyODQ3Nzc1fQ.alN1ryrsCfcJquAK3-7tJKzGzcJK1GmnimJNUlHSU_Q	{"id":"staff_1760247605348_8h4p63gzo","cin":"06919920","firstName":"wael","lastName":"boussaid","role":"WORKER","phoneNumber":"58991429","lastLogin":"2025-10-12T07:56:15.430Z","loginTime":"2025-10-12T07:56:15.430Z"}	f	2025-10-12 07:56:15.437	2025-11-11 07:56:15	f	\N	2025-10-12 07:56:15.438
cmgniqvrw00034ahqhfqcgixp	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjYyMzM2LCJleHAiOjE3NjI4NTQzMzZ9.tEOcbVhkHyDFWmctVJ_GfXTHOUsyiD6_V1b9f9Cd5I8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T09:45:36.852Z","loginTime":"2025-10-12T09:45:36.852Z"}	f	2025-10-12 09:45:36.859	2025-11-11 09:45:36	f	\N	2025-10-12 09:45:36.86
cmgnja73c00054ahqy1ortts8	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjYzMjM3LCJleHAiOjE3NjI4NTUyMzd9.4Qa3IRI644Xwl2m1g1F59H5WLpUgnjYkKtWWZes5ErY	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T10:00:37.983Z","loginTime":"2025-10-12T10:00:37.983Z"}	f	2025-10-12 10:00:37.992	2025-11-11 10:00:37	f	\N	2025-10-12 10:00:37.992
cmgjn4p9o00094a5j6vjdrx2h	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDI3ODM1LCJleHAiOjE3NjI2MTk4MzV9._33mwZHpbTFqncBMj2mHDbSmYgVQfzOacsAnDkOOv-0	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T16:37:15.361Z","loginTime":"2025-10-09T16:37:15.361Z"}	f	2025-10-09 16:37:15.371	2025-11-08 16:37:15	f	\N	2025-10-09 16:37:15.372
cmgmms6wm00074a80wcf71rkf	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjA4NjUwLCJleHAiOjE3NjI4MDA2NTB9.rEwGTVJItln6s2UtM4ZuabUVDw1F5zJDty52KKawbZ4	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-11T18:50:50.220Z","loginTime":"2025-10-11T18:50:50.220Z"}	f	2025-10-11 18:50:50.23	2025-11-10 18:50:50	f	\N	2025-10-11 18:50:50.231
cmgo7ndc1000r4a9zc00t4kgk	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAzMDQxNjMsImV4cCI6MTc2Mjg5NjE2M30.t6LwBCq3l1642bdFjalUdcBqnI-BnJDoKw0QKYJKI98	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T21:22:43.384Z","loginTime":"2025-10-12T21:22:43.384Z"}	f	2025-10-12 21:22:43.393	2025-11-11 21:22:43	f	\N	2025-10-12 21:22:43.393
cmgnmb40p000f4ahqyl2e5cwa	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjY4MzE5LCJleHAiOjE3NjI4NjAzMTl9.hcWoeTAgxA0KOpKWu1zCHgZplq3dkugXfXC-xH8dIds	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T11:25:19.502Z","loginTime":"2025-10-12T11:25:19.502Z"}	f	2025-10-12 11:25:19.512	2025-11-11 11:25:19	f	\N	2025-10-12 11:25:19.513
cmgn8a8fc00014a8cc5dyd9fk	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyNDQ3NjMsImV4cCI6MTc2MjgzNjc2M30.Oc10mEXZDFNIwdTsyAvRMcCEzUmNdSnlyy-ul3_9zzU	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T04:52:43.934Z","loginTime":"2025-10-12T04:52:43.934Z"}	f	2025-10-12 14:54:55.443	2025-11-11 04:52:43	f	\N	2025-10-12 04:52:43.944
cmgnfgiu100214a8cjd4ph4ey	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjU2ODE0LCJleHAiOjE3NjI4NDg4MTR9.uvIVz9D6HFxmSRFIIictZO_CG83WjoX6lIcPO8drSmk	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T08:13:34.672Z","loginTime":"2025-10-12T08:13:34.672Z"}	f	2025-10-12 08:13:34.681	2025-11-11 08:13:34	f	\N	2025-10-12 08:13:34.681
cmgnfioge00234a8c7689v1vj	staff_1760247605348_8h4p63gzo	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzYwNTM0OF84aDRwNjNnem8iLCJjaW4iOiIwNjkxOTkyMCIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI1NjkxNSwiZXhwIjoxNzYyODQ4OTE1fQ.24qA3JAD5Tzbp-H7bfpYWBFnbJ94Vz0DX_LD_5vi_V8	{"id":"staff_1760247605348_8h4p63gzo","cin":"06919920","firstName":"wael","lastName":"boussaid","role":"WORKER","phoneNumber":"58991429","lastLogin":"2025-10-12T08:15:15.271Z","loginTime":"2025-10-12T08:15:15.271Z"}	f	2025-10-12 09:29:55.35	2025-11-11 08:15:15	f	\N	2025-10-12 08:15:15.279
cmgnjat3600074ahq2h6ewqyt	staff_1760247605348_8h4p63gzo	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzYwNTM0OF84aDRwNjNnem8iLCJjaW4iOiIwNjkxOTkyMCIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI2MzI2NiwiZXhwIjoxNzYyODU1MjY2fQ.eCuNdf_B82Oc6ot6Hxudhi5yFr_CnglPC9qha9u7xoc	{"id":"staff_1760247605348_8h4p63gzo","cin":"06919920","firstName":"wael","lastName":"boussaid","role":"WORKER","phoneNumber":"58991429","lastLogin":"2025-10-12T10:01:06.488Z","loginTime":"2025-10-12T10:01:06.488Z"}	t	2025-10-12 10:01:06.497	2025-11-11 10:01:06	f	\N	2025-10-12 10:01:06.498
cmgjnlqjk000b4a5ja8jydqls	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDI4NjMwLCJleHAiOjE3NjI2MjA2MzB9.0x3gk1EENq6aF3ir9nSdga5Oh8APBErFdYva6b1WI8o	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T16:50:30.166Z","loginTime":"2025-10-09T16:50:30.166Z"}	f	2025-10-09 16:50:30.176	2025-11-08 16:50:30	f	\N	2025-10-09 16:50:30.176
cmgo7s4k3000t4a9zgp50zbfu	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAzMDQzODUsImV4cCI6MTc2Mjg5NjM4NX0.O6hAb-lr3JdAWGpNMK7bKolkaIPAEXAL842-eJS2pYk	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"ALA","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T21:26:25.290Z","loginTime":"2025-10-12T21:26:25.290Z"}	f	2025-10-12 21:26:25.298	2025-11-11 21:26:25	f	\N	2025-10-12 21:26:25.299
cmgnmm3si000h4ahq5ctb9uqw	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjY4ODMyLCJleHAiOjE3NjI4NjA4MzJ9.06Lkkx497W-EThpMGMFoGyaurAhJw5UBslVJ4ks5Elc	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T11:33:52.423Z","loginTime":"2025-10-12T11:33:52.423Z"}	f	2025-10-12 11:33:52.433	2025-11-11 11:33:52	f	\N	2025-10-12 11:33:52.434
cmgndo2up001r4a8c77dry726	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjUzODA3LCJleHAiOjE3NjI4NDU4MDd9.8z3gQ9qleoq5MxlPX1_2UeQ-e7SmJekuRkx8-BSBA5Q	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T07:23:27.976Z","loginTime":"2025-10-12T07:23:27.976Z"}	f	2025-10-12 07:23:27.984	2025-11-11 07:23:27	f	\N	2025-10-12 07:23:27.985
cmgndor8s001t4a8chzlneadq	staff_1760247605348_8h4p63gzo	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzYwNTM0OF84aDRwNjNnem8iLCJjaW4iOiIwNjkxOTkyMCIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI1MzgzOSwiZXhwIjoxNzYyODQ1ODM5fQ.kRycY8ueera1Oweh7hhICEJbNgMZnfsSW88BSjZ9dy4	{"id":"staff_1760247605348_8h4p63gzo","cin":"06919920","firstName":"wael","lastName":"boussaid","role":"WORKER","phoneNumber":"58991429","lastLogin":"2025-10-12T07:23:59.590Z","loginTime":"2025-10-12T07:23:59.590Z"}	f	2025-10-12 07:23:59.596	2025-11-11 07:23:59	f	\N	2025-10-12 07:23:59.596
cmgnqgwfh00034a9zcuwjetfc	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjc1MzA4LCJleHAiOjE3NjI4NjczMDh9.dM-bgNO1Ea-wr2RoqC6rj1cvFWWe0B0xyPxj2WszX44	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T13:21:48.066Z","loginTime":"2025-10-12T13:21:48.066Z"}	f	2025-10-12 13:21:48.076	2025-11-11 13:21:48	f	\N	2025-10-12 13:21:48.077
cmgnqmyqy00054a9zmjkhq4jp	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjc1NTkxLCJleHAiOjE3NjI4Njc1OTF9.CtpqEyDliyqBSv40aQW_SuwRq88Q7Jhj8WXMmMwgK3o	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T13:26:31.009Z","loginTime":"2025-10-12T13:26:31.009Z"}	f	2025-10-12 13:26:31.017	2025-11-11 13:26:31	f	\N	2025-10-12 13:26:31.018
cmgmmsvrj00094a80ssha6fc3	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyMDg2ODIsImV4cCI6MTc2MjgwMDY4Mn0.HIfjy29MmnZ5BZX57J_2tA2Ij4vS6RVb8WfKZrh1rao	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-11T18:51:22.438Z","loginTime":"2025-10-11T18:51:22.438Z"}	f	2025-10-11 18:51:22.447	2025-11-10 18:51:22	f	\N	2025-10-11 18:51:22.448
cmgjp5j0h000d4a5j0m3nty1m	staff_1759571310147_i6fil8b2b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTU3MTMxMDE0N19pNmZpbDhiMmIiLCJjaW4iOiIwNjc4MDkyMiIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDMxMjMzLCJleHAiOjE3NjI2MjMyMzN9.0xW3vFoYlmCvzJOfgde9sK6WfmFHhJPKuA_T0-XptP0	{"id":"staff_1759571310147_i6fil8b2b","cin":"06780922","firstName":"salah","lastName":"gassouma","role":"ADMIN","phoneNumber":"06780922","lastLogin":"2025-10-09T17:33:53.145Z","loginTime":"2025-10-09T17:33:53.145Z"}	f	2025-10-09 17:33:53.153	2025-11-08 17:33:53	f	\N	2025-10-09 17:33:53.154
cmgnmtx86000j4ahqn6suyv6y	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjY5MTk3LCJleHAiOjE3NjI4NjExOTd9.k6kTU-RpwiUER1dXSSBj2-zu6E8UH9Ni3rcVfwOYE_s	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T11:39:57.164Z","loginTime":"2025-10-12T11:39:57.165Z"}	f	2025-10-12 11:39:57.174	2025-11-11 11:39:57	f	\N	2025-10-12 11:39:57.174
cmgmmzl54000b4a806ctzd107	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjA4OTk1LCJleHAiOjE3NjI4MDA5OTV9.icowFBwnAmHREGkVIn0BPxLPmW9hCfup_EhMmtPdx4Q	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-11T18:56:35.261Z","loginTime":"2025-10-11T18:56:35.261Z"}	f	2025-10-12 06:25:11.705	2025-11-10 18:56:35	f	\N	2025-10-11 18:56:35.272
cmgna9ehm000d4a8cui5w3e8e	staff_1760247642213_in7dp0fty	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDI0NzY0MjIxM19pbjdkcDBmdHkiLCJjaW4iOiIwNjk3NDM2MyIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc2MDI0ODA4NCwiZXhwIjoxNzYyODQwMDg0fQ.3gvvNLfSzX5bOAD_zLze_XK7-4zRKTakQf2bo69pOks	{"id":"staff_1760247642213_in7dp0fty","cin":"06974363","firstName":"lassad","lastName":"bhouri","role":"WORKER","phoneNumber":"95144141","lastLogin":"2025-10-12T05:48:04.371Z","loginTime":"2025-10-12T05:48:04.371Z"}	t	2025-10-13 02:22:14.805	2025-11-11 05:48:04	f	\N	2025-10-12 05:48:04.379
cmgnrk3ml00074a9zmcxce3td	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjc3MTM2LCJleHAiOjE3NjI4NjkxMzZ9.2X3PbIOsoK356lySEbpKtQpJVNGaXCsyfvzPA7sGwt0	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T13:52:16.982Z","loginTime":"2025-10-12T13:52:16.982Z"}	f	2025-10-12 16:53:11.671	2025-11-11 13:52:16	f	\N	2025-10-12 13:52:16.989
cmg5l1hw9000b4a5kz1ov8uex	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5MTc3Nzk5LCJleHAiOjE3NjE3Njk3OTl9.guw7gjPrFodnDvh2WKlWvdkI-_OAwn683S7MYsOJomE	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-09-29T20:29:59.723Z","loginTime":"2025-09-29T20:29:59.723Z"}	f	2025-09-29 20:30:00.152	2025-10-29 20:29:59	f	\N	2025-09-29 20:30:00.153
cmg5jobxc00054a5kaj7oqxjm	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTkxNzU1MDUsImV4cCI6MTc2MTc2NzUwNX0.wo31hVtlEkwZHH8_IwL0I4R4-0CWVcFXd7Q1MDljZgU	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-09-29T19:51:45.838Z","loginTime":"2025-09-29T19:51:45.838Z"}	f	2025-09-29 19:51:46.272	2025-10-29 19:51:45	f	\N	2025-09-29 19:51:46.272
cmgjpkyzv000f4a5j5zyr479m	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDMxOTUzLCJleHAiOjE3NjI2MjM5NTN9.JXnYSs5GfR1fcZKFwzTPiMjzS3FHo2fu0SciHdBdFWs	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T17:45:53.697Z","loginTime":"2025-10-09T17:45:53.697Z"}	f	2025-10-09 17:45:53.706	2025-11-08 17:45:53	f	\N	2025-10-09 17:45:53.707
cmgo8vbzv000x4a9z0bz9utnl	staff_1759571310147_i6fil8b2b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTU3MTMxMDE0N19pNmZpbDhiMmIiLCJjaW4iOiIwNjc4MDkyMiIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzA2MjE0LCJleHAiOjE3NjI4OTgyMTR9.yU_kXLAzj-cChCHHMTYRxWDukCNEeWt5MXzSYGBCBOA	{"id":"staff_1759571310147_i6fil8b2b","cin":"06780922","firstName":"salah","lastName":"gassouma","role":"ADMIN","phoneNumber":"06780922","lastLogin":"2025-10-12T21:56:54.514Z","loginTime":"2025-10-12T21:56:54.514Z"}	t	2025-10-12 21:56:54.522	2025-11-11 21:56:54	f	\N	2025-10-12 21:56:54.523
cmg5jldy500034a5ksmr8syxz	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5MTc1MzY4LCJleHAiOjE3NjE3NjczNjh9.rHwRxLhvE0czFYe2zIxov_TOvf5-KO1tXvcIJg4EL-M	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-09-29T19:49:28.500Z","loginTime":"2025-09-29T19:49:28.500Z"}	f	2025-09-29 19:49:28.925	2025-10-29 19:49:28	f	\N	2025-09-29 19:49:28.925
cmg5k4eaj00094a5k5o3j5lvu	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5MTc2MjU1LCJleHAiOjE3NjE3NjgyNTV9.wDK97SHNqnrweVayDwKQPKdi5LpKWCzwzxkuSfFKh3w	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-09-29T20:04:15.408Z","loginTime":"2025-09-29T20:04:15.408Z"}	f	2025-09-29 20:04:15.835	2025-10-29 20:04:15	f	\N	2025-09-29 20:04:15.835
cmg5jpt0600074a5kadlkvgvk	staff_1759175512105_5uy7rwamf	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTUxMjEwNV81dXk3cndhbWYiLCJjaW4iOiIwNjc1MTMyMyIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc1OTE3NTU3NCwiZXhwIjoxNzYxNzY3NTc0fQ.h3eyRzcL7yMRPJpE2ngPpP3mPlAlSY-KFj6gM5Jptp0	{"id":"staff_1759175512105_5uy7rwamf","cin":"06751323","firstName":"fhal","lastName":"najah","role":"WORKER","phoneNumber":"06751323","lastLogin":"2025-09-29T19:52:54.633Z","loginTime":"2025-09-29T19:52:54.633Z"}	f	2025-09-29 19:52:55.061	2025-10-29 19:52:54	f	\N	2025-09-29 19:52:55.062
cmgmn5gnt000d4a80cpr2az09	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyMDkyNjksImV4cCI6MTc2MjgwMTI2OX0.shveqO1GIyX-rNn2YZilwCdzKrGLDduvJXUZnulBC2I	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-11T19:01:09.397Z","loginTime":"2025-10-11T19:01:09.397Z"}	f	2025-10-11 19:01:09.401	2025-11-10 19:01:09	f	\N	2025-10-11 19:01:09.401
cmgo8sl30000v4a9zwrzplsiz	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAzMDYwODYsImV4cCI6MTc2Mjg5ODA4Nn0.OkBE2cKTHiQJgp3f4YVP4F1m2rP_1Jxk_9TQSbmWTL8	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"ALA","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T21:54:46.323Z","loginTime":"2025-10-12T21:54:46.323Z"}	f	2025-10-12 21:54:46.332	2025-11-11 21:54:46	f	\N	2025-10-12 21:54:46.333
cmgnuc1pi00094a9zcq4nkx6r	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyODE4MDAsImV4cCI6MTc2Mjg3MzgwMH0.YOST-tWZI5qwx33aS88OjbsRnXl40LG8s0aVOiSevvY	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T15:10:00.093Z","loginTime":"2025-10-12T15:10:00.093Z"}	f	2025-10-12 17:11:00.077	2025-11-11 15:10:00	f	\N	2025-10-12 15:10:00.103
cmg5lak1x000d4a5kg6hrhx55	staff_1759175512105_5uy7rwamf	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTUxMjEwNV81dXk3cndhbWYiLCJjaW4iOiIwNjc1MTMyMyIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc1OTE3ODIyMiwiZXhwIjoxNzYxNzcwMjIyfQ.sE4SuCPMw2fqOROztdHyjlidtsmbSopPz83d1f_aRMA	{"id":"staff_1759175512105_5uy7rwamf","cin":"06751323","firstName":"fhal","lastName":"najah","role":"WORKER","phoneNumber":"06751323","lastLogin":"2025-09-29T20:37:02.426Z","loginTime":"2025-09-29T20:37:02.426Z"}	f	2025-09-29 20:37:02.853	2025-10-29 20:37:02	f	\N	2025-09-29 20:37:02.854
cmg5m1y8v000f4a5k2eot4tw0	staff_1759175512105_5uy7rwamf	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTUxMjEwNV81dXk3cndhbWYiLCJjaW4iOiIwNjc1MTMyMyIsInJvbGUiOiJXT1JLRVIiLCJzdGF0aW9uSWQiOiJsb2NhbCIsImlhdCI6MTc1OTE3OTUwMCwiZXhwIjoxNzYxNzcxNTAwfQ.XbncWT_eA6KUvHIiKRmf9COCgAufqSDvVzWfOYyVugk	{"id":"staff_1759175512105_5uy7rwamf","cin":"06751323","firstName":"fhal","lastName":"najah","role":"WORKER","phoneNumber":"06751323","lastLogin":"2025-09-29T20:58:20.532Z","loginTime":"2025-09-29T20:58:20.532Z"}	t	2025-09-29 20:58:20.959	2025-10-29 20:58:20	f	\N	2025-09-29 20:58:20.959
cmgc48fl700014ashpepyvxez	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk1NzI4MzMsImV4cCI6MTc2MjE2NDgzM30.2i5UuPQigQ4ZXeYK7FNMeELj1oIbU7uCPkJaRmIpFgY	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-04T10:13:53.087Z","loginTime":"2025-10-04T10:13:53.087Z"}	f	2025-10-04 10:13:53.515	2025-11-03 10:13:53	f	\N	2025-10-04 10:13:53.516
cmgc54ltp00034ashe3r28gsw	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk1NzQzMzQsImV4cCI6MTc2MjE2NjMzNH0.pD3SFNyWYxOAqWv7kPpEicaGhC0grh1L22vtA-qdOdY	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-04T10:38:54.157Z","loginTime":"2025-10-04T10:38:54.157Z"}	f	2025-10-04 10:38:54.589	2025-11-03 10:38:54	f	\N	2025-10-04 10:38:54.59
cmgg8zlxf00014a7cctsamfax	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4MjI2ODQsImV4cCI6MTc2MjQxNDY4NH0.7wUv9x47U7fnTqWCqAYMeTq9aoVcE33UEPKxX90po2Q	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T07:38:04.604Z","loginTime":"2025-10-07T07:38:04.604Z"}	f	2025-10-07 07:38:04.611	2025-11-06 07:38:04	f	\N	2025-10-07 07:38:04.612
cmgg95aax00034a7cxyy0jwhs	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4MjI5NDksImV4cCI6MTc2MjQxNDk0OX0.1lxbVihjUXUWAS2z-qWsUhoIzNzCzklVVJX92W_UmH0	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T07:42:29.474Z","loginTime":"2025-10-07T07:42:29.474Z"}	f	2025-10-07 07:42:29.481	2025-11-06 07:42:29	f	\N	2025-10-07 07:42:29.482
cmgc3ayta00014aa9cfxuf5t9	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5NTcxMjcxLCJleHAiOjE3NjIxNjMyNzF9.PfvXnz168P2JCQsxBTRKD8ijnDwDHwC4cfyVzemCyws	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-04T09:47:51.693Z","loginTime":"2025-10-04T09:47:51.693Z"}	f	2025-10-04 09:47:52.126	2025-11-03 09:47:51	f	\N	2025-10-04 09:47:52.127
cmgc3ss1i00034aa9zdvflcut	staff_1759571310147_i6fil8b2b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTU3MTMxMDE0N19pNmZpbDhiMmIiLCJjaW4iOiIwNjc4MDkyMiIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5NTcyMTAyLCJleHAiOjE3NjIxNjQxMDJ9.RBuFnkSeH-g1scaCb6vnKVGxruyG2hRvKitC4kAfG5w	{"id":"staff_1759571310147_i6fil8b2b","cin":"06780922","firstName":"salah","lastName":"gassouma","role":"ADMIN","phoneNumber":"06780922","lastLogin":"2025-10-04T10:01:42.733Z","loginTime":"2025-10-04T10:01:42.733Z"}	f	2025-10-04 10:01:43.158	2025-11-03 10:01:42	f	\N	2025-10-04 10:01:43.159
cmgnywyds000b4a9zslznge93	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyODk0OTQsImV4cCI6MTc2Mjg4MTQ5NH0.3wFXZQdJQm6kKOc_kiXLBqDaCkS2YXN5roo8wA27Emo	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T17:18:14.021Z","loginTime":"2025-10-12T17:18:14.021Z"}	f	2025-10-12 17:18:14.032	2025-11-11 17:18:14	f	\N	2025-10-12 17:18:14.032
cmgjpsuyw000h4a5jo5snxbwt	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDMyMzIxLCJleHAiOjE3NjI2MjQzMjF9.8GrMY1SSfuqw8A11hD6w7q3RSFuLSSzwf5-YW2zzBso	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T17:52:01.725Z","loginTime":"2025-10-09T17:52:01.725Z"}	f	2025-10-09 17:52:01.735	2025-11-08 17:52:01	f	\N	2025-10-09 17:52:01.736
cmgo8y6jq000z4a9zo7lfgorh	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAzMDYzNDcsImV4cCI6MTc2Mjg5ODM0N30.7O2Fcbvw1dWkVdOJ9ZQhJzC-4BzlJn83ZfFzMbgsKes	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"ALA","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T21:59:07.422Z","loginTime":"2025-10-12T21:59:07.422Z"}	t	2025-10-13 02:22:14.829	2025-11-11 21:59:07	f	\N	2025-10-12 21:59:07.431
cmghslta900014a88soy50geu	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTE2MDk5LCJleHAiOjE3NjI1MDgwOTl9.slWiiHAACUw9nx3yTPAewqX28QP6hffsvqu0edYC1D8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T09:34:59.446Z","loginTime":"2025-10-08T09:34:59.446Z"}	f	2025-10-08 09:34:59.457	2025-11-07 09:34:59	f	\N	2025-10-08 09:34:59.457
cmggfrks600094a7c7gp4o2sv	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4MzQwNjcsImV4cCI6MTc2MjQyNjA2N30.Y8_OYB_KdWrUC4mnVV5JkEp6yLLApR5iNziGISTiXZ8	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T10:47:47.181Z","loginTime":"2025-10-07T10:47:47.181Z"}	f	2025-10-07 10:47:47.189	2025-11-06 10:47:47	f	\N	2025-10-07 10:47:47.19
cmgg9657700054a7cr6t6eo7t	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4MjI5ODksImV4cCI6MTc2MjQxNDk4OX0.lYuHaRggt_RSj0k5BXLS8zOXuJ9DIJbK6QahowlX6e8	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"maher","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T07:43:09.513Z","loginTime":"2025-10-07T07:43:09.513Z"}	f	2025-10-07 07:43:09.522	2025-11-06 07:43:09	f	\N	2025-10-07 07:43:09.523
cmgg9zysc00074a7cuw8910ik	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5ODI0MzgwLCJleHAiOjE3NjI0MTYzODB9.L1DQB6SP2c0yl0QG3G3amU8TUmVweKCBHyxad9cXk0A	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-07T08:06:20.885Z","loginTime":"2025-10-07T08:06:20.885Z"}	f	2025-10-07 10:30:08.35	2025-11-06 08:06:20	f	\N	2025-10-07 08:06:20.893
cmggqwv87000d4a7coolo7edz	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4NTI3ODksImV4cCI6MTc2MjQ0NDc4OX0.5tpG-XIgpji5zHM1n_eHYieCSYuoagQf1F2l5Ws-CxE	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadal","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T15:59:49.776Z","loginTime":"2025-10-07T15:59:49.776Z"}	f	2025-10-07 15:59:49.783	2025-11-06 15:59:49	f	\N	2025-10-07 15:59:49.783
cmgnz3sye000d4a9znmtk2ccq	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyODk4MTMsImV4cCI6MTc2Mjg4MTgxM30.qnXprdA1ygr9HUc9u_ZCP3LKUO7QSg9NyQ0IAvwg_fU	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T17:23:33.580Z","loginTime":"2025-10-12T17:23:33.580Z"}	f	2025-10-12 17:23:33.59	2025-11-11 17:23:33	f	\N	2025-10-12 17:23:33.591
cmgjqhq75000j4a5ja9ubhj5o	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDMzNDgxLCJleHAiOjE3NjI2MjU0ODF9.UctDsN-GztDBjdTW52LbDqq7aCVtjRUEPRnZ7AbEWzw	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T18:11:21.939Z","loginTime":"2025-10-09T18:11:21.939Z"}	f	2025-10-11 17:25:56.532	2025-11-08 18:11:21	f	\N	2025-10-09 18:11:21.953
cmggfyfdw000b4a7c2hgy11so	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5ODM0Mzg2LCJleHAiOjE3NjI0MjYzODZ9.0CldIUzbH890EPE3exR0rEDoM181QGhUvKx6SeeBJUw	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-07T10:53:06.777Z","loginTime":"2025-10-07T10:53:06.777Z"}	f	2025-10-07 16:38:01.818	2025-11-06 10:53:06	f	\N	2025-10-07 10:53:06.788
cmggr8s7a000f4a7cid3zf5m8	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk4NTMzNDUsImV4cCI6MTc2MjQ0NTM0NX0.FSI_mJVSeU5jV7hfQcsFuK1Chbq4y9wXwJHs0_h838M	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-07T16:09:05.724Z","loginTime":"2025-10-07T16:09:05.724Z"}	f	2025-10-07 17:09:05.752	2025-11-06 16:09:05	f	\N	2025-10-07 16:09:05.734
cmgnz4vyw000f4a9z6svcy987	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyODk4NjQsImV4cCI6MTc2Mjg4MTg2NH0.8G8K3tWM782tFEp1--dg6SHG7nOEgSGxnQfhnrz_X9w	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T17:24:24.143Z","loginTime":"2025-10-12T17:24:24.143Z"}	f	2025-10-12 17:24:24.151	2025-11-11 17:24:24	f	\N	2025-10-12 17:24:24.152
cmgnz9emk000h4a9zto0dk3ml	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyOTAwNzQsImV4cCI6MTc2Mjg4MjA3NH0.yGO_X0Hj7X4dTgIjpjPGKuFHKlzCG66CD-3Pwyyc8kE	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-12T17:27:54.948Z","loginTime":"2025-10-12T17:27:54.948Z"}	f	2025-10-12 17:27:54.956	2025-11-11 17:27:54	f	\N	2025-10-12 17:27:54.957
cmght7bh900054a88xlirs3qh	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTE3MTAyLCJleHAiOjE3NjI1MDkxMDJ9.TparOQ2jKG7r1rFXtbivzpTLwoKAO4vodsuRnP44AgY	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T09:51:42.803Z","loginTime":"2025-10-08T09:51:42.803Z"}	f	2025-10-08 09:51:42.813	2025-11-07 09:51:42	f	\N	2025-10-08 09:51:42.813
cmghtby3s00074a88621oth63	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTE3MzE4LCJleHAiOjE3NjI1MDkzMTh9.sbpvrFeUnlQH5iojoy3H-4y5sI9RMGg242PKbwoyJ_c	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T09:55:18.751Z","loginTime":"2025-10-08T09:55:18.751Z"}	f	2025-10-08 09:55:18.759	2025-11-07 09:55:18	f	\N	2025-10-08 09:55:18.76
cmghth0oq00094a8809oug7mi	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTE3NTU1LCJleHAiOjE3NjI1MDk1NTV9.Fohi8I8QmUU1zWzPvWxuTkIzeDk3X2cFu1tzKlLcwGg	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T09:59:15.379Z","loginTime":"2025-10-08T09:59:15.379Z"}	f	2025-10-08 09:59:15.386	2025-11-07 09:59:15	f	\N	2025-10-08 09:59:15.387
cmghtjtzq000b4a88tc1ygt25	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTE3Njg2LCJleHAiOjE3NjI1MDk2ODZ9.eFS0uDo_4EwEqetUsLb1a3vgoEGAz9mhzhFpkbMTzwU	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T10:01:26.670Z","loginTime":"2025-10-08T10:01:26.670Z"}	f	2025-10-08 10:01:26.678	2025-11-07 10:01:26	f	\N	2025-10-08 10:01:26.679
cmghuy9ce000d4a88zadzezur	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTIwMDM5LCJleHAiOjE3NjI1MTIwMzl9.HgJcu8WbHHH00P2TgYPx6FDz2k91JiEmg__-nL2n7uo	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T10:40:39.364Z","loginTime":"2025-10-08T10:40:39.364Z"}	f	2025-10-08 10:40:39.373	2025-11-07 10:40:39	f	\N	2025-10-08 10:40:39.374
cmght6ngo00034a887t2obzm7	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk5MTcwNzEsImV4cCI6MTc2MjUwOTA3MX0.uYhfR4oQaAoyT0_O07mU9A2R2deObOR6Lm1Z-E118Ro	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-08T09:51:11.680Z","loginTime":"2025-10-08T09:51:11.680Z"}	f	2025-10-08 09:51:11.687	2025-11-07 09:51:11	f	\N	2025-10-08 09:51:11.688
cmghuz9xn000f4a88ws7kukwm	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTIwMDg2LCJleHAiOjE3NjI1MTIwODZ9.eCzWoLTJX-4ezNFbdXGftfqd9RDmq_5U2CvXnk-AH-I	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T10:41:26.787Z","loginTime":"2025-10-08T10:41:26.787Z"}	f	2025-10-08 10:41:26.795	2025-11-07 10:41:26	f	\N	2025-10-08 10:41:26.796
cmgo0q26q000j4a9zw5m5p21o	staff_1760209249802_llckjlapc	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc2MDIwOTI0OTgwMl9sbGNramxhcGMiLCJjaW4iOiIwNjkyMTY2MyIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyOTI1MzEsImV4cCI6MTc2Mjg4NDUzMX0.raZYH4phFfbok2jpIMkS1dMmM02Ya5yLLQSQ4WxFXE0	{"id":"staff_1760209249802_llckjlapc","cin":"06921663","firstName":"SI ","lastName":"ALA","role":"SUPERVISOR","phoneNumber":"22158703","lastLogin":"2025-10-12T18:08:51.591Z","loginTime":"2025-10-12T18:08:51.591Z"}	f	2025-10-12 18:08:51.602	2025-11-11 18:08:51	f	\N	2025-10-12 18:08:51.603
cmgo27hxp000n4a9z86e6qi3w	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyOTUwMjQsImV4cCI6MTc2Mjg4NzAyNH0.wdMcdkCcVCexMvECFiLRTk8vQwIiteMk5UehXtaxWrU	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-12T18:50:24.775Z","loginTime":"2025-10-12T18:50:24.775Z"}	t	2025-10-13 02:03:15.732	2025-11-11 18:50:24	f	\N	2025-10-12 18:50:24.781
cmgo1cd48000l4a9z3i0pifba	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAyOTM1NzIsImV4cCI6MTc2Mjg4NTU3Mn0.ym1Y80No5NK5XX1LiezDJJqlz7Oc-ehLWBsdc5C9dVw	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-12T18:26:12.191Z","loginTime":"2025-10-12T18:26:12.191Z"}	f	2025-10-12 18:26:12.199	2025-11-11 18:26:12	f	\N	2025-10-12 18:26:12.2
cmghv0ibw000h4a881v95j8lx	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NTk5MjAxNDQsImV4cCI6MTc2MjUxMjE0NH0._4qHfuJ-5U_cDOAUtQTDEeWkpA1FQTaHLe8MEkfG2rk	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-08T10:42:24.322Z","loginTime":"2025-10-08T10:42:24.322Z"}	f	2025-10-08 18:00:40.45	2025-11-07 10:42:24	f	\N	2025-10-08 10:42:24.332
cmgjhp78x00014aw77ynbpuvw	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDE4NzE0LCJleHAiOjE3NjI2MTA3MTR9.vna0audkrzg8F6YfwniSVUAe_u40-M9gH1GnrvRlMyk	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T14:05:14.089Z","loginTime":"2025-10-09T14:05:14.089Z"}	f	2025-10-09 14:05:14.097	2025-11-08 14:05:14	f	\N	2025-10-09 14:05:14.098
cmghwf7jd000j4a88w7uqd6jp	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTIyNTA5LCJleHAiOjE3NjI1MTQ1MDl9.IRcYb4COEK5QtySHdu1wfGPxyLWLpJfldCGC7HBVzXk	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T11:21:49.790Z","loginTime":"2025-10-08T11:21:49.790Z"}	f	2025-10-08 16:34:52.458	2025-11-07 11:21:49	f	\N	2025-10-08 11:21:49.801
cmgi7orc8000l4a88vu3cx3vp	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTQxNDMxLCJleHAiOjE3NjI1MzM0MzF9.XSuQZTdA7w-uI7CIzWF4DNhyvPjUkQw9hCSK-Iuhblg	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T16:37:11.134Z","loginTime":"2025-10-08T16:37:11.134Z"}	f	2025-10-08 16:37:11.144	2025-11-07 16:37:11	f	\N	2025-10-08 16:37:11.145
cmgi8h06z000n4a88xfyvps2g	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTQyNzQ4LCJleHAiOjE3NjI1MzQ3NDh9.7YARRou55vJuOgOzMoU3FvChkcU-i6i0olj1kiPArmk	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T16:59:08.979Z","loginTime":"2025-10-08T16:59:08.979Z"}	f	2025-10-08 16:59:08.986	2025-11-07 16:59:08	f	\N	2025-10-08 16:59:08.987
cmgi9wbnr000p4a88ldn4i35b	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTQ1MTQzLCJleHAiOjE3NjI1MzcxNDN9.IlJgutb-heFMVapAurvzP2PI3c-fsGBESkRk2UmdOBQ	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T17:39:03.293Z","loginTime":"2025-10-08T17:39:03.293Z"}	f	2025-10-08 17:39:03.302	2025-11-07 17:39:03	f	\N	2025-10-08 17:39:03.303
cmgjg4fuq000t4a887glhj1j0	staff_1759175419713_ib5c2pncz	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1OTE3NTQxOTcxM19pYjVjMnBuY3oiLCJjaW4iOiIwNjc3MjM0MCIsInJvbGUiOiJTVVBFUlZJU09SIiwic3RhdGlvbklkIjoibG9jYWwiLCJpYXQiOjE3NjAwMTYwNjUsImV4cCI6MTc2MjYwODA2NX0.wznvE0nV340h-w1RVRx_sk_3W8QA7aJUm0o6zQQjnrY	{"id":"staff_1759175419713_ib5c2pncz","cin":"06772340","firstName":"fadhel","lastName":"mehri","role":"SUPERVISOR","phoneNumber":"06772340","lastLogin":"2025-10-09T13:21:05.853Z","loginTime":"2025-10-09T13:21:05.853Z"}	f	2025-10-09 15:52:28.771	2025-11-08 13:21:05	f	\N	2025-10-09 13:21:05.858
cmgjhsu5j00014a5jjlgpov9t	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMDE4ODgzLCJleHAiOjE3NjI2MTA4ODN9.SG7FXBYkp07UwXrJcq1jwXv8ctlOp3Ymq3WmyJRzGMI	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-09T14:08:03.742Z","loginTime":"2025-10-09T14:08:03.742Z"}	f	2025-10-09 14:08:03.751	2025-11-08 14:08:03	f	\N	2025-10-09 14:08:03.752
cmgiamurp000r4a88r9ivxn4w	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzU5OTQ2MzgxLCJleHAiOjE3NjI1MzgzODF9.8VFggGZgOUn8xhqvnsTBxNhRBUmMTgPS5-RTvY7BLk8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-08T17:59:41.115Z","loginTime":"2025-10-08T17:59:41.115Z"}	f	2025-10-08 17:59:41.124	2025-11-07 17:59:41	f	\N	2025-10-08 17:59:41.125
cmgo28mxf000p4a9zne5c3zrh	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMjk1MDc3LCJleHAiOjE3NjI4ODcwNzd9.qLmYUqxd4FFj526SjZslm-qi4hG5OTafhgTaJs_yGJg	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-12T18:51:17.900Z","loginTime":"2025-10-12T18:51:17.900Z"}	f	2025-10-12 21:21:48.194	2025-11-11 18:51:17	f	\N	2025-10-12 18:51:17.907
cmgpge8280007i0eqybbxjgno	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzc5MzE5LCJleHAiOjE3NjI5NzEzMTl9.NU6pJ4lv3VuKxB3IrKkLpwx8nGuX6Gl9kShs_dJOL3o	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T18:15:19.344Z","loginTime":"2025-10-13T18:15:19.344Z","selectedRoute":"ALL"}	f	2025-10-13 18:15:19.374	2025-11-12 18:15:19	f	\N	2025-10-13 18:15:19.376
cmgp9zmyh0003i0eqn8s9vvkd	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzY4NTYxLCJleHAiOjE3NjI5NjA1NjF9.1LFdXpa-yjADvig046OhJuGOF2yy2FNhW2pltD-TCl8	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T15:16:01.118Z","loginTime":"2025-10-13T15:16:01.118Z","selectedRoute":"MOKNIN_TEBOULBA"}	f	2025-10-13 17:32:12.519	2025-11-12 15:16:01	f	\N	2025-10-13 15:16:01.145
cmgoxk2h30001i08gpwj7bwtb	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzQ3Njc5LCJleHAiOjE3NjI5Mzk2Nzl9.vO62Mos79yT_BHjciHZhgAKdoL2k_9TFHT4f0KDvQHc	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T09:27:59.323Z","loginTime":"2025-10-13T09:27:59.323Z","selectedRoute":"MOKNIN_TEBOULBA"}	f	2025-10-13 14:20:54.463	2025-11-12 09:27:59	f	\N	2025-10-13 09:27:59.367
cmgoov0tq0001i0btrsgboov7	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzMzMDczLCJleHAiOjE3NjI5MjUwNzN9.d5FYtZ2QA8-zCpXyfkixr6IlzoV_7idb5HuF2Ch8vTU	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T05:24:33.852Z","loginTime":"2025-10-13T05:24:33.852Z","selectedRoute":"KSAR_HLEL"}	f	2025-10-13 08:41:58.692	2025-11-12 05:24:33	f	\N	2025-10-13 05:24:33.902
cmgp91vvl0001i0eq051l2ovj	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzY2OTg2LCJleHAiOjE3NjI5NTg5ODZ9.Lx_VJhMGMB7_FwpyNxZf_qlPgrtgKcbTsLVkEIv576s	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T14:49:46.365Z","loginTime":"2025-10-13T14:49:46.366Z","selectedRoute":"KSAR_HLEL"}	f	2025-10-13 14:49:46.399	2025-11-12 14:49:46	f	\N	2025-10-13 14:49:46.401
cmgpooy5v0005i0xwevcuvd4b	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzkzMjU2LCJleHAiOjE3NjI5ODUyNTZ9.DHeSAc4KSs5Iei8tMfksFT-6o4tvsJLYM-1wGtjsZkQ	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T22:07:36.659Z","loginTime":"2025-10-13T22:07:36.659Z","selectedRoute":"KSAR_HLEL"}	f	2025-10-13 22:07:36.691	2025-11-12 22:07:36	f	\N	2025-10-13 22:07:36.692
cmgpi0fa60001i0xwuv0w7yyi	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzgyMDM0LCJleHAiOjE3NjI5NzQwMzR9.78LCtq027lqYqqxa19HIyg2U9XXZBLtCmlkCe7wPJqs	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T19:00:34.720Z","loginTime":"2025-10-13T19:00:34.720Z","selectedRoute":"KSAR_HLEL"}	f	2025-10-13 21:00:56.35	2025-11-12 19:00:34	f	\N	2025-10-13 19:00:34.782
cmgpf2ri90005i0equy56xril	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzc3MTA1LCJleHAiOjE3NjI5NjkxMDV9.-up7NtzW1a1yeNBslBabR-QPc7os9qewCRYt6a9dkCc	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T17:38:25.059Z","loginTime":"2025-10-13T17:38:25.059Z","selectedRoute":"KSAR_HLEL"}	f	2025-10-13 17:38:25.088	2025-11-12 17:38:25	f	\N	2025-10-13 17:38:25.089
cmgppc58m0007i0xwa668pq93	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzk0MzM4LCJleHAiOjE3NjI5ODYzMzh9.U-MamTfCADgvegHXHpuwICfdFaSt-F0RfvQ4FTfn5ig	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T22:25:38.933Z","loginTime":"2025-10-13T22:25:38.933Z","selectedRoute":"JEMMAL"}	t	2025-10-13 22:25:38.949	2025-11-12 22:25:38	f	\N	2025-10-13 22:25:38.95
cmgpmowu40003i0xwg95eqsw4	staff_1758995428363_2nhfegsve	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGFmZklkIjoic3RhZmZfMTc1ODk5NTQyODM2M18ybmhmZWdzdmUiLCJjaW4iOiIxNDA0NTczOSIsInJvbGUiOiJBRE1JTiIsInN0YXRpb25JZCI6ImxvY2FsIiwiaWF0IjoxNzYwMzg5ODk1LCJleHAiOjE3NjI5ODE4OTV9.HZvIXH4faBkKRkwb4GxlEpw8vSU_f8D2crRerko7TnE	{"id":"staff_1758995428363_2nhfegsve","cin":"14045739","firstName":"User","lastName":"Ivan","role":"ADMIN","phoneNumber":"14045739","lastLogin":"2025-10-13T21:11:35.709Z","loginTime":"2025-10-13T21:11:35.709Z","selectedRoute":null}	f	2025-10-13 21:11:35.739	2025-11-12 21:11:35	f	\N	2025-10-13 21:11:35.741
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.staff (id, cin, phone_number, first_name, last_name, role, is_active, last_login, created_at, updated_at) FROM stdin;
staff_1759175419713_ib5c2pncz	06772340	06772340	fadhel	mehri	SUPERVISOR	t	2025-10-12 18:50:24.777	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1760209401624_2h1mjn6x7	06951078	50087284	TLILI	MARZOUKI	WORKER	t	\N	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1759571310147_i6fil8b2b	06780922	06780922	salah	gassouma	ADMIN	t	2025-10-12 21:56:54.518	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1760247605348_8h4p63gzo	06919920	58991429	wael	boussaid	WORKER	t	2025-10-12 10:01:06.493	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1760209249802_llckjlapc	06921663	22158703	ALA	ALA	SUPERVISOR	t	2025-10-12 21:59:07.424	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1759175512105_5uy7rwamf	06751323	06751323	fhal	najah	WORKER	t	2025-09-29 20:58:20.743	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1760247642213_in7dp0fty	06974363	95144141	lassad	bhouri	WORKER	t	2025-10-12 05:48:04.373	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff_1758995428363_2nhfegsve	14045739	14045739	User	Ivan	ADMIN	t	2025-10-19 00:23:16.665	2025-10-15 07:16:36.362542	2025-10-15 07:16:36.362542
staff-002	87654321	+21687654321	Fatma	Ben Salem	WORKER	t	2025-10-15 07:18:38.314	2025-10-15 07:18:30.304409	2025-10-15 07:18:30.304409
staff-001	12345678	+21612345678	Ahmed	Ben Ali	SUPERVISOR	t	2025-10-18 00:08:11.428	2025-10-15 07:16:43.597885	2025-10-15 07:16:43.597885
\.


--
-- Data for Name: station_config; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.station_config (id, station_id, station_name, governorate, delegation, address, opening_time, closing_time, is_operational, service_fee, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: station_daily_statistics; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.station_daily_statistics (id, station_id, date, total_seats_booked, total_seat_income, total_day_passes_sold, total_day_pass_income, total_income, total_transactions, active_staff_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stations; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.stations (id, station_id, station_name, governorate, delegation, address, opening_time, closing_time, is_operational, service_fee, created_at, updated_at) FROM stdin;
781077cf-906e-4192-b1f2-32f363c13bb7	STN001	Station Tunis	Tunis	Tunis Centre	\N	06:00	22:00	t	0.200	2025-10-18 20:19:01.520602	2025-10-18 20:19:01.520602
8f5a893d-8781-455e-9b54-8eea463aed5b	STN002	Station Sfax	Sfax	Sfax Ville	\N	06:00	22:00	t	0.200	2025-10-18 20:19:01.520602	2025-10-18 20:19:01.520602
a2b26c82-2ed6-4aa9-a799-ba90aaa2208c	STN003	Station Sousse	Sousse	Sousse Médina	\N	06:00	22:00	t	0.200	2025-10-18 20:19:01.520602	2025-10-18 20:19:01.520602
\.


--
-- Data for Name: trips; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.trips (id, vehicle_id, license_plate, destination_id, destination_name, queue_id, seats_booked, start_time, created_at, vehicle_capacity, base_price) FROM stdin;
30d09d6655498884ffd5b43e	cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	station-ksar-hlel	KSAR HLEL	\N	8	2025-10-19 00:21:16.593	2025-10-19 00:21:16.593	8	1.75
4091a30e4d87b8115f045720	veh_3132362054554e2035303734	126 TUN 5074	station-moknin	MOKNIN	\N	8	2025-10-19 00:51:33.477	2025-10-19 00:51:33.477	8	1.75
\.


--
-- Data for Name: vehicle_authorized_stations; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.vehicle_authorized_stations (id, vehicle_id, station_id, station_name, priority, is_default, created_at) FROM stdin;
cmggfq81t0001i0cbc0ikr5yq	veh_3133302054554e2033313438	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.033
cmggfq8250003i0cbi4t0qida	veh_3133302054554e2033313438	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.045
cmggfq82c0005i0cbpl7nzq9l	veh_3133302054554e2033313438	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.052
cmggfq82i0007i0cb9zllnh41	veh_3133302054554e2033313438	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.057
cmggfq82x000bi0cb0w5qedki	veh_3132372054554e2037323732	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.074
cmggfq835000di0cbs34feqqe	veh_3233332054554e2036363831	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.081
cmggfq83f000fi0cb2ulsjhd8	veh_3235322054554e2032303637	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.092
cmggfq83n000hi0cbsna51era	veh_3133312054554e2038323138	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.099
cmggfq83s000ji0cb0r8pfxgs	veh_3138322054554e2032303330	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.104
cmggfq83z000li0cbrn1unmyp	veh_3137392054554e2034323934	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.111
cmggfq84b000ni0cbjgcne0h7	veh_3232322054554e2037343639	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.123
cmggfq84n000pi0cb1uljm5kk	veh_3132392054554e2032373735	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.135
cmggfq84r000ri0cb70pe5e73	veh_3132392054554e2032373735	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.139
cmggfq84w000ti0cb742ku2ws	veh_3132392054554e2032373735	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.144
cmggfq851000vi0cbysu4ut8l	veh_3132392054554e2032373735	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.148
cmggfq85g000zi0cbembt16i1	veh_3138322054554e2035303133	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.164
cmggfq85l0011i0cbc89cmwyy	veh_3138322054554e2035303133	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.169
cmggfq85r0013i0cbfvagvtfr	veh_3138322054554e2035303133	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.175
cmggfq85w0015i0cbxa97z8cs	veh_3138322054554e2035303133	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.18
cmggfq8680019i0cb2z3mr7fh	veh_3136322054554e2033353136	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.193
cmggfq86e001bi0cbi3ecqgt1	veh_3138352054554e2039343035	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.198
cmggfq86n001di0cboz2uirsp	veh_3132312054554e2039333033	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.207
cmggfq86w001fi0cb4ef1lgdb	veh_3136392054554e2037393937	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.216
cmggfq871001hi0cbbljtk4ca	veh_3136392054554e2037393937	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.221
cmggfq877001ji0cb2wu8oeht	veh_3136392054554e2037393937	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.228
cmggfq87e001li0cbe6j9xyzm	veh_3136392054554e2037393937	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.233
cmggfq87v001pi0cb26xm9vqf	veh_3234392054554e2039373736	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.252
cmggfq885001ri0cb4kuu9ngt	veh_3232342054554e2035333333	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.261
cmggfq889001ti0cbcu5rm61q	veh_3232342054554e2035333333	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.265
cmggfq88d001vi0cbyp03c8lf	veh_3232342054554e2035333333	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.269
cmggfq88g001xi0cb1fj0lk0l	veh_3232342054554e2035333333	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.272
cmggfq8960023i0cbeddfq30h	veh_3233392054554e2034373831	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.297
cmggfq8990025i0cbqwzx5rsd	veh_3233392054554e2034373831	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.301
cmggfq89d0027i0cbha1k21uh	veh_3233392054554e2034373831	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.305
cmggfq89h0029i0cblht5ibll	veh_3233392054554e2034373831	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.309
cmggfq89x002di0cb3lamapio	veh_3137352054554e2033363732	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.324
cmggfq8a7002fi0cb28l6o8ia	veh_3233372054554e2038333430	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.335
cmggfq8ai002hi0cbune6t08j	veh_3234372054554e2038353536	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.347
cmggfq8as002ji0cb0mrdlcpb	veh_3233352054554e2032323238	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.356
cmggfq8b3002li0cb39nk6qzu	veh_3230362054554e2039393431	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.367
cmggfq8bg002ni0cbs7f5iczd	veh_3134302054554e2038343834	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.379
cmggfq8br002pi0cb8vegutw9	veh_3139372054554e2039323934	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.39
cmggfq8bz002ri0cbnnthu20a	veh_3132362054554e2035303734	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.398
cmggfq8c7002ti0cbuwq3i6iz	veh_3138312054554e2038373936	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.406
cmggfq8ch002vi0cbp6862rw6	veh_3132352054554e20393939	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.417
cmggfq8cs002xi0cbe5cj6fig	veh_3132372054554e2031373833	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.427
cmggfq8d4002zi0cba68ks9pw	veh_3134382054554e2035373837	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.44
cmggfq8db0031i0cbiuu255st	veh_3134382054554e2035373837	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.447
cmggfq8dh0033i0cbghxzc96m	veh_3134382054554e2035373837	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.452
cmggfq8dl0035i0cbonrqmeuf	veh_3134382054554e2035373837	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.458
cmggfq8dz0039i0cbngpajzpv	veh_3139332054554e2035333736	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.471
cmggfq8e6003bi0cbccpoz8fe	veh_3139332054554e2035333736	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.477
cmggfq8ec003di0cbm63wmwwf	veh_3139332054554e2035333736	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.484
cmggfq8eg003fi0cbk1c0ktly	veh_3139332054554e2035333736	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.488
cmggfq8ex003ji0cbji1u7cqo	veh_3234352054554e20363034	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.505
cmggfq8f2003li0cb5d46qy4f	veh_3234352054554e20363034	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.51
cmggfq8f8003ni0cb5tirdw9k	veh_3234352054554e20363034	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.516
cmggfq8fd003pi0cbknoghx3v	veh_3234352054554e20363034	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.521
cmggfq8fq003ti0cbnfl2h3v4	veh_3139312054554e2035323537	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.534
cmggfq8fu003vi0cb8sh33o3e	veh_3139312054554e2035323537	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.538
cmggfq8fz003xi0cbd8p2lnuv	veh_3139312054554e2035323537	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.543
cmggfq8g5003zi0cbe1i9wo8s	veh_3139312054554e2035323537	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.548
cmggfq8gl0043i0cby3vvmhnz	veh_3233352054554e2033313138	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.565
cmggfq8gq0045i0cbfoxwpc3x	veh_3233352054554e2033313138	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.57
cmggfq8gw0047i0cbthfya1zq	veh_3233352054554e2033313138	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.576
cmggfq8h10049i0cbhaizhxub	veh_3233352054554e2033313138	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.581
cmggfq8he004di0cby0h0dda5	veh_3234342054554e2031333431	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.594
cmggfq8hh004fi0cbkvg6qry1	veh_3234342054554e2031333431	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.597
cmggfq8hk004hi0cbi3qbj5oa	veh_3234342054554e2031333431	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.6
cmggfq8hn004ji0cb4ptxd2pn	veh_3234342054554e2031333431	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.603
cmggfq8i0004ni0cb79bm9srl	veh_3134352054554e2031303634	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.616
cmggfq8i9004pi0cbugbmnjr8	veh_3133382054554e2035373738	station-teboulba	TEBOULBA	1	t	2025-10-07 10:46:44.625
cmggfq8ig004ri0cbjqfdur0d	veh_3134322054554e2032323736	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.632
cmggfq8im004ti0cb54ipykrc	veh_3133322054554e2037323139	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.638
cmggfq8iv004vi0cb9uv60uny	veh_3230342054554e2037373131	station-teboulba	TEBOULBA	1	t	2025-10-07 10:46:44.647
cmggfq8j4004xi0cbksxyl3rj	veh_3133382054554e2031303234	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.656
cmggfq8j9004zi0cbwmwfp209	veh_3133382054554e2031303234	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.661
cmggfq8jd0051i0cb5wggwqz7	veh_3133382054554e2031303234	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.665
cmggfq8jh0053i0cbnlvygt66	veh_3133382054554e2031303234	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.669
cmggfq8js0057i0cbtqt4n3kh	veh_3135332054554e2031303634	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.68
cmggfq8jz0059i0cb4padhyhk	veh_3139342054554e2039333031	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.688
cmggfq8k7005bi0cbx5a39aw7	veh_3235332054554e2039343138	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.696
cmggfq8kg005di0cbz7qkit2a	veh_3132372054554e2034333739	station-teboulba	TEBOULBA	1	t	2025-10-07 10:46:44.704
cmggfq8ko005fi0cb0g1nuigv	veh_3230332054554e2033313538	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.712
cmggfq8ks005hi0cb84rs65t3	veh_3230332054554e2033313538	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.716
cmggfq8kw005ji0cb50c95q8l	veh_3230332054554e2033313538	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.72
cmggfq8kz005li0cbv1y1uciv	veh_3230332054554e2033313538	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.723
cmggfq8lb005pi0cb2dvqjz2g	veh_3232352054554e2032373531	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.735
cmggfq8lf005ri0cbfdqj96t2	veh_3232352054554e2032373531	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.739
cmggfq8li005ti0cb759z0wkg	veh_3232352054554e2032373531	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.743
cmggfq8lm005vi0cbn9vrknuu	veh_3232352054554e2032373531	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.746
cmggfq8lw005zi0cblwcovg5m	veh_3234372054554e2038393531	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.757
cmggfq8m30061i0cblnt9pg43	veh_3234392054554e2038333534	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.764
cmggfq8ma0063i0cbpgtvppoi	veh_3233382054554e2034333232	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.771
cmggfq8me0065i0cbn5a51j5e	veh_3233382054554e2034333232	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.774
cmggfq8mh0067i0cbnbnvhgnf	veh_3233382054554e2034333232	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.777
cmggfq8ml0069i0cbm7wkd8vx	veh_3233382054554e2034333232	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.781
cmggfq8mw006di0cbwkqljyjd	veh_3133302054554e2032313636	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.792
cmggfq8mz006fi0cbqjficlud	veh_3133302054554e2032313636	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.795
cmggfq8n2006hi0cbdoz6xr6j	veh_3133302054554e2032313636	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.798
cmggfq8n5006ji0cbfmgrupg0	veh_3133302054554e2032313636	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.801
cmggfq8ne006ni0cbsaxv1oyp	veh_3232362054554e2035333334	station-moknin	MOKNIN	1	t	2025-10-07 10:46:44.81
cmggfq8nk006pi0cb3u12gl10	veh_3235302054554e20363739	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.816
cmggfq8nn006ri0cbjje7eabi	veh_3235302054554e20363739	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.819
cmggfq8nq006ti0cbz18xzr7c	veh_3235302054554e20363739	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.822
cmggfq8nt006vi0cbvynpba3g	veh_3235302054554e20363739	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.826
cmggfq8o4006zi0cbqsb8u166	veh_3233372054554e2039353336	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.836
cmggfq8o70071i0cbapk0wj7o	veh_3233372054554e2039353336	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.839
cmggfq8oa0073i0cblx8yms99	veh_3233372054554e2039353336	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.842
cmggfq8od0075i0cbc5rmjfin	veh_3233372054554e2039353336	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.845
cmggfq8ot007bi0cbbri8e7ra	veh_3134302054554e2038323731	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.861
cmggfq8oz007di0cb386ctjh7	veh_3234392054554e2034303332	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.868
cmggfq8p6007fi0cbgprkwdzq	veh_3132322054554e2033383536	station-jemmal	JEMMAL	1	t	2025-10-07 10:46:44.875
cmggfq8pd007hi0cb72ykd9p9	veh_3134302054554e2032363731	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.881
cmggfq8pk007ji0cbfdea0xxv	veh_3232372054554e2034333739	station-teboulba	TEBOULBA	1	t	2025-10-07 10:46:44.888
cmggfq8pr007li0cbqcyipc84	veh_3133302054554e2038313636	station-ksar-hlel	KSAR HLEL	1	t	2025-10-07 10:46:44.895
cmggfq8pu007ni0cbtf3cc9ep	veh_3133302054554e2038313636	station-jemmal	JEMMAL	2	f	2025-10-07 10:46:44.899
cmggfq8py007pi0cb5welvmfn	veh_3133302054554e2038313636	station-moknin	MOKNIN	3	f	2025-10-07 10:46:44.902
cmggfq8q1007ri0cbqdl6mkhc	veh_3133302054554e2038313636	station-teboulba	TEBOULBA	4	f	2025-10-07 10:46:44.905
cmggfq8qd007vi0cbbn8hxt8a	veh_3234302054554e2037373131	station-teboulba	TEBOULBA	1	t	2025-10-07 10:46:44.917
4383c78c-8c49-43bd-a3a7-49b07e858484	96b8a5b6-6676-45a0-8888-12c6bb9d2910	station-jemmal	JEMMAL	1	f	2025-10-07 13:19:32.056
99934933-b555-4d79-951c-78a5f237931b	96b8a5b6-6676-45a0-8888-12c6bb9d2910	station-ksar-hlel	KSAR HLEL	1	f	2025-10-07 13:19:32.06
800f131b-3217-4594-b22f-d4695b160452	96b8a5b6-6676-45a0-8888-12c6bb9d2910	station-moknin	MOKNIN	1	f	2025-10-07 13:19:32.064
b15a129a-24f4-4747-9c09-e5d721b89001	96b8a5b6-6676-45a0-8888-12c6bb9d2910	station-teboulba	TEBOULBA	1	f	2025-10-07 13:19:32.07
9a95891b-8c72-47c9-ac83-073aa3d4d72a	91a8014b-8b7d-4bc9-9f79-95266bbe14f6	station-jemmal	JEMMAL	1	f	2025-10-07 14:28:05.665
9eedba6b-becd-4f21-a4c8-0746f612704e	050f7843-d32d-4694-80bc-f18f13265d96	station-jemmal	JEMMAL	1	f	2025-10-07 14:33:52.38
daf22071-2974-4244-bf29-471f61b447e2	89a51db6-9bc4-4251-a8ef-7aba5ad62cf5	station-ksar-hlel	KSAR HLEL	1	f	2025-10-07 14:42:42.338
4a175957-08c3-4979-9782-c82c6557054b	22409a80-4ece-45d6-8123-bed8ef4a05a4	station-ksar-hlel	KSAR HLEL	1	f	2025-10-07 14:44:53.219
7c08d344-2873-448c-a129-4de1796ab243	14caeefb-d661-4e77-921a-954bafbe7a2c	station-moknin	MOKNIN	1	f	2025-10-07 14:51:18.398
78d5b820-ef53-4a93-91e9-581be9cc3941	29049e60-903f-4439-a095-3aac7cd39c70	station-jemmal	JEMMAL	1	f	2025-10-07 15:21:31.652
3c908b9e-a436-42b2-b0fc-197e56e6ff27	de937d42-3187-46c2-bfdc-445891797d55	station-jemmal	JEMMAL	1	f	2025-10-07 15:22:49.466
f4f293e2-b8c8-4fd1-99bf-d3eed904aa6e	3f86f0cc-ab55-4045-8672-9b5388668503	station-jemmal	JEMMAL	1	f	2025-10-07 15:39:12.09
35be9f5b-8bfc-4751-b392-663911e0469b	5a487488-41bf-4863-9b46-14b51ed931fc	station-jemmal	JEMMAL	1	f	2025-10-07 15:40:08.83
572ddd5c-8056-4f3e-87ec-f4b0f63b5f47	bd9b90a8-5927-451b-8c6c-d0c71ad30148	station-jemmal	JEMMAL	1	f	2025-10-07 15:41:51.213
93257549-00c3-488a-91d8-07e416df0a78	def04ebe-4c4a-4af4-8db1-b16b26c38331	station-jemmal	JEMMAL	1	f	2025-10-07 15:43:41.045
74b57fba-b84c-4e55-9499-468838984c43	def04ebe-4c4a-4af4-8db1-b16b26c38331	station-ksar-hlel	KSAR HLEL	1	f	2025-10-07 15:43:41.05
80fdef93-309d-413e-8c15-0e481cdd6ceb	570e26a7-09ee-4fce-b718-15b255119878	station-jemmal	JEMMAL	1	f	2025-10-07 16:04:23.157
9a5c99bc-0a79-44cc-bbba-970ed21400fc	570e26a7-09ee-4fce-b718-15b255119878	station-ksar-hlel	KSAR HLEL	1	f	2025-10-07 16:04:23.16
39770c66-c6da-4fce-962f-84c6cd0a9d05	570e26a7-09ee-4fce-b718-15b255119878	station-moknin	MOKNIN	1	f	2025-10-07 16:04:23.164
e01106f0-457c-427a-adff-fc1d33e5957f	570e26a7-09ee-4fce-b718-15b255119878	station-teboulba	TEBOULBA	1	f	2025-10-07 16:04:23.168
0d97a52c-818b-448e-a4f2-93dfb1b139df	c7c738d1-d016-40dd-8d31-a1510b697a8d	station-jemmal	JEMMAL	1	f	2025-10-08 11:28:00.48
05aab604-e737-47a7-acad-8cae4642479c	c7c738d1-d016-40dd-8d31-a1510b697a8d	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 11:28:00.485
2208c407-7a4a-4796-9374-e1842f4d60fa	c7c738d1-d016-40dd-8d31-a1510b697a8d	station-moknin	MOKNIN	1	f	2025-10-08 11:28:00.489
006eef59-2f0e-4245-9344-1a1992be3924	c7c738d1-d016-40dd-8d31-a1510b697a8d	station-teboulba	TEBOULBA	1	f	2025-10-08 11:28:00.491
63c571d0-c9ec-4594-b23b-7df94ab27554	21b1699c-55db-449d-9854-e787ff06c33a	station-jemmal	JEMMAL	1	f	2025-10-08 11:36:14.906
1fdadaf1-b00c-4e79-9db7-dfdc3f65741c	21b1699c-55db-449d-9854-e787ff06c33a	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 11:36:14.911
1bc84470-ebfe-488e-b351-2d4a087a31b0	21b1699c-55db-449d-9854-e787ff06c33a	station-moknin	MOKNIN	1	f	2025-10-08 11:36:14.915
aeeab26b-bb55-48e9-9c7c-3c980dc880c1	21b1699c-55db-449d-9854-e787ff06c33a	station-teboulba	TEBOULBA	1	f	2025-10-08 11:36:14.919
7afb52a9-429d-4ac7-85cc-0ef53812e41f	48439240-9a9a-4342-975b-b5dc0a1679d9	station-jemmal	JEMMAL	1	f	2025-10-08 11:43:11.144
0e39e44f-87b1-44de-826e-211c884be4a1	e00a2c72-5dab-4480-a522-e27af88d22fd	station-jemmal	JEMMAL	1	f	2025-10-08 11:45:10.214
895bd32b-faa0-4274-b42d-cb2bea4fd19c	e00a2c72-5dab-4480-a522-e27af88d22fd	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 11:45:10.218
5e162cdb-eb89-413a-b527-a1f788442c80	e00a2c72-5dab-4480-a522-e27af88d22fd	station-moknin	MOKNIN	1	f	2025-10-08 11:45:10.223
9222e741-a4db-4ea8-a853-1614155f2bba	e00a2c72-5dab-4480-a522-e27af88d22fd	station-teboulba	TEBOULBA	1	f	2025-10-08 11:45:10.226
7fa238f5-3895-43bb-8268-089203931d30	ab273830-0eae-4c6d-940c-34745e0494c7	station-jemmal	JEMMAL	1	f	2025-10-08 11:48:19.277
85a20a6e-2f19-4669-9c2d-aa05d296783f	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	station-jemmal	JEMMAL	1	f	2025-10-08 11:53:26.8
f4125882-a817-487c-b873-12e5483d19c1	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 11:53:26.804
8b42e820-b6fb-4622-971e-d9ea0969e6f4	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	station-moknin	MOKNIN	1	f	2025-10-08 11:53:26.807
8bbcefc8-974c-46a1-bbf0-c2b261df6bc5	f11bbac1-46b5-4b95-9e7b-d1afc42c050c	station-teboulba	TEBOULBA	1	f	2025-10-08 11:53:26.81
dc3b2714-80fe-45a6-81a7-c9b695dd39d4	456e2ee1-927b-410a-b77f-b1f43098f1bd	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 11:58:19.519
dfd40ec7-4738-4d72-b691-f001dc2dfacc	128f10f5-5bdc-4cac-b165-96c2fefeca6c	station-jemmal	JEMMAL	1	f	2025-10-08 11:59:05.623
d51ccb8c-bab8-4b13-ab9d-9129b4ef0be1	20568779-4dd7-4dde-8961-356fa6bfbadc	station-jemmal	JEMMAL	1	f	2025-10-08 12:03:20.891
2fc16e88-d534-4ff1-b459-b73ff0e9cf95	20568779-4dd7-4dde-8961-356fa6bfbadc	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 12:03:20.897
f01f2fe5-180f-482c-bce6-8b943b1b5876	20568779-4dd7-4dde-8961-356fa6bfbadc	station-moknin	MOKNIN	1	f	2025-10-08 12:03:20.901
8b139bed-820f-4f3f-8bfd-95cdb0e2a361	20568779-4dd7-4dde-8961-356fa6bfbadc	station-teboulba	TEBOULBA	1	f	2025-10-08 12:03:20.906
e9f4e10a-ab8b-4c1b-99fa-449410f61973	c68362f6-3ba2-4845-b188-4735d353eecd	station-jemmal	JEMMAL	1	f	2025-10-08 12:04:10.412
5184f4de-98f3-46a2-90c6-3bf4d45ec526	c68362f6-3ba2-4845-b188-4735d353eecd	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 12:04:10.416
e0c15950-a684-4611-9f35-ce1d66069493	c68362f6-3ba2-4845-b188-4735d353eecd	station-moknin	MOKNIN	1	f	2025-10-08 12:04:10.42
097eaca4-096d-491b-81c7-594a2c6dd1b0	c68362f6-3ba2-4845-b188-4735d353eecd	station-teboulba	TEBOULBA	1	f	2025-10-08 12:04:10.423
e62ed6d1-2669-44c3-bdb6-35e7204d3269	4ca4bc71-ccb7-4b02-9e30-7a6e74aa5696	station-moknin	MOKNIN	1	f	2025-10-08 12:04:49.904
47c4f6c8-e226-4acb-b27b-7f3b52866c31	9dca1b65-1688-4c5c-9209-e35e9f21290e	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 12:10:39.722
a26a4224-4d25-474c-bbb3-54c0c0ac84e6	0ed253e9-6c76-464a-9cc9-6369fa3f119b	station-jemmal	JEMMAL	1	f	2025-10-08 13:02:43.311
766279a3-81bd-4ba0-836e-4f19036c302a	c84ba5d0-0ac4-4b61-ba37-e8973889a6b6	station-jemmal	JEMMAL	1	f	2025-10-08 15:05:08.668
38889a30-38bc-4f4c-be81-010c33f76c98	d6257331-1a01-4a8b-9a66-c70addf18f7b	station-jemmal	JEMMAL	1	f	2025-10-08 15:05:51.722
56e0986f-3f79-4ba3-a018-d7171331fda3	d6257331-1a01-4a8b-9a66-c70addf18f7b	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 15:05:51.727
5b82569e-bdf1-4a06-99e0-f13574da0ee7	d6257331-1a01-4a8b-9a66-c70addf18f7b	station-moknin	MOKNIN	1	f	2025-10-08 15:05:51.729
dc9eb5f3-b6f8-40a9-b124-14f1e89c340c	d6257331-1a01-4a8b-9a66-c70addf18f7b	station-teboulba	TEBOULBA	1	f	2025-10-08 15:05:51.731
c8179c1b-42e0-4e5c-bbbe-c5b8e628d8d6	97bc7054-912b-467b-90e2-f1862501cd2b	station-jemmal	JEMMAL	1	f	2025-10-08 15:06:39.735
e4703d9c-78f0-497f-aa0c-ea5b0c5fa691	97bc7054-912b-467b-90e2-f1862501cd2b	station-ksar-hlel	KSAR HLEL	1	f	2025-10-08 15:06:39.738
b725e7f6-b8d1-4401-b33a-fe76ab21393f	97bc7054-912b-467b-90e2-f1862501cd2b	station-moknin	MOKNIN	1	f	2025-10-08 15:06:39.744
3a5d8083-8ee1-4457-b954-f7c0f0f4dc73	97bc7054-912b-467b-90e2-f1862501cd2b	station-teboulba	TEBOULBA	1	f	2025-10-08 15:06:39.746
1c0f01c3-e266-49e7-9149-72158ff513ad	6af5315d-f06e-416b-9bb4-b95fe86f1158	station-jemmal	JEMMAL	1	f	2025-10-09 14:21:55.751
a6900739-8251-4319-8f5c-d6eeea721161	cad327d2-45d8-485a-b98f-323a7335f640	station-jemmal	JEMMAL	1	f	2025-10-09 14:25:44.575
aac30900-cc2f-44d1-93a2-45ac3c9907f5	cad327d2-45d8-485a-b98f-323a7335f640	station-ksar-hlel	KSAR HLEL	1	f	2025-10-09 14:25:44.58
32902d00-0de6-4d1f-93a7-250d616bcf7b	cad327d2-45d8-485a-b98f-323a7335f640	station-moknin	MOKNIN	1	f	2025-10-09 14:25:44.585
41488ef5-31da-4f2b-ac9a-488541670ee9	cad327d2-45d8-485a-b98f-323a7335f640	station-teboulba	TEBOULBA	1	f	2025-10-09 14:25:44.591
9e31f5e0-7bd2-4652-8cb2-db68eb6a7680	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	station-jemmal	JEMMAL	1	f	2025-10-09 14:26:29.618
e15cfdbd-14db-47c9-be76-20718f2c8b79	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	station-ksar-hlel	KSAR HLEL	1	f	2025-10-09 14:26:29.623
f2506215-9c0c-42a8-bb65-dbeb45b3e716	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	station-moknin	MOKNIN	1	f	2025-10-09 14:26:29.626
9053619b-8e66-420e-bd09-a70273bfd2e9	6c2d68b2-d7b0-403f-a521-1196ec87ff6d	station-teboulba	TEBOULBA	1	f	2025-10-09 14:26:29.631
cmgna1wmr00054a8cerfas7wd	vehicle_1760247734626_cuorwq86x	station-jemmal	JEMMAL	1	f	2025-10-12 05:42:14.643
cmgna1wn000074a8ce77cxiky	vehicle_1760247734626_cuorwq86x	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 05:42:14.652
cmgna1wn900094a8coeutu1ct	vehicle_1760247734626_cuorwq86x	station-moknin	MOKNIN	1	f	2025-10-12 05:42:14.662
cmgna1wnk000b4a8c1zoprvy7	vehicle_1760247734626_cuorwq86x	station-teboulba	TEBOULBA	1	f	2025-10-12 05:42:14.672
cmgnaqxdn000f4a8cjt5seany	vehicle_1760248901989_kkpdqpdp0	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:01:42.011
cmgnav2ub000h4a8ct7ushkqx	vehicle_1760249095699_7h62u6flc	station-jemmal	JEMMAL	1	f	2025-10-12 06:04:55.715
cmgnav2uj000j4a8ca0jh6wfs	vehicle_1760249095699_7h62u6flc	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:04:55.723
cmgnav2ur000l4a8cfvgyrdm5	vehicle_1760249095699_7h62u6flc	station-moknin	MOKNIN	1	f	2025-10-12 06:04:55.731
cmgnav2uz000n4a8chng3k1fh	vehicle_1760249095699_7h62u6flc	station-teboulba	TEBOULBA	1	f	2025-10-12 06:04:55.739
cmgnay1gg000p4a8cpoktw3ko	vehicle_1760249233865_2rdyukkkq	station-jemmal	JEMMAL	1	f	2025-10-12 06:07:13.888
cmgnay1gs000r4a8c4essku36	vehicle_1760249233865_2rdyukkkq	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:07:13.901
cmgnay1h3000t4a8cvbiazcja	vehicle_1760249233865_2rdyukkkq	station-moknin	MOKNIN	1	f	2025-10-12 06:07:13.912
cmgnay1hg000v4a8cxlipgu1c	vehicle_1760249233865_2rdyukkkq	station-teboulba	TEBOULBA	1	f	2025-10-12 06:07:13.924
cmgnb4k1s000x4a8cqddq1le6	vehicle_1760249537900_i1ktr6j30	station-jemmal	JEMMAL	1	f	2025-10-12 06:12:17.921
cmgnb7318000z4a8c3upp44g4	vehicle_1760249655820_o2w7zbb4b	station-jemmal	JEMMAL	1	f	2025-10-12 06:14:15.836
cmgnb8qsc00114a8c0znruea6	vehicle_1760249733257_lk9zxkckf	station-jemmal	JEMMAL	1	f	2025-10-12 06:15:33.276
cmgnb8qsk00134a8ccvcn386x	vehicle_1760249733257_lk9zxkckf	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:15:33.284
cmgnb8qsr00154a8cewxete5s	vehicle_1760249733257_lk9zxkckf	station-moknin	MOKNIN	1	f	2025-10-12 06:15:33.292
cmgnb8qt000174a8cme8v7mab	vehicle_1760249733257_lk9zxkckf	station-teboulba	TEBOULBA	1	f	2025-10-12 06:15:33.3
cmgnbz0uk00194a8co83bhb9g	vehicle_1760250959358_yucrp9a2g	station-jemmal	JEMMAL	1	f	2025-10-12 06:35:59.372
cmgnbz0us001b4a8ce8r0qwka	vehicle_1760250959358_yucrp9a2g	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:35:59.381
cmgnbz0v0001d4a8cwsvmqcjt	vehicle_1760250959358_yucrp9a2g	station-moknin	MOKNIN	1	f	2025-10-12 06:35:59.388
cmgnbz0v8001f4a8c9bcut9c1	vehicle_1760250959358_yucrp9a2g	station-teboulba	TEBOULBA	1	f	2025-10-12 06:35:59.396
cmgncayx3001h4a8cxnudlpb1	vehicle_1760251516726_v3xdgeaou	station-teboulba	TEBOULBA	1	f	2025-10-12 06:45:16.743
cmgnccsuq001j4a8cdzwdactb	vehicle_1760251602175_4y0a2r1fm	station-jemmal	JEMMAL	1	f	2025-10-12 06:46:42.195
cmgncf21p001l4a8c868ewa0a	vehicle_1760251707403_45c6e9gdt	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 06:48:27.422
cmgnctqq5001n4a8ch6niby31	vehicle_1760252392573_ilt6t9ei2	station-jemmal	JEMMAL	1	f	2025-10-12 06:59:52.589
cmgncy1eb001p4a8chqra3h2n	vehicle_1760252593027_xjlilyx8e	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 07:03:13.044
5b27d410-640b-4c96-bcb7-f48d3b9b8e12	e31a2351-1d6e-4b4c-b1f4-ae81a9167981	station-teboulba	TEBOULBA	1	f	2025-10-12 08:23:48.551
74d8a5a2-7fe9-4bae-85fb-3505f237858f	e4f7cd3d-69bc-4482-8923-5bd42e68b698	station-jemmal	JEMMAL	1	f	2025-10-12 08:51:26.867
cmgnhq77700014a7x8kh90j7q	vehicle_1760260625377_plz85u34c	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 09:17:05.395
0ffa0387-028d-4e21-b32a-3c13e9d5db54	f76e78fc-fd60-4b26-ae9d-a119459aa2a6	station-jemmal	JEMMAL	1	f	2025-10-12 11:00:58.532
4da15f10-cf21-49cb-937b-6de0394bb9da	b9e3efb0-32f2-4e68-8fbf-c7f032fc7c90	station-moknin	MOKNIN	1	f	2025-10-12 11:04:52.418
fd244f92-f5c9-4863-b635-796e12c2a3f2	0815e14d-a7ae-404a-9c16-353626398e6f	station-jemmal	JEMMAL	1	f	2025-10-12 11:16:58.362
d229cc47-c708-4dff-9b06-f7451a4c1cd3	0815e14d-a7ae-404a-9c16-353626398e6f	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 11:16:58.369
c8ebd101-3074-4a26-a3c7-d4643102a233	0815e14d-a7ae-404a-9c16-353626398e6f	station-moknin	MOKNIN	1	f	2025-10-12 11:16:58.372
72fbcf84-310f-4cf1-9d78-fe0020a3bc43	0815e14d-a7ae-404a-9c16-353626398e6f	station-teboulba	TEBOULBA	1	f	2025-10-12 11:16:58.38
32cfe748-2203-4c0a-b2b7-4e7c7f772427	b339ef18-7892-48ff-96c8-82df56271eae	station-teboulba	TEBOULBA	1	f	2025-10-12 11:31:41.387
78fb0a2e-843e-4e97-9b32-4850662ae5b1	866ffcfd-be45-46fe-894e-104ac2bd71df	station-jemmal	JEMMAL	1	f	2025-10-12 11:49:29.386
c6de7405-0c3a-48d7-a55d-533fe456b980	0d51ab0b-dd63-4030-803d-43971f5991de	station-jemmal	JEMMAL	1	f	2025-10-12 11:51:19.449
419d9d7c-f52d-4ba3-b6e2-f695d71b258a	d084e91a-df8b-4f8d-a3a9-f09b74395a85	station-jemmal	JEMMAL	1	f	2025-10-12 11:57:51.898
0eb60343-971b-4d0f-b24a-46a64e28a12b	d084e91a-df8b-4f8d-a3a9-f09b74395a85	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 11:57:51.903
c809b2f0-0f8b-4ce3-a6e2-08c267ff83ce	d084e91a-df8b-4f8d-a3a9-f09b74395a85	station-moknin	MOKNIN	1	f	2025-10-12 11:57:51.907
d266a15d-5f0e-47f8-ac95-2ded5e6edda9	d084e91a-df8b-4f8d-a3a9-f09b74395a85	station-teboulba	TEBOULBA	1	f	2025-10-12 11:57:51.912
c9082a3d-e846-4a52-9bef-3904c58e5417	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	station-jemmal	JEMMAL	1	f	2025-10-12 11:58:17.432
c36a379f-46f7-43ef-a01f-b6e77fb6f753	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 11:58:17.437
78f3907b-38f7-412f-aae1-ca84e61469b6	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	station-moknin	MOKNIN	1	f	2025-10-12 11:58:17.441
935125d6-7312-4d02-8cc4-42a4edd238b7	6f680192-2aaf-4eae-aac9-4b31f41a2d8d	station-teboulba	TEBOULBA	1	f	2025-10-12 11:58:17.444
d3b0e048-9c52-4c23-abae-947763f3da6c	428de0a6-be2e-436b-918d-7887419291c0	station-jemmal	JEMMAL	1	f	2025-10-12 11:59:03.157
a5dcb16c-c6e6-4b29-9c48-4e8521007e34	979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	station-jemmal	JEMMAL	1	f	2025-10-12 12:16:03.785
64cabb73-98c8-49db-b2b1-7b66047106e0	007bd630-a4cb-4244-95ea-7b7828c6ac53	station-jemmal	JEMMAL	1	f	2025-10-12 12:34:40.804
3be92928-7245-400d-aad0-721e69da5708	4bb4a12b-8571-4cc4-aa9b-c460a878cada	station-jemmal	JEMMAL	1	f	2025-10-12 13:11:05.404
9ca2d186-735e-49a6-a723-6d5883787eae	a827ab5f-fffd-4e01-b50d-378c4f61f615	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 13:50:47.928
b4c1522c-528e-4307-a6d1-c80324000a42	00784611-53e2-498b-b30b-778e5376efac	station-jemmal	JEMMAL	1	f	2025-10-12 14:19:59.962
36608bd5-912c-43b4-8b32-c08b4d0bdaf2	ea2a4966-8d93-4041-9876-e1465f09ebc9	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 15:09:26.046
2a927c81-1df9-432b-bdef-f20a5081472d	ea2a4966-8d93-4041-9876-e1465f09ebc9	station-jemmal	JEMMAL	1	f	2025-10-12 15:09:26.051
65a1d8c0-d2d5-417b-a348-10cfef99c7c2	24bd242e-9ed7-41dd-91e4-e91290118db6	station-jemmal	JEMMAL	1	f	2025-10-12 15:16:28.834
05585187-d231-46c7-9749-c95298dc6128	ccb80a37-fc0c-4f3a-8354-8e6e91a11e48	station-moknin	MOKNIN	1	f	2025-10-12 15:20:29.612
414b2116-f7d9-401d-b655-d2d83b0a821f	1e792121-0a50-429a-bfe8-7e1a0e8c1ab6	station-jemmal	JEMMAL	1	f	2025-10-12 15:50:13.556
9f9c37c1-daf1-4b0d-ac71-81838a62370a	a7938b81-2018-4dcf-8456-4d51e8e1aef4	station-jemmal	JEMMAL	1	f	2025-10-12 15:56:29.194
4f1fc621-cd12-45f1-bd0f-822a064b99f8	e7795446-726f-43f7-bb34-aba040be0bde	station-ksar-hlel	KSAR HLEL	1	f	2025-10-12 15:58:39.942
ea857a62-7988-4693-86f6-d3cd7a3fd472	4d000425-8615-4b20-9648-2052e3776b49	station-teboulba	TEBOULBA	1	f	2025-10-12 16:48:02.485
07478d71-950b-46f5-9a24-da23f37d34ab	015afe3a-3526-42fc-a9ae-4d963be711c0	station-jemmal	JEMMAL	1	f	2025-10-12 17:12:41.859
6b8b3461-e1c2-4c6c-8f66-1ef61b274329	068fea9c-279a-4df3-a497-2dde7cc6e9d0	station-teboulba	TEBOULBA	1	f	2025-10-12 17:13:32.724
4d8d728e-3493-4e08-a0c1-fbb61ec73128	3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	station-jemmal	JEMMAL	1	f	2025-10-12 17:15:10.94
a90aeaa5-c7a9-4e07-b2bf-26b7bc3cc8fe	10440f4d-acde-4772-8237-0a646d4fd650	station-jemmal	JEMMAL	1	f	2025-10-12 17:57:09.466
auth_1760418875036_3eco6z16b	vehicle_1760418874312_yfjec858a	station-jemmal	JEMMAL	1	f	2025-10-14 06:14:35.038
auth_1760418875687_sc0z928bu	vehicle_1760418874312_yfjec858a	station-ksar-hlel	KSAR HLEL	1	f	2025-10-14 06:14:35.689
auth_1760418876609_0eqn6tgqi	vehicle_1760418874312_yfjec858a	station-moknin	MOKNIN	1	f	2025-10-14 06:14:36.611
auth_1760418877085_qw92lngjz	vehicle_1760418874312_yfjec858a	station-teboulba	TEBOULBA	1	f	2025-10-14 06:14:37.086
720560b1-52e9-4fe0-bac1-fd84f275be52	fd49c3ca-e379-4111-8a37-a0a58d68e05f	STN001	Station Tunis	1	t	2025-10-15 09:33:08.163
64bf5221-7a99-4d87-a8be-78d9a5121ac6	a3822825-4ecc-4d6a-892b-ae13706767a3	station-jemmal	JEMMAL	1	t	2025-10-15 15:42:37.186
3e9dcaf6-7cfe-4fac-8829-2db3574af3eb	a01d1105-9e36-4eba-b164-34e2bba4adf8	station-jemmal	JEMMAL	1	t	2025-10-15 15:42:37.213
\.


--
-- Data for Name: vehicle_queue; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.vehicle_queue (id, vehicle_id, destination_id, destination_name, sub_route, sub_route_name, "queueType", queue_position, status, entered_at, available_seats, total_seats, base_price, estimated_departure, actual_departure, queue_type) FROM stdin;
\.


--
-- Data for Name: vehicle_schedules; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.vehicle_schedules (id, vehicle_id, route_id, departure_time, available_seats, total_seats, status, actual_departure) FROM stdin;
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: ivan
--

COPY public.vehicles (id, license_plate, capacity, phone_number, is_active, is_available, is_banned, default_destination_id, default_destination_name, created_at, updated_at, available_seats, total_seats, base_price, destination_id, destination_name) FROM stdin;
veh_3133302054554e2033313438	130 TUN 3148	8	29232735	t	t	f	\N	\N	2025-10-07 10:46:44.024	2025-10-07 10:46:44.024	8	8	2.00	\N	\N
veh_3132372054554e2037323732	127 TUN 7272	8	94780013	t	t	f	\N	\N	2025-10-07 10:46:44.07	2025-10-07 10:46:44.07	8	8	2.00	\N	\N
veh_3233332054554e2036363831	233 TUN 6681	8	58970761	t	t	f	\N	\N	2025-10-07 10:46:44.078	2025-10-07 10:46:44.078	8	8	2.00	\N	\N
veh_3235322054554e2032303637	252 TUN 2067	8	55592957	t	t	f	\N	\N	2025-10-07 10:46:44.085	2025-10-07 10:46:44.085	8	8	2.00	\N	\N
veh_3138322054554e2032303330	182 TUN 2030	8	99332608	t	t	f	\N	\N	2025-10-07 10:46:44.102	2025-10-07 10:46:44.102	8	8	2.00	\N	\N
veh_3137392054554e2034323934	179 TUN 4294	8	50892458	t	t	f	\N	\N	2025-10-07 10:46:44.108	2025-10-07 10:46:44.108	8	8	2.00	\N	\N
veh_3232322054554e2037343639	222 TUN 7469	8	97317164	t	t	f	\N	\N	2025-10-07 10:46:44.117	2025-10-07 10:46:44.117	8	8	2.00	\N	\N
veh_3132392054554e2032373735	129 TUN 2775	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.129	2025-10-07 10:46:44.129	8	8	2.00	\N	\N
veh_3138322054554e2035303133	182 TUN 5013	8	25712890	t	t	f	\N	\N	2025-10-07 10:46:44.158	2025-10-07 10:46:44.158	8	8	2.00	\N	\N
veh_3136322054554e2033353136	162 TUN 3516	8	23615494	t	t	f	\N	\N	2025-10-07 10:46:44.189	2025-10-07 10:46:44.189	8	8	2.00	\N	\N
veh_3132312054554e2039333033	121 TUN 9303	8	23898768	t	t	f	\N	\N	2025-10-07 10:46:44.202	2025-10-07 10:46:44.202	8	8	2.00	\N	\N
veh_3136392054554e2037393937	169 TUN 7997	8	26709485	t	t	f	\N	\N	2025-10-07 10:46:44.212	2025-10-07 10:46:44.212	8	8	2.00	\N	\N
veh_3232342054554e2035333333	224 TUN 5333	8	97464589	t	t	f	\N	\N	2025-10-07 10:46:44.256	2025-10-07 10:46:44.256	8	8	2.00	\N	\N
veh_3137352054554e2033363732	175 TUN 3672	8	97967577	t	t	f	\N	\N	2025-10-07 10:46:44.319	2025-10-07 10:46:44.319	8	8	2.00	\N	\N
veh_3233372054554e2038333430	237 TUN 8340	8	20532342	t	t	f	\N	\N	2025-10-07 10:46:44.331	2025-10-07 10:46:44.331	8	8	2.00	\N	\N
veh_3234372054554e2038353536	247 TUN 8556	8	58891837	t	t	f	\N	\N	2025-10-07 10:46:44.342	2025-10-07 10:46:44.342	8	8	2.00	\N	\N
veh_3233352054554e2032323238	235 TUN 2228	8	23257568	t	t	f	\N	\N	2025-10-07 10:46:44.351	2025-10-07 10:46:44.351	8	8	2.00	\N	\N
veh_3230362054554e2039393431	206 TUN 9941	8	96811709	t	t	f	\N	\N	2025-10-07 10:46:44.363	2025-10-07 10:46:44.363	8	8	2.00	\N	\N
veh_3134302054554e2038343834	140 TUN 8484	8	25637511	t	t	f	\N	\N	2025-10-07 10:46:44.373	2025-10-07 10:46:44.373	8	8	2.00	\N	\N
veh_3139372054554e2039323934	197 TUN 9294	8	21526177	t	t	f	\N	\N	2025-10-07 10:46:44.385	2025-10-07 10:46:44.385	8	8	2.00	\N	\N
veh_3132362054554e2035303734	126 TUN 5074	8	97316555	t	t	f	\N	\N	2025-10-07 10:46:44.396	2025-10-07 10:46:44.396	8	8	2.00	\N	\N
veh_3138312054554e2038373936	181 TUN 8796	8	99102510	t	t	f	\N	\N	2025-10-07 10:46:44.403	2025-10-07 10:46:44.403	8	8	2.00	\N	\N
veh_3132352054554e20393939	125 TUN 999	8	95577018	t	t	f	\N	\N	2025-10-07 10:46:44.412	2025-10-07 10:46:44.412	8	8	2.00	\N	\N
veh_3132372054554e2031373833	127 TUN 1783	8	98632403	t	t	f	\N	\N	2025-10-07 10:46:44.422	2025-10-07 10:46:44.422	8	8	2.00	\N	\N
veh_3139332054554e2035333736	193 TUN 5376	8	20258908	t	t	f	\N	\N	2025-10-07 10:46:44.465	2025-10-07 10:46:44.465	8	8	2.00	\N	\N
veh_3234352054554e20363034	245 TUN 604	8	43278970	t	t	f	\N	\N	2025-10-07 10:46:44.499	2025-10-07 10:46:44.499	8	8	2.00	\N	\N
veh_3139312054554e2035323537	191 TUN 5257	8	41116440	t	t	f	\N	\N	2025-10-07 10:46:44.529	2025-10-07 10:46:44.529	8	8	2.00	\N	\N
veh_3233352054554e2033313138	235 TUN 3118	8	98588595	t	t	f	\N	\N	2025-10-07 10:46:44.559	2025-10-07 10:46:44.559	8	8	2.00	\N	\N
veh_3234342054554e2031333431	244 TUN 1341	8	25477138	t	t	f	\N	\N	2025-10-07 10:46:44.59	2025-10-07 10:46:44.59	8	8	2.00	\N	\N
veh_3134352054554e2031303634	145 TUN 1064	8	98244390	t	t	f	\N	\N	2025-10-07 10:46:44.612	2025-10-07 10:46:44.612	8	8	2.00	\N	\N
veh_3133382054554e2035373738	138 TUN 5778	8	97345440	t	t	f	\N	\N	2025-10-07 10:46:44.621	2025-10-07 10:46:44.621	8	8	2.00	\N	\N
veh_3134322054554e2032323736	142 TUN 2276	8	27104401	t	t	f	\N	\N	2025-10-07 10:46:44.629	2025-10-07 10:46:44.629	8	8	2.00	\N	\N
veh_3230342054554e2037373131	204 TUN 7711	8	97733449	t	t	f	\N	\N	2025-10-07 10:46:44.642	2025-10-07 10:46:44.642	8	8	2.00	\N	\N
veh_3133382054554e2031303234	138 TUN 1024	8	97600407	t	t	f	\N	\N	2025-10-07 10:46:44.652	2025-10-07 10:46:44.652	8	8	2.00	\N	\N
veh_3139342054554e2039333031	194 TUN 9301	8	52035264	t	t	f	\N	\N	2025-10-07 10:46:44.684	2025-10-07 10:46:44.684	8	8	2.00	\N	\N
veh_3235332054554e2039343138	253 TUN 9418	8	46546646	t	t	f	\N	\N	2025-10-07 10:46:44.692	2025-10-07 10:46:44.692	8	8	2.00	\N	\N
veh_3132372054554e2034333739	127 TUN 4379	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.7	2025-10-07 10:46:44.7	8	8	2.00	\N	\N
veh_3230332054554e2033313538	203 TUN 3158	8	53785597	t	t	f	\N	\N	2025-10-07 10:46:44.708	2025-10-07 10:46:44.708	8	8	2.00	\N	\N
veh_3232352054554e2032373531	225 TUN 2751	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.731	2025-10-07 10:46:44.731	8	8	2.00	\N	\N
veh_3234372054554e2038393531	247 TUN 8951	8	96064136	t	t	f	\N	\N	2025-10-07 10:46:44.753	2025-10-07 10:46:44.753	8	8	2.00	\N	\N
veh_3234392054554e2038333534	249 TUN 8354	8	53978422	t	t	f	\N	\N	2025-10-07 10:46:44.76	2025-10-07 10:46:44.76	8	8	2.00	\N	\N
veh_3233382054554e2034333232	238 TUN 4322	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.768	2025-10-07 10:46:44.768	8	8	2.00	\N	\N
veh_3133302054554e2032313636	130 TUN 2166	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.789	2025-10-07 10:46:44.789	8	8	2.00	\N	\N
veh_3232362054554e2035333334	226 TUN 5334	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.807	2025-10-07 10:46:44.807	8	8	2.00	\N	\N
veh_3235302054554e20363739	250 TUN 679	8	95426912	t	t	f	\N	\N	2025-10-07 10:46:44.813	2025-10-07 10:46:44.813	8	8	2.00	\N	\N
veh_3233372054554e2039353336	237 TUN 9536	8	98406016	t	t	f	\N	\N	2025-10-07 10:46:44.832	2025-10-07 10:46:44.832	8	8	2.00	\N	\N
veh_3134302054554e2038323731	140 TUN 8271	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.858	2025-10-07 10:46:44.858	8	8	2.00	\N	\N
veh_3234392054554e2034303332	249 TUN 4032	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.865	2025-10-07 10:46:44.865	8	8	2.00	\N	\N
veh_3132322054554e2033383536	122 TUN 3856	8	\N	t	t	f	\N	\N	2025-10-07 10:46:44.871	2025-10-07 10:46:44.871	8	8	2.00	\N	\N
veh_3134302054554e2032363731	140 TUN 2671	8	97768051	t	t	f	\N	\N	2025-10-07 10:46:44.878	2025-10-07 10:46:44.878	8	8	2.00	\N	\N
veh_3232372054554e2034333739	227 TUN 4379	8	97368125	t	t	f	\N	\N	2025-10-07 10:46:44.885	2025-10-07 10:46:44.885	8	8	2.00	\N	\N
veh_3133302054554e2038313636	130 TUN 8166	8	97470570	t	t	f	\N	\N	2025-10-07 10:46:44.892	2025-10-07 10:46:44.892	8	8	2.00	\N	\N
veh_3234302054554e2037373131	240 TUN 7711	8	97733449	t	t	f	\N	\N	2025-10-07 10:46:44.913	2025-10-07 10:46:44.913	8	8	2.00	\N	\N
96b8a5b6-6676-45a0-8888-12c6bb9d2910	146 TUN 3509	8	97928683	t	t	f	\N	\N	2025-10-07 13:19:32.035	2025-10-07 13:19:32.035	8	8	2.00	\N	\N
91a8014b-8b7d-4bc9-9f79-95266bbe14f6	173 TUN 8414	8	98411163	t	t	f	\N	\N	2025-10-07 14:28:05.651	2025-10-07 14:28:05.651	8	8	2.00	\N	\N
veh_3134382054554e2035373837	148 TUN 5784	8	94851005	t	t	f	\N	\N	2025-10-07 10:46:44.435	2025-10-08 09:42:12.122	8	8	2.00	\N	\N
050f7843-d32d-4694-80bc-f18f13265d96	179 TUN 9294	8	21526177	t	t	f	\N	\N	2025-10-07 14:33:52.364	2025-10-07 14:33:52.364	8	8	2.00	\N	\N
89a51db6-9bc4-4251-a8ef-7aba5ad62cf5	196 TUN 1122	8	55264956	t	t	f	\N	\N	2025-10-07 14:42:42.317	2025-10-07 14:42:42.317	8	8	2.00	\N	\N
veh_3133312054554e2038323138	131 TUN 8218	8	22653136	t	t	t	\N	\N	2025-10-07 10:46:44.095	2025-10-07 14:44:04.454	8	8	2.00	\N	\N
veh_3138352054554e2039343035	185 TUN 9405	6	94030030	t	t	f	\N	\N	2025-10-07 10:46:44.195	2025-10-08 09:38:09.753	8	8	2.00	\N	\N
veh_3133322054554e2037323139	132 TUN 7219	8	97956292	t	t	f	\N	\N	2025-10-07 10:46:44.635	2025-10-08 09:42:47.828	8	8	2.00	\N	\N
veh_3234392054554e2039373736	249 TUN 9776	8	59670088	t	t	f	\N	\N	2025-10-07 10:46:44.246	2025-10-08 09:48:53.03	8	8	2.00	\N	\N
veh_3233392054554e2034373831	239 TUN 4781	8	20064707	t	t	f	\N	\N	2025-10-07 10:46:44.294	2025-10-12 12:52:45.116	8	8	2.00	\N	\N
veh_3135332054554e2031303634	153 TUN 1064	8	\N	t	t	t	\N	\N	2025-10-07 10:46:44.677	2025-10-12 22:30:35.926	8	8	2.00	\N	\N
22409a80-4ece-45d6-8123-bed8ef4a05a4	131 TUN 8213	8	22653136	t	t	f	\N	\N	2025-10-07 14:44:53.205	2025-10-07 14:44:53.205	8	8	2.00	\N	\N
14caeefb-d661-4e77-921a-954bafbe7a2c	136 TUN 1486	8	98677175	t	t	f	\N	\N	2025-10-07 14:51:18.386	2025-10-07 14:51:18.386	8	8	2.00	\N	\N
29049e60-903f-4439-a095-3aac7cd39c70	175 TUN 8029	8	97815404	t	t	f	\N	\N	2025-10-07 15:21:31.636	2025-10-07 15:21:31.636	8	8	2.00	\N	\N
de937d42-3187-46c2-bfdc-445891797d55	242 TUN 2817	8	53935290	t	t	f	\N	\N	2025-10-07 15:22:49.452	2025-10-07 15:22:49.452	8	8	2.00	\N	\N
3f86f0cc-ab55-4045-8672-9b5388668503	220 TUN 6725	8	21999555	t	t	f	\N	\N	2025-10-07 15:39:12.078	2025-10-07 15:39:12.078	8	8	2.00	\N	\N
5a487488-41bf-4863-9b46-14b51ed931fc	242 TUN 1417	8	97085339	t	t	f	\N	\N	2025-10-07 15:40:08.821	2025-10-07 15:40:08.821	8	8	2.00	\N	\N
bd9b90a8-5927-451b-8c6c-d0c71ad30148	199 TUN 6994	8	96531703	t	t	f	\N	\N	2025-10-07 15:41:51.206	2025-10-07 15:41:51.206	8	8	2.00	\N	\N
def04ebe-4c4a-4af4-8db1-b16b26c38331	252 TUN 471	8	55597400	t	t	f	\N	\N	2025-10-07 15:43:41.029	2025-10-07 15:43:41.029	8	8	2.00	\N	\N
570e26a7-09ee-4fce-b718-15b255119878	164 TUN 3509	8	97928683	t	t	f	\N	\N	2025-10-07 16:04:23.143	2025-10-07 16:04:23.143	8	8	2.00	\N	\N
c7c738d1-d016-40dd-8d31-a1510b697a8d	147 TUN 2993	8	93942501	t	t	f	\N	\N	2025-10-08 11:28:00.448	2025-10-08 11:28:00.448	8	8	2.00	\N	\N
21b1699c-55db-449d-9854-e787ff06c33a	189 TUN 2251	8	20703658	t	t	f	\N	\N	2025-10-08 11:36:14.884	2025-10-08 11:36:14.884	8	8	2.00	\N	\N
48439240-9a9a-4342-975b-b5dc0a1679d9	238 TUN 6573	8	29392271	t	t	f	\N	\N	2025-10-08 11:43:11.13	2025-10-08 11:43:11.13	8	8	2.00	\N	\N
e00a2c72-5dab-4480-a522-e27af88d22fd	191 TUN 8903	8	29468818	t	t	f	\N	\N	2025-10-08 11:45:10.192	2025-10-08 11:45:10.192	8	8	2.00	\N	\N
ab273830-0eae-4c6d-940c-34745e0494c7	218 TUN 1158	8	95305900	t	t	f	\N	\N	2025-10-08 11:48:19.264	2025-10-08 11:48:19.264	8	8	2.00	\N	\N
f11bbac1-46b5-4b95-9e7b-d1afc42c050c	210 TUN 4130	8	29714887	t	t	f	\N	\N	2025-10-08 11:53:26.774	2025-10-08 11:53:26.774	8	8	2.00	\N	\N
456e2ee1-927b-410a-b77f-b1f43098f1bd	120 TUN 1718	8	22089888	t	t	f	\N	\N	2025-10-08 11:58:19.505	2025-10-08 11:58:19.505	8	8	2.00	\N	\N
128f10f5-5bdc-4cac-b165-96c2fefeca6c	243 TUN 4358	8	54124918	t	t	f	\N	\N	2025-10-08 11:59:05.613	2025-10-08 11:59:05.613	8	8	2.00	\N	\N
20568779-4dd7-4dde-8961-356fa6bfbadc	166 TUN 8519	8	97893187	t	t	f	\N	\N	2025-10-08 12:03:20.863	2025-10-08 12:03:20.863	8	8	2.00	\N	\N
c68362f6-3ba2-4845-b188-4735d353eecd	192 TUN 3858	8	54502607	t	t	f	\N	\N	2025-10-08 12:04:10.395	2025-10-08 12:04:10.395	8	8	2.00	\N	\N
4ca4bc71-ccb7-4b02-9e30-7a6e74aa5696	255 TUN 4893	8	92777147	t	t	f	\N	\N	2025-10-08 12:04:49.89	2025-10-08 12:04:49.89	8	8	2.00	\N	\N
9dca1b65-1688-4c5c-9209-e35e9f21290e	140 TUN 2335	8	57084170	t	t	f	\N	\N	2025-10-08 12:10:39.71	2025-10-08 12:10:39.71	8	8	2.00	\N	\N
0ed253e9-6c76-464a-9cc9-6369fa3f119b	184 TUN 1376	8	24156600	t	t	f	\N	\N	2025-10-08 13:02:43.297	2025-10-08 13:02:43.297	8	8	2.00	\N	\N
c84ba5d0-0ac4-4b61-ba37-e8973889a6b6	121 TUN 9450	8	96064510	t	t	f	\N	\N	2025-10-08 15:05:08.66	2025-10-08 15:05:08.66	8	8	2.00	\N	\N
d6257331-1a01-4a8b-9a66-c70addf18f7b	221 TUN 5867	8	96124333	t	t	f	\N	\N	2025-10-08 15:05:51.707	2025-10-08 15:05:51.707	8	8	2.00	\N	\N
97bc7054-912b-467b-90e2-f1862501cd2b	248 TUN 2941	8	99745181	t	t	f	\N	\N	2025-10-08 15:06:39.716	2025-10-08 15:06:39.716	8	8	2.00	\N	\N
6af5315d-f06e-416b-9bb4-b95fe86f1158	135 TUN 257	8	22206837	t	t	f	\N	\N	2025-10-09 14:21:55.736	2025-10-09 14:21:55.736	8	8	2.00	\N	\N
cad327d2-45d8-485a-b98f-323a7335f640	247 TUN 9550	8	55131836	t	t	f	\N	\N	2025-10-09 14:25:44.55	2025-10-09 14:25:44.55	8	8	2.00	\N	\N
6c2d68b2-d7b0-403f-a521-1196ec87ff6d	121 TUN 7844	8	97805048	t	t	f	\N	\N	2025-10-09 14:26:29.598	2025-10-09 14:26:29.598	8	8	2.00	\N	\N
vehicle_1760247734626_cuorwq86x	210TUN4130	8	52929114	t	t	f	\N	\N	2025-10-12 05:42:14.627	2025-10-12 05:42:14.627	8	8	2.00	\N	\N
vehicle_1760248901989_kkpdqpdp0	247TUN5381	8	92557111	t	t	f	\N	\N	2025-10-12 06:01:41.991	2025-10-12 06:01:41.991	8	8	2.00	\N	\N
vehicle_1760249095699_7h62u6flc	193TUN6376	8	20258908	t	t	f	\N	\N	2025-10-12 06:04:55.699	2025-10-12 06:04:55.699	8	8	2.00	\N	\N
vehicle_1760249233865_2rdyukkkq	121TUN7184	8	95003004	t	t	f	\N	\N	2025-10-12 06:07:13.866	2025-10-12 06:07:13.866	8	8	2.00	\N	\N
vehicle_1760249537900_i1ktr6j30	127TUN2965	8	55417792	t	t	f	\N	\N	2025-10-12 06:12:17.9	2025-10-12 06:12:17.9	8	8	2.00	\N	\N
vehicle_1760249655820_o2w7zbb4b	127TUN2956	8	55417792	t	t	f	\N	\N	2025-10-12 06:14:15.821	2025-10-12 06:14:15.821	8	8	2.00	\N	\N
vehicle_1760249733257_lk9zxkckf	224TUN2800	8	23016374	t	t	f	\N	\N	2025-10-12 06:15:33.258	2025-10-12 06:15:33.258	8	8	2.00	\N	\N
vehicle_1760250959358_yucrp9a2g	166TUN7598	8	50075035	t	t	f	\N	\N	2025-10-12 06:35:59.359	2025-10-12 06:35:59.359	8	8	2.00	\N	\N
vehicle_1760251516726_v3xdgeaou	178TUN3446	8	\N	t	t	f	\N	\N	2025-10-12 06:45:16.727	2025-10-12 06:45:16.727	8	8	2.00	\N	\N
vehicle_1760251602175_4y0a2r1fm	178TUN1173	8	\N	t	t	f	\N	\N	2025-10-12 06:46:42.176	2025-10-12 06:46:42.176	8	8	2.00	\N	\N
vehicle_1760252392573_ilt6t9ei2	253TUN2817	8	\N	t	t	f	\N	\N	2025-10-12 06:59:52.574	2025-10-12 06:59:52.574	8	8	2.00	\N	\N
vehicle_1760252593027_xjlilyx8e	141TUN5692	8	\N	t	t	f	\N	\N	2025-10-12 07:03:13.028	2025-10-12 07:03:13.028	8	8	2.00	\N	\N
vehicle_1760251707403_45c6e9gdt	124TUN237	8	20985662	t	t	f	\N	\N	2025-10-12 06:48:27.404	2025-10-12 07:05:16.367	8	8	2.00	\N	\N
e31a2351-1d6e-4b4c-b1f4-ae81a9167981	181 TUN 5476	8	\N	t	t	f	\N	\N	2025-10-12 08:23:48.54	2025-10-12 08:23:48.54	8	8	2.00	\N	\N
e4f7cd3d-69bc-4482-8923-5bd42e68b698	244 TUN 4941	8	\N	t	t	f	\N	\N	2025-10-12 08:51:26.85	2025-10-12 08:51:26.85	8	8	2.00	\N	\N
vehicle_1760260625377_plz85u34c	250TUN7082	8	\N	t	t	f	\N	\N	2025-10-12 09:17:05.378	2025-10-12 09:17:05.378	8	8	2.00	\N	\N
f76e78fc-fd60-4b26-ae9d-a119459aa2a6	243 TUN 3852	8	\N	t	t	f	\N	\N	2025-10-12 11:00:58.52	2025-10-12 11:00:58.52	8	8	2.00	\N	\N
b9e3efb0-32f2-4e68-8fbf-c7f032fc7c90	127 TUN 5147	8	\N	t	t	f	\N	\N	2025-10-12 11:04:52.403	2025-10-12 11:04:52.403	8	8	2.00	\N	\N
0815e14d-a7ae-404a-9c16-353626398e6f	222 TUN 2263	8	\N	t	t	f	\N	\N	2025-10-12 11:16:58.351	2025-10-12 11:16:58.351	8	8	2.00	\N	\N
b339ef18-7892-48ff-96c8-82df56271eae	251 TUN 7611	8	98596700	t	t	f	\N	\N	2025-10-12 11:31:41.371	2025-10-12 11:31:41.371	8	8	2.00	\N	\N
866ffcfd-be45-46fe-894e-104ac2bd71df	170 TUN 2905	8	\N	t	t	f	\N	\N	2025-10-12 11:49:29.378	2025-10-12 11:49:29.378	8	8	2.00	\N	\N
0d51ab0b-dd63-4030-803d-43971f5991de	182 TUN 5096	8	\N	t	t	f	\N	\N	2025-10-12 11:51:19.431	2025-10-12 11:51:19.431	8	8	2.00	\N	\N
d084e91a-df8b-4f8d-a3a9-f09b74395a85	233 TUN 7278	8	\N	t	t	f	\N	\N	2025-10-12 11:57:51.881	2025-10-12 11:57:51.881	8	8	2.00	\N	\N
6f680192-2aaf-4eae-aac9-4b31f41a2d8d	233 TUN 7287	8	\N	t	t	f	\N	\N	2025-10-12 11:58:17.418	2025-10-12 11:58:17.418	8	8	2.00	\N	\N
428de0a6-be2e-436b-918d-7887419291c0	247 TUN 6296	8	\N	t	t	f	\N	\N	2025-10-12 11:59:03.144	2025-10-12 11:59:03.144	8	8	2.00	\N	\N
979bf5a2-ee69-4c7c-9cc0-ff4469d2bd30	249 TUN 818	8	\N	t	t	f	\N	\N	2025-10-12 12:16:03.767	2025-10-12 12:16:03.767	8	8	2.00	\N	\N
007bd630-a4cb-4244-95ea-7b7828c6ac53	224 TUN 5232	8	\N	t	t	f	\N	\N	2025-10-12 12:34:40.796	2025-10-12 12:34:40.796	8	8	2.00	\N	\N
4bb4a12b-8571-4cc4-aa9b-c460a878cada	242 TUN 7358	8	\N	t	t	f	\N	\N	2025-10-12 13:11:05.392	2025-10-12 13:11:05.392	8	8	2.00	\N	\N
a827ab5f-fffd-4e01-b50d-378c4f61f615	180 TUN 3276	8	\N	t	t	f	\N	\N	2025-10-12 13:50:47.922	2025-10-12 13:50:47.922	8	8	2.00	\N	\N
00784611-53e2-498b-b30b-778e5376efac	225 TUN 458	8	\N	t	t	f	\N	\N	2025-10-12 14:19:59.95	2025-10-12 14:19:59.95	8	8	2.00	\N	\N
ea2a4966-8d93-4041-9876-e1465f09ebc9	244 TUN 6319	8	96204881	t	t	f	\N	\N	2025-10-12 15:09:26.039	2025-10-12 15:09:26.039	8	8	2.00	\N	\N
24bd242e-9ed7-41dd-91e4-e91290118db6	253 TUN 6900	8	\N	t	t	f	\N	\N	2025-10-12 15:16:28.818	2025-10-12 15:16:28.818	8	8	2.00	\N	\N
ccb80a37-fc0c-4f3a-8354-8e6e91a11e48	187 TUN 1357	8	\N	t	t	f	\N	\N	2025-10-12 15:20:29.6	2025-10-12 15:20:29.6	8	8	2.00	\N	\N
1e792121-0a50-429a-bfe8-7e1a0e8c1ab6	225 TUN 5376	8	\N	t	t	f	\N	\N	2025-10-12 15:50:13.544	2025-10-12 15:50:13.544	8	8	2.00	\N	\N
a7938b81-2018-4dcf-8456-4d51e8e1aef4	249 TUN 9077	8	\N	t	t	f	\N	\N	2025-10-12 15:56:29.182	2025-10-12 15:56:29.182	8	8	2.00	\N	\N
e7795446-726f-43f7-bb34-aba040be0bde	182 TUN 7866	8	\N	t	t	f	\N	\N	2025-10-12 15:58:39.935	2025-10-12 15:58:39.935	8	8	2.00	\N	\N
4d000425-8615-4b20-9648-2052e3776b49	178 TUN 7005	8	\N	t	t	f	\N	\N	2025-10-12 16:48:02.474	2025-10-12 16:48:02.474	8	8	2.00	\N	\N
015afe3a-3526-42fc-a9ae-4d963be711c0	130 TUN 2221	8	\N	t	t	f	\N	\N	2025-10-12 17:12:41.848	2025-10-12 17:12:41.848	8	8	2.00	\N	\N
068fea9c-279a-4df3-a497-2dde7cc6e9d0	203 TUN 2938	8	\N	t	t	f	\N	\N	2025-10-12 17:13:32.711	2025-10-12 17:13:32.711	8	8	2.00	\N	\N
3ee39d2e-797b-43ec-a49c-ec36b2f1ac20	234 TUN 411	8	\N	t	t	f	\N	\N	2025-10-12 17:15:10.927	2025-10-12 17:15:10.927	8	8	2.00	\N	\N
10440f4d-acde-4772-8237-0a646d4fd650	252 TUN 5925	8	\N	t	t	f	\N	\N	2025-10-12 17:57:09.453	2025-10-12 17:57:09.453	8	8	2.00	\N	\N
vehicle_1760418874312_yfjec858a	853TUN5522	8	55223366	t	t	f	\N	\N	2025-10-14 06:14:34.313	2025-10-14 06:14:34.313	8	8	2.00	\N	\N
fd49c3ca-e379-4111-8a37-a0a58d68e05f	123 TUN 4567	8	\N	t	t	f	\N	\N	2025-10-15 09:32:42.543	2025-10-15 09:32:42.543	8	8	2.00	\N	\N
a01d1105-9e36-4eba-b164-34e2bba4adf8	111 TUN 1111	1	\N	t	t	f	\N	\N	2025-10-15 15:42:03.348	2025-10-15 15:42:03.348	1	1	2.00	\N	\N
a3822825-4ecc-4d6a-892b-ae13706767a3	222 TUN 2222	4	\N	t	t	f	\N	\N	2025-10-15 15:42:20.281	2025-10-15 15:42:20.281	4	4	2.00	\N	\N
40718af1-8404-4fdd-8914-111d8e393e9c	999 TUN 9999	1	\N	t	t	f	\N	\N	2025-10-16 23:48:14.134	2025-10-16 23:48:14.134	1	1	2.00	\N	\N
8fdf3bef-a3d1-4baf-8ca4-c99b380e4458	888 TUN 8888	1	\N	t	t	f	\N	\N	2025-10-16 23:50:09.05	2025-10-16 23:50:09.05	1	1	2.00	\N	\N
eaccda73-0cd4-46f6-9d0e-ad4a3961e453	777 TUN 7777	1	\N	t	t	f	\N	\N	2025-10-16 23:59:58.571	2025-10-16 23:59:58.571	1	1	2.00	\N	\N
\.


--
-- Name: offline_customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ivan
--

SELECT pg_catalog.setval('public.offline_customers_id_seq', 1, false);


--
-- Name: operation_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ivan
--

SELECT pg_catalog.setval('public.operation_logs_id_seq', 54, true);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: day_passes day_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.day_passes
    ADD CONSTRAINT day_passes_pkey PRIMARY KEY (id);


--
-- Name: exit_passes exit_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.exit_passes
    ADD CONSTRAINT exit_passes_pkey PRIMARY KEY (id);


--
-- Name: offline_customers offline_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.offline_customers
    ADD CONSTRAINT offline_customers_pkey PRIMARY KEY (id);


--
-- Name: operation_logs operation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.operation_logs
    ADD CONSTRAINT operation_logs_pkey PRIMARY KEY (id);


--
-- Name: print_queue print_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.print_queue
    ADD CONSTRAINT print_queue_pkey PRIMARY KEY (id);


--
-- Name: printers printers_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.printers
    ADD CONSTRAINT printers_pkey PRIMARY KEY (id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: station_config station_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.station_config
    ADD CONSTRAINT station_config_pkey PRIMARY KEY (id);


--
-- Name: station_daily_statistics station_daily_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.station_daily_statistics
    ADD CONSTRAINT station_daily_statistics_pkey PRIMARY KEY (id);


--
-- Name: station_daily_statistics station_daily_statistics_station_id_date_key; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.station_daily_statistics
    ADD CONSTRAINT station_daily_statistics_station_id_date_key UNIQUE (station_id, date);


--
-- Name: stations stations_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_pkey PRIMARY KEY (id);


--
-- Name: stations stations_station_id_key; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.stations
    ADD CONSTRAINT stations_station_id_key UNIQUE (station_id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- Name: vehicle_authorized_stations vehicle_authorized_stations_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicle_authorized_stations
    ADD CONSTRAINT vehicle_authorized_stations_pkey PRIMARY KEY (id);


--
-- Name: vehicle_queue vehicle_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicle_queue
    ADD CONSTRAINT vehicle_queue_pkey PRIMARY KEY (id);


--
-- Name: vehicle_schedules vehicle_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicle_schedules
    ADD CONSTRAINT vehicle_schedules_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: bookings_booking_status_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_booking_status_idx ON public.bookings USING btree (booking_status);


--
-- Name: bookings_cancelled_at_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_cancelled_at_idx ON public.bookings USING btree (cancelled_at);


--
-- Name: bookings_created_at_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_created_at_idx ON public.bookings USING btree (created_at);


--
-- Name: bookings_created_by_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_created_by_idx ON public.bookings USING btree (created_by);


--
-- Name: bookings_is_verified_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_is_verified_idx ON public.bookings USING btree (is_verified);


--
-- Name: bookings_local_id_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX bookings_local_id_key ON public.bookings USING btree (local_id);


--
-- Name: bookings_queue_id_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_queue_id_idx ON public.bookings USING btree (queue_id);


--
-- Name: bookings_verification_code_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX bookings_verification_code_idx ON public.bookings USING btree (verification_code);


--
-- Name: bookings_verification_code_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX bookings_verification_code_key ON public.bookings USING btree (verification_code);


--
-- Name: idx_bookings_created_by; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_bookings_created_by ON public.bookings USING btree (created_by);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (booking_status);


--
-- Name: idx_bookings_verification; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_bookings_verification ON public.bookings USING btree (verification_code);


--
-- Name: idx_day_passes_created_by; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_day_passes_created_by ON public.day_passes USING btree (created_by);


--
-- Name: idx_day_passes_license_plate; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_day_passes_license_plate ON public.day_passes USING btree (license_plate);


--
-- Name: idx_day_passes_purchase_date; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_day_passes_purchase_date ON public.day_passes USING btree (purchase_date);


--
-- Name: idx_day_passes_valid_period; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_day_passes_valid_period ON public.day_passes USING btree (valid_from, valid_until);


--
-- Name: idx_day_passes_vehicle_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_day_passes_vehicle_id ON public.day_passes USING btree (vehicle_id);


--
-- Name: idx_exit_passes_created_by; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_created_by ON public.exit_passes USING btree (created_by);


--
-- Name: idx_exit_passes_destination_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_destination_id ON public.exit_passes USING btree (destination_id);


--
-- Name: idx_exit_passes_exit_time; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_exit_time ON public.exit_passes USING btree (current_exit_time);


--
-- Name: idx_exit_passes_license_plate; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_license_plate ON public.exit_passes USING btree (license_plate);


--
-- Name: idx_exit_passes_queue_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_queue_id ON public.exit_passes USING btree (queue_id);


--
-- Name: idx_exit_passes_vehicle_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_exit_passes_vehicle_id ON public.exit_passes USING btree (vehicle_id);


--
-- Name: idx_print_queue_priority; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_print_queue_priority ON public.print_queue USING btree (priority, created_at);


--
-- Name: idx_print_queue_status; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_print_queue_status ON public.print_queue USING btree (status);


--
-- Name: idx_printers_ip_address; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_printers_ip_address ON public.printers USING btree (ip_address);


--
-- Name: idx_printers_station_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_printers_station_id ON public.printers USING btree (station_id);


--
-- Name: idx_staff_active; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_staff_active ON public.staff USING btree (is_active);


--
-- Name: idx_staff_cin; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_staff_cin ON public.staff USING btree (cin);


--
-- Name: idx_station_daily_stats_date; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_station_daily_stats_date ON public.station_daily_statistics USING btree (date);


--
-- Name: idx_station_daily_stats_station_date; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_station_daily_stats_station_date ON public.station_daily_statistics USING btree (station_id, date);


--
-- Name: idx_station_daily_stats_station_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_station_daily_stats_station_id ON public.station_daily_statistics USING btree (station_id);


--
-- Name: idx_trips_date; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_date ON public.trips USING btree (date(start_time));


--
-- Name: idx_trips_destination_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_destination_id ON public.trips USING btree (destination_id);


--
-- Name: idx_trips_license_plate; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_license_plate ON public.trips USING btree (license_plate);


--
-- Name: idx_trips_queue_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_queue_id ON public.trips USING btree (queue_id);


--
-- Name: idx_trips_start_time; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_start_time ON public.trips USING btree (start_time);


--
-- Name: idx_trips_vehicle_id; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX idx_trips_vehicle_id ON public.trips USING btree (vehicle_id);


--
-- Name: routes_station_id_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX routes_station_id_key ON public.routes USING btree (station_id);


--
-- Name: sessions_token_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX sessions_token_key ON public.sessions USING btree (token);


--
-- Name: staff_cin_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX staff_cin_key ON public.staff USING btree (cin);


--
-- Name: station_config_station_id_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX station_config_station_id_key ON public.station_config USING btree (station_id);


--
-- Name: vehicle_authorized_stations_vehicle_id_station_id_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX vehicle_authorized_stations_vehicle_id_station_id_key ON public.vehicle_authorized_stations USING btree (vehicle_id, station_id);


--
-- Name: vehicle_queue_destination_id_queueType_status_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX "vehicle_queue_destination_id_queueType_status_idx" ON public.vehicle_queue USING btree (destination_id, "queueType", status);


--
-- Name: vehicle_queue_destination_id_sub_route_status_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicle_queue_destination_id_sub_route_status_idx ON public.vehicle_queue USING btree (destination_id, sub_route, status);


--
-- Name: vehicle_queue_queue_position_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicle_queue_queue_position_idx ON public.vehicle_queue USING btree (queue_position);


--
-- Name: vehicle_queue_status_queueType_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX "vehicle_queue_status_queueType_idx" ON public.vehicle_queue USING btree (status, "queueType");


--
-- Name: vehicle_queue_vehicle_id_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicle_queue_vehicle_id_idx ON public.vehicle_queue USING btree (vehicle_id);


--
-- Name: vehicles_is_active_is_available_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicles_is_active_is_available_idx ON public.vehicles USING btree (is_active, is_available);


--
-- Name: vehicles_is_banned_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicles_is_banned_idx ON public.vehicles USING btree (is_banned);


--
-- Name: vehicles_license_plate_idx; Type: INDEX; Schema: public; Owner: ivan
--

CREATE INDEX vehicles_license_plate_idx ON public.vehicles USING btree (license_plate);


--
-- Name: vehicles_license_plate_key; Type: INDEX; Schema: public; Owner: ivan
--

CREATE UNIQUE INDEX vehicles_license_plate_key ON public.vehicles USING btree (license_plate);


--
-- Name: bookings bookings_cancelled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: bookings bookings_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: bookings bookings_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.vehicle_queue(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: bookings bookings_verified_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_verified_by_id_fkey FOREIGN KEY (verified_by_id) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: day_passes day_passes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.day_passes
    ADD CONSTRAINT day_passes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: day_passes day_passes_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.day_passes
    ADD CONSTRAINT day_passes_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: exit_passes exit_passes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.exit_passes
    ADD CONSTRAINT exit_passes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: exit_passes exit_passes_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.exit_passes
    ADD CONSTRAINT exit_passes_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.vehicle_queue(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: exit_passes exit_passes_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.exit_passes
    ADD CONSTRAINT exit_passes_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: operation_logs operation_logs_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.operation_logs
    ADD CONSTRAINT operation_logs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: sessions sessions_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: station_daily_statistics station_daily_statistics_station_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.station_daily_statistics
    ADD CONSTRAINT station_daily_statistics_station_id_fkey FOREIGN KEY (station_id) REFERENCES public.stations(id);


--
-- Name: trips trips_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_queue_id_fkey FOREIGN KEY (queue_id) REFERENCES public.vehicle_queue(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: trips trips_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: vehicle_authorized_stations vehicle_authorized_stations_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicle_authorized_stations
    ADD CONSTRAINT vehicle_authorized_stations_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vehicle_queue vehicle_queue_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ivan
--

ALTER TABLE ONLY public.vehicle_queue
    ADD CONSTRAINT vehicle_queue_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

