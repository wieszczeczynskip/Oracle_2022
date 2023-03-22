ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
CREATE TABLE Funkcje (
    funkcja VARCHAR2(20) CONSTRAINT fu_fu_pk PRIMARY KEY,
    min_myszy NUMBER(3) CONSTRAINT fu_minm_ch CHECK (min_myszy > 5),
    max_myszy NUMBER(3) CONSTRAINT fu_maxm_ch1 CHECK (max_myszy < 200),
    CONSTRAINT fu_maxm_ch2 CHECK (max_myszy >= min_myszy)
    );
CREATE TABLE Wrogowie (
    imie_wroga VARCHAR2(15) CONSTRAINT wr_im_pk PRIMARY KEY,
    stopien_wrogosci NUMBER(2) CONSTRAINT wr_st_ch CHECK (stopien_wrogosci BETWEEN 1 AND 10),
    gatunek VARCHAR2(15),
    lapowka VARCHAR2(20)
    );
CREATE TABLE Kocury (
    imie VARCHAR(15) CONSTRAINT ko_im_nn NOT NULL,
    plec VARCHAR2(1) CONSTRAINT ko_pl_ch CHECK (plec IN ('K', 'M')),
    pseudo VARCHAR2(15) CONSTRAINT ko_pk PRIMARY KEY,
    funkcja VARCHAR2(10) CONSTRAINT ko_fu_fk REFERENCES Funkcje(funkcja),
    szef VARCHAR2(15) CONSTRAINT ko_sz_fk REFERENCES Kocury(pseudo),
    w_stadku_od DATE DEFAULT SYSDATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2)
    );
CREATE TABLE Bandy (
    nr_bandy NUMBER(2) CONSTRAINT ba_nrb_pk PRIMARY KEY,
    nazwa VARCHAR2(20) CONSTRAINT ba_na_nn NOT NULL,
    teren VARCHAR2(15) CONSTRAINT ba_te_un UNIQUE,
    szef_bandy VARCHAR2(15) CONSTRAINT ba_szb_un UNIQUE CONSTRAINT ba_szb_fk REFERENCES Kocury(pseudo)
    );
ALTER TABLE Kocury ADD CONSTRAINT ko_nrb_fk FOREIGN KEY (nr_bandy) REFERENCES Bandy(nr_bandy);
CREATE TABLE Wrogowie_kocurow (
    pseudo VARCHAR2(15) CONSTRAINT wrk_ps_fk REFERENCES Kocury(pseudo),
    imie_wroga VARCHAR2(15) CONSTRAINT wrk_imw_fk REFERENCES Wrogowie(imie_wroga),
    data_incydentu DATE CONSTRAINT wrk_dai_nn NOT NULL,
    opis_incydentu VARCHAR2(50),
    CONSTRAINT wrk_psim_pk PRIMARY KEY(pseudo, imie_wroga)
    );
