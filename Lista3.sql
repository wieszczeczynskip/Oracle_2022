ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--Zadanie 34
DECLARE 
    funkcja Kocury.funkcja%TYPE;
BEGIN
    SELECT funkcja INTO funkcja FROM Kocury WHERE funkcja = UPPER('&Funkcja') GROUP BY funkcja;
    DBMS_OUTPUT.PUT_LINE(funkcja);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(funkcja);
END;
/

--Zadanie 35
DECLARE
    kocur Kocury%ROWTYPE;
    fits BOOLEAN := FALSE;
BEGIN
    SELECT * INTO kocur FROM Kocury WHERE pseudo = UPPER('&pseudo');
    DBMS_OUTPUT.PUT_LINE(kocur.pseudo);
    
    IF (NVL(kocur.przydzial_myszy,0) + NVL(kocur.myszy_extra,0))*12>700 THEN
        fits := TRUE;
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy>700');
    END IF;
    
    IF kocur.imie LIKE '%A%' THEN
        fits := TRUE;
        DBMS_OUTPUT.PUT_LINE('imie zawiera litere A');
    END IF;
    
    IF EXTRACT(MONTH FROM kocur.w_stadku_od) = 5 THEN
        fits := TRUE;
        DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada');
    END IF;
    
    IF fits=FALSE THEN
        DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('BRAK TAKIEGO KOTA');
END;
/

--Zadanie 36
DECLARE
    CURSOR kursor IS SELECT * FROM Kocury LEFT JOIN Funkcje ON Kocury.funkcja = Funkcje.funkcja ORDER BY przydzial_myszy FOR UPDATE OF przydzial_myszy;
    kocur kursor%ROWTYPE;
    suma NUMBER;
    maxprzydzial NUMBER;
    tempprzydzial NUMBER;
    lzmian NUMBER := 0;
BEGIN
    SELECT SUM(NVL(przydzial_myszy,0)) INTO suma FROM Kocury;
    <<mainloop>>LOOP
        OPEN kursor;
        LOOP
            FETCH kursor INTO kocur;
            EXIT WHEN kursor%NOTFOUND;
            maxprzydzial := kocur.max_myszy;
            IF kocur.przydzial_myszy != maxprzydzial THEN
                tempprzydzial := ROUND(kocur.przydzial_myszy*1.1);
                IF tempprzydzial > maxprzydzial THEN
                    tempprzydzial := maxprzydzial;
                END IF;
                lzmian := lzmian + 1;
                suma := suma - kocur.przydzial_myszy + tempprzydzial;
                UPDATE Kocury
                SET przydzial_myszy = tempprzydzial
                WHERE CURRENT OF kursor;
                --DBMS_OUTPUT.PUT_LINE(suma || kocur.imie || tempprzydzial);
                EXIT mainloop WHEN suma > 1050;
            END IF;
        END LOOP;
        CLOSE kursor;
    END LOOP;
    DBMS_OUTPUT.PUT('Calk. przydzial w stadku ' || suma);
    DBMS_OUTPUT.PUT_LINE('  Zmian - ' || lzmian);
END;
/
SELECT imie, przydzial_myszy "Myszki po podwyzce" FROM Kocury ORDER BY w_stadku_od;
ROLLBACK;

--Zadanie 37
DECLARE
    CURSOR kursor IS SELECT * FROM Kocury ORDER BY (NVL(przydzial_myszy,0)+NVL(myszy_extra,0)) DESC;
    kocur kursor%ROWTYPE;
BEGIN
    OPEN kursor;
    DBMS_OUTPUT.PUT_LINE('Nr  Pseudonim  Zjada');
    DBMS_OUTPUT.PUT_LINE('--------------------');
    FOR i IN 1..5
    LOOP
        FETCH kursor INTO kocur;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(i) || '   ' || RPAD(kocur.pseudo, 11) || LPAD(TO_CHAR(NVL(kocur.przydzial_myszy,0)+NVL(kocur.myszy_extra,0)),5));
        EXIT WHEN i = 5;
    END LOOP;
END;
/

--Zadanie 38
DECLARE
    maxlvl NUMBER := 0;
    lvl NUMBER := 1;
    maxlvls NUMBER := &Ile_szefów;
    kocur Kocury%ROWTYPE;
