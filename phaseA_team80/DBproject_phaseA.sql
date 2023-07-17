-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 2.1 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- create function
CREATE or REPLACE FUNCTION 2_1_DocumentsClientsAndCreditCards(
	action varchar , doc varchar , fn varchar, ln varchar, s character, 
	birth date, addr varchar, c varchar, coun varchar, ctype varchar, cnum varchar,
	cholder varchar,expdate date
	)
	RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
begin 

	if action = 'insert' THEN
		insert into person("idPerson",fname,lname,sex,dateofbirth,address,city,country) 
		(
		select * from ( select (getmaxid()+1::integer)::integer as "idPerson",fn as fname,ln as lname,s as sex,birth as dateofbirth,
						addr as address,c as city,coun as country) AS results);

		insert into client("idClient",documentclient)
		( select * from(select (getmaxid()::integer)::integer as "idClient",doc as documentclient )As res);

		insert into creditcard( cardtype, number, expiration , holder, "clientID")
		(select * from(select ctype as cardtype, cnum as number, expdate as expiration, 
						   cholder as holder, (getmaxid()::integer)::integer as "clientID" )as r);
	elsif action = 'update' then
		update person
		set fname = fn,
			lname = ln,
			sex = s,
			dateofbirth = birth,
			address = addr,
			city = c,
			country = coun
		where (person."idPerson" = (select cli."idClient" from "client" cli
									where (cli.documentclient = doc)));

		update creditcard
		set cardtype = ctype,
			number = cnum,
			expiration = expdate,
			holder = cholder
		where (creditcard."clientID" = (select cli."idClient" from "client" cli
										where (cli.documentclient = doc)));

	elsif action = 'delete' then		
		delete from person
		where (person."idPerson" = (select cli."idClient" from "client" cli
								where (cli.documentclient = doc)));
		delete from creditcard
		where (creditcard."clientID" = (select cli."idClient" from "client" cli
										where (cli.documentclient = doc)));
		delete from	client
		where (client."idClient" = (select cli."idClient" from "client" cli
									where (cli.documentclient = doc)));
	end if;	 
end;
$BODY$

-- call function
select * from insert_update_2_1('delete' , '82362' , 'alexis', 'boutalis', 'm', 
	'1998-03-25', 'smirni', 'peiraias', 'greece', 'mastercard', '09876547',
	'bvsdbdsb','2024-09-08'
	)



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 2.1 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- create function
CREATE OR REPLACE FUNCTION public."2_2_InsertNewBookings"(
	id_hotel integer,
	start_date date,
	end_date date)
    RETURNS boolean
    LANGUAGE 'plpgsql'

AS $BODY$
declare
	r_client integer;
	r_employee integer;
	newidhotelbooking integer;
	newidroom integer;
	r_bookedforperson integer;
	r_checkin date;
	r_checkout date;
	newrate real;

