SET SERVEROUTPUT ON

---------------------------------------- PROIECT V1 ----------------------------------------

----------------------- STRUCTURI DE CONTROL + CURSORI IMPLICITI/EXPLICITI -----------------------

-- Se afiseaza populariatea unui laptop in functie de cantitatea comandata.

-- test: laptop_id = 2 (popularitate mare)
-- test: laptop_id = 11 (popularitate scazuta)
-- test: laptop_id = 5 (nepopular)

ACCEPT laptop_id_input PROMPT 'Introduceti idul laptopului: ';
DECLARE
    v_laptop_id z_order_lines.laptop_id%TYPE := &laptop_id_input;
    v_quantity z_order_lines.quantity%TYPE;
    v_laptop_model z_laptops.laptop_model%TYPE;
BEGIN
    SELECT SUM(quantity) total_ordered_quantity
    INTO v_quantity
    FROM Z_ORDER_LINES
    WHERE laptop_id = v_laptop_id;
    
    SELECT laptop_model
    INTO v_laptop_model
    FROM z_laptops
    WHERE laptop_id = v_laptop_id;
    
    IF v_quantity > 3 THEN
        DBMS_OUTPUT.PUT_LINE('Laptopul ' || v_laptop_model || ' este un laptop popular, cantitatea comandata fiind: ' || v_quantity);
    ELSIF v_quantity BETWEEN 1 AND 3 THEN
        DBMS_OUTPUT.PUT_LINE('Laptopul ' || v_laptop_model || ' are o populariatate scazuta, cantitatea comandata fiind: ' || v_quantity);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Laptopul ' || v_laptop_model || ' nu este un laptop popular, acesta nu fiind comandat de loc ');
    END IF;
END;
/

-- Se dubleaza capacitatea memoriei RAM a unui laptop in functie de pretul introdus de la tastatura.
-- Daca exista vreun laptop cu pretul mai mare decat pretul introdus, atunci i se dubleaza memoria RAM.
-- Daca nu exista niciun laptop cu pretul mai mare decat pretul introdus, atunci nu se produc modificari.

-- test: pret = 9000 (se produc modificari)
-- test: pret = 52000 (nu se produc modificari)

ACCEPT price_input PROMPT 'Introduceti pretul: ';
DECLARE
    v_price z_laptops.price%TYPE := &price_input;
BEGIN
    UPDATE z_laptops
    SET ram_memory_size = ram_memory_size * 2
    WHERE price > v_price;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista laptop cu pretul mai mare ca ' || v_price);
    ELSE
        DBMS_OUTPUT.PUT_LINE('S a dublat capacitatea memoriei RAM pentru ' || SQL%ROWCOUNT || ' laptopuri');
    END IF;
END;
/

ROLLBACK;

-- Se afiseaza toate laptopurile si pentru fiecare se precizeaza daca este 
-- mic, mediu sau mare in functie de dimensiunea displayului

DECLARE
    CURSOR iterator IS 
        SELECT *
        FROM z_laptops;
BEGIN
    FOR variable IN iterator LOOP
    DBMS_OUTPUT.PUT_LINE(variable.laptop_id || '. ' || variable.laptop_model);
        CASE 
            WHEN variable.display_size BETWEEN 13 AND 14 THEN
                DBMS_OUTPUT.PUT_LINE('--> ' || variable.display_size || ' => laptop mic');
            WHEN variable.display_size BETWEEN 15 AND 16 THEN
--                DBMS_OUTPUT.PUT_LINE(variable.laptop_id || '. ' || variable.laptop_model);
                DBMS_OUTPUT.PUT_LINE('--> ' || variable.display_size || ' => laptop mediu');
            WHEN variable.display_size >= 16 THEN
--                DBMS_OUTPUT.PUT_LINE(variable.laptop_id || '. ' || variable.laptop_model);
                DBMS_OUTPUT.PUT_LINE('--> ' || variable.display_size || ' => laptop mare');
            ELSE 
--                DBMS_OUTPUT.PUT_LINE(variable.laptop_id || '. ' || variable.laptop_model);
                DBMS_OUTPUT.PUT_LINE('--> ' || variable.display_size || ' => necunoscut');
        END CASE;
    END LOOP;
END;
/

-- Se afiseaza toate brandurile. Pentru fiecare brand se afiseaza toate laptopurile si
-- numarul total de laptopuri vandute

DECLARE
    v_brand_name z_laptop_brands.name%TYPE;
    v_laptop_model z_laptops.laptop_model%TYPE;
    total_quantity_ordered NUMBER;
    
    CURSOR i_brand IS
        SELECT *
        FROM z_laptop_brands;
BEGIN
    FOR var_brand IN i_brand LOOP
        DBMS_OUTPUT.PUT_LINE(var_brand.laptop_brand_id || '. ' || var_brand.name);
        
        FOR var_laptop IN (SELECT * FROM z_laptops WHERE laptop_brand_id = var_brand.laptop_brand_id) LOOP
            DBMS_OUTPUT.PUT_LINE('   ' || var_laptop.laptop_id || '. ' || var_laptop.laptop_model);
        END LOOP;
        
        SELECT SUM(ol.quantity) --total_quantity_ordered
        INTO total_quantity_ordered
        FROM z_order_lines ol
        JOIN z_laptops l ON ol.laptop_id = l.laptop_id
        WHERE laptop_brand_id = var_brand.laptop_brand_id;
        
        DBMS_OUTPUT.PUT_LINE('   *Total quantity ordered from the brand ' || var_brand.name || ' is ' || total_quantity_ordered);
    END LOOP;
END;
/

-- Se afiseaza utilizatorii care stau in Romania