BEGIN
    SELECT MAX(LEVEL)-1 INTO maxlvl 
    FROM Kocury 
    CONNECT BY PRIOR pseudo = szef
    START WITH szef IS NULL;
    maxlvls := LEAST(maxlvl, maxlvls);
    -----------------------------------------------
    DBMS_OUTPUT.PUT('Imie           ');
    FOR i IN 1..maxlvls
    LOOP
        DBMS_OUTPUT.PUT('|  ' || 'Szef ' || i || '         ');
    END LOOP;
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT('---------------');
    FOR i IN 1..maxlvls
    LOOP
        DBMS_OUTPUT.PUT('------------------');
    END LOOP;
    DBMS_OUTPUT.NEW_LINE;
    -----------------------------------------------
    FOR wiersz IN (SELECT * FROM Kocury WHERE funkcja IN ('MILUSIA', 'KOT'))
    LOOP
        lvl := 1;
        DBMS_OUTPUT.PUT(RPAD(wiersz.imie,15));
        kocur := wiersz;
        WHILE lvl<=maxlvls 
        LOOP
            IF kocur.szef IS NULL THEN
                DBMS_OUTPUT.PUT('|  ' || RPAD(' ',15));
            ELSE
                SELECT * INTO kocur FROM Kocury WHERE kocur.szef = pseudo;
                DBMS_OUTPUT.PUT('|  ' || RPAD(kocur.imie,15));
            END IF;
            lvl := lvl + 1;
        END LOOP;
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;
END;
/

--Zadanie 39
DECLARE
    CURSOR kursor IS SELECT * FROM Bandy;
    banda Bandy%ROWTYPE;
    
    nr bandy.nr_bandy%TYPE;
    nazwa bandy.nazwa%TYPE;
    teren bandy.teren%TYPE;
    
    nr_exc EXCEPTION;
    banda_exc EXCEPTION;
    nazwa_exc EXCEPTION;
    teren_exc EXCEPTION;
    
BEGIN
    nr := &Numer;
    nazwa := UPPER('&Nazwa');
    teren := UPPER('&Teren');
    
    IF nr <= 0 THEN
        RAISE nr_exc;
    END IF;
    
    OPEN kursor;
    
    LOOP
        FETCH kursor INTO banda;
        EXIT WHEN kursor%NOTFOUND;
        IF nr = banda.nr_bandy THEN
            RAISE banda_exc;
        END IF;
        IF nazwa = banda.nazwa THEN
            RAISE nazwa_exc;
        END IF;
        IF teren = banda.teren THEN
            RAISE teren_exc;
        END IF;
    END LOOP;
    
    INSERT INTO Bandy VALUES (nr, nazwa, teren, NULL);
    
EXCEPTION
    WHEN nr_exc THEN
        DBMS_OUTPUT.PUT_LINE('Numer bandy nie mo¿e byæ <= 0');
    WHEN banda_exc THEN
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(nr) || ' ju¿ istnieje');
    WHEN nazwa_exc THEN
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(nazwa) || ' ju¿ istnieje');
    WHEN teren_exc THEN
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(teren) || ' ju¿ istnieje');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/
ROLLBACK;

--Zadanie 40
CREATE OR REPLACE PROCEDURE NowaBanda(nr NUMBER, nazwa VARCHAR2, teren VARCHAR2) AS
        CURSOR kursor IS SELECT * FROM Bandy;
        banda Bandy%ROWTYPE;
        
        nr_exc EXCEPTION;
        banda_exc EXCEPTION;
        nazwa_exc EXCEPTION;
        teren_exc EXCEPTION;
    
    BEGIN
        IF nr <= 0 THEN
            RAISE nr_exc;
        END IF;
    
        OPEN kursor;
    
        LOOP
            FETCH kursor INTO banda;
            EXIT WHEN kursor%NOTFOUND;
            IF nr = banda.nr_bandy THEN
                RAISE banda_exc;
            END IF;
            IF nazwa = banda.nazwa THEN
                RAISE nazwa_exc;
            END IF;
            IF teren = banda.teren THEN
                RAISE teren_exc;
            END IF;
        END LOOP;
        
        INSERT INTO Bandy VALUES (nr, nazwa, teren, NULL);
    
    EXCEPTION
        WHEN nr_exc THEN
            DBMS_OUTPUT.PUT_LINE('Numer bandy nie mo¿e byæ <= 0');
        WHEN banda_exc THEN
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(nr) || ' ju¿ istnieje');
        WHEN nazwa_exc THEN
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(nazwa) || ' ju¿ istnieje');
        WHEN teren_exc THEN
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(teren) || ' ju¿ istnieje');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
/