BEGIN
		--find a random client
		SELECT "idClient" INTO r_client FROM client 
		ORDER BY random() LIMIT 1;

		--make a new hotelbooking
		INSERT INTO hotelbooking("reservationdate","cancellationdate","bookedbyclientID","payed","status")
		VALUES(start_date-20,start_date-10,r_client,false,'confirmed');

		--find a random employee
		SELECT "idEmployee" INTO r_employee
		FROM employee e, person p
		WHERE("idEmployee" = "idPerson" AND "country"=(SELECT country FROM person
													   WHERE "idPerson"="r_client"))
		ORDER BY random() LIMIT 1;

		--get last booking
		SELECT "idhotelbooking" INTO newidhotelbooking FROM hotelbooking
		ORDER BY "idhotelbooking" DESC LIMIT 1;

		--save the manager 
		INSERT INTO manages("idhotelbooking","idEmployee")
		VALUES(newidhotelbooking,r_employee);
		<<make_loop>>
		FOR i in 1..FLOOR(random() * 5 + 1)::int LOOP	
				--make random person
				SELECT "idPerson" INTO "r_bookedforperson" FROM person
				ORDER BY random() LIMIT 1;

				--make random room
				SELECT "idRoom" INTO "newidroom" FROM room
				WHERE "idHotel"=id_hotel
				ORDER BY random() LIMIT 1;
				<<make_loop_2>>
				LOOP
						--make random checkin and random checkout
						SELECT ("start_date" + CAST((random()*(CAST((end_date) AS date) - CAST((start_date) AS date))) AS integer )) INTO r_checkin;
						SELECT ("start_date" + CAST((random()*(CAST((end_date) AS date) - CAST((start_date) AS date))) AS integer )) INTO r_checkout;

						--repeat until to get valid dates
						IF (r_checkin<r_checkout) AND (SELECT COUNT(*) FROM roombooking
													   WHERE "roomID" = newidroom AND((checkin > r_checkin AND checkin < r_checkout) OR
																					  (checkout > r_checkin AND checkout < r_checkout))) = 0 THEN
						--take rate
						SELECT rate INTO newrate FROM room r , roombooking rb
						WHERE ("idHotel"=id_hotel AND r."idRoom" = rb."roomID");
						EXIT make_loop_2;

						END IF;
				END LOOP;	

		INSERT INTO "roombooking"("hotelbookingID", "roomID", "bookedforpersonID", "checkin", "checkout", "rate")
		VALUES ("newidhotelbooking", "newidroom", "r_bookedforperson", "r_checkin", "r_checkout","newrate");
		END LOOP;
		return true;
	
END
$BODY$;





-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.1 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- create function
	CREATE FUNCTION searchOffer_3_1()
	RETURNS TABLE (
	country varchar,
	city varchar
	) AS $$
	BEGIN
	return query
		select distinct h.country, h.city 
		from hotel h 
		inner join roomrate r 
		on h."idHotel" = r."idHotel" 
		where discount >30; 
	END; $$
	LANGUAGE plpgsql;

	-- call function
	select * from searchOffer_3_1()

--code
select distinct h.country, h.city 
from hotel h 
inner join roomrate r 
on h."idHotel" = r."idHotel" 
where discount >30 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.2 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- create function
CREATE OR REPLACE FUNCTION public."3_2_searchHotels"(
	hotelstar character varying,
	prefix character varying)
    RETURNS TABLE(hotelname character varying, stars character varying, roomtype character varying, discount real, rate real) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
RETURN QUERY
WITH help AS(
SELECT DISTINCT h.name, h."idHotel", rrate.roomtype, rrate.discount, rrate.rate
FROM "hotel" h inner join "roomrate" rrate On(h."idHotel" = rrate."idHotel")
WHERE ((h.stars = HotelStar
        AND left(h.name,1) = prefix
        AND (rrate.rate - (rrate.discount/100*rrate.rate)) < 80 )
        AND rrate.roomtype = 'Studio'    )
    ) 

SELECT help.name, HotelStar, help.roomtype, help.discount, help.rate
FROM "hotelfacilities" hf, "facility" f1, "facility" f2, help 
WHERE (hf."namefacility" = f1."nameFacility"
       AND f1."nameFacility"= 'Restaurant'
       AND f2."nameFacility"= 'Breakfast' 
       AND(help."idHotel" = hf."idHotel")   );
    END;
$BODY$;

ALTER FUNCTION public."3_2_searchHotels"(character varying, character varying)
    OWNER TO postgres;

-- call function
select * from public."3_2_searchHotels"('3','S')


--code
WITH help AS(
SELECT DISTINCT h.name, h."idHotel", rrate.roomtype, rrate.discount
FROM "hotel" h inner join "roomrate" rrate On(h."idHotel" = rrate."idHotel")
WHERE ((h.stars = HotelStar
        AND left(h.name,1) = prefix
        AND (rrate.rate - (rrate.discount/100*rrate.rate)) < 80 )
        AND rrate.roomtype = 'Studio'    )
    ) 

