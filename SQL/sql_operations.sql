-- Afisare tara si orasul in care locuieste fiecare user
SELECT U.FIRST_NAME, U.LAST_NAME, CO.NAME AS COUNTRY, CI.NAME AS CITY
FROM Z_USERS U
JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
JOIN Z_CITIES CI ON A.CITY_ID = CI.CITY_ID;

-- Afisare tara si orasul in care locuieste fiecare user care a comandat macar un laptop
SELECT U.FIRST_NAME, U.LAST_NAME, CO.NAME AS COUNTRY, CI.NAME AS CITY
FROM Z_USERS U
JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
JOIN Z_CITIES CI ON A.CITY_ID = CI.CITY_ID
JOIN Z_LAPTOP_ORDERS LO ON U.USER_ID = LO.USER_ID
WHERE U.USER_ID = LO.USER_ID;

--  Selectarea tuturor userilor si a tarii in care locuiesc (daca au) 
-- si selectarea tuturor tarilor indiferent daca au sau nu un user asociat
SELECT U.USER_ID, U.FIRST_NAME, CO.NAME AS COUNTRY_NAME
FROM Z_USERS U
LEFT JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
LEFT JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
UNION
SELECT USER_ID, FIRST_NAME, CO.NAME AS COUNTRY_NAME
FROM Z_COUNTRIES CO
LEFT JOIN Z_ADDRESSES A ON CO.COUNTRY_ID = A.COUNTRY_ID
LEFT JOIN Z_USERS U ON A.ADDRESS_ID = U.ADDRESS_ID;

-- Afisare toti userii si numarul de laptopuri comandate
SELECT 
    U.USER_ID,
    U.FIRST_NAME,
    U.LAST_NAME,
    U.EMAIL,
    SUM(QUANTITY) AS NO_ORDERED_LAPTOPS
FROM Z_USERS U
LEFT JOIN Z_LAPTOP_ORDERS LO ON U.USER_ID = LO.USER_ID
LEFT JOIN Z_ORDER_LINES OL ON LO.LAPTOP_ORDER_ID = OL.LAPTOP_ORDER_ID
GROUP BY U.USER_ID, U.FIRST_NAME, U.LAST_NAME, U.EMAIL
ORDER BY U.USER_ID;

-- Afisare toti userii care nu au dat comanda
SELECT U.USER_ID, U.FIRST_NAME, U.EMAIL, LO.LAPTOP_ORDER_ID
FROM Z_LAPTOP_ORDERS LO
RIGHT JOIN Z_USERS U ON LO.USER_ID = U.USER_ID
WHERE LAPTOP_ORDER_ID IS NULL;

-- Afisare toate laptopurile, de cate ori au fost comandate si cantitatea totala comandata
SELECT 
    L.LAPTOP_ID, 
    LB.NAME, 
    L.LAPTOP_MODEL, 
    COUNT(OL.LAPTOP_ID) AS NO_ORDERS, 
    SUM(OL.QUANTITY) AS ORDERED_QUANTITY
FROM Z_LAPTOPS L
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
LEFT JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
GROUP BY L.LAPTOP_ID, LB.NAME, L.LAPTOP_MODEL
ORDER BY L.LAPTOP_ID ASC;

-- Afisare laptopuri care au fost comandate intre 1 si 3 ori
SELECT 
    L.LAPTOP_ID,
    LB.NAME,
    L.LAPTOP_MODEL,
    COUNT(OL.LAPTOP_ID) AS NO_ORDERS
FROM Z_LAPTOPS L
JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
HAVING COUNT(OL.LAPTOP_ID) BETWEEN 1 AND 3
GROUP BY L.LAPTOP_ID, LB.NAME, L.LAPTOP_MODEL;

