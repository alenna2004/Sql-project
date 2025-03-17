--простые

--Найти все отели в сша с кондиционером
SELECT DISTINCT 
    hotelid, 
    name, 
    street  
FROM 
    (SELECT * 
    FROM 
        hotel 
        NATURAL JOIN 
            (SELECT townid FROM town WHERE town.country='USA')
    ) t1 
    NATURAL JOIN 
    room 
WHERE air_condition='true' 
ORDER by name ASC;

--Найти три самых дорогих тура
SELECT * 
FROM 
    tour 
ORDER BY price DESC 
LIMIT 3;

--Найти все перелеты из США в Eгипет
SELECT * 
FROM 
    flight 
WHERE
    flight.departure_airport_townid IN (SELECT townid FROM town WHERE town.country='USA')
    AND flight.arrival_airport_townid IN (SELECT townid FROM town WHERE town.country='Egypt');

--Найти сколько человек связано с заказом
SELECT 
    orderid, 
    COUNT(*) 
FROM 
    people_data_order GROUP BY orderid;


--средние

--Найти все свободные номера в период между 2025.07.08 и 2025.08.09
WITH t1 AS (SELECT 
                roomid 
            FROM 
                room_order 
            WHERE (start_date, end_date) OVERLAPS ('2025-07-08'::date, 
                                                    '2025-08-09'::date)
                                                  ),
t2 AS (SELECT
             roomid 
        FROM 
            (SELECT * 
            FROM tour_order NATURAL JOIN tour) 
        WHERE (start_date, end_date) OVERLAPS ('2025-07-08'::date, 
                                                '2025-08-09'::date)
                                              ),
t3 AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2),
t4 AS (SELECT 
            roomid, 
            COUNT(*) AS count 
        FROM t3 GROUP BY roomid),
t5 AS (SELECT coalesce(t4.roomid,room.roomid) AS roomid, 
              coalesce(count ,0) AS count, 
              num_of_rooms_in_hotel FROM t4 RIGHT JOIN room ON room.roomid= t4.roomid)
SELECT * FROM t5 
WHERE count < num_of_rooms_in_hotel 
ORDER BY roomid;

--Найти какой отель бронировали наибольшее число раз
WITH t1 AS (SELECT 
                roomid 
            FROM room_order),
t2 AS (SELECT 
            roomid 
            FROM (SELECT * 
                 FROM tour_order NATURAL JOIN tour)
       ),
t3 AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2),
t4 AS (SELECT 
            roomid, 
            COUNT(*) AS count 
        FROM t3 GROUP BY roomid),
t5 AS (SELECT 
            hotelid, 
            coalesce(count ,0) AS c 
        FROM t4 RIGHT JOIN room ON room.roomid= t4.roomid)
SELECT 
    hotelid, 
    SUM(c) AS sum 
FROM t5
GROUP BY hotelid ORDER BY sum DESC;

--Найти все перелеты в конкретный город и все номера в этом городе
SELECT 
    townid, 
    flightid, 
    roomid 
FROM (SELECT 
            roomid, 
            hotelid 
      FROM room 
      WHERE hotelid IN (SELECT 
                            hotelid 
                        FROM hotel JOIN flight ON hotel.townId=flight.arrival_airport_townid)
      )
NATURAL JOIN 
(SELECT 
    hotelid, 
    flightid, 
    townid 
FROM hotel JOIN flight ON hotel.townId=flight.arrival_airport_townid) 
ORDER BY townid;

--Найти заказы перелетов, отелей и туров конкретного  пользователя 
WITH t0 AS (SELECT * 
            FROM m_order WHERE personid='97452'),
t1 AS (SELECT * 
       FROM t0 NATURAL JOIN room_order),
t2 AS (SELECT * 
       FROM t0 NATURAL JOIN tour_order),
t3 AS (SELECT * 
       FROM t0 NATURAL JOIN flight_order),
t4 AS (SELECT 
            coalesce(t1.orderid, t2.orderid) AS orderid, 
            tourid, 
            roomid 
        FROM t2 FULL OUTER JOIN t1 ON t1.orderid=t2.orderid)
SELECT 
    coalesce(t3.orderid, t4.orderid) AS orderid, 
    tourid, 
    roomid, 
    flightid 
