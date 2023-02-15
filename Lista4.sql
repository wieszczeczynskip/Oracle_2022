ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--Zadanie 47
CREATE OR REPLACE TYPE KocuryT AS OBJECT
(
 imie VARCHAR2(15),
 plec VARCHAR2(1),
 pseudo VARCHAR2(10),
 funkcja VARCHAR2(10),
 szef REF KocuryT,
 w_stadku_od DATE,
 przydzial_myszy NUMBER(3),
 myszy_extra NUMBER(3),
 nr_bandy NUMBER(2),
 MEMBER FUNCTION Dane RETURN VARCHAR2,
 MEMBER FUNCTION Dochod RETURN NUMBER,
 MEMBER FUNCTION WStadkuOd RETURN DATE
);

CREATE OR REPLACE TYPE BODY KocuryT AS
    MEMBER FUNCTION Dane RETURN VARCHAR2 IS
    BEGIN
        RETURN (CASE plec WHEN 'M' THEN 'Kot ' ELSE 'Kotka ' END)|| imie;
    END;
    MEMBER FUNCTION Dochod RETURN NUMBER IS
    BEGIN
        RETURN NVL(przydzial_myszy,0)+NVL(myszy_extra,0);
    END;
    MEMBER FUNCTION WStadkuOd RETURN DATE IS
    BEGIN
        RETURN TO_CHAR(w_stadku_od, 'YYYY-MM-DD');
    END;
END;
/

CREATE OR REPLACE TYPE PlebsT AS OBJECT
(
  id_plebsu NUMBER,
  kocur REF KocuryT
);

CREATE OR REPLACE TYPE ElitaT AS OBJECT
(
  id_elity INTEGER,
  kocur REF KocuryT,
  sluga REF PlebsT
);

CREATE OR REPLACE TYPE KontoT AS OBJECT
(
	id_akcji NUMBER,
	wlasciciel_konta REF ElitaT,
	data_wprowadzenia DATE,
	data_usuniecia DATE,
	MEMBER PROCEDURE dodaj_mysz,
	MEMBER PROCEDURE usun_mysz
);
/

CREATE OR REPLACE TYPE BODY KontoT AS
    MEMBER PROCEDURE dodaj_mysz IS
    BEGIN
        data_wprowadzenia:=CURRENT_DATE;
    END;
    MEMBER PROCEDURE usun_mysz IS
    BEGIN
        data_usuniecia:=CURRENT_DATE;
    END;
END;
/