SELECT help.name, HotelStar, help.roomtype, help.discount
FROM "hotelfacilities" hf, "facility" f1, "facility" f2, help 
WHERE (hf."namefacility" = f1."nameFacility"
       AND f1."nameFacility"= 'Restaurant'
       AND f2."nameFacility"= 'Breakfast' 
       AND(help."idHotel" = hf."idHotel")   );

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.3 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- create function
	create function maxDiscountHotelandRooms3_3()
	returns table(
	IdHotel integer,
	HotelName varchar,
	RoomType varchar,
	Discount real) as $$
	begin
	return query
		select  h."idHotel", h.name, rrate.roomtype, rrate.discount
		from hotel h, roomrate rrate
		where h."idHotel" = rrate."idHotel" and rrate.discount = (select max(rrate.discount)
																  from roomrate rrate)
		order by rrate.roomtype;
	end; $$
	language plpgsql;

	-- call function
	select * from maxDiscountHotelandRooms3_3()

--code
select  h."idHotel", h.name, rrate.roomtype, rrate.discount
from hotel h, roomrate rrate
where h."idHotel" = rrate."idHotel" and rrate.discount = (select max(rrate.discount)
														  from roomrate rrate)
order by rrate.roomtype
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.4 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--create function
CREATE OR REPLACE FUNCTION public."3_4_hotelBooking"(
	hotelid integer)
    RETURNS TABLE(clientid integer, idhotelbooking integer, hotelname character varying, fname character varying, lname character varying, reservationdate date, bookedby text) 
    LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
	select distinct on(hb."bookedbyclientID") hb."bookedbyclientID",  hb."idhotelbooking", h.name , p."fname" , p."lname" , hb."reservationdate",
		(case when hb."bookedbyclientID" = e."idEmployee" then 'Employee' else 'Client' end) as "BookedBy"
	from person p, hotelbooking hb, employee e, roombooking rb, room r, hotel h
	where (hb."bookedbyclientID" = p."idPerson" and 
		   hb."idhotelbooking" = rb."hotelbookingID" and rb."roomID"=r."idRoom" and r."idHotel"=h."idHotel" and h."idHotel" = hotelid)
	group by h.name, hb."bookedbyclientID", hb."idhotelbooking", p."fname",p."lname",hb."reservationdate","BookedBy"
	order by hb."bookedbyclientID";
END;
$BODY$;

-- call function
select * from public."3_4_hotelBooking"(43)

--code
select distinct on(hb."bookedbyclientID") hb."bookedbyclientID", h.name , hb."idhotelbooking", p."fname" , p."lname" , hb."reservationdate",
	(case when hb."bookedbyclientID" = e."idEmployee" then 'Employee' else 'Client' end) as "BookedBy"
from person p, hotelbooking hb, employee e, roombooking rb, room r, hotel h
where (hb."bookedbyclientID" = p."idPerson" and 
	   hb."idhotelbooking" = rb."hotelbookingID" and rb."roomID"=r."idRoom" and r."idHotel"=h."idHotel" and h."idHotel" = 43)
group by h.name, hb."bookedbyclientID", hb."idhotelbooking", p."fname",p."lname",hb."reservationdate","BookedBy"
order by hb."bookedbyclientID"




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.5 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--create function
CREATE OR REPLACE FUNCTION public."3_5_emptyActivities"(givenid integer)
RETURNS TABLE(acttype activity_type, stime time with time zone, etime time with time zone, "weekDay" numeric) 
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
return query

    select activitytype, starttime, endtime, weekday from activity a
    left join participates p on a."weekday" = p."week_Day"
    where p."week_Day" is null and a."takeplace" = givenid;

END;
$BODY$

-- call function
select * from public."3_5_emptyActivities"(11)


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.6 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--create function
CREATE OR REPLACE FUNCTION public."3_6_calculateAVG"(facIn character varying)
    RETURNS TABLE(facilityName character varying) 
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY
SELECT "nameFacility" FROM facility 
WHERE "type" = 'hotel' and "subtypeOf" = facilityName;

END;
$BODY$;