-- Afisare tara cu cele mai multe laptopuri comandate
SELECT CO.NAME, SUM(OL.QUANTITY) AS ORDERED_QUANTITY
FROM Z_COUNTRIES CO
JOIN Z_ADDRESSES A ON CO.COUNTRY_ID = A.COUNTRY_ID
JOIN Z_USERS U ON A.ADDRESS_ID = U.ADDRESS_ID
JOIN Z_LAPTOP_ORDERS LO ON U.USER_ID = LO.USER_ID
JOIN Z_ORDER_LINES OL ON LO.LAPTOP_ORDER_ID = OL.LAPTOP_ORDER_ID
GROUP BY CO.NAME
ORDER BY SUM(OL.QUANTITY) DESC
FETCH FIRST 1 ROW ONLY;

-- Afisare toti userii si numarul de laptopuri comandate
SELECT 
    U.USER_ID,
    U.FIRST_NAME,
    U.LAST_NAME,
    U.EMAIL,
    SUM(QUANTITY) AS NO_ORDERED_LAPTOPS
FROM Z_USERS U
LEFT JOIN Z_LAPTOP_ORDERS LO ON U.USER_ID = LO.USER_ID
LEFT JOIN Z_ORDER_LINES OL ON LO.LAPTOP_ORDER_ID = OL.LAPTOP_ORDER_ID
GROUP BY U.USER_ID, U.FIRST_NAME, U.LAST_NAME, U.EMAIL
ORDER BY U.USER_ID;

-- Afisare comenzile de peste 5000 de lei
SELECT LAPTOP_ORDER_ID, SUM(QUANTITY*PRICE)
FROM Z_ORDER_LINES
HAVING SUM(QUANTITY*PRICE) > 5000
GROUP BY LAPTOP_ORDER_ID;

-- Afisare comenzi care au valoarea de 5000 de lei sau 10000 de lei
SELECT LAPTOP_ORDER_ID, SUM(QUANTITY*PRICE) AS ORDER_VALUE
FROM Z_ORDER_LINES
HAVING SUM(QUANTITY*PRICE) IN (5000, 10000)
GROUP BY LAPTOP_ORDER_ID;

--Afisare cel mai mic pret dintre preturile toate laptopurilor
SELECT MIN(PRICE) AS LOWEST_PRICE_FOR_A_LAPTOP
FROM Z_LAPTOPS;

-- Afisare cea mai mare cantitate de laptopuri comandate intr-o singura comanda
SELECT MAX(QUANTITY) AS HIGHEST_QUANITTY_ORDERED
FROM Z_ORDER_LINES;

-- Afisare pretul in medie pentru metoda de livrare
SELECT AVG(PRICE) AS AVERAGE_SHIPPING_PRICE
FROM Z_SHIPPING_METHODS;

-- Afisare dimensiunea medie a displayului pentru fiecare brand de laptopuri
SELECT 
    LB.NAME,
    ROUND(AVG(L.DISPLAY_SIZE), 2) AS AVERAGE_SIZE
FROM Z_LAPTOPS L
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
GROUP BY LB.NAME;

-- Afisare valoarea medie a comenzilor
SELECT TRUNC(AVG(ONE_ORDER_VALUE)) AS AVERAGE_ORDER_VALUE
FROM (SELECT LAPTOP_ORDER_ID, SUM(PRICE*QUANTITY) AS ONE_ORDER_VALUE
             FROM Z_ORDER_LINES
             GROUP BY LAPTOP_ORDER_ID);
             
-- Afisare cate laptopuri contin in numele culorii 'black' si pretul lor mediu
SELECT 
    COUNT(LAPTOP_ID) AS BLACK_LAPTOPS,
    TRUNC(AVG(PRICE), 2) AS AVERGAGE_PRICE
FROM Z_LAPTOPS 
WHERE LOWER(COLOR) LIKE '%black%';

