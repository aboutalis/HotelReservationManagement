# Hotel Reservation Management System

***This project is implemented as part of the "Baseis Dedomenwn" subject at the Technical University of Crete.***

The purpose of this project is to develop a hotel reservation system that supports hotels in different countries. The system allows hotel employees and customers to make reservations, either through hotel staff or directly via the internet. The system aims to provide a streamlined and efficient booking experience for hotels and their customers.

## ER Diagram

![Screenshot 2023-07-17 160911](https://github.com/aboutalis/HotelReservationManagement/assets/132292767/6e166d39-0047-4cc2-b773-81028996ca30)

The project involves implementing various functionalities using PostgreSQL database management system and JDBC for communication with a Java application.

## Phase A: Implementation of the relational schema and required functionality.

### 1. Relational Schema Implementation

&emsp;1.1. Convert the red-colored portion of the ER model into a relational schema. Implement the new tables in the installed PostgreSQL database.

### 2. Data Management (Construction of PostgreSQL functions)

&emsp;2.1. Insert/delete/update customer and their credit card information.
   - Input parameters: action ('insert'/'update'/'delete'), documentclient, fname, lname, sex, dateofbirth, address, city, country, cardtype, number, holder, expiration.

&emsp;2.2. Insert a number of reservations for room bookings within a specific time period for a hotel (idHotel).
   - The reservation date (reservationdate) and cancellation date (cancelationdate) should be set 20 and 10 days, respectively, before the start of the reservation period.
   - For each reservation, a random selection of one to five hotel rooms, arrival date (checkin), and departure date (checkout) should be made within the defined time period.
   - The reservations should be made by random individuals, and the responsible person for each room should also be randomly selected with the restriction of residing in the same country as the person making the reservation.
   - None of the individuals involved in the reservation should be hotel employees.
   - When creating reservations, overlapping with existing reservations should be avoided (avoid creating reservations for the same room with overlapping dates). (*)

### 3. Data Retrieval (Construction of PostgreSQL functions)

&emsp;3.1. Search for countries/cities that have room offers with a discount of more than 30%.

&emsp;3.2. Search for hotels with a specific number of stars and names starting with specific letters (prefix) that offer Studio rooms priced below 80 euros (including any discounts), provide breakfast, and have a restaurant.

&emsp;3.3. Display hotels and their room types with the highest discounts. The results should be displayed in alphabetical order based on the room type.

&emsp;3.4. Display the reservations of a specific hotel with details (idHotelbooking, clientFname, clientLname, reservationdate, bookedBy). The last column should indicate 'employee' or 'client' depending on whether the reservation was made by an employee or the client themselves, respectively.

&emsp;3.5. Retrieve all activities of a hotel that have been scheduled but have no participation yet.

&emsp;3.6. Display all subtypes of amenities for a first-level facility. A first-level facility is considered an amenity that is not a subtype of any other amenity. ()

&emsp;3.7. Search for hotels that provide specific amenities and have available rooms that also offer specific amenities. Take into account the hierarchy of amenities. ()

&emsp;3.8. Search for hotels that have at least one available room of each room type offered by the hotel. (*)

### 4. Calculations (Construction of PostgreSQL functions)

&emsp;4.1. Find the number of activities in which each customer associated with a hotel has participated or is participating (some customers may not participate in any activity).

&emsp;4.2. Calculate the average age of individuals for whom room reservations of a specific type have been made.

&emsp;4.3. Calculate the cheapest room rate per type in hotels of a specific country and display the city (or cities) where they are located.

&emsp;4.4. Identify hotels that have generated revenues higher than the average revenue per city.

&emsp;4.5. Calculate the occupancy rate per month for a specific hotel and year. The occupancy rate is the percentage of booked rooms out of the total number of rooms.

### 5. Functionality using triggers

&emsp;5.1. When a payment is made for a reservation in a hotel, the transactions table should be appropriately updated, which stores all the financial transactions between hotels and customers.

&emsp;5.2. Changing the cancellation deadline for a reservation is allowed only if the reservation is managed by the hotel manager. Cancellations are not permitted once the cancellation deadline has passed, nor are changes resulting from room removal or a decrease in the length of stay. After the cancellation deadline, only additions of rooms or extensions of the length of stay are allowed.

&emsp;5.3. Each insertion/update/deletion of a room reservation should update the total payment amount (totalamount) based on the room rate (rate). The room rate (rate) in the reservation is automatically updated based on the applicable discount. In the case of changes or deletions in a paid reservation, the cancellation date should be checked. If the cancellation date has passed, a message indicating the inability to execute the change should be displayed, while otherwise, the appropriate refund or additional payment should be recorded in the transactions table. In the case of extending the stay (checkout), the availability of the room should be checked, and the appropriate message for the date until which the specific room is available should be displayed.

### 6. Functionality using views

&emsp;6.1. Create a view that displays the available (for the current date) rooms, along with their types and the date until which they are available, for a specific hotel. ()

&emsp;6.2. Create a view that provides the weekly room reservation plan for a hotel for the week following the current week, sorted according to the room number. Assume that a week starts on Sunday and ends on Saturday. Each row of the view will provide information for one room (room number, current rate, and any discount), and for each day of the week, the customer's identification document number (documentclient) will be reported if there is a reservation for the room, or 0 (zero) if there is no reservation. Only updates that involve the rate, discount, and change of status from unavailable to available or vice versa (with the appropriate update of the customer's identification document number - documentclient) are allowed in the view. To implement the updates in the view, appropriate triggers should be constructed that perform the necessary actions on the underlying tables of the view. (*)

## Phase B: Communication between Java application and the PostgreSQL database management system using JDBC

To implement the application, you will use the Eclipse IDE and the JDBC driver provided with the PostgreSQL server.

The application should offer a menu with options for the following:
- Enter connection details for a specific PostgreSQL database (IP address, database name, username, password).
- Search based on a hotel name prefix and present the results alphabetically with an incrementing number. Select a hotel (by entering an incrementing number) for the following tasks:
  - Search for hotel customers with a surname prefix and display the results (customer code and customer details) alphabetically.
  - Display room reservation details for a specific customer (input: customer code) of the hotel. The result should be sorted by reservation code and include an incrementing number, room code, arrival and departure dates, and the room charge. The user can then enter one of the incrementing numbers and proceed to update the arrival/departure dates and room charge. If the user enters the number zero, they should return to the main menu.
  - Display available rooms (identifier, number, and type) for a specified time period. The result should include an incrementing number. The user can then enter one of the incrementing numbers to select a room and make a reservation for the specific search time period for a customer (input: customer code).

Please refer to the project documentation and code implementation for more details on the implementation and functionalities.

The project folders that have been delivered include the following:
- Phase A: This folder contains the files and resources related to the first phase of the project. It includes the implementation of the relational schema, along with the required functionalities specified in the enunciation document for Phase A.
- Phase B: In this folder, you will find the materials pertaining to the second phase of the project. It encompasses the communication between the Java application and the PostgreSQL database management system using JDBC, as well as the implementation of the functionalities outlined in the enunciation document for Phase B.

Each folder includes the respective enunciation document for the corresponding phase, providing detailed instructions and requirements for the project implementation.