-- call function
select * from public."3_6_calculateAVG"('Kids Services')


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.7 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- create function
CREATE OR REPLACE FUNCTION public."3_7_printHotelWithFacilities"(facIn character varying, roomIN character varying)
    RETURNS TABLE("Hotel Name" character varying) 
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY
	with hoteltable as(
	select hf."idHotel"
	from hotelfacilities hf, facility f
	where f."nameFacility"=hf."namefacility" and f.type='hotel' and hf."namefacility"=facIn
	),  roomtable as(
		select distinct r."idHotel" 
		from room r, roomfacilities rf, facility f
		where rf."idRoom"=r."idRoom" and f."nameFacility"=rf."nameFacility" 
			and f.type='room' and rf."nameFacility"=roomIN
		), freeroom as(
		select distinct r."idHotel"
		from roombooking rb, room r
		where rb."roomID"=r."idRoom" and (rb."checkin"<current_date or rb."checkin">current_date )
		)

	select h."name"
	from hotel h, roomtable rtable,hoteltable htable, freeroom fr
	where h."idHotel"=htable."idHotel" and htable."idHotel"=rtable."idHotel" and rtable."idHotel"=fr."idHotel";
END;
$BODY$;
	
-- call function
select * from public."3_7_printHotelWithFacilities"('Bar', 'Extra Pillows')

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 3.8 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--create function
CREATE OR REPLACE FUNCTION public."3_8_printHotelsWithEmptyRooms"()
RETURNS table(name varchar, idHotel integer)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY

with help as(
        SELECT DISTINCT r."idHotel", count(r.roomtype) as helpcounter
        FROM room r, roombooking rb
        WHERE rb."roomID"=r."idRoom" AND rb."roomID" in (SELECT rb."roomID" 
                                                 		 FROM roombooking 
                                                 		 WHERE current_date>checkout OR current_date<checkin)
        GROUP BY r."idHotel",r."roomtype"
        ), hotelscounter as(
           		SELECT h."idHotel" , count(help.helpcounter) as sumup
          		FROM hotel h, help
            	WHERE h."idHotel"=help."idHotel"
            	GROUP BY h."idHotel"
            	ORDER BY h."idHotel"
        		), allroomsinhotels as(
						SELECT DISTINCT r."idHotel", count(DISTINCT r.roomtype) as everyroomtype
						FROM room r, roombooking rb
						WHERE rb."roomID"=r."idRoom" 
						GROUP BY r."idHotel")

SELECT h."name", h."idHotel"
FROM hotel h, hotelscounter hc, allroomsinhotels ar
WHERE(h."idHotel"=hc."idHotel" AND hc.sumup = ar.everyroomtype AND hc."idHotel" = ar."idHotel");

END;
$BODY$;

-- call function
select * from public."3_8_printHotelsWithEmptyRooms"()


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 4.1 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- create function
CREATE OR REPLACE FUNCTION public."4_1_countActivitiesPerPerson"(
	idperson int, idhotel integer)
    RETURNS table("NumberOfActivities" bigint)
   
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY

select count(*) 
from participates par, activity act, hotel h, person per
where par."role" = 'participant' and act."weekday"=par."week_Day" and act."takeplace"=h."idHotel" 
	 and par."personID"=per."idPerson" and per."idPerson" = idperson and act."takeplace" = idhotel
group by act."activitytype",per."idPerson";

END;
$BODY$;

-- call function
select * from public."4_1_countActivitiesPerPerson"(8,11)



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 4.2 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--na to kanw na mhn emfanizei thn wra
	
	select AVG((age(current_date,dateofbirth))) as date,r.roomtype
	from person p, roombooking rb, room r
	where p."idPerson"=rb."bookedforpersonID" and rb."roomID" = r."idRoom"
	group by r.roomtype
	order by r.roomtype

	

	--2os tropos
	select CAST(AVG(date_part('year', now())-extract(year from dateofbirth)) AS real),r.roomtype
	from person p, roombooking rb, room r
	where p."idPerson"=rb."bookedforpersonID" and rb."roomID" = r."idRoom"
	group by r.roomtype
	order by r.roomtype

-------------------------------------------------------------------------------------------
-- create function
CREATE OR REPLACE FUNCTION public."4_2_calculateAVG"()
    RETURNS table(avg date, roomtype varchar)
    
	LANGUAGE 'plpgsql'
    
AS $BODY$
BEGIN
RETURN QUERY
	select avg((age(current_date,dateofbirth))) as date,r.roomtype
	from person p, roombooking rb, room r
	where p."idPerson"=rb."bookedforpersonID" and rb."roomID" = r."idRoom"
	group by r.roomtype
	order by r.roomtype;