FROM t3 FULL OUTER JOIN t4 ON t3.orderid=t4.orderid;


--сложные

--Для каждого отеля посчитать общее число бронирований за год и доход отеля в каждом месяце
--t1-t3 получение таблицы комната-даты бронирования
WITH t1 AS (SELECT 
                roomid, 
                start_date, 
                end_date 
            FROM room_order),
t2 AS (SELECT 
            roomid, 
            start_date, 
            end_date 
        FROM (SELECT * 
              FROM tour_order NATURAL JOIN tour)
        ),
t3 AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2),
--t4-t5 выделение в полученной таблице месяца и года и соединение ее с отелем
t4 AS (SELECT 
            roomid, 
            DATE_PART('month',start_date) AS month, 
            date_part('year', start_date) AS year, 
            start_date 
        FROM t3),
t5 AS (SELECT 
            hotelid, 
            roomid,
            month, 
            year, 
            price 
        FROM t4 NATURAL JOIN room),
--t6 подсчет числа заказов за год
t6 AS (SELECT 
            hotelid, 
            name, 
            COUNT(*) AS total_orders_num 
        FROM t5 NATURAL JOIN hotel 
        GROUP BY hotelid, name),
--t7 рассчет выручки по месяцам для каждой комнаты
t7 AS (SELECT
            roomid, hotelid,
            SUM(CASE WHEN month = 9 AND YEAR = 2024 THEN price ELSE 0 END) 
                AS "2024-09",
            SUM(CASE WHEN month = 10 AND YEAR = 2024 THEN price ELSE 0 END) 
                AS "2024-10",
            SUM(CASE WHEN month = 11 AND YEAR = 2024 THEN price ELSE 0 END) 
                AS "2024-11",
            SUM(CASE WHEN month = 12 AND YEAR = 2024 THEN price ELSE 0 END) 
                AS "2024-12",
            SUM(CASE WHEN month = 1 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-01",
            SUM(CASE WHEN month = 2 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-02",
            SUM(CASE WHEN month = 3 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-03",
            SUM(CASE WHEN month = 4 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-04",
            SUM(CASE WHEN month = 5 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-05",
            SUM(CASE WHEN month = 6 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-06",
            SUM(CASE WHEN month = 7 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-07",
            SUM(CASE WHEN month = 8 AND YEAR = 2025 THEN price ELSE 0 END) 
                AS "2025-08"
        FROM t5 
        GROUP BY roomId, hotelid)
SELECT
            hotelid, name, total_orders_num,
            SUM("2024-09") AS "2024-09",
            SUM("2024-10") AS "2024-10",
            SUM("2024-11") AS "2024-11",
            SUM("2024-12") AS "2024-12",
            SUM("2025-01") AS "2025-01",
            SUM("2025-02") AS "2025-02",
            SUM("2025-03") AS "2025-03",
            SUM("2025-04") AS "2025-04",
            SUM("2025-05") AS "2025-05",
            SUM("2025-06") AS "2025-06",
            SUM("2025-07") AS "2025-07",
            SUM("2025-08") AS "2025-08"
        FROM t7 NATURAL JOIN t6 
        GROUP BY hotelid, name, total_orders_num;

--Найти для каждого пользователя те направления в которых он предпочитает путешествовать(предпочтительная страна и предпочтительные города) на основе этих предпочтений предложить пользователю тур, который мог бы ему понравиться
--t1-t11 получение таблицы человек-город по всем заказам и всем избранным
WITH tour_town AS (SELECT 
                        tourid, 
                        arrival_airport_townid AS townid 
                    FROM flight JOIN tour ON tour.flightid=flight.flightid),
t1 AS (SELECT 
            orderid, 
            personid, 
            flightid 
        FROM m_order NATURAL JOIN flight_order),
t2 AS (SELECT 
            orderid, 
            personid, 
            tourid 
        FROM m_order NATURAL JOIN tour_order),
t3 AS (SELECT 
            orderid, 
            personid, 
            roomid 
        FROM m_order NATURAL JOIN room_order),
t4 AS (SELECT 
            orderid, 
            personid, 
            townid 
        FROM t2 NATURAL JOIN tour_town),
t6 AS (SELECT 
            orderid, 
            personid, 
            arrival_airport_townid 
        FROM t1 NATURAL JOIN flight),
t7 AS (SELECT 
            orderid, 
            personid, 
            townid 
        FROM t3 
        NATURAL JOIN 
        (SELECT * FROM hotel NATURAL JOIN room)
        ),
t8 AS (SELECT 
            favouritesid, 
            personid, 
            arrival_airport_townid 
        FROM favourites 
        NATURAL JOIN 
        (SELECT * FROM flight_favourites NATURAL JOIN flight)
        ),
t9 AS (SELECT 
            favouritesid, 
            personid, 
            arrival_airport_townid 
        FROM favourites 
        NATURAL JOIN 
            (SELECT * 
            FROM tour_favourites NATURAL JOIN 
                                        (SELECT * 
                                        FROM flight JOIN tour ON tour.flightid=flight.flightid)
            )
        ),
t10 AS (SELECT 
            favouritesid, 
            personid, 
            townid 
        FROM favourites 
        NATURAL JOIN 
        (SELECT * FROM hotel_favourites NATURAL JOIN hotel)
        ),
t11 AS (SELECT * FROM t4 
        UNION ALL 
        SELECT * FROM t6 
        UNION ALL 
        SELECT * FROM t7 
        UNION ALL 
        SELECT * FROM t8 
        UNION ALL 
        SELECT * FROM t9 
        UNION ALL 
        SELECT * FROM t10),
count_towns AS (SELECT 
                    personid, 
                    name, 
                    townid,
                    ROW_NUMBER() OVER (PARTITION BY personid ORDER BY COUNT(name) DESC) rn1
                FROM t11 NATURAL JOIN town 
                GROUP BY personid, name, townid),
count_countries AS (SELECT 
                        personid, 
                        country,
                        ROW_NUMBER() OVER (PARTITION BY personid ORDER BY COUNT(country) DESC) rn2
                    FROM t11 NATURAL JOIN town 
                    GROUP BY personid, country),
--t12-t13 получение предпочитаемого города и предпочитаемой страны
t12 as(SELECT 
            personid, 
            townid, 
            name AS fav_town 
        FROM count_towns 
        WHERE rn1 = 1),
t13 AS (SELECT 
            personid, 
            country AS fav_country 
        FROM count_countries 
        WHERE rn2 = 1),
fav AS (SELECT * FROM t12 NATURAL JOIN t13),
rec_by_town AS (SELECT fav.personid,
                       (SELECT tourid 
                        FROM tour_town 
                        WHERE tour_town.townid = fav.townid
                        EXCEPT
                        SELECT tourid
                        FROM t2
                        WHERE personid = fav.personid LIMIT 1) AS recommend_by_town_tourid 
                FROM fav),
tour_country AS (SELECT * FROM tour_town NATURAL JOIN town),
rec_by_country AS (SELECT fav.personid,
                        (SELECT tourid 
                        FROM tour_country
                        WHERE tour_country.country = fav.fav_country
                        EXCEPT
                        SELECT tourid 
                        FROM t2 
                        WHERE personid = fav.personid LIMIT 1) AS recommend_by_country_tourid 
                    FROM fav)
SELECT 
    personid, 
    fav_town, 
    fav_country, 
    COALESCE(recommend_by_town_tourid, recommend_by_country_tourid) AS recommended_tour 
FROM fav NATURAL JOIN 
(rec_by_town NATURAL JOIN rec_by_country);


--Для каждого пользователя определить параметры отеля, которые он обычно выбирает и предложить ему три отеля, которые могли бы ему понравиться
--t1-t5 получение единой таблицы человек-отель-комната по всем заказам
WITH t1 AS (SELECT 
                personid, 
                roomid 
            FROM (SELECT * FROM room_order NATURAL JOIN m_order)
            ),
t2 AS  (SELECT 
            personid, 
            roomid 
        FROM (SELECT * 
             FROM tour NATURAL JOIN (SELECT * FROM tour_order NATURAL JOIN m_order)
             )
        ),
t3 AS  (SELECT 
            personid, 
            roomid 
        FROM favourites NATURAL JOIN (SELECT * 
                                      FROM tour_favourites 
                                                    NATURAL JOIN 
                                                    (SELECT 
                                                        tour.roomid, 
                                                        tourid 
                                                    FROM 
                                                    room JOIN tour 
                                                    ON room.roomid=tour.roomid)
                                      )
        ),
t4 AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2 UNION ALL SELECT * FROM t3),
t5 AS (SELECT * 
        FROM t4 
        NATURAL JOIN 
        (SELECT * FROM room NATURAL JOIN hotel)
      ),
--t6 общее цисло заказов для каждого человека
t6 AS (SELECT 
            personid, 
            COUNT(*) AS total_count 
        FROM t5
        GROUP BY personid),
--t7 рассчет средней цены, среднего количества звезд и в скольки процентах случая человек выбирал то или иное удобство
t7 AS (SELECT personid,
                AVG(num_of_stars) AS stars,
                AVG(price) AS price,
                CAST(SUM(swimming_pool::int)AS real)*100/total_count 
                    AS swimming_pool, 
                CAST(SUM(parking::int)AS real)*100/total_count 
                    AS parking, 
                CAST(SUM(gymnasium::int)AS real)*100/total_count 
                    AS gymnasium, 
                CAST(SUM(spa_center::int)AS real)*100/total_count 
                    AS spa_center, 
                CAST(SUM(free_WiFi::int)AS real)*100/total_count 
                    AS free_WiFi, 
                CAST(SUM(private_beach::int)AS real)*100/total_count 
                    AS private_beach, 
                CAST(SUM(restaurant::int)AS real)*100/total_count 
                    AS restaurant, 
                CAST(SUM(golf_field::int)AS real)*100/total_count 
                    AS golf_field , 
                CAST(SUM(bar::int)AS real)*100/total_count 
                    AS bar,
                CAST(SUM(air_condition::int)AS real)*100/total_count 
                    AS air_condition,
                CAST(SUM(chimney::int)AS real)*100/total_count 
                    AS chimney,
                CAST(SUM(balcon::int)AS real)*100/total_count 
                    AS balcon,
                CAST(SUM(kitchen::int)AS real)*100/total_count 
                    AS kitchen,
                CAST(SUM(private_bathroom::int)AS real)*100/total_count 
                    AS private_bathroom,
                CAST(SUM(mini_bar::int)AS real)*100/total_count 
                    AS mini_bar,
                CAST(SUM(tea_coffee::int)AS real)*100/total_count 
                    AS tea_coffee,
                CAST(SUM(tv::int)AS real)*100/total_count 
                    AS tv
        FROM t5 NATURAL JOIN t6 GROUP BY personid, total_count),
pref AS (SELECT
                personid, round(stars, 2) AS stars, round(price,2) 
                    AS price,
                CASE WHEN swimming_pool > 50 THEN true ELSE false END  
                    AS swimming_pool,
                CASE WHEN parking > 50 THEN true ELSE false END  
                    AS parking,
                CASE WHEN gymnasium > 50 THEN true ELSE false END  
                    AS gymnasium,
                CASE WHEN spa_center > 50 THEN true ELSE false END 
                    AS spa_center,
                CASE WHEN free_WiFi > 50 THEN true ELSE false END 
                    AS free_WiFi,
                CASE WHEN private_beach > 50 THEN true ELSE false END 
                    AS private_beach,
                CASE WHEN restaurant > 50 THEN true ELSE false END 
                    S restaurant,
                CASE WHEN golf_field > 50 THEN true ELSE false END 
                    AS golf_field,
                CASE WHEN bar > 50 THEN true ELSE false END 
                    AS bar,
                CASE WHEN air_condition > 50 THEN true ELSE false END 
                    AS air_condition,
                CASE WHEN chimney > 50 THEN true ELSE false END 
                    AS chimney,
                CASE WHEN balcon > 50 THEN true ELSE false END 
                    AS balcon,
                CASE WHEN kitchen > 50 THEN true ELSE false END 
                    AS kitchen,
                CASE WHEN private_bathroom > 50 THEN true ELSE false END 
                    AS private_bathroom,
                CASE WHEN mini_bar > 50 THEN true ELSE false END 
                    AS mini_bar,
                CASE WHEN tea_coffee > 50 THEN true ELSE false END 
                    AS tea_coffee,
                CASE WHEN tv > 50 THEN true ELSE false END 
                    AS tv
            FROM t7),
ranked_hotels AS (SELECT
                    personid, hotel_room.hotelid,
                    ROW_NUMBER() OVER (PARTITION BY pref.personid ORDER BY (
                        (pref.price >= hotel_room.price)::int 
                        +
                        (pref.stars <= hotel_room.num_of_stars)::int 
                        +
                        (pref.swimming_pool = hotel_room.swimming_pool)::int 
                        +
                        (pref.parking = hotel_room.parking)::int 
                        +
                        (pref.gymnasium = hotel_room.gymnasium)::int 
                        +
                        (pref.spa_center = hotel_room.spa_center)::int 
                        +
                        (pref.free_WiFi = hotel_room.free_wifi)::int 
                        +
                        (pref.private_beach = hotel_room.private_beach)::int 
                        +
                        (pref.restaurant = hotel_room.restaurant)::int 
                        +
                        (pref.golf_field = hotel_room.golf_field)::int 
                        +
                        (pref.bar = hotel_room.bar)::int 
                        +
                        (pref.air_condition = hotel_room.air_condition)::int 
                        +
                        (pref.chimney = hotel_room.chimney)::int 
                        +
                        (pref.balcon = hotel_room.balcon)::int
                        +
                        (pref.kitchen = hotel_room.kitchen)::int 
                        +
                        (pref.private_bathroom = 
                            hotel_room.private_bathroom)::int 
                        +
                        (pref.mini_bar = hotel_room.mini_bar)::int 
                        +
                        (pref.tea_coffee = hotel_room.tea_coffee)::int 
                        +
                        (pref.tv = hotel_room.tv)::int) DESC) AS rn
                    FROM pref, (hotel NATURAL JOIN room) AS hotel_room),
recommend AS (SELECT
                  personid,
                  MAX(CASE WHEN rn = 1 THEN hotelId END) AS hotelid_1,
                  MAX(CASE WHEN rn = 2 THEN hotelId END) AS hotelid_2,
                  MAX(CASE WHEN rn = 3 THEN hotelId END) AS hotelid_3
                FROM ranked_hotels
                GROUP BY personid)
SELECT * FROM pref NATURAL JOIN recommend;


--Для каждого аэропорта посчитать сколько самолетов за день вылетает из него  и сколько в него прилетает, а также в какие часы аэропорт наиболее загружен
WITH t1 AS (SELECT 
                townid, 
                nearest_airport_code, 
                extract(hour FROM arrival_time) AS time 
            FROM flight JOIN town ON flight.arrival_airport_townid= town.townid),
t2 AS (SELECT 
            townid, 
            nearest_airport_code, 
            extract(hour FROM departure_time) AS time 
        FROM flight JOIN town ON flight.arrival_airport_townid= town.townid),
t3 AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2),
num_flights AS (SELECT * 
                FROM 
                    (SELECT 
                        townid, 
                        nearest_airport_code AS airport, 
                        COUNT(*) AS num_arrival_flights 
                    FROM t1 
                    GROUP BY townid, nearest_airport_code) 
                    NATURAL JOIN
                    (SELECT 
                        townid, 
                        nearest_airport_code AS airport, 
                        COUNT(*) AS num_dep_flights 
                    FROM t2 
                    GROUP BY townid, nearest_airport_code)
                ),
t4 AS (SELECT 
            townid, 
            nearest_airport_code, time, 
            COUNT(*) AS c  
        FROM t3 
        GROUP BY townid, nearest_airport_code, time 
        ORDER BY townid),
t5 AS (SELECT 
            townid, 
            nearest_airport_code, 
            time, 
            ROW_NUMBER() OVER (PARTITION BY townid ORDER BY time DESC) AS rn 
        FROM t4),
busy_hour AS (SELECT 
                    townid, 
                    nearest_airport_code AS airport, 
                    time AS busy_hour 
              FROM t5 WHERE rn=1)
SELECT * FROM num_flights NATURAL JOIN busy_hour;