-- Afisare cate comenzi au fost livrate de Fan Courier, valoarea comenzii (cu tot cu pretul
-- metodei de livrare si totalul userilor care au dat aceste comenzi
SELECT 
    COUNT(LO.LAPTOP_ORDER_ID) AS LAPTOPS_FANCOURIER,
    COUNT(LO.USER_ID) AS USERS,
    (SUM(OL.PRICE) +  (COUNT(LO.LAPTOP_ORDER_ID) * SM.PRICE)) AS TOTAL_VALUE
FROM Z_LAPTOP_ORDERS LO
JOIN Z_SHIPPING_METHODS SM ON LO.SHIPPING_METHOD_ID = SM.SHIPPING_METHOD_ID
JOIN Z_ORDER_LINES OL ON LO.LAPTOP_ORDER_ID = OL.LAPTOP_ORDER_ID
WHERE UPPER(SM.NAME) LIKE 'FAN%COURIER'
GROUP BY SM.PRICE;

-- Afisare laptopuri al caror tip de procesor este 'Ryzen'. Pentru fiecare laptop
-- sa se afiseze si pretul, cantitatea in care a fost cumparat si profitul generat.
SELECT 
    L.LAPTOP_ID, 
    LB.NAME AS LAPTOP_BRAND, 
    L.LAPTOP_MODEL, 
    L.CPU_TYPE,
    L.PRICE,
    SUM(OL.QUANTITY) AS ORDERED_QUANTITY,
    SUM(OL.PRICE*OL.QUANTITY) AS PROFIT
FROM Z_LAPTOPS L
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
LEFT JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
WHERE INITCAP(CPU_TYPE) LIKE 'Ryzen%'
GROUP BY    
    L.LAPTOP_ID, 
    LB.NAME, 
    L.LAPTOP_MODEL, 
    L.CPU_TYPE,
    L.PRICE;
    
-- Pentru fiecare laptop sa se afiseze modelul si pretul folosind operatorul de concatenare
SELECT 'Laptopul: ' || LAPTOP_MODEL || ' are pretul de ' || PRICE || 'lei' LAPTOP_PRICE
FROM Z_LAPTOPS;

-- Afisare cate laptopuri comandate au modelul MacBook si profitul adus de acestea
SELECT 
    SUM(OL.QUANTITY) AS TOTAL_QUANTITY_MACBOOK, 
    SUM(OL.PRICE) AS PROFIT
FROM Z_ORDER_LINES OL
JOIN Z_LAPTOPS L ON OL.LAPTOP_ID = L.LAPTOP_ID
WHERE LOWER(SUBSTR(L.LAPTOP_MODEL, 1, 7)) = 'macbook';

-- Afisare user id, numele de familie, numarul de telefon concatenat cu primele 2 litere din
-- numele tarii, lungimea numarului de telefon
SELECT 
    U.USER_ID, 
    U.LAST_NAME, 
    CONCAT(U.PHONE_NUMBER, SUBSTR(CO.NAME,1,2)) AS PHONE_COUNTRY,
    LENGTH(PHONE_NUMBER)
FROM Z_USERS U
JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID;

-- Afisare zilele dintre ultima comanda plasata si ziua de azi
SELECT ROUND(SYSDATE - ORDER_DATE) AS DAYS
FROM Z_LAPTOP_ORDERS 
WHERE ORDER_DATE = (SELECT ORDER_DATE 
                    FROM Z_LAPTOP_ORDERS
                    ORDER BY ORDER_DATE DESC
                    FETCH FIRST 1 ROW ONLY);
                    
-- Afisare idul comenzii, data in care a fost plasata comanda, numarul de luni intre 
-- data de azi si data plasarii comenzii, urmatoarea zi de luni dupa data plasarii, 
-- ultima zi din luna din care face parte data plasarii si data corespunzatoare dupa 10
-- luni de la data plasarii comenzii
SELECT 
    LAPTOP_ORDER_ID,
    ORDER_DATE,
    ROUND(MONTHS_BETWEEN(SYSDATE, ORDER_DATE)) AS MONTHS,
    NEXT_DAY(ORDER_DATE, 'MONDAY') AS NEXT_MONDAY,
    LAST_DAY(ORDER_DATE) AS LAST_DAY_FROM_MONTH,
    ADD_MONTHS(ORDER_DATE, 10) AS DATE_AFTER_10_MONTHS
FROM Z_LAPTOP_ORDERS;

-- Categorisirea laptopurilor in functie de marimea display-ului. 
-- dimensiune display < 15.3, atunci laptopul intrain categoria 'Mic'
-- dimensiune dispkay = 15.3, categorie 'Mediu'
-- dimensiune display > 15.3, categorie 'Mare'
SELECT
    LAPTOP_ID,
    LAPTOP_MODEL,
    DISPLAY_SIZE,
    DECODE(
        SIGN(DISPLAY_SIZE - 15.3),
        -1, 'Small',
         0, 'Medium',
         1, 'Large'
          ) AS DISPLAY_CATEGORY
FROM
    Z_LAPTOPS;
    
-- Categorisirea laptopurilor in functie de dimensiunea memoriei de tip SSD
SELECT
    LAPTOP_ID,
    LAPTOP_MODEL,
    SSD_MEMORY_SIZE,
    CASE
        WHEN SSD_MEMORY_SIZE <= 256 THEN 'Small'
        WHEN SSD_MEMORY_SIZE >= 512 AND SSD_MEMORY_SIZE <= 512 THEN 'Medium'
        WHEN SSD_MEMORY_SIZE >= 1000 THEN 'Large'
        ELSE 'Unknown'
    END AS SSD_MEMORY_CATEGORY
FROM
    Z_LAPTOPS;
    
-- Selectarea userilor care nu au o tara
SELECT U.USER_ID, U.FIRST_NAME, CO.NAME AS COUNTRY_NAME
FROM Z_USERS U
LEFT JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
LEFT JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
MINUS
SELECT USER_ID, FIRST_NAME, CO.NAME AS COUNTRY_NAME
FROM Z_COUNTRIES CO
JOIN Z_ADDRESSES A ON CO.COUNTRY_ID = A.COUNTRY_ID
JOIN Z_USERS U ON A.ADDRESS_ID = U.ADDRESS_ID;

-- Selectarea userilor cu id-ul cuprins intre 1 si 4 si al caror prenume incepe cu litera M
SELECT USER_ID, FIRST_NAME
FROM Z_USERS
WHERE USER_ID BETWEEN 1 AND 4
INTERSECT
SELECT USER_ID, FIRST_NAME
FROM Z_USERS
WHERE FIRST_NAME LIKE 'M%';

-- Selectarea userilor din Romania si a celor din Italia, utilizand UNION
SELECT U.USER_ID, U.FIRST_NAME, U.LAST_NAME, CO.NAME
FROM Z_USERS U
JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
WHERE UPPER(CO.NAME) = 'ROMANIA'
UNION
SELECT U.USER_ID, U.FIRST_NAME, U.LAST_NAME, CO.NAME
FROM Z_USERS U
JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
WHERE UPPER(CO.NAME) = 'ITALIA';

-- Afisare cel mai scump laptop si cantitatea in care a fost cumparat
SELECT  
    L.LAPTOP_ID, 
    LB.NAME AS BRAND_NAME, 
    L.LAPTOP_MODEL, 
    L.PRICE,
    OL.QUANTITY
FROM Z_LAPTOPS L
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
LEFT JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
WHERE L.PRICE = (SELECT MAX(PRICE) FROM Z_LAPTOPS);

-- Afisare laptopul care a generat cele mai multe vanzari
SELECT 
    L.LAPTOP_ID,
    LB.NAME AS BRAND,
    L.LAPTOP_MODEL,
    SUM(OL.QUANTITY*OL.PRICE) AS GENERATED_SALES_VALUE
FROM Z_LAPTOPS L
JOIN Z_LAPTOP_BRANDS LB ON L.LAPTOP_BRAND_ID = LB.LAPTOP_BRAND_ID
JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
WHERE L.LAPTOP_ID =(SELECT LAPTOP_ID
                   FROM Z_ORDER_LINES
                   GROUP BY LAPTOP_ID
                   ORDER BY SUM(QUANTITY*PRICE) DESC
                   FETCH FIRST 1 ROW ONLY)
GROUP BY L.LAPTOP_ID, LB.NAME, L.LAPTOP_MODEL;

-- Afisare toate laptopurile care au un pret mai mare ca pretul mediu per laptop si cantitatea
-- vanduta pentru fiecare
SELECT OL.QUANTITY AS SOLD_QUANTITY, L.*
FROM Z_LAPTOPS L
LEFT JOIN Z_ORDER_LINES OL ON L.LAPTOP_ID = OL.LAPTOP_ID
WHERE L.PRICE > (SELECT AVG(LA.PRICE) FROM Z_LAPTOPS LA);

-- Afisare laptopuri care au un pret mai mare fata de pretul mediu al laptopurilor 
-- cu acelasi brand
SELECT L.LAPTOP_ID, L.LAPTOP_BRAND_ID, L.LAPTOP_MODEL, L.PRICE
FROM Z_LAPTOPS L
WHERE L.PRICE > (SELECT AVG(LB.PRICE)
                 FROM Z_LAPTOPS LB
                 WHERE LB.LAPTOP_BRAND_ID = L.LAPTOP_BRAND_ID);
                 
-- Afisare toti userii si cati bani au dat pe laptopuri, dar si pe livrare
SELECT 
    U.USER_ID, 
    U.FIRST_NAME, 
    U.LAST_NAME,
    (SELECT SUM(OL.PRICE * OL.QUANTITY)
     FROM Z_ORDER_LINES OL
     JOIN Z_LAPTOP_ORDERS LO ON OL.LAPTOP_ORDER_ID = LO.LAPTOP_ORDER_ID
     WHERE LO.USER_ID = U.USER_ID) AS AMOUNT_SPENT_ON_LAPTOPS,
    (SELECT SUM(SM.PRICE)
     FROM Z_SHIPPING_METHODS SM
     JOIN Z_LAPTOP_ORDERS LO ON SM.SHIPPING_METHOD_ID = LO.SHIPPING_METHOD_ID
     WHERE LO.USER_ID = U.USER_ID) AS AMOUNT_SPENT_ON_SHIPPING
FROM Z_USERS U
ORDER BY U.USER_ID ASC;

-- Crearea unei tabele virtuale cu urmatoarele coloane: 
-- id-ul comenzii,id-ul userului, pretul total al laptopurilor din comanda, 
-- pretul metodei de livrare si pretul total
CREATE OR REPLACE VIEW ORDERS_PRICES_DETAILS AS
SELECT  
    OL.LAPTOP_ORDER_ID, 
    LO.USER_ID,
    SUM(OL.PRICE*OL.QUANTITY) AS LAPTOPS_PRICE,
    SM.PRICE AS SHIPPING_PRICE,
    SUM(OL.PRICE*OL.QUANTITY) + SM.PRICE AS TOTAL_PRICE
FROM Z_LAPTOP_ORDERS LO
JOIN Z_ORDER_LINES OL ON LO.LAPTOP_ORDER_ID = OL.LAPTOP_ORDER_ID
JOIN Z_SHIPPING_METHODS SM ON LO.SHIPPING_METHOD_ID = SM.SHIPPING_METHOD_ID
GROUP BY  
    OL.LAPTOP_ORDER_ID, 
    LO.USER_ID,
    SM.PRICE
ORDER BY LAPTOP_ORDER_ID;

-- Crearea unei tabele virtuale cu urmatoarele coloane:
-- id user, nume, prenume, tara si orasul din adresa 
CREATE OR REPLACE VIEW USERS_COUNTRY_CITY AS
SELECT 
    U.USER_ID,
    U.FIRST_NAME,
    U.LAST_NAME,
    CO.NAME AS COUNTRY,
    CI.NAME AS CITY
FROM Z_USERS U
LEFT JOIN Z_ADDRESSES A ON U.ADDRESS_ID = A.ADDRESS_ID
LEFT JOIN Z_COUNTRIES CO ON A.COUNTRY_ID = CO.COUNTRY_ID
LEFT JOIN Z_CITIES CI ON A.CITY_ID = CI.CITY_ID
ORDER BY U.USER_ID ASC;

-- Afisare toti userii pt care suma totala a comenzilor este mai mare de 10000 de lei
SELECT * 
FROM ORDERS_PRICES_DETAILS
WHERE TOTAL_PRICE >= 10000
ORDER BY LAPTOP_ORDER_ID;

-- Stergere tabela virtuala
DROP VIEW ORDERS_PRICES_DETAILS;
DROP VIEW USERS_COUNTRY_CITY;

-- Creare index pentru coloana "price" din tabelul Z_ORDER_LINES
CREATE INDEX IDX_ORDER_LINES_PRICE ON Z_ORDER_LINES(PRICE);

-- Creare index pentru coloana "quantity" din tabelul Z_ORDER_LINES
CREATE INDEX IDX_ORDER_LINES_QUANTITY ON Z_ORDER_LINES(QUANTITY);

-- Vizualizare indecsi
SELECT * FROM USER_INDEXES;

-- Afisare useri si valoarea laptopurilor comandate daca pretul >= 10000 si cantitatea >= 1
SELECT 
    U.USER_ID, 
    U.FIRST_NAME, 
    U.LAST_NAME, 
    SUM(OL.PRICE*OL.QUANTITY)
FROM Z_ORDER_LINES OL
JOIN Z_LAPTOP_ORDERS LO ON OL.LAPTOP_ORDER_ID = LO.LAPTOP_ORDER_ID
JOIN Z_USERS U ON LO.USER_ID = U.USER_ID
WHERE 
    OL.PRICE >= 10000 
    AND 
    OL.QUANTITY >= 1
GROUP BY    
    U.USER_ID, 
    U.FIRST_NAME, 
    U.LAST_NAME;
    
-- Stergere indecsi
DROP INDEX IDX_ORDER_LINES_PRICE;
DROP INDEX IDX_ORDER_LINES_QUANTITY;

-- Creare sinonim privat pentru tabela Z_SHIPPING_METHODS
CREATE OR REPLACE SYNONYM SM FOR Z_SHIPPING_METHODS;

-- Afisare metode de livrare, folodind sinonimul creat anterior
SELECT * FROM SM;

-- Vizualizare sinonime
SELECT * FROM USER_SYNONYMS;

-- Stergere sinonim
DROP SYNONYM SM;

-- Crearea unei secvente pentru asigurarea unicitatii cheii primare din tabela Z_USERS
CREATE SEQUENCE SEQ_NR_USER 
START WITH 100 INCREMENT BY 1
MAXVALUE 1000 NOCYCLE;

-- Sa se insereze 2 useri in tabela Z_USERS, folosind secventa creata anterior
INSERT INTO Z_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES(SEQ_NR_USER.NEXTVAL, 'Celmaitareprenume', 'Numesmecher', 'alabala@gmail.com');

INSERT INTO Z_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES(SEQ_NR_USER.NEXTVAL, 'Celmaiprostprenume', 'Numenaspa', 'portocala@gmail.com');

-- Afisare valoare curenta a secventei create anterior
SELECT SEQ_NR_USER.CURRVAL FROM DUAL;

-- Modificarea pasului de incrementare si valoarea maxima a secventei anterioare
ALTER SEQUENCE SEQ_NR_USER INCREMENT BY 10;
ALTER SEQUENCE SEQ_NR_USER MAXVALUE 5000;

-- Exemplificare ca s-a marit pasul de incrementare
INSERT INTO Z_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL)
VALUES(SEQ_NR_USER.NEXTVAL, 'Celmaiprostprenume', 'Numenaspa', 'portocala@gmail.com');

SELECT SEQ_NR_USER.CURRVAL FROM DUAL;

-- Stergere secventa
DROP SEQUENCE SEQ_NR_USER;