DECLARE
    CURSOR i_country IS
        SELECT * 
        FROM z_countries;
BEGIN
    FOR var_country IN i_country LOOP
        IF(var_country.name LIKE 'Romania') THEN
        DBMS_OUTPUT.PUT_LINE(var_country.name || ':');
            FOR var_user IN (SELECT * 
                            FROM z_users u
                            JOIN z_addresses a ON u.address_id = a.address_id
                            WHERE country_id = var_country.country_id) LOOP
            DBMS_OUTPUT.PUT_LINE('  -> ' || var_user.first_name || ' ' || var_user.last_name);
            END LOOP;
        END IF;
    END LOOP;
END;
/

-- Se afiseaza tara si orasul in care locuieste fiecare user care a comandat cel mai scump laptop comandat

DECLARE
    CURSOR i_user (p z_laptops.laptop_id%TYPE) IS --idul celui mai scump laptop comandat
        SELECT u.user_id, u.first_name, u.last_name, l.laptop_model, l.price
        FROM z_users u
        JOIN z_laptop_orders lo ON u.user_id = lo.user_id
        JOIN z_order_lines ol ON lo.laptop_order_id = ol.laptop_order_id
        JOIN z_laptops l ON ol.laptop_id = l.laptop_id
        WHERE ol.laptop_id = p;
    
    most_expensive_ordered_laptop_id z_laptops.laptop_id%TYPE;
    country_name z_countries.name%TYPE;
    city_name z_cities.name%TYPE;