END;
$BODY$;

-- call function
select * from public."4_2_calculateAVG"()
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 4.3 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- create function
CREATE OR REPLACE FUNCTION public."4_3_cheapestRoomPerCountry"(
	coun varchar)
    RETURNS table(rtype varchar, minrate real, 
				  country varchar, city varchar)
   
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY

WITH help AS(
	SELECT DISTINCT on (rr."roomtype") roomtype, rr."rate" as minrate
	FROM roomrate rr , hotel h
    WHERE(rr."idHotel" = h."idHotel" AND h."country" = coun)
    GROUP BY rr."roomtype",rr."rate"
    ORDER BY rr."roomtype"
)

SELECT DISTINCT rr."roomtype", rr."rate", h."country", h."city"
FROM roomrate rr , hotel h , help
WHERE(rr."idHotel" = h."idHotel" AND h."country" = coun AND help.minrate = rr."rate" AND help.roomtype = rr."roomtype")
GROUP BY rr."roomtype",rr."rate",h."country",h."city";

END;
$BODY$;

-- call function
select * from public."4_3_cheapestRoomPerCountry"('China')

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 4.4 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- create function
CREATE OR REPLACE FUNCTION public."4_4_findHotelsWithIncomeUpToAverage"(
    )
    RETURNS TABLE(hname character varying, cname character varying, hotelIncome real) 
    LANGUAGE 'plpgsql'
    
AS $BODY$
BEGIN
RETURN QUERY

WITH temp AS(
        SELECT  help."city" as ecity, AVG(income) AS averagecityincome
            FROM(
                SELECT h."city" as city, h."name" as name, SUM(hb."totalamount") as income 
                FROM hotel h, hotelbooking hb, roombooking rb , room r
                WHERE (hb."idhotelbooking" = rb."hotelbookingID" AND rb."roomID" = r."idRoom" 
                       AND r."idHotel" = h."idHotel" )
                GROUP BY  h."name" ,h."city"
                ORDER BY h."city"
            )AS help
            GROUP BY  help."city"
            ORDER BY help."city"
        )

    SELECT help2.namecity, help2.namehotel, help2.hotelincome 
    FROM "temp",(
        SELECT SUM(hb."totalamount") as hotelincome, h."city" as namecity, h."name" as namehotel
        FROM  hotel h, hotelbooking hb, room r,roombooking rb
        WHERE(hb."idhotelbooking" = rb."hotelbookingID" AND rb."roomID" = r."idRoom" 
                   AND r."idHotel" = h."idHotel") 
        GROUP BY h."city",h."name"
        )AS help2
    WHERE(help2.hotelincome >= temp.averagecityincome AND help2.namecity = temp.ecity)
    GROUP BY  help2.namecity, help2.namehotel, help2.hotelincome
    ORDER BY help2.namecity;
END;
$BODY$;

-- call function
select * from public."4_4_findHotelsWithIncomeUpToAverage"()


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 4.5 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- create function
CREATE OR REPLACE FUNCTION public."4_5_calculateFullness"(
	givenid integer,
	monthh integer,
	yearr integer)
    RETURNS TABLE(hname character varying, percentage real) 
    LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
--the user give the idHotel, the month and the year in order to find the percentage
SELECT help."name" "Hotel Name", CAST((EXTRACT(epoch FROM(sum(help.sub)/(SELECT count(r."idRoom") as plithos 
														  FROM room r, hotel h 
														  WHERE(r."idHotel" = h."idHotel" and h."idHotel"=givenid
																AND help."name" = h."name"))))/3600)/720*100 AS REAL) AS "Percentage(%)"
FROM(
    SELECT DISTINCT ON(rb."hotelbookingID") rb."hotelbookingID", r."idRoom", h."name", r."idRoom", r."roomtype", rb."checkin", rb."checkout",  h."city",
		(SELECT (age(checkout,checkin)) as sub)
    FROM roombooking rb , room r, hotel h
    WHERE(rb."roomID" = r."idRoom" AND r."idHotel" = h."idHotel" and h."idHotel"=givenid
      AND EXTRACT(MONTH FROM rb."checkin") = monthh AND EXTRACT(YEAR FROM rb."checkin")= yearr)
    GROUP BY r."idRoom", h."name", r."roomtype", rb."checkin", rb."checkout", h."city", rb."hotelbookingID"
)AS help
GROUP BY help."name";

