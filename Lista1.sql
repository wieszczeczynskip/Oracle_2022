ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--Zadanie 1
SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA" FROM Wrogowie_kocurow 
WHERE data_incydentu < '2010-01-01' AND data_incydentu >= '2009-01-01'; 

--Zadanie 2
SELECT imie, funkcja, w_stadku_od "Z NAMI OD" FROM Kocury
WHERE plec='D' AND w_stadku_od >= '2005-09-01' AND w_stadku_od <= '2007-07-31';

--Zadanie 3
SELECT imie_wroga "WROG", gatunek, stopien_wrogosci "STOPIEN WROGOSCI" FROM Wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci ASC;

--Zadanie 4
SELECT imie||' zwany '||pseudo||' (fun. '||funkcja||') lowi myszki w bandzie '||nr_bandy||' od '||w_stadku_od "WSZYSTKO O KOCURACH" FROM Kocury
WHERE plec='M'
ORDER BY w_stadku_od DESC, pseudo;

--Zadanie 5
SELECT pseudo, REGEXP_REPLACE(REGEXP_REPLACE(pseudo, 'L', '%', 1, 1), 'A', '#', 1, 1) "Po wymianie A na # oraz L na %"  FROM Kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';

--Zadanie 6
SELECT imie, w_stadku_od "W stadku", ROUND(przydzial_myszy/1.1) "Zjada³", ADD_MONTHS(w_stadku_od, 6) "Podwyzka", przydzial_myszy "Zjada"  FROM Kocury
WHERE MONTHS_BETWEEN(SYSDATE,w_stadku_od)>=13*12 AND EXTRACT(month FROM w_stadku_od) BETWEEN 3 AND 9
ORDER BY przydzial_myszy DESC;

--Zadanie 7
SELECT imie, przydzial_myszy*3 "MYSZY KWARTALNIE", NVL(myszy_extra,0)*3 "KWARTALNE DODATKI" FROM Kocury
WHERE przydzial_myszy>55 AND przydzial_myszy>2*NVL(myszy_extra,0)
ORDER BY przydzial_myszy DESC;

--Zadanie 8
SELECT imie,
CASE
    WHEN przydzial_myszy*12>660 THEN TO_CHAR(przydzial_myszy*12)
    WHEN przydzial_myszy*12=660 THEN 'Limit'
    ELSE 'Ponizej 660'
END AS "Zjada rocznie" FROM Kocury
ORDER BY imie;

--Zadanie 9.1
SELECT pseudo, w_stadku_od "W STADKU", 
CASE WHEN NEXT_DAY(LAST_DAY(SYSDATE)-7, 'ŒRODA')>=SYSDATE THEN
    CASE
        WHEN EXTRACT(day FROM w_stadku_od)<=15 THEN NEXT_DAY(LAST_DAY(SYSDATE)-7, 'ŒRODA')
        ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS(SYSDATE,1))-7, 'ŒRODA')
    END
    ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS(SYSDATE,1))-7, 'ŒRODA')
END AS "WYPLATA" FROM Kocury
ORDER BY w_stadku_od;

--Zadanie 9.2
SELECT pseudo, w_stadku_od "W STADKU", 
CASE WHEN NEXT_DAY(LAST_DAY('2022-10-27')-7, 'ŒRODA')>='2022-10-27' THEN
    CASE
        WHEN EXTRACT(day FROM w_stadku_od)<=15 THEN NEXT_DAY(LAST_DAY('2022-10-27')-7, 'ŒRODA')
        ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-27',1))-7, 'ŒRODA')
    END
    ELSE NEXT_DAY(LAST_DAY(ADD_MONTHS('2022-10-27',1))-7, 'ŒRODA')
END AS "WYPLATA" FROM Kocury
ORDER BY w_stadku_od;

--Zadanie 10.1
SELECT 
CASE
    WHEN COUNT(*) = 1 THEN pseudo||' - Unikalny'
    ELSE pseudo||' - Nieunikalny'
END AS "Unikalnoœæ atr. PSEUDO" FROM Kocury
GROUP BY pseudo;

--Zadanie 10.2
SELECT 
CASE
    WHEN COUNT(*) = 1 THEN szef||' - Unikalny'
    ELSE szef||' - Nieunikalny'
END AS "Unikalnoœæ atr. SZEF" FROM Kocury
WHERE szef IS NOT NULL
GROUP BY szef
ORDER BY szef;


--Zadanie 11
SELECT pseudo, COUNT(imie_wroga) "Liczba wrogow" FROM Wrogowie_kocurow
GROUP BY pseudo
HAVING COUNT(imie_wroga)>1;

--Zadanie 12
SELECT 'Liczba kotow=' " ", count(pseudo) "  ", 'lowi jako' "   ", funkcja "    ", 'i zjada max.' "     ", MAX(NVL(przydzial_myszy,0)+NVL(myszy_extra,0)) "      ", 'myszy miesiecznie' "       " FROM Kocury
WHERE plec='D' AND funkcja!='SZEFUNIO'
GROUP BY funkcja
HAVING AVG(NVL(przydzial_myszy,0)+NVL(myszy_extra,0))>50;

--Zadanie 13
SELECT nr_bandy "Nr bandy", plec "Plec", MIN(NVL(przydzial_myszy,0)) "Minimalny przydzial" FROM Kocury
GROUP BY nr_bandy, plec;

--Zadanie 14
SELECT LEVEL "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy" FROM Kocury
WHERE plec='M'
CONNECT BY PRIOR pseudo=szef
START WITH funkcja='BANDZIOR';

--Zadanie 15
SELECT LPAD('===>', (LEVEL-1)*4, '===>')||(LEVEL-1)||'                '||imie "Hierarchia", NVL(szef, 'Sam sobie panem') "Pseudo szefa", funkcja "Funkcja" FROM Kocury
WHERE myszy_extra>0
CONNECT BY PRIOR pseudo=szef
START WITH funkcja='SZEFUNIO';

--Zadanie 16
SELECT LPAD(' ', (LEVEL-1)*4)||pseudo "Droga sluzbowa" FROM Kocury
CONNECT BY PRIOR szef=pseudo
START WITH plec='M' AND MONTHS_BETWEEN(SYSDATE, w_stadku_od)>13*12 AND myszy_extra IS NULL;