BEGIN
    SELECT l.laptop_id 
    INTO most_expensive_ordered_laptop_id
    FROM z_laptops l
    JOIN z_order_lines ol ON l.laptop_id = ol.laptop_id
    ORDER BY l.price DESC
    FETCH FIRST 1 ROW ONLY;
    
    SELECT co.name
    INTO country_name
    FROM z_countries co
    JOIN z_addresses a ON co.country_id = a.country_id
    JOIN z_users u ON a.address_id = u.address_id
    JOIN z_laptop_orders lo ON u.user_id  = lo.user_id
    JOIN z_order_lines ol ON lo.laptop_order_id = ol.laptop_order_id
    WHERE ol.laptop_id = most_expensive_ordered_laptop_id;
    
    FOR var_user IN i_user (most_expensive_ordered_laptop_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Userul ' || var_user.first_name || ' ' || var_user.last_name || ' este din ' || country_name || ' si a comandat laptopul ' || var_user.laptop_model || ', ');
        DBMS_OUTPUT.PUT_LINE('acesta fiind cel mai scump laptop comandat. ');
        DBMS_OUTPUT.PUT_LINE('Pretul laptopului este ' || var_user.price);
    END LOOP;
END;
/

---------------------------------------- PROIECT V2 ----------------------------------------

---------------------------- EXCEPTII IMPLICITE / EXPLICITE ----------------------------

-- Se dubleaza pretul metodei de livrare al carui id este introdus de la tastatura

-- test: shipping_method_id = 1, pretul s a modificat in 30
-- test: shipping_method_id = 4, nu exista metoda de livrare cu idul introdus

ACCEPT shipping_method_id_input PROMPT 'Introduceti idul metodei de livrare careia vreti sa ii dublati pretul: ';
DECLARE
    v_shipping_method_id z_shipping_methods.shipping_method_id%TYPE := &shipping_method_id_input;
    v_price z_shipping_methods.price%TYPE;
    v_name z_shipping_methods.name%TYPE;
BEGIN
    SELECT price, name
    INTO v_price, v_name
    FROM z_shipping_methods
    WHERE shipping_method_id = v_shipping_method_id;
    
    v_price := v_price * 2;
    UPDATE z_shipping_methods
    SET price = v_price
    WHERE shipping_method_id = v_shipping_method_id;
    
    SELECT price
    INTO v_price 
    FROM z_shipping_methods
    WHERE shipping_method_id = v_shipping_method_id;

    DBMS_OUTPUT.PUT_LINE('Pretul metodei de livrare '|| v_name || ' s a modificat. Noul pret este: ' || v_price);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista nicio meotda de livrare cu idul introdus');
END;
/

ROLLBACK;

-- Se dubleaza pretul pentru un singur laptop cu capacitatea RAM introdusa de utilizator

-- test: input = 96 (exista un singur laptop cu capacitatea RAM = 96 => se modifica pretul)
-- test: input = 8 (mai multe laptopuri au capacitatea RAM = 8 => TOO_MANY_ROWS)
-- test: input = 100 (nu exista niciun laptop cu capacitatea RAM = 100 => NO_DATA_FOUND)

ACCEPT v_ram_memory_size_input PROMPT 'Introduceti capacitatea RAM: ';
DECLARE
    v_ram_memory_size z_laptops.ram_memory_size%TYPE := &v_ram_memory_size_input;
    v_price z_laptops.price%TYPE;
    v_laptop_id z_laptops.laptop_id%TYPE;
BEGIN
    SELECT laptop_id, price
    INTO v_laptop_id, v_price
    FROM z_laptops
    WHERE ram_memory_size = v_ram_memory_size;
    
    DBMS_OUTPUT.PUT_LINE('Modificare laptop cu id: ' || v_laptop_id);
    DBMS_OUTPUT.PUT_LINE('Pret vechi: ' || v_price);

    UPDATE z_laptops
    SET price = price*2
    WHERE laptop_id = v_laptop_id;
    
    SELECT price
    INTO v_price
    FROM z_laptops
    WHERE ram_memory_size = v_ram_memory_size;
    
    DBMS_OUTPUT.PUT_LINE('Pret nou: ' || v_price);

EXCEPTION
    WHEN NO_DATA_FOUND THEN 
        DBMS_OUTPUT.PUT_LINE('Niciun laptop cu capacitatea RAM introdusa');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Prea multe randuri');
END;
/

ROLLBACK;

-- Se afiseaza userii din tara introdusa de la tastatura

-- test: input = 1 (tara exista si are useri)
-- test: input = 4 (tara exista, dar niciun user nu este din aceasta tara)
-- test: input = 100 (tara nu exista)

ACCEPT country_id_input PROMPT 'Introduceti idul tarii: ';
DECLARE
    v_country_id z_countries.country_id%TYPE := &country_id_input;
    v_country_name z_countries.name%TYPE;
    v_user_count NUMBER := 0;
    
    NO_USERS_IN_COUNTRY EXCEPTION;
BEGIN
    SELECT name INTO v_country_name
    FROM z_countries
    WHERE country_id = v_country_id;
    
    IF v_country_name IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE(v_country_name || ':');
        SELECT COUNT(*)
        INTO v_user_count
        FROM z_users u
        JOIN z_addresses a ON u.address_id = a.address_id
        WHERE a.country_id = v_country_id;

        IF v_user_count <> 0 THEN
            FOR var_user IN (SELECT first_name, last_name
                              FROM z_users u
                              JOIN z_addresses a ON u.address_id = a.address_id
                              WHERE a.country_id = v_country_id) LOOP
                DBMS_OUTPUT.PUT_LINE('  -> ' || var_user.first_name || ' ' || var_user.last_name);
            END LOOP;
        ELSE
            RAISE NO_USERS_IN_COUNTRY;
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista nicio tara cu idul introdus');
    WHEN NO_USERS_IN_COUNTRY THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista useri din tara introdusa');
END;
/

-- Inserarea unui user in tabela z_users cu datele introduse de la tastatura

-- test: Se face inserarea cu succes
--       -> user_id_input = 100
--       -> first_name_input = a
--       -> last_name_input = a
--       -> email_input = a
-- test: Se apeleaza exceptia ID_GRESIT: Idul trebuie sa contina doar numere
--       -> user_id_input = abc
--       -> first_name_input = a
--       -> last_name_input = a
--       -> email_input = a
-- test: Se apeleaza exceptia ID_NU_E_UNIC: Idul introdus nu este unic
--       -> user_id_input = 1
--       -> first_name_input = a
--       -> last_name_input = a
--       -> email_input = a

ACCEPT user_id_input PROMPT 'user id: ';
ACCEPT first_name_input PROMPT 'first name: ';
ACCEPT last_name_input PROMPT 'last name: ';
ACCEPT email_input PROMPT 'email : ';
DECLARE
    v_user_id z_users.user_id%TYPE;
    v_first_name z_users.first_name%TYPE := LOWER('&first_name_input');
    v_last_name z_users.last_name%TYPE := LOWER('&last_name_input');
    v_email z_users.email%TYPE := LOWER('&email_input');

    ID_GRESIT EXCEPTION;
    PRAGMA EXCEPTION_INIT(ID_GRESIT, -06502);
BEGIN
    v_user_id := TO_NUMBER('&user_id_input');

    DBMS_OUTPUT.PUT_LINE(v_user_id || ' - ' || v_first_name || ' - ' || v_last_name || ' - ' || v_email);
    
    INSERT INTO z_users(user_id, first_name, last_name, email)
    VALUES(v_user_id, v_first_name, v_last_name, v_email);
    
    DBMS_OUTPUT.PUT_LINE('User inserat cu succes!');
EXCEPTION
    WHEN ID_GRESIT THEN
        DBMS_OUTPUT.PUT_LINE('Userul nu a putut fi introdus. Idul trebuie sa contina doar numere');
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Userul nu a putut fi introdus. Idul introdus nu este unic');
END;
/

ROLLBACK;

-- Stergerea unei adrese pe baza idului introdus de la tastatura. Daca adresa este atribuita
-- macar unui user, atunci nu poate fi stearsa.

-- test: address_id_input = 1 (Adresa nu se sterge)
-- test: 
--      -> Rulati comanda de INSERT a unei adrese noi (este dupa blocul pl/sql)  
--      -> address_id_input = 100 (Adresa se sterge)

ACCEPT address_id_input PROMPT 'Introduceti idul adresei pe care vreti sa o stergeti:';
DECLARE
    v_address_id Z_addresses.address_id%TYPE := &address_id_input;
    
    ADRESA_ESTE_FOLOSITA EXCEPTION;
    PRAGMA EXCEPTION_INIT(ADRESA_ESTE_FOLOSITA, -2292);
BEGIN
    DELETE FROM z_addresses
    WHERE address_id = v_address_id;
    
    DBMS_OUTPUT.PUT_LINE('Adresa stearsa cu succes!');
EXCEPTION
    WHEN ADRESA_ESTE_FOLOSITA THEN
        DBMS_OUTPUT.PUT_LINE('Adresa nu poate fi stearsa deoarece este atribuita unuia sau mai multor useri.');
        DBMS_OUTPUT.PUT_LINE('Stergeti userii cu address_id = ' || v_address_id || ', dupa care stergeti adresa.');
END;
/

INSERT INTO Z_ADDRESSES (address_id, country_id, city_id)
VALUES (100, 1, 1);

ROLLBACK;

---------------------------------------- PROIECT V3 ----------------------------------------

----------------------------------- PROCEDURI + FUNCTII ------------------------------------

--IDEI:
--1. Y procedura: adaug o noua coloana, for update -> clientii care au cumparat x laptopuri primesc cupon reducere
--2. Y procedura?: pun intr o tabela indexata clientii care ... 
--3. procedura: parametru: id laptop, returnare: detalii laptop
--4. Y peocedura: parametru: firma + dimensiune dorita, returnare: laptopuri corespunzatoare
--5. Y functie: parametru: id client, returnare: cate laptopuri a cumparat
--6. procedura: parametru: id comanda, returnare: detalii comanda: client, data, pret etc
--7. procedura top 3 clienti, afisare clienti cu cele mai multe comenzi
--8. -> Y functie: returneaza de cate ori a fost comandat un laptop
--   -> procedura: foloseste functia de mai sus ca sa faca top 3 laptopuri
--9. Y functie: adauga un nou laptop in tabel
--10. Y procedure: parametru: brand id, afisare: toate laptopurile din baza de date cu brandul asta si 
--                 de cate ori au fost comandate

-- Creez coloana 'discount' in tabela z_users.
-- Procedura atribuie discount clientilor care au cumparat 3 sau mai multe laptopuri. 
-- Pentru calcularea numarului de laptopuri comandate, am facut o functie. 
-- Functia creata o folosesc in procedura pentru acordarea discountului.

ALTER TABLE z_users
ADD discount NUMBER DEFAULT 0;

/
CREATE OR REPLACE FUNCTION get_no_ordered_laptops (p_user_id z_users.user_id%TYPE)
RETURN NUMBER
IS
    no_ordered_laptops NUMBER;
BEGIN
    SELECT SUM(ol.quantity)
    INTO no_ordered_laptops
    FROM z_users u
    JOIN z_laptop_orders lo ON u.user_id = lo.user_id
    JOIN z_order_lines ol ON lo.laptop_order_id = ol.laptop_order_id
    WHERE u.user_id = p_user_id;
    
    RETURN no_ordered_laptops;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;    
END;
/

/
CREATE OR REPLACE PROCEDURE give_discount
IS
    CURSOR c IS
        SELECT *
        FROM z_users
        FOR UPDATE OF discount;
       
    var c%ROWTYPE;
BEGIN
    OPEN c;
    LOOP
        FETCH c INTO var;
        EXIT WHEN c%NOTFOUND;
        
        IF get_no_ordered_laptops(var.user_id) >= 3 THEN
            UPDATE z_users
            SET discount = 1000
            WHERE CURRENT OF c;
        END IF;
    END LOOP;
END;
/

EXECUTE give_discount;

-- Procedura care creeaza si afiseaza o tabela indexata cu userii care au cumparat laptopuri cu brandul 
-- dat ca parametru.

/
CREATE OR REPLACE PROCEDURE create_table_users_laptop_brand (p_brand_name z_laptop_brands.name%TYPE)
IS
    TYPE rec IS RECORD
    (
        user_id z_users.user_id%TYPE,
        user_full_name VARCHAR2(100)
    );
    TYPE table_users_laptop_brand IS TABLE OF rec;
    t table_users_laptop_brand;
BEGIN
    SELECT u.user_id, u.first_name ||' '|| u.last_name
    BULK COLLECT INTO t
    FROM z_users u
    JOIN z_laptop_orders lo ON u.user_id = lo.user_id
    JOIN z_order_lines ol ON lo.laptop_order_id = ol.laptop_order_id
    JOIN z_laptops l ON ol.laptop_id = l.laptop_id
    JOIN z_laptop_brands lb ON l.laptop_brand_id = lb.laptop_brand_id
    WHERE UPPER(lb.name) LIKE UPPER(p_brand_name);
    
    DBMS_OUTPUT.PUT_LINE('***********'||' Utilizatori care au comandat de la: '||UPPER(p_brand_name)||' ***********');
    FOR i IN 1.. t.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(t(i).user_id ||' '|| t(i).user_full_name);
    END LOOP;
END;
/

EXECUTE create_table_users_laptop_brand('apple');

-- Functie care insereaza un laptop in tabela z_laptops. Datele ce trebuie inserate se dau ca parametrii si sunt
-- verificate. Idul laptopului este calculat automat in interiorul functiei.

/
CREATE OR REPLACE FUNCTION insert_new_laptop (
    p_laptop_brand_id z_laptops.laptop_brand_id%TYPE,
    p_laptop_model z_laptops.laptop_model%TYPE, 
    p_cpu_brand_id z_laptops.cpu_brand_id%TYPE,
    p_price z_laptops.price%TYPE
)
RETURN VARCHAR2
IS
    CURSOR c_laptop_brand_ids IS
        SELECT laptop_brand_id
        FROM z_laptop_brands;

    CURSOR c_cpu_brand_ids IS
        SELECT cpu_brand_id
        FROM z_cpu_brands;
    
    correct_data BOOLEAN := FALSE;
    p_laptop_id z_laptops.laptop_id%TYPE;
    message VARCHAR2(100);
    
    WRONG_BRAND EXCEPTION;
    WRONG_CPU EXCEPTION;
BEGIN
    FOR i IN c_laptop_brand_ids LOOP
        IF p_laptop_brand_id = i.laptop_brand_id THEN
            correct_data := TRUE;
        END IF;
    END LOOP;
    
    IF correct_data = FALSE THEN
        RAISE WRONG_BRAND;
    END IF;
    correct_data := FALSE;
    
    FOR i IN c_cpu_brand_ids LOOP
        IF p_cpu_brand_id = i.cpu_brand_id THEN
            correct_data := TRUE;
        END IF;
    END LOOP;
    
    IF correct_data = FALSE THEN
        RAISE WRONG_CPU;
    END IF;
    
    SELECT MAX(laptop_id) + 1
    INTO p_laptop_id
    FROM z_laptops;
    
    INSERT INTO z_laptops (laptop_id, laptop_brand_id, laptop_model, cpu_brand_id, price)
    VALUES(p_laptop_id, p_laptop_brand_id, p_laptop_model, p_cpu_brand_id, p_price);
    
    message := 'Laptopul a fost inserat cu succes!';
    
    RETURN message;
EXCEPTION
    WHEN WRONG_BRAND THEN
        message := 'Error: Idul brandului este gresit';
        RETURN message;
    
    WHEN WRONG_CPU THEN
        message := 'Error: Idul CPU este gresit';
        RETURN message;
END;
/

/
BEGIN
    -- Test 1: date corecte
--    DBMS_OUTPUT.PUT_LINE(insert_new_laptop(2, 'Laptop Gaming Lenovo Legion 7', 3, 11067));
    -- Test 2: brand id gresit 
--    DBMS_OUTPUT.PUT_LINE(insert_new_laptop(0, 'Laptop Gaming Lenovo Legion 7', 3, 11067));
    -- Test 3: cpu id gresit
    DBMS_OUTPUT.PUT_LINE(insert_new_laptop(3, 'Laptop Gaming Lenovo Legion 7', 100, 11067));
END;
/

rollback;

-- Functie care returneaza cantitatea comandata a unui laptop. Idul laptopului este dat ca parametru
-- Test: laptop_id_input = 1 (laptopul exista si a fost comandat)
-- Test: laptop_id_input = 100 (laptopul nu exista)

/
CREATE OR REPLACE FUNCTION get_ordered_quantity (p_laptop_id z_laptops.laptop_id%TYPE)
RETURN NUMBER
IS
    ordered_quantity NUMBER;
BEGIN
    SELECT SUM(quantity)
    INTO ordered_quantity
    FROM z_order_lines ol
    WHERE laptop_id = p_laptop_id;
    
    RETURN ordered_quantity;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

/
ACCEPT laptop_id_input PROMPT 'laptop id:'
DECLARE
    v_laptop_id z_laptops.laptop_id%TYPE := &laptop_id_input;
BEGIN
    IF get_ordered_quantity(v_laptop_id) IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Laptopul introdus nu exista sau nu a fost comandat');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Cantitate comandata ' || get_ordered_quantity(v_laptop_id));        
    END IF;
