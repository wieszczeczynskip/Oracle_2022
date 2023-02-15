ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--Zadanie 17
SELECT pseudo "POLUJE W POLU", przydzial_myszy "PRZYDZIAL MYSZY", nazwa
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE przydzial_myszy > 50 AND teren IN ('POLE', 'CALOSC')
ORDER BY przydzial_myszy DESC;

--Zadanie 18
SELECT K2.imie, K2.w_stadku_od "POLUJE OD" 
FROM Kocury K1, Kocury K2
WHERE K1.imie = 'JACEK' AND K1.w_stadku_od>K2.w_stadku_od
ORDER BY K2.w_stadku_od DESC;

--Zadanie 19a
SELECT K1.imie "Imie", K1.funkcja "Funkcja", NVL(K2.imie, ' ') "Szef 1", NVL(K3.imie, ' ') "Szef 2", NVL(K4.imie, ' ') "Szef 4"
FROM Kocury K1 LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
               LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
               LEFT JOIN Kocury K4 ON K3.szef = K4.pseudo
WHERE K1.funkcja IN ('KOT', 'MILUSIA');

--Zadanie 19b
--zaczynamy od kota/milusi i szukamy szefów i w kazdej krotce jest imie i funkcja z korzenia czyli 1 kota
SELECT *
FROM
(
    SELECT CONNECT_BY_ROOT imie "Imie", imie "Imie szefa", CONNECT_BY_ROOT funkcja "Funkcja", LEVEL "L"
    FROM Kocury
    CONNECT BY PRIOR szef = pseudo
    START WITH funkcja IN ('KOT', 'MILUSIA')
) PIVOT (
    MAX("Imie szefa") FOR L IN (2 "Szef 1", 3 "Szef 2", 4 "Szef 3")
);

--Zadanie 19c
--zaczynamy tam gdzie kot nie ma szefa i szukamy jego podw³adnych i ich podw³adnych i wybieramy te krotki gdzie funkcja to kot/milusia
SELECT imie, funkcja, RTRIM(REVERSE(RTRIM(SYS_CONNECT_BY_PATH(REVERSE(imie), '|'), imie)), '|') "IMIEONA KOLEJNYCH SZEFÓW"
FROM Kocury
WHERE funkcja = 'KOT' OR funkcja = 'MILUSIA'
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

--Zadanie 20
SELECT K.imie "Imie kotki", B.nazwa "Nazwa bandy", WK.imie_wroga "Imie wroga", W.stopien_wrogosci "Ocena wroga", WK.data_incydentu "Data inc."
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
              JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
              JOIN Wrogowie W ON WK.imie_wroga = W.imie_wroga
WHERE WK.data_incydentu > '2007-01-01' AND K.plec = 'D'
ORDER BY K.imie, WK.imie_wroga;

--Zadanie 21
SELECT B.nazwa "Nazwa bandy", COUNT(DISTINCT K.pseudo) "Koty z wrogami"
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
              JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY B.nazwa;

--Zadanie 22
SELECT K.funkcja "Funkcja", K.pseudo "Pseudonim kota", COUNT(WK.imie_wroga) "Liczba wrogow"
FROM Kocury K JOIN Wrogowie_kocurow WK ON K.pseudo = WK.pseudo
GROUP BY K.pseudo, K.funkcja
HAVING COUNT(WK.imie_wroga) > 1;