END;
$BODY$;

-- call function
select * from public."4_5_calculateFullness"(107, 6, 2021)


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 5.1 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create function trig5_1()
returns trigger as 
$$
begin
	if(TG_OP ='UPDATE') then
		insert into "transaction"("amount", "idTransaction", "action", "bookingID", "date")
		values (new."totalamount", "getmaxTransID"()+1, 'update',NEW."idhotelbooking", current_date);
		return new;
	end if;
	if(TG_OP ='INSERT') then
		if (new.payed=true) then
			insert into "transaction"("amount", "idTransaction", "action", "bookingID", "date")
			values (new."totalamount", "getmaxTransID"()+1, 'booking',NEW."idhotelbooking", current_date);
			return new;
		else
			return new;
		end if;
	end if;
end;
$$
language 'plpgsql'

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

create trigger trigger_hotelbooking_func5_1
after insert or update OF payed
on public.hotelbooking
for each row execute procedure public.trig5_1();


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 5.2 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----1st trigger
CREATE FUNCTION public.trig5_2_update()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    --Update the cancelation date of hotelbooking
    IF (EXISTS (SELECT "bookedbyclientID" FROM hotelbooking as hb
                JOIN manages as m on OLD.idhotelbooking = m.idhotelbooking AND OLD."bookedbyclientID" = m."idEmployee" 
                JOIN employee as e on m."idEmployee" = e."idEmployee" AND e."role" = 'manager' )=true) THEN
        return NEW;
    ELSE
    RAISE 'Employee has not authority for this action!';
    RETURN OLD;
    END IF;

END;
$BODY$

CREATE TRIGGER trigger_hotelbooking_func5_2_update
    BEFORE UPDATE OF cancellationdate
    ON public.hotelbooking
    FOR EACH ROW EXECUTE PROCEDURE public.trig5_2_update();
	
----2nd trigger
CREATE FUNCTION public.trig5_2_roomBookingChanges()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    cdate date;
BEGIN
IF (TG_OP = 'DELETE') THEN
    SELECT cancellationdate INTO cdate FROM hotelbooking WHERE idhotelbooking IN(
    SELECT "hotelbookingID" FROM roombooking WHERE "roomID" =NEW."roomID" AND "hotelbookingID"=NEW."hotelbookingID");

    IF CURRENT_DATE > cdate THEN
        RAISE 'Cannot DELETE because the cancellation date have past.';
        RETURN NULL;
    ELSE
        RETURN OLD;
    END IF;
END IF;
IF (TG_OP = 'UPDATE') THEN
	SELECT cancellationdate INTO cdate FROM hotelbooking WHERE idhotelbooking IN(
    SELECT "hotelbookingID" FROM roombooking WHERE "roomID" =NEW."roomID" AND "hotelbookingID"=NEW."hotelbookingID");

    IF CURRENT_DATE < cdate THEN
        RETURN NEW;
    ELSE
		IF NEW.checkout<OLD.checkout THEN
            RAISE 'Due to Cancellation Date can not reduce the duration of booking.';
            RETURN OLD;
		ELSIF NEW.checkout>OLD.checkout THEN
            RETURN NEW;
		END IF;
    END IF;
END IF;
END;
$BODY$;


CREATE TRIGGER trig5_2changes
    BEFORE UPDATE OR DELETE 
    ON public.roombooking
    FOR EACH ROW
    EXECUTE PROCEDURE public.trig5_2_roomBookingChanges();



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- ERWTHMA 5.3 -------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create function test()
returns trigger
language 'plpgsql'
as $$
declare
	cancel_date date;
	days integer;
	pay boolean;