END;
/

-- Procedura: primeste ca parametru numele unui brand si afiseaza toate laptopurile din acest brand, cantitatea
-- comandata si valoarea totala adusa.

/
CREATE OR REPLACE PROCEDURE laptops_details (p_brand_name z_laptop_brands.name%TYPE)
IS
    CURSOR c IS 
        SELECT  
            l.laptop_id,
            l.laptop_model,
            SUM(ol.quantity) as ordered_quantity,
            SUM(ol.price) as total_value
        FROM z_laptops l
        JOIN z_order_lines ol ON l.laptop_id = ol.laptop_id
        JOIN z_laptop_brands lb ON l.laptop_brand_id = lb.laptop_brand_id
        WHERE UPPER(lb.name) LIKE UPPER(p_brand_name)
        GROUP BY l.laptop_id, l.laptop_model;
    
    check_brand_name z_laptop_brands.name%TYPE;
BEGIN
    SELECT name
    INTO check_brand_name
    FROM z_laptop_brands
    WHERE UPPER(name) LIKE UPPER(p_brand_name);
    
    DBMS_OUTPUT.PUT_LINE('******** '||UPPER(p_brand_name) || ' laptops ********');
    DBMS_OUTPUT.PUT_LINE('laptop id - laptop model - ordered quantity - total value');
    FOR var IN c LOOP
        DBMS_OUTPUT.PUT_LINE(var.laptop_id ||' - '|| var.laptop_model ||' - '|| var.ordered_quantity ||' - '|| var.total_value);
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Nume brand gresit!');
END;
/