-- Zadanie 23
SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra > 0 AND (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 > 864
UNION
SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 "DAWKA ROCZNA", '864' "DAWKA"
FROM Kocury
WHERE myszy_extra > 0 AND (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 = 864
UNION
SELECT imie, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM Kocury
WHERE myszy_extra > 0 AND (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) * 12 < 864
ORDER BY 2 DESC;

-- Zadanie 24a
SELECT B.nr_bandy "NR BANDY", B.nazwa, B.teren
FROM Bandy B LEFT JOIN Kocury K ON B.nr_bandy = K.nr_bandy
WHERE K.pseudo IS NULL;

-- Zadanie 24b
SELECT nr_bandy "NR BANDY", nazwa, teren
FROM Bandy JOIN (SELECT nr_bandy
      FROM Bandy
      MINUS
      SELECT nr_bandy
      FROM Kocury) USING (nr_bandy);

-- Zadanie 25
SELECT imie, funkcja, przydzial_myszy
FROM Kocury
WHERE przydzial_myszy >= 3 * 
(SELECT przydzial_myszy 
 FROM 
 (SELECT *
  FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
  ORDER BY przydzial_myszy DESC)
 WHERE funkcja = 'MILUSIA' AND teren in ('SAD', 'CALOSC') AND ROWNUM = 1);

-- Zadanie 26
SELECT funkcja,  ROUND(AVG(NVL(przydzial_myszy, 0 ) + NVL(myszy_extra, 0))) "Œrednio najw. i najm. myszy"
FROM Kocury
WHERE funkcja <> 'SZEFUNIO'
GROUP BY funkcja
HAVING ROUND(AVG(NVL(przydzial_myszy, 0 ) + NVL(myszy_extra, 0))) IN (
        (SELECT MAX(ROUND(AVG(NVL(przydzial_myszy, 0 ) + NVL(myszy_extra, 0))))
         FROM Kocury
         WHERE funkcja <> 'SZEFUNIO'
         GROUP BY funkcja),
        (SELECT MIN(ROUND(AVG(NVL(przydzial_myszy, 0 ) + NVL(myszy_extra, 0))))
         FROM Kocury
         WHERE funkcja <> 'SZEFUNIO'
         GROUP BY funkcja));

-- Zadanie 27a
-- DISTINCT w COUNT
SELECT pseudo, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "Zjada"
FROM KOCURY K
WHERE 6 > 
(SELECT COUNT(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))
 FROM KOCURY
 WHERE (NVL(K.przydzial_myszy, 0) + NVL(K.myszy_extra, 0) < NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)))
ORDER BY "Zjada" DESC;

-- Zadanie 27b
-- DISTINCT w ostatnim SELECT
SELECT pseudo, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "Zjada"
FROM Kocury
WHERE (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) IN
(SELECT *
 FROM
 (SELECT NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)
  FROM Kocury
  ORDER BY NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) DESC)
 WHERE ROWNUM <= 6);
 
-- Zadanie 27c
-- DISTINCT w COUNT
SELECT K1.pseudo, MIN(NVL(K1.przydzial_myszy, 0) + NVL(K1.myszy_extra, 0)) "Zjada"
FROM Kocury K1 LEFT JOIN Kocury K2 ON (NVL(K1.przydzial_myszy, 0) + NVL(K1.myszy_extra,0)) < (NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra,0))
GROUP BY K1.pseudo
HAVING COUNT(DISTINCT NVL(K2.przydzial_myszy, 0) + NVL(K2.myszy_extra,0)) <= 1
ORDER BY "Zjada" DESC;

-- Zadanie 27d
-- DENSE_RANK()
SELECT pseudo, "Zjada"
FROM
(SELECT pseudo, (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) "Zjada", RANK() OVER (ORDER BY (NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) DESC) "Pozycja"
 FROM Kocury)
WHERE "Pozycja" <= 7;

-- Zadanie 28
SELECT TO_CHAR(EXTRACT (YEAR FROM w_stadku_od)) "ROK", COUNT(*) "Liczba wst¹pieñ"
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
HAVING COUNT(*) IN 
(
    (SELECT *
     FROM
        (SELECT COUNT(*)
         FROM Kocury
         GROUP BY EXTRACT(YEAR FROM w_stadku_od)
         HAVING COUNT(*) > 
            (SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od)))
             FROM Kocury
             GROUP BY EXTRACT(YEAR FROM w_stadku_od)
            )
         ORDER BY COUNT(*)
        )
     WHERE ROWNUM = 1
    ),
    (SELECT *
     FROM
        (SELECT COUNT(*)
         FROM Kocury
         GROUP BY EXTRACT(YEAR FROM w_stadku_od)
         HAVING COUNT(*) < 
            (SELECT AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od)))
             FROM Kocury
             GROUP BY EXTRACT(YEAR FROM w_stadku_od)
            )
         ORDER BY COUNT(*) DESC
        )
     WHERE ROWNUM = 1
    )
)
UNION
SELECT 'Œrednia', ROUND(AVG(COUNT(EXTRACT(YEAR FROM w_stadku_od))), 7)
FROM Kocury
GROUP BY EXTRACT(YEAR FROM w_stadku_od)
ORDER BY 2;