begin
	days=new.checkout-new.checkin;
	select cancellationdate into cancel_date from hotelbooking where idhotelbooking in(
	select "hotelbookingID" from roombooking where "roomID" =new."roomID" and "hotelbookingID"=new."hotelbookingID"
);
	select payed into pay from hotelbooking where idhotelbooking=new."hotelbookingID";

	if(TG_OP='INSERT') then
		UPDATE public.hotelbooking
		SET totalamount=new.rate * days
		WHERE "hotelbookingID"=new."hotelbookingID";
		return new;
		
	elsif(TG_OP='UPDATE') then
		days=new.checkout-old.checkout;
		UPDATE public.hotelbooking
		SET totalamount=old.totalamount + new.rate * days
		WHERE "hotelbookingID"=new."hotelbookingID";
		return new;	
		
		if pay='true' then
			if current_date>cancel_date then
				raise 'past cancellation date';
				return old;
			else
				INSERT INTO public.transaction("idTransaction", date, amount, action, "bookingID")
				VALUES (default, current_date, new.rate*days, 'update', new."hotelbookingID");
				return new;
			end if;
		end if;
		
	elsif(TG_OP='DELETE') then
		if pay='true' then
			if current_date>cancel_date then
				raise 'past cancellation date';
				return old;
			else
				INSERT INTO public.transaction("idTransaction", date, amount, action, "bookingID")
				VALUES (default, current_date, old.totalamount, 'cancellation', new."hotelbookingID");
				return new;
			end if;
		end if;
	end if;
end;
$$


CREATE TRIGGER testttt
    BEFORE INSERT OR DELETE OR UPDATE 
    ON public.roombooking
    FOR EACH ROW EXECUTE PROCEDURE public."test"();


delete from transaction
where "idTransaction"=16 and "bookingID"=107



----------------------------------------------------------------------------------------------------------------
-------------------------------------------------VIEW-----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
--create view
CREATE VIEW view6_1 AS(
    With roomfree as(
            SELECT DISTINCT r."idRoom", r."roomtype"
            FROM room r
            JOIN roombooking rb ON r."idRoom" = rb."roomID"
            WHERE rb."roomID" NOT IN (SELECT DISTINCT r."idRoom" 
                                       FROM hotel h, room r, roombooking rb
                                       WHERE(r."idRoom"=rb."roomID" AND
                                       ((rb."checkin" <= current_date AND rb."checkout" >= current_date) 
                                       OR (rb."checkin" < current_date AND rb."checkout" >= current_date ) 
                                       OR (current_date <= rb."checkin" AND current_date >= rb."checkin"))))
            ORDER BY r."idRoom"
        ),
        nextdate as(
            	SELECT r."idRoom" as idr, rb."checkin" as nextdate,hot."idHotel" as hotelidd
            	FROM room r, roombooking rb,hotel hot
            	WHERE r."idRoom"=rb."roomID" AND hot."idHotel" = r."idHotel" AND rb."checkin">=current_date 
                GROUP BY r."idRoom",rb."checkin",hot."idHotel"
                ORDER BY r."idRoom" 
        )
    SELECT DISTINCT h."idHotel", fr."idRoom" ,fr."roomtype", MIN(nd.nextdate)
    FROM nextdate nd, roomfree fr, room r, hotel h
    WHERE(h."idHotel" = nd.hotelidd AND fr."idRoom" = nd.idr)
    GROUP BY h."idHotel",fr."idRoom" ,fr."roomtype"
    ORDER BY h."idHotel"
)

--create function for view
CREATE FUNCTION public."funcFor_view6_1"(givenid integer)
RETURNS TABLE(hotel_id integer,room_id integer, roomtype varchar, nextreserveddate date)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY
	SELECT * FROM view6_1 WHERE "idHotel" = givenid;
END;
$BODY$

--call view
SELECT * FROM public."funcFor_view6_1"(55)




----------------------------------------------------------------------------------------------------------------
-------------------------------------------------VIEW-----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
--create function for view
CREATE OR REPLACE FUNCTION public.funcFor_view6_2(givenid integer)
    RETURNS TABLE(weekdays double precision, hotelid integer, roomid integer, roomtype character varying, 
				  rate real, discount real, documentclient character varying) 
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
RETURN QUERY

	SELECT * FROM view6_2 WHERE hid = givenid;