EXECUTE laptops_details('lenovo');

-- Procedura care primeste ca parametrii filtrele: firma si dimensiune
-- si afiseaza laptopurile corespunzatoare

/
CREATE OR REPLACE PROCEDURE brand_and_size_filter (p_brand_name z_laptop_brands.name%TYPE, p_display_size z_laptops.display_size%TYPE)
IS    
    CURSOR c IS
        SELECT 
            l.laptop_id,
            l.laptop_model,
            lb.name,
            l.display_size,
            l.color,
            l.price
        FROM z_laptops l
        JOIN z_laptop_brands lb ON l.laptop_brand_id = lb.laptop_brand_id
        WHERE 
            UPPER(lb.name) LIKE UPPER(p_brand_name)
            AND
            l.display_size = p_display_size;
    
    check_filters NUMBER;
    
    NO_DATA_FOUND_FOR_SPECIFIED_FILTERS EXCEPTION;
BEGIN
    SELECT COUNT(l.laptop_id)
    INTO check_filters
    FROM z_laptop_brands lb
    JOIN z_laptops l ON lb.laptop_brand_id = l.laptop_brand_id
    WHERE 
        UPPER(lb.name) LIKE UPPER(p_brand_name)
        AND 
        l.display_size = p_display_size;

    IF check_filters = 0 THEN
        RAISE NO_DATA_FOUND_FOR_SPECIFIED_FILTERS;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(UPPER(p_brand_name) || ' laptopuri cu dimensiunea displayului ' || p_display_size || ' inci :');
    FOR var IN c LOOP
        DBMS_OUTPUT.PUT_LINE(
            var.laptop_id || ' - ' ||
            var.laptop_model || ' - ' ||
            var.name || ' - ' ||
            var.display_size || ' - ' ||
            var.color || ' - ' ||
            var.price
        );
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND_FOR_SPECIFIED_FILTERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: Nu s a gasit niciun laptop cu filtrele introduse!');
END;
/