-- Zadanie 29a
SELECT K1.imie, MIN(NVL(K1.przydzial_myszy, 0)+NVL(K1.myszy_extra, 0)) "ZJADA", MIN(K1.nr_bandy) "NR BANDY", AVG(NVL(K2.przydzial_myszy, 0)+NVL(K2.myszy_extra, 0)) "SREDNIA BANDY"
FROM Kocury K1 JOIN Kocury K2 ON K1.nr_bandy = K2.nr_bandy
WHERE K1.plec = 'M'
GROUP BY K1.imie
HAVING MIN(NVL(K1.przydzial_myszy, 0)+NVL(K1.myszy_extra, 0)) < AVG(NVL(K2.przydzial_myszy, 0)+NVL(K2.myszy_extra, 0));

-- Zadanie 29b
SELECT imie, NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0) "ZJADA", nr_bandy "NR BANDY", "SREDNIA BANDY"
FROM 
    (SELECT nr_bandy, AVG(NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0)) "SREDNIA BANDY"
     FROM Kocury
     GROUP BY nr_bandy)
    JOIN Kocury USING (nr_bandy)
WHERE NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0) < "SREDNIA BANDY" AND plec = 'M'
GROUP BY imie, NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0), nr_bandy, "SREDNIA BANDY";

-- Zadanie 29c
SELECT imie, NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0) "ZJADA", nr_bandy "NR BANDY",
    (SELECT AVG(NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0))
     FROM Kocury K2
     WHERE K2.nr_bandy = K1.nr_bandy) "SREDNIA BANDY"
FROM Kocury K1
WHERE K1.plec = 'M' AND NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0) < 
    (SELECT AVG(NVL(przydzial_myszy, 0)+NVL(myszy_extra, 0))
     FROM Kocury K2
     WHERE K2.nr_bandy = K1.nr_bandy);

-- Zadanie 30
SELECT imie, TO_CHAR(w_stadku_od) || ' <--- NAJSTARSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM 
    (SELECT imie, w_stadku_od, nazwa, MAX(w_stadku_od) OVER (PARTITION BY K.nr_bandy) maxstaz
     FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    )
WHERE w_stadku_od = maxstaz
UNION
SELECT imie, TO_CHAR(w_stadku_od) || ' <--- NAJMLODSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM 
    (SELECT imie, w_stadku_od, nazwa, MIN(w_stadku_od) OVER (PARTITION BY K.nr_bandy) minstaz
     FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
    )
WHERE w_stadku_od = minstaz
UNION
SELECT imie, TO_CHAR(w_stadku_od)
FROM
    (SELECT imie, w_stadku_od,  
     MAX(w_stadku_od) OVER (PARTITION BY K.nr_bandy) maxstaz,
     MIN(w_stadku_od) OVER (PARTITION BY K.nr_bandy) minstaz
     FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy)
WHERE w_stadku_od != maxstaz AND w_stadku_od != minstaz;