DROP PROCEDURE NowaBanda;

--Zadanie 41
CREATE OR REPLACE TRIGGER maxplus1
BEFORE INSERT ON Bandy
FOR EACH ROW
BEGIN
    SELECT MAX(nr_bandy)+1 INTO :NEW.nr_bandy FROM Bandy;
END;
/

--Test
BEGIN
    NowaBanda(9, 'asdasd', 'adasd');
END;
/
SELECT * FROM Bandy;
ROLLBACK;
DROP TRIGGER maxplus1;

--Zadanie 42a
CREATE OR REPLACE PACKAGE wirus AS
    przydzial_tygrysa NUMBER := 0;
    count_nagroda NUMBER := 0;
    count_kara NUMBER := 0;
    flag BOOLEAN := FALSE;
END;
/

CREATE OR REPLACE TRIGGER set_przydzial_tygrysa
    BEFORE UPDATE ON Kocury
    BEGIN
        SELECT przydzial_myszy INTO wirus.przydzial_tygrysa FROM Kocury WHERE pseudo='TYGRYS';
    END;
/

CREATE OR REPLACE TRIGGER wirus_zmiany
    BEFORE UPDATE ON Kocury
    FOR EACH ROW
    DECLARE
        roznica NUMBER := 0;
    BEGIN
        IF :NEW.funkcja = 'MILUSIA' THEN
            wirus.flag := TRUE;
            IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
                DBMS_OUTPUT.PUT_LINE('Nie mozna zmieniæ przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                :NEW.przydzial_myszy := :OLD.przydzial_myszy;
            ELSE
                roznica := :NEW.przydzial_myszy - :OLD.przydzial_myszy;
                IF roznica < 0.1*wirus.przydzial_tygrysa THEN
                    DBMS_OUTPUT.PUT_LINE('Ró¿nica: ' || roznica || ' Przydzial Tygrysa: ' || wirus.przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('+1 Kara za zmianê przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                    wirus.count_kara := wirus.count_kara + 1;
                    :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1*wirus.przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ ' || :OLD.pseudo || ': ' || :NEW.przydzial_myszy || ', stary przydzial: ' || :OLD.przydzial_myszy);
                    :NEW.myszy_extra := :NEW.myszy_extra + 5;
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ extra ' || :OLD.pseudo || ': ' || :NEW.myszy_extra || ', stary przydzial extra: ' || :OLD.myszy_extra);
                ELSIF roznica >= 0.1*wirus.przydzial_tygrysa THEN
                    wirus.count_nagroda := wirus.count_nagroda + 1;
                    DBMS_OUTPUT.PUT_LINE('Ró¿nica: ' || roznica || ' Przydzial Tygrysa: ' || wirus.przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('+1 Nagroda za zmianê przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ ' || :OLD.pseudo || ': ' || :NEW.przydzial_myszy || ', stary przydzial: ' || :OLD.przydzial_myszy);
                END IF;
            END IF;
        END IF;
    END;
/

CREATE OR REPLACE TRIGGER wirus_tygrys
AFTER UPDATE ON Kocury
BEGIN
    IF wirus.flag THEN
        wirus.flag := FALSE;
        IF wirus.count_kara > 0 THEN
            UPDATE Kocury SET przydzial_myszy = ROUND(przydzial_myszy * POWER(0.9, wirus.count_kara)) WHERE pseudo = 'TYGRYS';
            DBMS_OUTPUT.PUT_LINE('Zabrano '|| TO_CHAR(wirus.przydzial_tygrysa - ROUND(wirus.przydzial_tygrysa * POWER(0.9, wirus.count_kara))) ||' przydzialu myszy tygrysowi.');
            wirus.count_kara := 0;
        END IF;
        IF wirus.count_nagroda > 0 THEN
            UPDATE Kocury SET myszy_extra = myszy_extra + 5 * wirus.count_nagroda WHERE pseudo = 'TYGRYS';
            DBMS_OUTPUT.PUT_LINE('Dodano '|| TO_CHAR(5 * wirus.count_nagroda) ||' mysz extra tygrysowi.');
            wirus.count_nagroda := 0;
        END IF;
    END IF;
END;
/

--Test
UPDATE Kocury SET przydzial_myszy = 50 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;
UPDATE Kocury SET przydzial_myszy = 0 WHERE pseudo = 'PUSZYSTA';
UPDATE Kocury SET przydzial_myszy = 22 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;
UPDATE Kocury SET przydzial_myszy = 31 WHERE funkcja = 'MILUSIA';
ROLLBACK;

DROP TRIGGER set_przydzial_tygrysa;
DROP TRIGGER wirus_zmiany;
DROP TRIGGER wirus_tygrys;
DROP PACKAGE wirus;


--Zadanie 42b
CREATE OR REPLACE TRIGGER wirus
    FOR UPDATE ON Kocury
    COMPOUND TRIGGER
        przydzial_tygrysa NUMBER := 0;
        count_nagroda NUMBER := 0;
        count_kara NUMBER := 0;
        flag BOOLEAN := FALSE;
        roznica NUMBER := 0;
    
    BEFORE STATEMENT IS
    BEGIN
        SELECT przydzial_myszy INTO przydzial_tygrysa FROM Kocury WHERE pseudo='TYGRYS';
    END BEFORE STATEMENT;
    
    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.funkcja = 'MILUSIA' THEN
            flag := TRUE;
            IF :NEW.przydzial_myszy <= :OLD.przydzial_myszy THEN
                DBMS_OUTPUT.PUT_LINE('Nie mozna zmieniæ przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                :NEW.przydzial_myszy := :OLD.przydzial_myszy;
            ELSE
                roznica := :NEW.przydzial_myszy - :OLD.przydzial_myszy;
                IF roznica < 0.1*przydzial_tygrysa THEN
                    DBMS_OUTPUT.PUT_LINE('Ró¿nica: ' || roznica || ' Przydzial Tygrysa: ' || przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('+1 Kara za zmianê przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                    count_kara := count_kara + 1;
                    :NEW.przydzial_myszy := :NEW.przydzial_myszy + ROUND(0.1*przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ ' || :OLD.pseudo || ': ' || :NEW.przydzial_myszy || ', stary przydzial: ' || :OLD.przydzial_myszy);
                    :NEW.myszy_extra := :NEW.myszy_extra + 5;
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ extra ' || :OLD.pseudo || ': ' || :NEW.myszy_extra || ', stary przydzial extra: ' || :OLD.myszy_extra);
                ELSIF roznica >= 0.1*przydzial_tygrysa THEN
                    count_nagroda := count_nagroda + 1;
                    DBMS_OUTPUT.PUT_LINE('Ró¿nica: ' || roznica || ' Przydzial Tygrysa: ' || przydzial_tygrysa);
                    DBMS_OUTPUT.PUT_LINE('+1 Nagroda za zmianê przydzia³u '|| :OLD.pseudo||' z '|| :OLD.przydzial_myszy||' na '|| :NEW.przydzial_myszy);
                    DBMS_OUTPUT.PUT_LINE('Nowy przydzia³ ' || :OLD.pseudo || ': ' || :NEW.przydzial_myszy || ', stary przydzial: ' || :OLD.przydzial_myszy);
                END IF;
            END IF;
        END IF;
    END BEFORE EACH ROW;
    
    AFTER STATEMENT IS
    BEGIN
        IF flag THEN
            flag := FALSE;
            IF count_kara > 0 THEN
                UPDATE Kocury SET przydzial_myszy = ROUND(przydzial_myszy * POWER(0.9, count_kara)) WHERE pseudo = 'TYGRYS';
                DBMS_OUTPUT.PUT_LINE('Zabrano '|| TO_CHAR(przydzial_tygrysa - ROUND(przydzial_tygrysa * POWER(0.9, count_kara))) ||' przydzialu myszy tygrysowi.');
                count_kara := 0;
            END IF;
            IF count_nagroda > 0 THEN
                UPDATE Kocury SET myszy_extra = myszy_extra + 5 * count_nagroda WHERE pseudo = 'TYGRYS';
                DBMS_OUTPUT.PUT_LINE('Dodano '|| TO_CHAR(5 * count_nagroda) ||' mysz extra tygrysowi.');
                count_nagroda := 0;
            END IF;
        END IF;
    END AFTER STATEMENT;
END;
/

--Test
UPDATE Kocury SET przydzial_myszy = 50 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;
UPDATE Kocury SET przydzial_myszy = 0 WHERE pseudo = 'PUSZYSTA';
UPDATE Kocury SET przydzial_myszy = 22 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;
UPDATE Kocury SET przydzial_myszy = 31 WHERE funkcja = 'MILUSIA';
ROLLBACK;

DROP TRIGGER wirus;
/


--SELECT MAX(K1.plec), COUNT(DISTINCT K2.pseudo) FROM Kocury K1 JOIN Kocury K2 ON K1.plec = K2.plec GROUP BY K1.plec ORDER BY K1.plec;
--SELECT plec FROM Kocury GROUP BY plec ORDER BY plec;
--SELECT B.nazwa, MAX(B.nr_bandy) "NR_BANDY", COUNT(*) ilosc_kotow, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) ilosc_bandaplec, K.plec plec FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy WHERE K.pseudo IS NOT NULL GROUP BY B.nazwa, K.plec ORDER BY B.nazwa;
--SELECT MAX(B.nr_bandy) "NR_BANDY", SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) ilosc_bandaplecfunkcja, K.plec plec, F.funkcja funkcja FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy JOIN Funkcje F ON K.funkcja = F.funkcja WHERE K.pseudo IS NOT NULL GROUP BY B.nazwa, K.plec, F.funkcja ORDER BY B.nazwa;


--Zadanie 43
DECLARE
    CURSOR kursor_funkcje IS SELECT F.funkcja, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma_funkcji FROM Funkcje F LEFT JOIN Kocury K ON F.funkcja = K.funkcja WHERE K.pseudo IS NOT NULL GROUP BY F.funkcja ORDER BY MAX(max_myszy) DESC;
   
    --podzial na bandy plci funkcje
    CURSOR kursor_plci_bandy_funkcje IS SELECT MAX(B.nr_bandy) "NR_BANDY", SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) ilosc_bandaplecfunkcja, K.plec plec, F.funkcja funkcja FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy JOIN Funkcje F ON K.funkcja = F.funkcja WHERE K.pseudo IS NOT NULL GROUP BY B.nazwa, K.plec, F.funkcja ORDER BY B.nazwa;    
    
    --podzial na bandy i plci
    CURSOR kursor_plci_bandy IS SELECT B.nazwa, MAX(B.nr_bandy) "NR_BANDY", COUNT(*) ilosc_kotow, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) ilosc_bandaplec, K.plec plec FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy WHERE K.pseudo IS NOT NULL GROUP BY B.nazwa, K.plec ORDER BY B.nazwa;

    ilosc NUMBER;
BEGIN
    --1 Linijka
    DBMS_OUTPUT.PUT('NAZWA BANDY       PLEC    ILE ');
    FOR funkcja IN kursor_funkcje
    LOOP
        DBMS_OUTPUT.PUT(RPAD(funkcja.funkcja,10));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    SUMA');
    --2 Linijka
    DBMS_OUTPUT.PUT('----------------- ------ ----');
    FOR fun IN kursor_funkcje
    LOOP
        DBMS_OUTPUT.PUT(' ---------');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(' --------');
    --Bandy
    FOR pb IN kursor_plci_bandy
    LOOP
        DBMS_OUTPUT.PUT(CASE WHEN pb.plec = 'D' THEN RPAD(pb.nazwa, 18) ELSE RPAD(' ', 18) END);
        DBMS_OUTPUT.PUT(CASE WHEN pb.plec = 'D' THEN 'Kotka' ELSE 'Kocur' END);
        ilosc := pb.ilosc_kotow;    
        DBMS_OUTPUT.PUT(LPAD(ilosc, 4));
        
            
        FOR funkcja IN kursor_funkcje
        LOOP
            ilosc := 0;
            FOR pbf IN kursor_plci_bandy_funkcje
            LOOP
                IF pbf.nr_bandy = pb.nr_bandy AND pbf.plec = pb.plec AND pbf.funkcja = funkcja.funkcja THEN
                    ilosc := pbf.ilosc_bandaplecfunkcja;
                    EXIT;
                END IF;
            END LOOP;
            DBMS_OUTPUT.PUT(LPAD(NVL(ilosc, 0), 10));
        END LOOP;
        
        
        ilosc := pb.ilosc_bandaplec;
        DBMS_OUTPUT.PUT(LPAD(NVL(ilosc, 0), 10));
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;
    --Przerwa
    DBMS_OUTPUT.PUT('----------------- ------ ----');
    FOR funkcja IN kursor_funkcje
    LOOP
        DBMS_OUTPUT.PUT(' ---------');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(' --------');
    --Ostatnia linijka
    DBMS_OUTPUT.PUT('Zjada razem                ');
    FOR funkcja IN kursor_funkcje
    LOOP
        ilosc := funkcja.suma_funkcji;
        DBMS_OUTPUT.PUT(LPAD(NVL(ilosc, 0), 10));
    END LOOP;
    
    SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) INTO ilosc FROM Kocury;
    DBMS_OUTPUT.PUT(LPAD(NVl(ilosc, 0), 10));
    DBMS_OUTPUT.NEW_LINE;
END;
/

--Zadanie 44
CREATE OR REPLACE FUNCTION Podatek(pseudonim Kocury.pseudo%TYPE, inny_podatek NUMBER := 0) RETURN NUMBER IS
        podst NUMBER;
        podwladni NUMBER;
        wrogowie NUMBER;
    BEGIN
        SELECT CEIL(0.05 * przydzial_myszy) INTO podst FROM Kocury WHERE pseudonim = pseudo;
        SELECT COUNT(*) INTO podwladni FROM Kocury WHERE szef = pseudonim;
        SELECT COUNT(*) INTO wrogowie FROM Wrogowie_kocurow WHERE pseudo = pseudonim;
        
        IF podwladni > 0 THEN
            podwladni := 0;
        ELSE
            podwladni := 2;
        END IF;
        
        IF wrogowie > 0 THEN
            wrogowie := 0;
        ELSE 
            wrogowie := 1;
        END IF;
        
        RETURN podst + podwladni + wrogowie + inny_podatek;
    END;
/

CREATE OR REPLACE PACKAGE Podatek_package AS
    FUNCTION Podatek(pseudonim Kocury.pseudo%TYPE, inny_podatek NUMBER := 0) RETURN NUMBER;
    PROCEDURE NowaBanda(nr NUMBER, nazwa VARCHAR2, teren VARCHAR2);
END Podatek_package;
/

CREATE OR REPLACE PACKAGE BODY Podatek_package AS
    FUNCTION Podatek(pseudonim Kocury.pseudo%TYPE, inny_podatek NUMBER := 0) RETURN NUMBER IS
            podst NUMBER;
            podwladni NUMBER;
            wrogowie NUMBER;
        BEGIN
            SELECT CEIL(0.05 * przydzial_myszy) INTO podst FROM Kocury WHERE pseudonim = pseudo;
            SELECT COUNT(*) INTO podwladni FROM Kocury WHERE szef = pseudonim;
            SELECT COUNT(*) INTO wrogowie FROM Wrogowie_kocurow WHERE pseudo = pseudonim;
            
            IF podwladni > 0 THEN
                podwladni := 0;
            ELSE
                podwladni := 2;
            END IF;
            
            IF wrogowie > 0 THEN
                wrogowie := 0;
            ELSE 
                wrogowie := 1;
            END IF;
            
            RETURN podst + podwladni + wrogowie + inny_podatek;
        END;

    PROCEDURE NowaBanda(nr NUMBER, nazwa VARCHAR2, teren VARCHAR2) IS
            CURSOR kursor IS SELECT * FROM Bandy;
            banda Bandy%ROWTYPE;
            
            nr_exc EXCEPTION;
            banda_exc EXCEPTION;
            nazwa_exc EXCEPTION;
            teren_exc EXCEPTION;
        
        BEGIN
            IF nr <= 0 THEN
                RAISE nr_exc;
            END IF;
        
            OPEN kursor;
        
            LOOP
                FETCH kursor INTO banda;
                EXIT WHEN kursor%NOTFOUND;
                IF nr = banda.nr_bandy THEN
                    RAISE banda_exc;
                END IF;
                IF nazwa = banda.nazwa THEN
                    RAISE nazwa_exc;
                END IF;
                IF teren = banda.teren THEN
                    RAISE teren_exc;
                END IF;
            END LOOP;
            
            INSERT INTO Bandy VALUES (nr, nazwa, teren, NULL);
        
        EXCEPTION
            WHEN nr_exc THEN
                DBMS_OUTPUT.PUT_LINE('Numer bandy nie mo¿e byæ <= 0');
            WHEN banda_exc THEN
                DBMS_OUTPUT.PUT_LINE(TO_CHAR(nr) || ' ju¿ istnieje');
            WHEN nazwa_exc THEN
                DBMS_OUTPUT.PUT_LINE(TO_CHAR(nazwa) || ' ju¿ istnieje');
            WHEN teren_exc THEN
                DBMS_OUTPUT.PUT_LINE(TO_CHAR(teren) || ' ju¿ istnieje');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(SQLERRM);
        END;
END;
/

BEGIN
    DBMS_OUTPUT.PUT(RPAD('PSEUDONIM', 10));
    DBMS_OUTPUT.PUT(LPAD('PODATEK POG£ÓWNY', 20));
    DBMS_OUTPUT.NEW_LINE;
    FOR kocur IN (SELECT pseudo FROM Kocury)
    LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(kocur.pseudo, 10) || LPAD(Podatek_package.podatek(kocur.pseudo), 20)); 
    END LOOP;
END;
/

DROP FUNCTION Podatek;
DROP PACKAGE Podatek_package;

--Zadanie 45
CREATE TABLE Dodatki_extra(pseudo VARCHAR2(15), dodatek NUMBER);

CREATE OR REPLACE TRIGGER antywirus
FOR UPDATE ON Kocury
COMPOUND TRIGGER
    flag BOOLEAN := FALSE;
    dynquery VARCHAR2(500);
    isInDodatki NUMBER;
    CURSOR kursor IS SELECT * FROM Kocury WHERE funkcja = 'MILUSIA';
    
    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.funkcja = 'MILUSIA' AND NOT SYS.LOGIN_USER = 'TYGRYS' THEN
            flag := TRUE;
        END IF;
    END BEFORE EACH ROW;
    
    AFTER STATEMENT IS
    BEGIN
        IF flag THEN
            FOR milusia IN kursor
            LOOP
                SELECT COUNT(*) INTO isInDodatki FROM Dodatki_extra WHERE pseudo = milusia.pseudo;
                IF isInDodatki > 0 THEN
                    EXECUTE IMMEDIATE 'UPDATE Dodatki_extra SET dodatek = dodatek - 10 WHERE pseudo = ''' || TO_CHAR(milusia.pseudo) || '''';
                ELSE
                    EXECUTE IMMEDIATE 'INSERT INTO Dodatki_extra VALUES (''' || TO_CHAR(milusia.pseudo) || ''', -10)';
                END IF;
            END LOOP;
            
            flag := FALSE;
            
        END IF;
    END AFTER STATEMENT;
END;
/

UPDATE Kocury SET przydzial_myszy = 20 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;

DROP TABLE Dodatki_extra;
DROP TRIGGER antywirus;
/

--Zadanie 46
CREATE TABLE Logi(kto VARCHAR2(15), kiedy DATE, komu VARCHAR2(15), operacja VARCHAR2(500));

CREATE OR REPLACE TRIGGER check_funkcja
BEFORE INSERT OR UPDATE ON Kocury
FOR EACH ROW
    DECLARE
        min_myszy_t NUMBER;
        max_myszy_t NUMBER;
        operacja VARCHAR2(500);
    BEGIN
        SELECT min_myszy INTO min_myszy_t FROM Funkcje WHERE funkcja = :NEW.funkcja;
        SELECT max_myszy INTO max_myszy_t FROM Funkcje WHERE funkcja = :NEW.funkcja;
    IF UPDATING THEN
        operacja := 'UPDATE';
    ELSE
        operacja := 'INSERT';
    END IF;
    
    IF :NEW.przydzial_myszy < min_myszy_t OR :NEW.przydzial_myszy > max_myszy_t THEN
        INSERT INTO Logi VALUES (SYS.LOGIN_USER, CURRENT_DATE, :NEW.pseudo, operacja);
        :NEW.przydzial_myszy := :OLD.przydzial_myszy;
    END IF;
END;
/

UPDATE Kocury SET przydzial_myszy = 10 WHERE pseudo = 'TYGRYS';
SELECT * FROM Logi;
SELECT * FROM Kocury WHERE pseudo = 'TYGRYS';

DROP TABLE Logi;
DROP TRIGGER check_funkcja;




--36, 43