EXECUTE brand_and_size_filter('apple', 15.3);
EXECUTE brand_and_size_filter('lenovo', 14);
EXECUTE brand_and_size_filter('sjdb', 15.3);
EXECUTE brand_and_size_filter('apple', 100);

---------------------------------------- PROIECT V4 ----------------------------------------

---------------------------------------- TRIGGERI ----------------------------------------

-- idei:
-- 1. Y in z_laptops fac o coloana noua 'quantity_sold'. trigger: cand se comanda un laptop, sa se schimbe si
--    valoarea din 'quantity_sold'
-- 2. la inserarea unui user sa se apeleze triggerul si sa seteze idul userului
-- 3. in z_users adaug coloana 'discount'. daca un user comanda mai mult de 5 laptopuri, se declanseaza triggerul
--    si ii acorda un discount. daca depaseste 10 laptopuri, alt discount.
-- 4. adaug o noua coloana in z_users 'total_amount_spent'. si triggerul creste valoarea asta la comanda data.
-- 5. Y in _shipping_methods modific numele unei metode de livrare => se modifica numele ei pt comenzile corespunzatoare
-- 6. Y atunci cand inserez in z_order_lines sa se calculeze automat pretul = quantity * pret laptop

-- In z_users adaug coloana 'bought_quantity' in care tin cont de numarul de laptopuri cumparate de fiecare user.
-- Calculez numarul de laptopuri comandate pana acum de fiecare user si il pun in coloana creata.
-- Trigger: atunci cand un user cumpara o anumita cantitate de laptopuri, se modifica valoarea coloanei 'bought_quantity'.

ALTER TABLE z_users
ADD bought_quantity NUMBER DEFAULT 0;

/
DECLARE
    CURSOR c IS 
        SELECT u.user_id, SUM(ol.quantity) AS bought_quantity_per_user
        FROM z_order_lines ol
        JOIN z_laptop_orders lo ON ol.laptop_order_id = lo.laptop_order_id
        JOIN z_users u ON lo.user_id = u.user_id
        GROUP BY u.user_id;
BEGIN
    FOR var IN c LOOP
        UPDATE z_users
        SET bought_quantity = var.bought_quantity_per_user
        WHERE user_id = var.user_id;
    END LOOP;
END;
/

/
CREATE OR REPLACE TRIGGER trg_update_bought_quantity
BEFORE INSERT ON z_order_lines
FOR EACH ROW
DECLARE
    v_user_id z_users.user_id%TYPE;
BEGIN 
    SELECT user_id
    INTO v_user_id
    FROM z_laptop_orders
    WHERE laptop_order_id = :NEW.laptop_order_id;

    UPDATE z_users
    SET bought_quantity = bought_quantity + :NEW.quantity
    WHERE user_id= v_user_id;
END;
/

-- Comanda declansatoare

INSERT INTO z_order_lines (laptop_order_id, laptop_id, quantity, price)
VALUES (1, 1, 2, 20000);

rollback;


-- In z_users adaug coloana 'discount' si o initializez cu 0. 
-- Trigger: Atunci cand un user are comandate mai mult de 5 laptopuri, i se acorda un discount in valoare de 1000 
--          de lei, iar daca userul a comandat mai mult de 10 laptopuri, atunci discontul este 2000 de lei.

ALTER TABLE z_users
ADD discount NUMBER DEFAULT 0;

/
CREATE OR REPLACE TRIGGER trg_give_discount
BEFORE INSERT ON z_order_lines
FOR EACH ROW
DECLARE
    v_user_id z_users.user_id%TYPE;
    total_bought_quantity NUMBER;
BEGIN
    SELECT user_id
    INTO v_user_id
    FROM z_laptop_orders
    WHERE laptop_order_id = :NEW.laptop_order_id;
    
    SELECT SUM(quantity) + :NEW.quantity
    INTO total_bought_quantity
    FROM z_order_lines
    WHERE laptop_order_id IN (
        SELECT laptop_order_id
        FROM z_laptop_orders
        WHERE user_id = v_user_id
    );
    
    IF total_bought_quantity >= 10 THEN
        UPDATE z_users
        SET discount = 2000
        WHERE user_id = v_user_id;
    ELSIF total_bought_quantity >= 5 THEN
        UPDATE z_users
        SET discount = 1000
        WHERE user_id = v_user_id;
    END IF;
END;
/

-- Test pentru discount = 1000

INSERT INTO z_laptop_orders (laptop_order_id, user_id, order_date, shipping_method_id, status)
VALUES (11, 1, SYSDATE, 1, 'Comanda este in procesare.');

--Comanda declansatoare
INSERT INTO z_order_lines (laptop_order_id, laptop_id, quantity, price)
VALUES (11, 1, 3, 30000);

--Test pentru discount = 2000

INSERT INTO z_laptop_orders (laptop_order_id, user_id, order_date, shipping_method_id, status)
VALUES (12, 3, SYSDATE, 1, 'Comanda este in procesare.');

--Comanda declansatoare
INSERT INTO z_order_lines (laptop_order_id, laptop_id, quantity, price)
VALUES (12, 14, 10, 12000);

rollback;

-- In tabela z_laptops adaug coloana 'quantity_sold'. Pentru fiecare laptop initializez coloana cu cantitatea 
-- vanduta pana in acest moment.
-- Trigger: Cand se comanda un laptop, se schimba valoarea coloanei quantity_sold, adaugand cantitatea comandata