-- Zadanie 31
CREATE OR REPLACE VIEW Bandy_info(nazwa_bandy, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS
SELECT nazwa, AVG(NVL(przydzial_myszy, 0)), MAX(NVL(przydzial_myszy, 0)), MIN(NVL(przydzial_myszy, 0)), COUNT(pseudo), COUNT(myszy_extra)
FROM Bandy B JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY nazwa;

SELECT * FROM Bandy_info;

SELECT pseudo "PSEUDONIM", imie, funkcja, NVL(przydzial_myszy, 0) "ZJADA", 'OD ' || min_spoz || ' DO ' || max_spoz "GRANICE SPOZYCIA", w_stadku_od "LOWI OD"
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy JOIN Bandy_info BI ON B.nazwa = BI.nazwa_bandy
WHERE pseudo = UPPER('&pseudo');

-- Zadanie 32
-- Przed zmian¹
SELECT pseudo "Pseudonim", plec "Plec", NVL(przydzial_myszy, 0) "Myszy przez podw.", NVL(myszy_extra, 0) "Extra przed podw."
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE pseudo IN 
(
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'LACIACI MYSLIWI'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
    UNION
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'CZARNI RYCERZE'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
);

-- Zmiana
UPDATE Kocury
SET przydzial_myszy = przydzial_myszy + DECODE(plec, 'D', 0.1 * (SELECT MIN(przydzial_myszy) FROM Kocury), 10),
    myszy_extra = NVL(myszy_extra, 0) + 0.15 * (SELECT AVG(NVL(myszy_extra, 0)) FROM Kocury K WHERE Kocury.nr_bandy = K.nr_bandy)
WHERE pseudo IN 
(
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'LACIACI MYSLIWI'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
    UNION
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'CZARNI RYCERZE'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
);

-- Po zmianie
SELECT pseudo "Pseudonim", plec "Plec", NVL(przydzial_myszy, 0) "Myszy po podw.", NVL(myszy_extra, 0) "Extra po podw."
FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
WHERE pseudo IN 
(
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'LACIACI MYSLIWI'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
    UNION
    (SELECT *
     FROM
        (SELECT pseudo 
         FROM Kocury K JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         WHERE nazwa = 'CZARNI RYCERZE'
         ORDER BY w_stadku_od ASC
        )
     WHERE ROWNUM <= 3
    )
);

-- Wycofanie zmian
ROLLBACK;

-- Zadanie 33a
SELECT DECODE(plec, 'Kocur', ' ', nazwa) "NAZWA BANDY", plec, "ILE", "SZEFUNIO", "BANDZIOR", "LOWCZY", "LAPACZ", "KOT", "MILUSIA", "DZIELCZY", "SUMA"
FROM
    (SELECT nazwa, DECODE(plec, 'D', 'Kotka', 'Kocur') plec, TO_CHAR(COUNT(pseudo)) "ILE",
     TO_CHAR(SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "SZEFUNIO",
     TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "BANDZIOR",
     TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "LOWCZY",
     TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "LAPACZ",
     TO_CHAR(SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "KOT",
     TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "MILUSIA",
     TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "DZIELCZY",
     TO_CHAR(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) "SUMA"
     FROM Kocury NATURAL JOIN Bandy
     GROUP BY nazwa, plec
     UNION ALL
     SELECT 'Z----------------', '------', '----', '---------', '---------', '---------', '---------', '---------', '---------', '---------', '-------'
     FROM dual
     UNION ALL
     SELECT 'ZJADA RAZEM', ' ', ' ',
     TO_CHAR(SUM(DECODE(funkcja, 'SZEFUNIO', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "SZEFUNIO",
     TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "BANDZIOR",
     TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "LOWCZY",
     TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "LAPACZ",
     TO_CHAR(SUM(DECODE(funkcja, 'KOT', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "KOT",
     TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "MILUSIA",
     TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0), 0))) "DZIELCZY",
     TO_CHAR(SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0))) "SUMA"
     FROM Kocury NATURAL JOIN Bandy
     ORDER BY 1,2 DESC
    );

-- Zadanie 33b
SELECT DECODE(plec, 'M', ' ', nazwa) "NAZWA BANDY", 
       DECODE(plec, 'D', 'Kotka', 'Kocur') plec, 
       TO_CHAR(ile) ile, 
       TO_CHAR(NVL(szefunio, 0)) szefunio, 
       TO_CHAR(NVL(bandzior, 0)) bandzior, 
       TO_CHAR(NVL(lowczy, 0)) lowczy, 
       TO_CHAR(NVL(lapacz, 0)) lapacz, 
       TO_CHAR(NVL(kot, 0)) kot, 
       TO_CHAR(NVL(milusia, 0)) milusia,
       TO_CHAR(NVL(dzielczy, 0)) dzielczy,
       TO_CHAR(suma) suma
FROM 
    (SELECT nazwa, plec, funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) przydzial
     FROM Kocury NATURAL JOIN Bandy)
        PIVOT
        (SUM(przydzial) FOR funkcja IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy))
        JOIN 
        (SELECT nazwa "N", plec "P", COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
         FROM Kocury K JOIN Bandy B ON K.nr_bandy= B.nr_bandy
         GROUP BY nazwa, plec
         ORDER BY nazwa)
        ON N = nazwa AND P = plec
    
UNION ALL

SELECT 'Z----------------', '------', '----', '---------', '---------', '---------', '---------', '---------', '---------', '---------', '-------'
FROM dual

UNION ALL

SELECT 'ZJADA RAZEM',
       ' ',
       ' ',
       TO_CHAR(NVL(szefunio, 0)) szefunio, 
       TO_CHAR(NVL(bandzior, 0)) bandzior, 
       TO_CHAR(NVL(lowczy, 0)) lowczy, 
       TO_CHAR(NVL(lapacz, 0)) lapacz, 
       TO_CHAR(NVL(kot, 0)) kot, 
       TO_CHAR(NVL(milusia, 0)) milusia,
       TO_CHAR(NVL(dzielczy, 0)) dzielczy,
       TO_CHAR(suma) suma
FROM
    (SELECT funkcja, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) przydzial
     FROM Kocury NATURAL JOIN Bandy)
        PIVOT
        (SUM(przydzial) FOR funkcja IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy))
        CROSS JOIN
        (SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma FROM Kocury);
       