CREATE OR REPLACE TYPE IncydentyT AS OBJECT
(
	id_incydentu NUMBER,
	ofiara REF KocuryT,
	imie_wroga VARCHAR2(15),
	data_incydentu DATE,
	opis_incydentu VARCHAR2(50),
	MEMBER FUNCTION Dane RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY IncydentyT AS
    MEMBER FUNCTION Dane RETURN VARCHAR2 IS
    BEGIN
        RETURN 'Incydent z '|| imie_wroga ||' w dniu '|| data_incydentu;
    END;
END;
/


CREATE TABLE KocuryR OF KocuryT
(
	CONSTRAINT kocr_pseudo_pk PRIMARY KEY (pseudo),
	CONSTRAINT kocr_func_fk FOREIGN KEY (funkcja) REFERENCES Funkcje(funkcja),
	CONSTRAINT kocr_banda_fk FOREIGN KEY (nr_bandy) REFERENCES Bandy(nr_bandy)
);

CREATE TABLE Plebs OF PlebsT
(
	CONSTRAINT plebs_pk PRIMARY KEY(id_plebsu),
	kocur NOT NULL
);

CREATE TABLE Elita OF ElitaT
(
	CONSTRAINT elita_pk PRIMARY KEY(id_elity),
	kocur NOT NULL,
	sluga SCOPE IS Plebs
);

CREATE TABLE Konto OF KontoT
(
	CONSTRAINT konto_pk PRIMARY KEY(id_akcji),
	wlasciciel_konta SCOPE IS Elita,
	CONSTRAINT konto_dw CHECK(data_wprowadzenia IS NOT NULL),
	CONSTRAINT konto_du CHECK(data_wprowadzenia >= data_usuniecia)
);

CREATE TABLE Incydenty OF IncydentyT
(
	CONSTRAINT inc_pk PRIMARY KEY (id_incydentu),
	ofiara SCOPE IS KocuryR,
	imie_wroga NOT NULL,
	CONSTRAINT inc_wrog_fk FOREIGN KEY (imie_wroga) REFERENCES Wrogowie(imie_wroga),
	data_incydentu NOT NULL
);

CREATE OR REPLACE TRIGGER CheckElita
    BEFORE INSERT OR UPDATE
    ON Elita
    FOR EACH ROW
DECLARE
    countPlebs NUMBER;
    countElita NUMBER;
BEGIN
    SELECT COUNT(kocur) INTO countPlebs FROM Plebs Pleb WHERE Pleb.kocur = :NEW.kocur;
    SELECT COUNT(kocur) INTO countElita FROM Elita Eli WHERE Eli.kocur = :NEW.kocur;
    IF countPlebs + countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot juz jest przypisany.');
    END IF;
END;

CREATE OR REPLACE TRIGGER CheckPlebs
    BEFORE INSERT OR UPDATE
    ON Plebs
    FOR EACH ROW
DECLARE
    countPlebs NUMBER;
    countElita NUMBER;
BEGIN
    SELECT COUNT(kocur) INTO countPlebs FROM Plebs Pleb WHERE Pleb.kocur = :NEW.kocur;
    SELECT COUNT(kocur) INTO countElita FROM Elita Eli WHERE Eli.kocur = :NEW.kocur;
    IF countPlebs + countElita > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Kot juz jest przypisany.');
    END IF;
END;

DELETE Incydenty;
DELETE Konto;
DELETE Elita;
DELETE Plebs;
DELETE KocuryR;

DROP TABLE Incydenty;
DROP TABLE Konto;
DROP TABLE Elita;
DROP TABLE Plebs;
DROP TABLE KocuryR;
DROP TYPE BODY IncydentyT;
DROP TYPE IncydentyT;
DROP TYPE BODY KontoT;
DROP TYPE KontoT;
DROP TYPE ElitaT;
DROP TYPE PlebsT;
DROP TYPE BODY KocuryT;
DROP TYPE KocuryT;

DROP TRIGGER CheckPlebs;
DROP TRIGGER CheckElita;

--INSERT DATA

INSERT INTO KocuryR VALUES('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1);

INSERT ALL
	INTO KocuryR VALUES('MICKA','D','LOLA','MILUSIA',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2009-10-14',25,47,1)
	INTO KocuryR VALUES('CHYTRY','M','BOLEK','DZIELCZY',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2002-05-05',50,NULL,1)
	INTO KocuryR VALUES('KOREK','M','ZOMBI','BANDZIOR',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2004-03-16',75,13,3)
    INTO KocuryR VALUES('BOLEK','M','LYSY','BANDZIOR',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2006-08-15',72,21,2)
    INTO KocuryR VALUES('RUDA','D','MALA','MILUSIA',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2006-09-17',22,42,1)
    INTO KocuryR VALUES('PUCEK','M','RAFA','LOWCZY',(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'2006-10-15',65,NULL,4)
SELECT * FROM DUAL;

INSERT ALL
    INTO KocuryR VALUES('JACEK','M','PLACEK','LOWCZY',(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),'2008-12-01',67,NULL,2)
    INTO KocuryR VALUES('BARI','M','RURA','LAPACZ',(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),'2009-09-01',56,NULL,2)
    INTO KocuryR VALUES('SONIA','D','PUSZYSTA','MILUSIA',(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZOMBI'),'2010-11-18',20,35,3)
	INTO KocuryR VALUES('LATKA','D','UCHO','KOT',(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),'2011-01-01',40,NULL,4)
    INTO KocuryR VALUES('DUDEK','M','MALY','KOT',(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),'2011-05-15',40,NULL,4)
    INTO KocuryR VALUES('ZUZIA','D','SZYBKA','LOWCZY',(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),'2006-07-21',65,NULL,2)
    INTO KocuryR VALUES('PUNIA','D','KURKA','LOWCZY',(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZOMBI'),'2008-01-01',61,NULL,3)
    INTO KocuryR VALUES('BELA','D','LASKA','MILUSIA',(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),'2008-02-01',24,28,2)
    INTO KocuryR VALUES('KSAWERY','M','MAN','LAPACZ',(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),'2008-07-12',51,NULL,4)
    INTO KocuryR VALUES('MELA','D','DAMA','LAPACZ',(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),'2008-11-01',51,NULL,4)
SELECT * FROM DUAL;

INSERT INTO KocuryR VALUES('LUCEK','M','ZERO','KOT',(SELECT REF(K) FROM KocuryR K WHERE pseudo='KURKA'),'2010-03-01',43,NULL,3);

INSERT ALL
    INTO Plebs VALUES(1,(SELECT REF(K) FROM KocuryR K WHERE pseudo='PLACEK'))
    INTO Plebs VALUES(2,(SELECT REF(K) FROM KocuryR K WHERE pseudo='RURA'))
	INTO Plebs VALUES(3,(SELECT REF(K) FROM KocuryR K WHERE pseudo='PUSZYSTA'))
	INTO Plebs VALUES(4,(SELECT REF(K) FROM KocuryR K WHERE pseudo='UCHO'))
    INTO Plebs VALUES(5,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MALY'))
    INTO Plebs VALUES(6,(SELECT REF(K) FROM KocuryR K WHERE pseudo='SZYBKA'))
    INTO Plebs VALUES(7,(SELECT REF(K) FROM KocuryR K WHERE pseudo='KURKA'))
    INTO Plebs VALUES(8,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LASKA'))
    INTO Plebs VALUES(9,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MAN'))
    INTO Plebs VALUES(10,(SELECT REF(K) FROM KocuryR K WHERE pseudo='DAMA'))
	INTO Plebs VALUES(11,(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZERO'))
SELECT * FROM DUAL;

DELETE FROM Plebs Where id_plebsu = '11';
INSERT INTO Plebs VALUES(11,(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZERO'));

INSERT ALL
    INTO Elita VALUES(1,(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=1))
    INTO Elita VALUES(2,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LOLA'),NULL)
    INTO Elita VALUES(3,(SELECT REF(K) FROM KocuryR K WHERE pseudo='BOLEK'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=1))
    INTO Elita VALUES(4,(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZOMBI'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=2))
    INTO Elita VALUES(5,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=3))
    INTO Elita VALUES(6,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MALA'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=4))
    INTO Elita VALUES(7,(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=5))
SELECT * FROM DUAL;

INSERT INTO Elita VALUES(7,(SELECT REF(K) FROM KocuryR K WHERE pseudo='RAFA'),(SELECT REF(P) FROM Plebs P WHERE id_plebsu=5));

INSERT ALL
    INTO Konto VALUES(1,(SELECT REF(E) FROM Elita E WHERE id_elity=1),SYSDATE,NULL)
    INTO Konto VALUES(2,(SELECT REF(E) FROM Elita E WHERE id_elity=2),SYSDATE,NULL)
    INTO Konto VALUES(3,(SELECT REF(E) FROM Elita E WHERE id_elity=3),SYSDATE,NULL)
    INTO Konto VALUES(4,(SELECT REF(E) FROM Elita E WHERE id_elity=4),SYSDATE,NULL)
    INTO Konto VALUES(5,(SELECT REF(E) FROM Elita E WHERE id_elity=4),SYSDATE,NULL)
    INTO Konto VALUES(6,(SELECT REF(E) FROM Elita E WHERE id_elity=1),SYSDATE,NULL)
    INTO Konto VALUES(7,(SELECT REF(E) FROM Elita E WHERE id_elity=6),SYSDATE,NULL)
    INTO Konto VALUES(8,(SELECT REF(E) FROM Elita E WHERE id_elity=1),SYSDATE,NULL)
    INTO Konto VALUES(9,(SELECT REF(E) FROM Elita E WHERE id_elity=4),SYSDATE,NULL)
    INTO Konto VALUES(10,(SELECT REF(E) FROM Elita E WHERE id_elity=4),SYSDATE,NULL)
SELECT * FROM DUAL;

INSERT ALL
    INTO Incydenty VALUES(1,(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY')
	INTO Incydenty VALUES(2,(SELECT REF(K) FROM KocuryR K WHERE pseudo='ZOMBI'),'SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY')
    INTO Incydenty VALUES(3,(SELECT REF(K) FROM KocuryR K WHERE pseudo='BOLEK'),'KAZIO','2005-03-29','POSZCZUL BURKIEM')
	INTO Incydenty VALUES(4,(SELECT REF(K) FROM KocuryR K WHERE pseudo='SZYBKA'),'GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI')
    INTO Incydenty VALUES(5,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MALA'),'CHYTRUSEK','2007-03-07','ZALECAL SIE')
    INTO Incydenty VALUES(6,(SELECT REF(K) FROM KocuryR K WHERE pseudo='TYGRYS'),'DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA')
    INTO Incydenty VALUES(7,(SELECT REF(K) FROM KocuryR K WHERE pseudo='BOLEK'),'DZIKI BILL','2007-11-10','ODGRYZL UCHO')
    INTO Incydenty VALUES(8,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LASKA'),'DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA')
    INTO Incydenty VALUES(9,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LASKA'),'KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK')
    INTO Incydenty VALUES(10,(SELECT REF(K) FROM KocuryR K WHERE pseudo='DAMA'),'KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY')
    INTO Incydenty VALUES(11,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MAN'),'REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL')
    INTO Incydenty VALUES(12,(SELECT REF(K) FROM KocuryR K WHERE pseudo='LYSY'),'BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA')
    INTO Incydenty VALUES(13,(SELECT REF(K) FROM KocuryR K WHERE pseudo='RURA'),'DZIKI BILL','2009-09-03','ODGRYZL OGON')
    INTO Incydenty VALUES(14,(SELECT REF(K) FROM KocuryR K WHERE pseudo='PLACEK'),'BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA')
    INTO Incydenty VALUES(15,(SELECT REF(K) FROM KocuryR K WHERE pseudo='PUSZYSTA'),'SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI')
    INTO Incydenty VALUES(16,(SELECT REF(K) FROM KocuryR K WHERE pseudo='KURKA'),'BUREK','2010-12-14','POGONIL')
    INTO Incydenty VALUES(17,(SELECT REF(K) FROM KocuryR K WHERE pseudo='MALY'),'CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA')
    INTO Incydenty VALUES(18,(SELECT REF(K) FROM KocuryR K WHERE pseudo='UCHO'),'SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI')
SELECT * FROM DUAL;

COMMIT;
/
--Referencja
SELECT E.kocur.Dane() "Dane wlasciciela konta", K.data_wprowadzenia "Data wprowadzenia"
FROM Elita E LEFT JOIN Konto K ON K.wlasciciel_konta=REF(E)
WHERE K.data_wprowadzenia > K.data_usuniecia OR K.data_usuniecia IS NULL;

--Podzapytanie
SELECT P.kocur.imie "Imie", P.kocur.funkcja, NVL(P.kocur.przydzial_myszy,0)+NVL(P.kocur.myszy_extra,0) "Dochod"
FROM Plebs P
WHERE P.kocur.pseudo IN (SELECT E.sluga.kocur.pseudo FROM Elita E);

--Grupowanie
SELECT K.wlasciciel_konta.kocur.pseudo "Wlasciciel", COUNT(*) "Ilosc myszy"
FROM Konto K
WHERE K.data_wprowadzenia > K.data_usuniecia OR K.data_usuniecia IS NULL
GROUP BY K.wlasciciel_konta.kocur.pseudo
ORDER BY COUNT(*) DESC;

--Zadania
--Zadanie 18 Lista 2
SELECT K.imie, K.WStadkuOd() "POLUJE OD"
FROM KocuryR K, KocuryR K2
WHERE K2.imie = 'JACEK' AND K.w_stadku_od < K2.w_stadku_od
ORDER BY K.w_stadku_od DESC;

--Zadanie 19a Lista 2

--zadanie 19a i wrogowie 
SELECT K.imie                                     "Imie",
       K.funkcja                                  "Funkcja",
       K.szef.imie                         "Szef 1",
       K.szef.szef.imie             "Szef 2",
       K.szef.szef.szef.imie "Szef 3"
FROM KocuryR K
WHERE K.funkcja IN ('KOT', 'MILUSIA');
/

--Zadanie 22 Lista 2
SELECT I.ofiara.funkcja "Funkcja", I.ofiara.pseudo "Pseudonim kota", COUNT(I.imie_wroga) "Liczba wrogow"
FROM Incydenty I
GROUP BY I.ofiara.funkcja, I.ofiara.pseudo
HAVING COUNT(I.imie_wroga) > 1;

--Zadanie 34 Lista 3
DECLARE
  fun KocuryR.funkcja%TYPE:='&nazwa_funkcji';
BEGIN
  SELECT funkcja INTO fun
  FROM KocuryR
  WHERE funkcja = UPPER(fun);
  DBMS_OUTPUT.PUT_LINE('Znaleziono kota pelniacego funkcje ' || fun);
  
  EXCEPTION
  WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('Znaleziono kota pelniacego funkcje ' || fun);
  WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota pelniacego funkcje ' || fun );
END;


--Zadanie 37 Lista 3
DECLARE
  nr NUMBER DEFAULT 1;

BEGIN
  DBMS_OUTPUT.PUT_LINE('Nr  Pseudonim  Zjada');
  DBMS_OUTPUT.PUT_LINE('--------------------');

  FOR kocur IN ( 
	SELECT Koc.pseudo, Koc.Dochod() cal_przydzial
	FROM KocuryR Koc
	ORDER BY cal_przydzial DESC) 
  LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(nr,3) || ' ' || RPAD(kocur.pseudo,10 )|| ' ' || LPAD(kocur.cal_przydzial,4));
    nr := nr + 1;
    EXIT WHEN nr > 5;
  END LOOP;
END;

--Zadanie 49

CREATE TABLE Myszy 
(
	nr_myszy NUMBER CONSTRAINT myszy_pk PRIMARY KEY,
	lowca VARCHAR2(15) CONSTRAINT lowca_fk REFERENCES Kocury(pseudo),
	zjadacz VARCHAR2(15) CONSTRAINT zjadacz_fk REFERENCES Kocury(pseudo),
	waga_myszy NUMBER(3),
	data_zlowienia DATE,
	data_wydania DATE
);

DECLARE
    data_start DATE:=TO_DATE('2004-01-01');
    data_koniec DATE:=TO_DATE('2023-01-23');
    liczba_miesiecy INTEGER := MONTHS_BETWEEN(data_koniec, data_start);
    
    TYPE t_myszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    myszki t_myszy;
    
    CURSOR ostatnie_srody IS 
		SELECT NEXT_DAY(LAST_DAY(ADD_MONTHS(sysdate, -rowNumber + 1)) - 7, 3) "date"
		FROM (SELECT ROWNUM rowNumber
			  FROM DUAL
              CONNECT BY LEVEL <= liczba_miesiecy+1);
    
    TYPE t_srody IS TABLE OF Kocury.w_stadku_od%TYPE INDEX BY BINARY_INTEGER;
    srody t_srody;
    
    first_day_month DATE;
    avg_spoz_month NUMBER;
    spoz_month NUMBER := 0;
    index_myszy NUMBER := 1;
	index_myszy_wpisanie NUMBER;

    i_sroda BINARY_INTEGER;
	i_pMyszy BINARY_INTEGER;
	i_pseudo BINARY_INTEGER;
    i_avg BINARY_INTEGER;
    i_kocur BINARY_INTEGER;


    TYPE t_pseudo IS TABLE OF Kocury.pseudo%TYPE;
    TYPE t_pMyszy IS TABLE OF Kocury.przydzial_myszy%TYPE;
    TYPE t_w_stadku_od IS TABLE OF Kocury.w_stadku_od%TYPE;
    tab_pseudo t_pseudo:=t_pseudo();
    tab_pMyszy t_pMyszy:=t_pMyszy();
    tab_w_stadku_od t_w_stadku_od:=t_w_stadku_od();
    
BEGIN
    DELETE FROM Myszy;
    
    OPEN ostatnie_srody;
    FETCH ostatnie_srody BULK COLLECT INTO srody;
    CLOSE ostatnie_srody;
    
    FOR i_sroda IN 1..(srody.COUNT-1)
    LOOP
        --index do pozniejszego rozdawania myszek
        index_myszy_wpisanie := index_myszy;
        
        first_day_month := TRUNC(srody(i_sroda), 'MONTH');
        
        --wybieranie kotow co dolaczyly przed dana sroda
        SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra,0), w_stadku_od BULK COLLECT INTO tab_pseudo, tab_pMyszy, tab_w_stadku_od
        FROM Kocury
        WHERE W_stadku_od < srody(i_sroda)
        START WITH szef IS NULL CONNECT BY PRIOR pseudo=szef;
        
        --spozycie mies. i avg.
        FOR i_pMyszy IN 1..tab_pMyszy.COUNT
        LOOP
            spoz_month := spoz_month + tab_pMyszy(i_pMyszy);
        END LOOP;
        avg_spoz_month := CEIL(spoz_month / tab_pMyszy.COUNT);
        
        --dodawanie myszy
        FOR i_pseudo IN 1..tab_pseudo.COUNT
        LOOP
            --ustalamy dzien od ktorego dany kot mogl lapac myszy
            IF tab_w_stadku_od(i_pseudo) > first_day_month THEN
                first_day_month := tab_w_stadku_od(i_pseudo);
            END IF;
            
            --dopisujemy kazda mysz, losowo waga i dzien z odp. przedzialu
            FOR i_avg IN 1..avg_spoz_month
            LOOP
                myszki(index_myszy).nr_myszy := index_myszy;
                myszki(index_myszy).lowca := tab_pseudo(i_pseudo);
                myszki(index_myszy).waga_myszy := CEIL(DBMS_RANDOM.VALUE(3, 10));
                myszki(index_myszy).data_zlowienia := first_day_month + DBMS_RANDOM.VALUE(0, srody(i_sroda) - first_day_month);
                index_myszy := index_myszy + 1;
            END LOOP;
            
            --odejmujemy myszy zlapane przez tego kota, ew. sprawdzamy ile musi zlapac ostatni kot przez zaokraglenia
            spoz_month := spoz_month - avg_spoz_month;
            IF spoz_month < avg_spoz_month THEN
                avg_spoz_month := spoz_month;
            END IF;
        END LOOP;
        
        --wyplata zgodnie z hierarchia
        IF data_koniec >= srody(i_sroda) THEN
            i_kocur:=1;
            LOOP
                IF tab_pMyszy(i_kocur) > 0 THEN
                    myszki(index_myszy_wpisanie).zjadacz := tab_pseudo(i_kocur);
                    myszki(index_myszy_wpisanie).data_wydania := srody(i_sroda);
                    tab_pMyszy(i_kocur) := tab_pMyszy(i_kocur)-1;
                    index_myszy_wpisanie := index_myszy_wpisanie+1;
                END IF;
                IF i_kocur = tab_pseudo.COUNT THEN
                    i_kocur := 1;
                ELSE
                    i_kocur := i_kocur+1;
                END IF;
                EXIT WHEN index_myszy_wpisanie = index_myszy;
            END LOOP;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('ilosc_myszek='||myszki.COUNT);
    --zapisanie historii myszek
    FORALL i IN 1..myszki.COUNT
    INSERT INTO Myszy VALUES(
        myszki(i).nr_myszy,
        myszki(i).lowca,
        myszki(i).zjadacz,
        myszki(i).waga_myszy,
        myszki(i).data_zlowienia,
        myszki(i).data_wydania
    );
END;
/

CREATE OR REPLACE PROCEDURE dodaj_myszy(pseudo VARCHAR, dzien_polowania DATE, ile_myszy NUMBER)
IS
    numer_myszy NUMBER;
    avg_myszy NUMBER;
    zlowione_w_miesiacu NUMBER;
    
    TYPE t_myszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    myszki t_myszy;
    
    za_duzo_myszy EXCEPTION;
    i BINARY_INTEGER;
BEGIN
    SELECT AVG(NVL(przydzial_myszy,0)+NVL(myszy_extra,0)) INTO avg_myszy FROM Kocury;
    
    SELECT COUNT(*) INTO zlowione_w_miesiacu
    FROM Myszy
    WHERE lowca=pseudo AND data_zlowienia > TRUNC(dzien_polowania, 'MONTH');
    
    IF ile_myszy > (avg_myszy-zlowione_w_miesiacu) THEN
        RAISE za_duzo_myszy;
    END IF;
    
    SELECT MAX(nr_myszy) INTO numer_myszy FROM Myszy;
    
    FOR i IN 1..ile_myszy
    LOOP
        numer_myszy:=numer_myszy+1;
        myszki(i).nr_myszy := numer_myszy;
        myszki(i).lowca := pseudo;
        myszki(i).waga_myszy := CEIL(DBMS_RANDOM.VALUE(3, 10));
        myszki(i).data_zlowienia := dzien_polowania;
    END LOOP;
    
    FORALL i IN 1..myszki.COUNT
    INSERT INTO Myszy VALUES(
        myszki(i).nr_myszy,
        myszki(i).lowca,
        myszki(i).zjadacz,
        myszki(i).waga_myszy,
        myszki(i).data_zlowienia,
        myszki(i).data_wydania
    );
    EXCEPTION
        WHEN za_duzo_myszy THEN DBMS_OUTPUT.PUT_LINE('Za duzo myszy');
END;
/

--dopisac sprawdzanie srody i wyplata raz w miesiacu 

CREATE OR REPLACE PROCEDURE wyplata_myszy(sroda DATE) IS
    TYPE t_pseudo IS TABLE OF Kocury.pseudo%TYPE;
    TYPE t_pMyszy IS TABLE OF Kocury.przydzial_myszy%TYPE;
    TYPE t_myszy IS TABLE OF Myszy%ROWTYPE INDEX BY BINARY_INTEGER;
    tab_pseudo t_pseudo := t_pseudo();
    tab_pMyszy t_pMyszy := t_pMyszy();
    myszki t_myszy;
    
    i_myszy NUMBER := 1;
    i_kocura NUMBER := 1;
    
    ostatnia_wyplata DATE := TO_DATE('2022-12-28');

BEGIN
    --wszystkie nie wydane jeszcze myszy
    IF (sroda = NEXT_DAY(LAST_DAY(TRUNC(sysdate, 'MONTH')) - 7, 'ŒRODA') AND sroda != ostatnia_wyplata) THEN
        SELECT * BULK COLLECT INTO myszki FROM Myszy WHERE data_wydania IS NULL;
        
        DBMS_OUTPUT.PUT_LINE('Do wyplacenia: ' || myszki.COUNT);
    
        SELECT pseudo, NVL(przydzial_myszy, 0)+NVL(myszy_extra,0) BULK COLLECT INTO tab_pseudo, tab_pMyszy
        FROM Kocury
        START WITH szef IS NULL
        CONNECT BY PRIOR pseudo=szef;
        
        LOOP
            IF tab_pMyszy(i_kocura)>0 THEN
                myszki(i_myszy).zjadacz := tab_pseudo(i_kocura);
                myszki(i_myszy).data_wydania := sroda;
                tab_pMyszy(i_kocura) := tab_pMyszy(i_kocura)-1;
                i_myszy := i_myszy+1;
            END IF;
            
            IF i_kocura = tab_pseudo.COUNT THEN
                i_kocura := 1;
            ELSE
                i_kocura := i_kocura+1;
            END IF;
            EXIT WHEN i_myszy > myszki.COUNT;
        END LOOP;
        
        FORALL i_myszy IN 1..myszki.COUNT
            UPDATE Myszy SET
                zjadacz = myszki(i_myszy).zjadacz,
                data_wydania = myszki(i_myszy).data_wydania
            WHERE nr_myszy = myszki(i_myszy).nr_myszy;
            
        ostatnia_wyplata := SYSDATE;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Dzis nie jest sroda!');
    END IF;
END;
/

EXECUTE dodaj_myszy('PLACEK', TO_DATE('2023-02-04'),30);

SELECT COUNT(*) FROM Myszy WHERE TO_DATE(data_zlowienia) = TO_DATE('2023-02-04');
ROLLBACK;

SELECT SUM(NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0)) 
FROM Kocury 
WHERE w_stadku_od < TO_DATE('2023-01-25');

EXECUTE wyplata_myszy('2023-01-24');

SELECT COUNT(*)
FROM Myszy WHERE data_wydania IS NULL;

ROLLBACK;