ALTER TABLE z_laptops
ADD quantity_sold NUMBER;

/
DECLARE
    CURSOR c IS 
        SELECT l.laptop_id, SUM(ol.quantity) AS quantity_sold_per_laptop
        FROM z_order_lines ol
        RIGHT JOIN z_laptops l ON ol.laptop_id = l.laptop_id
        GROUP BY l.laptop_id;
BEGIN
    FOR var IN c LOOP
        DBMS_OUTPUT.PUT_LINE(var.laptop_id ||' - '||var.quantity_sold_per_laptop);
        IF var.quantity_sold_per_laptop IS NULL THEN
            UPDATE z_laptops
            SET quantity_sold = 0
            WHERE  laptop_id = var.laptop_id;
        ELSE
            UPDATE z_laptops
            SET quantity_sold = var.quantity_sold_per_laptop
            WHERE laptop_id = var.laptop_id;
        END IF;
    END LOOP;
END;
/

/
CREATE OR REPLACE TRIGGER trg_raise_quantity_sold
AFTER INSERT ON z_order_lines
FOR EACH ROW
DECLARE
BEGIN
    UPDATE z_laptops
    SET quantity_sold = quantity_sold + :NEW.quantity
    WHERE laptop_id = :NEW.laptop_id;
END;
/

INSERT INTO z_laptop_orders (laptop_order_id, user_id, order_date, shipping_method_id, status)
VALUES (13, 2, SYSDATE, 1, 'Coamnda este in procesare.');

-- Coamanda declansatoare

INSERT INTO z_order_lines (laptop_order_id, laptop_id, quantity, price)
VALUES (13, 1, 3, 30000);

-- Trigger: Atunci cand inserez in z_order_lines, pretul sa fie calculat automat, fiind egal cu pretul laptopului
--          * cantitatea.

/
CREATE OR REPLACE TRIGGER trg_calculate_price
BEFORE INSERT ON z_order_lines
FOR EACH ROW
DECLARE
    laptop_price z_laptops.price%TYPE;
BEGIN
    SELECT price
    INTO laptop_price
    FROM z_laptops
    WHERE laptop_id = :NEW.laptop_id;
    
    :NEW.price := :NEW.quantity * laptop_price;
END;
/

-- Comanda declansatoare

INSERT INTO z_order_lines (laptop_order_id, laptop_id, quantity, price)
VALUES (1, 4, 2, 1); -- aici pretul ar trebui sa se calculeze automat si sa fie 2 * 5000 = 10000 lei

rollback;

-- Trigger: daca schimb idul unei metode de livrare din tabela z_shipping_methods, se schimba idul metodei de
--          livrare si in z_laptop_orders

/
CREATE OR REPLACE TRIGGER trg_change_shipping_method_name_everywhere
AFTER UPDATE OF shipping_method_id ON z_shipping_methods
FOR EACH ROW
DECLARE
BEGIN
    UPDATE z_laptop_orders
    SET shipping_method_id = :NEW.shipping_method_id
    WHERE shipping_method_id = :OLD.shipping_method_id;
END;
/

-- Comanda declansatoare

UPDATE z_shipping_methods
SET shipping_method_id = 9
WHERE shipping_method_id = 1;

rollback;

---------------------------------------- PACHETE ----------------------------------------

--Idei:
-- 1. pachet user_management : 
--    - functie check_user_id, parametru user_id verifica daca exista un anumit user
--    - procedura user_details, parametrul: user_id, afiseaza nume, prenume, adresa, 
--      lista cu laptopurile comandate. Se foloseste de functia check_user_id
-- 2. pachet order_management:
--    - functie order_total_price, parametru order_id, returneaza pretul total al unei comenzi
--    - procedura user_orders, parametru user_id, afiseaza detalii despre toate comenzile unui 
--      user. Se foloseste de functia de mai order_total_price.
-- 3. pachet laptop_management:
--    - procedura laptop_details, parametru laptop_id, afiseaza detalii laptop
--    - procedura laptop_users, parametru laptop_id, afiseaza userii care au cumparat laptopul
--      dat ca parametru

-- 1. Pachet user_management care contine: 
--    - Functia check_user_id. Primeste ca parametru user_id si verifica daca exista un anumit user, 
--      returnand TRUE sau FALSE
--    - Procedura user_details. Primeste ca parametru user_id si afiseaza detalii despre user: nume,
--      tara, orasul si laptopurile comandate de acesta (daca exista). Aceasta procedura foloseste
--      functia check_user_id pentru a verifica existenta userului.

-- test: input = 1 (userul exista si a comandat laptopuri)
-- test: input = 4 (userul exista, dar nu are comenzi)
-- test: input = 100 (userul nu exista)

/
CREATE OR REPLACE PACKAGE user_management IS
    FUNCTION check_user_id (p_user_id z_users.user_id%TYPE) RETURN BOOLEAN;
    PROCEDURE user_details (p_user_id z_users.user_id%TYPE);
END;
/