END;
$BODY$;

--call it
select * from public.funcfor_view6_2(20)

--create view
CREATE VIEW view6_2 AS(
	WITH availables AS (
	         SELECT h."idHotel" AS hid, r."idRoom" AS roomid, r.roomtype AS typeroom,
	            rr.rate AS costs, rr.discount AS disc, hb.idhotelbooking AS idbooking
	         FROM hotel h, room r, roomrate rr, roombooking rb, hotelbooking hb, client c
	         WHERE h."idHotel" = r."idHotel" AND r."idHotel" = rr."idHotel" AND rb."hotelbookingID" = hb.idhotelbooking
			 		AND r."idRoom" = rb."roomID"AND rr.roomtype::text = r.roomtype::text 
			 		AND hb."bookedbyclientID" = c."idClient" AND rb.checkin > (CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 7) 
			 		AND rb.checkin < (CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 13)
	         ORDER BY h."idHotel", r."idRoom"
	         ), gen AS (
				 SELECT date_part('isodow'::text, t.date) - 1::double precision AS weekday
				 FROM generate_series((CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 7)::timestamp with time zone, 
									  (CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 13)::timestamp with time zone, '1 day'::interval) t(date)
	        	)
	SELECT DISTINCT g.weekday, a.hid, a.roomid, a.typeroom, a.costs, a.disc,
	        CASE
	            WHEN (CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 7 + g.weekday::integer) > rb.checkin 
					AND (CURRENT_DATE - date_part('isodow'::text, CURRENT_DATE)::integer + 7 + g.weekday::integer) < rb.checkout THEN c.documentclient
	            ELSE '0'::character varying
	        END AS "case"
	FROM gen g, availables a, hotelbooking hb, roombooking rb, client c
	WHERE rb."hotelbookingID" = hb.idhotelbooking AND hb.idhotelbooking = a.idbooking 
	  		AND hb."bookedbyclientID" = c."idClient" 
	ORDER BY a.roomid
)





-- INSERT INTO public.participates(
-- 	"timetoStart", "timetoEnd", "week_Day", "personID", role)
-- 	VALUES ('10:00:00', '11:00:00', 1, 8, 'participant');

-- INSERT INTO public.participates(
-- 	"timetoStart", "timetoEnd", "week_Day", "personID", role)
-- 	VALUES ('10:00:00', '11:00:00', 1, 23, 'participant');

-- INSERT INTO public.participates(
-- 	"timetoStart", "timetoEnd", "week_Day", "personID", role)
-- 	VALUES ('10:00:00', '11:00:00', 1, 65, 'responsible');

-- INSERT INTO public.participates(
-- 	"timetoStart", "timetoEnd", "week_Day", "personID", role)
-- 	VALUES ('13:00:00', '14:00:00', 2, 67, 'participant');

-- INSERT INTO public.participates(
-- 	"timetoStart", "timetoEnd", "week_Day", "personID", role)
-- 	VALUES ('13:00:00', '14:00:00', 2, 108, 'responsible');



-- INSERT INTO public.activity(
-- 	activitytype, endtime, starttime, takeplace, reserve, weekday)
-- 	VALUES ('tennis', '11:00:00', '10:00:00', 11, 3, 1);
	
-- INSERT INTO public.activity(
-- 	activitytype, endtime, starttime, takeplace, reserve, weekday)
-- 	VALUES ('golf', '14:00:00', '13:00:00', 11, 3, 2);

-- INSERT INTO public.activity(
-- 	activitytype, endtime, starttime, takeplace, reserve, weekday)
-- 	VALUES ('soccer', '21:00:00', '23:00:00', 11, 19, 3);

-- INSERT INTO public.activity(
-- 	activitytype, endtime, starttime, takeplace, reserve, weekday)
-- 	VALUES ('swimming',  '11:30:00','09:00:00', 11, 19, 4);

-- INSERT INTO public.activity(
-- 	activitytype, endtime, starttime, takeplace, reserve, weekday)
-- 	VALUES ('tennis',  '17:30:00','16:00:00', 11, 20, 5);


