DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Showtimes;
DROP TABLE IF EXISTS Movies;
DROP TABLE IF EXISTS Theaters;
DROP TABLE IF EXISTS Customers;

CREATE TABLE Customers (
    CustomerID SERIAL PRIMARY KEY,
    CustomerName VARCHAR(100),
    Email VARCHAR(100),
    MembershipType VARCHAR(20)
);

CREATE TABLE Theaters (
    TheaterID SERIAL PRIMARY KEY,
    TheaterName VARCHAR(50),
    Location VARCHAR(100),
    Capacity INT
);

CREATE TABLE Movies (
    MovieID SERIAL PRIMARY KEY,
    Title VARCHAR(150),
    Genre VARCHAR(50),
    DurationMinutes INT
);

CREATE TABLE Showtimes (
    ShowtimeID SERIAL PRIMARY KEY,
    MovieID INT,
    TheaterID INT,
    ShowDate DATE,
    TicketPrice DECIMAL(10, 2),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID),
    FOREIGN KEY (TheaterID) REFERENCES Theaters(TheaterID)
);

CREATE TABLE Bookings (
    BookingID SERIAL PRIMARY KEY,
    CustomerID INT,
    ShowtimeID INT,
    BookingDate DATE,
    Quantity INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ShowtimeID) REFERENCES Showtimes(ShowtimeID)
);

INSERT INTO Customers (CustomerName, Email, MembershipType) VALUES
('John Doe', 'john.doe@cinema.com', 'VIP'),
('Jane Smith', 'jane.smith@cinema.com', 'Standard'),
('Alice Johnson', 'alice.j@cinema.com', 'VIP'),
('Bob Brown', 'bob.b@cinema.com', 'Student'),
('Charlie Black', 'charlie.b@cinema.com', 'Standard'),
('Diana Prince', 'diana.p@cinema.com', 'VIP'),
('Evan Wright', 'evan.w@cinema.com', 'Student');

INSERT INTO Theaters (TheaterName, Location, Capacity) VALUES
('Hall A - IMAX', 'Floor 1', 150),
('Hall B - Dolby Atmos', 'Floor 1', 100),
('Hall C - Standard', 'Floor 2', 80),
('Hall D - VIP Lounge', 'Floor 3', 30);

INSERT INTO Movies (Title, Genre, DurationMinutes) VALUES
('Inception', 'Sci-Fi', 148),
('The Dark Knight', 'Action', 152),
('Interstellar', 'Sci-Fi', 169),
('Parasite', 'Thriller', 132),
('Spirited Away', 'Animation', 125);

INSERT INTO Showtimes (MovieID, TheaterID, ShowDate, TicketPrice) VALUES
(1, 1, '2026-06-15', 18.50),
(1, 4, '2026-06-15', 35.00),
(2, 1, '2026-06-16', 19.00),
(3, 2, '2026-06-16', 16.00),
(4, 3, '2026-06-17', 12.00),
(5, 3, '2026-06-17', 10.00);

INSERT INTO Bookings (CustomerID, ShowtimeID, BookingDate, Quantity) VALUES
(1, 2, '2026-06-14', 2),
(3, 2, '2026-06-13', 3),
(4, 3, '2026-06-14', 2),
(5, 4, '2026-06-14', 1),
(6, 1, '2026-06-13', 4),
(7, 5, '2026-06-12', 2),
(1, 3, '2026-06-14', 2);

WITH BookingDetails AS (
    SELECT
        b.BookingID,
        c.CustomerName,
        c.MembershipType,
        m.Title AS MovieTitle,
        t.TheaterName,
        b.Quantity,
        s.TicketPrice,
        (b.Quantity * s.TicketPrice) AS BookingCost,
        b.BookingDate
    FROM
        Bookings b
    JOIN
        Customers c ON b.CustomerID = c.CustomerID
    JOIN
        Showtimes s ON b.ShowtimeID = s.ShowtimeID
    JOIN
        Movies m ON s.MovieID = m.MovieID
    JOIN
        Theaters t ON s.TheaterID = t.TheaterID
)
SELECT
    'VIP Category' AS CustomerSegment,
    MovieTitle,
    TheaterName,
    SUM(Quantity) AS TotalTicketsSold,
    SUM(BookingCost) AS TotalRevenue
FROM
    BookingDetails
WHERE
    MembershipType = 'VIP'
    AND BookingDate >= '2026-06-10'
GROUP BY
    MovieTitle,
    TheaterName
HAVING
    SUM(BookingCost) >= 30.00

UNION ALL

SELECT
    'Standard/Student Category' AS CustomerSegment,
    MovieTitle,
    TheaterName,
    SUM(Quantity) AS TotalTicketsSold,
    SUM(BookingCost) AS TotalRevenue
FROM
    BookingDetails
WHERE
    MembershipType IN ('Standard', 'Student')
    AND BookingDate >= '2026-06-10'
GROUP BY
    MovieTitle,
    TheaterName
ORDER BY
    TotalRevenue DESC;