/
CREATE OR REPLACE PACKAGE BODY user_management IS
    FUNCTION check_user_id (p_user_id z_users.user_id%TYPE) RETURN BOOLEAN
    IS
        test z_users.user_id%TYPE;
    BEGIN
        SELECT user_id
        INTO test
        FROM z_users
        WHERE user_id = p_user_id;
        
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN FALSE;
    END;
    
    PROCEDURE user_details (p_user_id z_users.user_id%TYPE)
    IS
        test NUMBER;
        contor NUMBER := 0;

        user_full_name VARCHAR2(50);
        country_name z_countries.name%TYPE;
        city_name z_cities.name%TYPE;
        
        CURSOR laptops IS
            SELECT 
                l.laptop_model,
                lb.name as brand_name,
                cb.name as cpu_name
            FROM z_laptops l
            JOIN z_laptop_brands lb ON l.laptop_brand_id = lb.laptop_brand_id
            JOIN z_cpu_brands cb ON l.cpu_brand_id = cb.cpu_brand_id
            JOIN z_order_lines ol ON l.laptop_id = ol.laptop_id
            JOIN z_laptop_orders lo ON ol.laptop_order_id = lo.laptop_order_id
            WHERE lo.user_id = p_user_id;
        
        WRONG_USER EXCEPTION;
        USER_WITH_NO_ORDERS EXCEPTION;
    BEGIN
        -- test daca exista userul
        IF check_user_id (p_user_id) = FALSE THEN
            RAISE WRONG_USER;
        END IF;
        
        SELECT 
            u.first_name || ' ' || u.last_name,
            co.name,
            ci.name
        INTO user_full_name, country_name, city_name
        FROM z_users u
        JOIN z_addresses a ON u.address_id = a.address_id
        JOIN z_countries co ON a.country_id = co.country_id
        JOIN z_cities ci ON a.city_id = ci.city_id
        WHERE u.user_id = p_user_id;
        
        DBMS_OUTPUT.PUT_LINE('User: '||user_full_name||' din tara '||country_name||' si orasul '||city_name);
        
        -- test daca userul a dat comenzi
        SELECT COUNT(user_id)
        INTO test
        FROM z_laptop_orders
        WHERE user_id = p_user_id;
        
        IF test = 0 THEN
            RAISE USER_WITH_NO_ORDERS;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('      a comandat urmatoarele laptopuri:');
        
        FOR i IN laptops LOOP
            contor := contor + 1;
            DBMS_OUTPUT.PUT_LINE('  '||contor||'. '||i.laptop_model||' - '||i.brand_name||' - '||i.cpu_name);
        END LOOP;
    EXCEPTION
        WHEN WRONG_USER THEN
            DBMS_OUTPUT.PUT_LINE('Nu exista userul introdus.');
        WHEN USER_WITH_NO_ORDERS THEN
            DBMS_OUTPUT.PUT_LINE('Userul nu a comandat niciun laptop.');    
    END;
END;
/

/
ACCEPT input_user_id PROMPT 'id user: '
DECLARE
    p_user_id z_users.user_id%TYPE := &input_user_id;
    test BOOLEAN;
BEGIN
    user_management.user_details(p_user_id);
END;
/

-- 2. Pachet order_management:
--    - Functia order_total_price. Primeste ca parametru order_id si returneaza pretul total 
--      al unei comenzi
--    - Procedura user_orders. Primeste ca parametru user_id si afiseaza detalii despre toate 
--      comenzile unui user. Se foloseste de functia order_total_price pentru a afisa valoarea
--      unei comenzi.

-- test: input = 10 (userul exista si a dat comenzi)
-- test: input = 8 (userul exista, dar nu a dat comenzi)
-- test  input = 100 (userul nu exista)

/
CREATE OR REPLACE PACKAGE order_management IS
    FUNCTION order_total_price (p_order_id z_order_lines.laptop_order_id%TYPE) RETURN NUMBER;
    PROCEDURE user_orders (p_user_id z_users.user_id%TYPE);
END;
/

/
CREATE OR REPLACE PACKAGE BODY order_management IS
    FUNCTION order_total_price (p_order_id z_order_lines.laptop_order_id%TYPE) RETURN NUMBER
    IS
        total_price NUMBER;
    BEGIN
        SELECT SUM(ol.price * ol.quantity)
        INTO total_price
        FROM z_order_lines ol
        JOIN z_laptop_orders lo ON ol.laptop_order_id = lo.laptop_order_id
        WHERE lo.laptop_order_id = p_order_id;
        
        RETURN total_price;
    END;
    
    PROCEDURE user_orders (p_user_id z_users.user_id%TYPE)
    IS
        CURSOR c IS 
            SELECT 
                laptop_order_id,
                order_date,
                sm.name AS shipping_method_name
            FROM z_laptop_orders lo
            JOIN z_shipping_methods sm ON lo.shipping_method_id = sm.shipping_method_id
            WHERE lo.user_id = p_user_id;
        
        contor NUMBER := 0;
        test1 z_users.user_id%TYPE;
        test2 NUMBER;
        
        USER_WITH_NO_ORDERS EXCEPTION;
    BEGIN
        SELECT user_id
        INTO test1
        FROM z_users
        WHERE user_id = p_user_id;
    
        SELECT COUNT(user_id)
        INTO test2
        FROM z_laptop_orders
        WHERE user_id = p_user_id;
        
        IF test2 = 0 THEN
            RAISE USER_WITH_NO_ORDERS;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Comenzile userului cu idul '||p_user_id||':');
        FOR i IN c LOOP
            contor := contor + 1;
            DBMS_OUTPUT.PUT_LINE(contor||'. '||'Id comanda: '||i.laptop_order_id||', Data comenzii: '||i.order_date||', Metoda de livrare: '||i.shipping_method_name||'.');
            DBMS_OUTPUT.PUT_LINE('  -> Valoarea comenzii: '||order_total_price(i.laptop_order_id));
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Userul nu exista.');
        WHEN USER_WITH_NO_ORDERS THEN
            DBMS_OUTPUT.PUT_LINE('Userul nu a dat comenzi.');
    END;
END;
/

/
ACCEPT input PROMPT 'user id: ';
DECLARE
    v_user_id z_users.user_id%TYPE := &input;
BEGIN
    order_management.user_orders(v_user_id);
END;
/










